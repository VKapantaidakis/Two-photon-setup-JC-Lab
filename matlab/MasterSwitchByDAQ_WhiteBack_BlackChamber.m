function MasterSwitchByDAQ_WhiteBack_BlackChamber
clc;

% ============================================================
% MASTER SCRIPT  (frame-logging version) - UBUNTU / MATLAB R2014b
%
% Protocol:
%   1. Ask for experiment metadata (Command Window, no Java dialog).
%   2. Open ViRMEn.
%   3. Open Arduino serial via arduinoFrameLog (single reader).
%   4. Wait for first DAQ/Arduino TTL pulse.
%   5. Load WhiteBack visual world, run WhiteBack.m code.
%   6. When WhiteBack ends at its frame threshold, switch.
%   7. Load BlackChamber visual world, run BlackChamber.m code.
%   8. Save all frame logs (CSV) into the session output folder.
%
% ---- IMPORTANT: LAUNCH MATLAB WITHOUT -softwareopengl ------------
%  ViRMEn's 3D engine (virmenOpenGLRoutines.mexa64) segfaults inside
%  MATLAB's bundled software libGL. Run experiments from the
%  "MATLAB 2P EXPERIMENT (hardware GL)" launcher. Use the
%  -softwareopengl launcher ONLY for designing worlds in the GUI.
%
% ---- LINUX NOTES ------------------------------------------------
%  * MATLAB R2014b on Linux only sees /dev/ttyS* ports. Symlink the
%    Arduino once (a udev rule makes it permanent):
%        sudo ln -sf /dev/ttyACM0 /dev/ttyS101
%  * User must be in the 'dialout' group:
%        sudo usermod -aG dialout $USER      (then log out / back in)
% ============================================================

% ------------------------------------------------------------
% 0) EDIT THESE FOR YOUR MACHINE
% ------------------------------------------------------------
SERIAL_PORT = '/dev/ttyS101';   % symlink to /dev/ttyACM0
baudRate    = 115200;

SHOW_LIVE_MONITOR = true;   % OPTION A: live DAQ panel during the run
MONITOR_EVERY     = 10;     % refresh the panel every N frames
AUTO_PLOT_AT_END  = true;   % OPTION B: plot the session when finished
PRINT_EVERY       = 50;     % console line every N frames (0 = off)

% ---- VR DISPLAY -----------------------------------------------------
% Testing on one screen: set FULLSCREEN_VR = false so the live monitor
% stays visible next to a windowed VR view.
% With the projector connected as a SECOND display: set
% FULLSCREEN_VR = true and VR_MONITOR = 2 so the fly gets the projector
% and your laptop screen keeps MATLAB + the monitor panel.
FULLSCREEN_VR = false;      % true = fullscreen (covers everything on that monitor)
VR_MONITOR    = 1;          % 1 = primary/laptop, 2 = projector when extended
VR_WIN_W      = 900;        % windowed size (used when FULLSCREEN_VR = false)
VR_WIN_H      = 700;
VR_WIN_LEFT   = 950;        % windowed position
VR_WIN_BOTTOM = 300;

rootDir  = fullfile(getenv('HOME'), 'Documents', 'MATLAB', 'virmen');
expDir   = fullfile(rootDir, 'experiments');
dataRoot = fullfile(getenv('HOME'), 'Documents', 'MATLAB', 'ExperimentData');

whiteBackMat    = fullfile(expDir, 'WhiteBack.mat');
blackChamberMat = fullfile(expDir, 'BlackChamber.mat');

% ============================================================
% 1) EXPERIMENT METADATA
% ============================================================
meta = getExperimentMetadata();

sessionStamp = datestr(now, 'yyyymmdd_HHMMSS');
dayStr       = datestr(now, 'yyyymmdd');
sessionName  = sprintf('%s_%s_%s_%s', meta.experimenter, meta.strain, ...
                       meta.experiment, datestr(now,'HHMMSS'));
sessionName  = regexprep(sessionName, '[^\w\-]', '_');
logDir       = fullfile(dataRoot, dayStr, sessionName);
if ~exist(logDir, 'dir'), mkdir(logDir); end

sessionTag        = ['sess_' sessionStamp];
meta.sessionTag   = sessionTag;
meta.sessionStart = datestr(now, 'yyyy-mm-dd HH:MM:SS');
meta.logDir       = logDir;
save(fullfile(logDir, 'metadata.mat'), 'meta');
writeMetadataTxt(fullfile(logDir, 'metadata.txt'), meta);

fprintf('\n=== SESSION ===\n');
fprintf('Experimenter : %s\n', meta.experimenter);
fprintf('Strain       : %s\n', meta.strain);
fprintf('Age (days)   : %s\n', meta.ageDays);
fprintf('Sex          : %s\n', meta.sex);
fprintf('Experiment   : %s\n', meta.experiment);
fprintf('Notes        : %s\n', meta.notes);
fprintf('Output folder: %s\n\n', logDir);

global guifig %#ok<*GVMIS>

% ============================================================
% OPEN VIRMEN
% ============================================================
if isempty(guifig) || ~ishandle(guifig)
    addpath(genpath(rootDir));
    virmen;
    pause(2);
end
if isempty(guifig) || ~ishandle(guifig)
    error('ViRMEn GUI did not open correctly.');
end

addpath(expDir);
rehash;
clear WhiteBack BlackChamber

% ============================================================
% CHECK REQUIRED FILES
% ============================================================
assert(exist(whiteBackMat, 'file') == 2,    'Missing file: %s', whiteBackMat);
assert(exist(blackChamberMat, 'file') == 2, 'Missing file: %s', blackChamberMat);
assert(exist(fullfile(expDir, 'WhiteBack.m'), 'file') == 2,    'Missing WhiteBack.m');
assert(exist(fullfile(expDir, 'BlackChamber.m'), 'file') == 2, 'Missing BlackChamber.m');
assert(exist('arduinoFrameLog', 'file') == 2, ...
    'Missing arduinoFrameLog.m -- put it on the MATLAB path.');

fprintf('Frame logs will be written to:\n  %s\n', logDir);
fprintf('Session tag: %s\n\n', sessionTag);

% ============================================================
% OPEN ARDUINO SERIAL (single owner: arduinoFrameLog)
% ============================================================
arduinoFrameLog('init', SERIAL_PORT, baudRate);
arduinoFrameLog('zero');
arduinoFrameLog('ledson');
arduinoFrameLog('start');

% ---- OPTION A: live DAQ monitor panel -------------------------------
% Fed by the same single reader (no second serial connection).
% Refresh every N frames; 10-20 is a good balance. Lower = snappier but
% competes with the ViRMEn render loop.
if SHOW_LIVE_MONITOR
    arduinoFrameLog('monitor', MONITOR_EVERY);
end
arduinoFrameLog('verbose', PRINT_EVERY);   % console frame counter

% ============================================================
% RESET BASE VARIABLES
% ============================================================
assignin('base', 'latestArduinoFrame', NaN);
assignin('base', 'lastExperimentEndReason', '');
assignin('base', 'lastExperimentEndFrame', NaN);
assignin('base', 'frameLog_WhiteBack', []);
assignin('base', 'frameLog_BlackChamber', []);
assignin('base', 'firstDAQPulseFrame', NaN);
assignin('base', 'firstDAQPulseClock', NaN);
assignin('base', 'firstDAQPulseClockStr', '');

% ============================================================
% WAIT FOR FIRST DAQ / ARDUINO PULSE
% ============================================================
fprintf('\nMaster script is armed.\n');
fprintf('You can start this BEFORE the DAQ starts.\n');
fprintf('Waiting for first DAQ/Arduino frame pulse on %s ...\n\n', SERIAL_PORT);

arduinoFrameLog('phase', 'preTrigger');
first      = arduinoFrameLog('waitfirst');
firstFrame = first(1);
firstClock = first(2);

assignin('base', 'firstDAQPulseFrame', firstFrame);
assignin('base', 'firstDAQPulseClock', firstClock);
assignin('base', 'firstDAQPulseClockStr', ...
    datestr(firstClock, 'yyyy-mm-dd HH:MM:SS.FFF'));

fprintf('First DAQ pulse received.\n');
fprintf('  Frame: %.0f\n', firstFrame);
fprintf('  Time: %s\n\n', datestr(firstClock, 'yyyy-mm-dd HH:MM:SS.FFF'));

% ============================================================
% PHASE 1: WHITEBACK
% ============================================================
fprintf('=== Loading WhiteBack world + WhiteBack code ===\n');
vrDisp = struct('fullScreen',FULLSCREEN_VR,'monitor',VR_MONITOR, ...
                'w',VR_WIN_W,'h',VR_WIN_H,'left',VR_WIN_LEFT,'bottom',VR_WIN_BOTTOM);
loadSavedExperimentIntoGui(whiteBackMat, @WhiteBack, vrDisp);

handles = guidata(guifig);
fprintf('Experiment code:   %s\n', func2str(handles.exper.experimentCode));
fprintf('Movement function: %s\n', func2str(handles.exper.movementFunction));
fprintf('Number of worlds:  %d\n', length(handles.exper.worlds));

arduinoFrameLog('phase', 'WhiteBack');

fprintf('\n=== Running WhiteBack ===\n');
virmenEventHandler('run', []);
fprintf('=== WhiteBack finished ===\n');

arduinoFrameLog('poll');
arduinoFrameLog('save', logDir, [sessionTag '_afterWhiteBack']);
arduinoFrameLog('stats');

whiteEndReason = evalin('base', 'lastExperimentEndReason');
whiteEndFrame  = evalin('base', 'lastExperimentEndFrame');
fprintf('WhiteBack end reason: %s\n', whiteEndReason);
fprintf('WhiteBack end frame: %.0f\n', whiteEndFrame);

if ~strcmp(whiteEndReason, 'frameThreshold')
    fprintf('\nNot switching because WhiteBack did not end from frame threshold.\n');
    fprintf('Expected reason: frameThreshold\n');
    fprintf('Actual reason: %s\n', whiteEndReason);
    arduinoFrameLog('save', logDir, [sessionTag '_ABORTED']);
    arduinoFrameLog('close');
    if AUTO_PLOT_AT_END
        try plotSession(logDir); catch, end
    end
    return
end

arduinoFrameLog('phase', 'interval');
pause(0.5);
arduinoFrameLog('poll');

% ============================================================
% PHASE 2: BLACKCHAMBER
% ============================================================
fprintf('\n=== Loading BlackChamber world + BlackChamber code ===\n');
loadSavedExperimentIntoGui(blackChamberMat, @BlackChamber, vrDisp);

handles = guidata(guifig);
fprintf('Experiment code:   %s\n', func2str(handles.exper.experimentCode));
fprintf('Movement function: %s\n', func2str(handles.exper.movementFunction));
fprintf('Number of worlds:  %d\n', length(handles.exper.worlds));

arduinoFrameLog('phase', 'BlackChamber');

fprintf('\n=== Running BlackChamber ===\n');
virmenEventHandler('run', []);
fprintf('=== BlackChamber finished ===\n');

arduinoFrameLog('poll');

blackEndReason = evalin('base', 'lastExperimentEndReason');
blackEndFrame  = evalin('base', 'lastExperimentEndFrame');
fprintf('BlackChamber end reason: %s\n', blackEndReason);
fprintf('BlackChamber end frame: %.0f\n', blackEndFrame);

% ============================================================
% SAVE + CLOSE
% ============================================================
fprintf('\n=== Writing frame logs ===\n');
arduinoFrameLog('save', logDir, sessionTag);
arduinoFrameLog('stats');

T = arduinoFrameLog('table');
assignin('base', 'frameLogTable', T);
try
    save(fullfile(logDir, [sessionTag '_frameLogTable.mat']), 'T');
catch
end

arduinoFrameLog('close');

fprintf('\nAll done. Data in:\n  %s\n', logDir);

% ---- OPTION B: plot the session now ---------------------------------
if AUTO_PLOT_AT_END
    try
        plotSession(logDir);
    catch ME
        fprintf(2,'Could not auto-plot session: %s\n', ME.message);
        fprintf('You can plot it later with:  plotSession(''%s'')\n', logDir);
    end
end

end


% =====================================================================
% HELPER: EXPERIMENT METADATA (Command Window -- no Java dialog)
% =====================================================================
function meta = getExperimentMetadata()

fprintf('\n===== EXPERIMENT METADATA =====\n');
meta.experimenter = input('Experimenter name        : ', 's');
meta.strain       = input('Fly strain / genotype    : ', 's');
meta.ageDays      = input('Fly age (days)           : ', 's');
meta.sex          = input('Sex (M/F)                : ', 's');
meta.experiment   = input('Experiment name          : ', 's');
meta.notes        = input('Notes (optional)         : ', 's');

meta.experimenter = strtrim(meta.experimenter);
meta.strain       = strtrim(meta.strain);
meta.ageDays      = strtrim(meta.ageDays);
meta.sex          = strtrim(meta.sex);
meta.experiment   = strtrim(meta.experiment);
meta.notes        = strtrim(meta.notes);

if isempty(meta.experimenter), meta.experimenter = 'unknown';    end
if isempty(meta.strain),       meta.strain       = 'strain';     end
if isempty(meta.experiment),   meta.experiment   = 'experiment'; end
if isempty(meta.sex),          meta.sex          = 'F';          end
if isempty(meta.ageDays),      meta.ageDays      = 'NA';         end
fprintf('===============================\n\n');

end


% =====================================================================
% HELPER: WRITE METADATA AS READABLE TEXT
% =====================================================================
function writeMetadataTxt(fpath, meta)

fid = fopen(fpath, 'w');
if fid < 0, warning('Could not write metadata.txt'); return; end
fn = fieldnames(meta);
for i = 1:numel(fn)
    v = meta.(fn{i});
    if ~ischar(v), v = num2str(v); end
    fprintf(fid, '%-14s : %s\n', fn{i}, v);
end
fclose(fid);

end


% =====================================================================
% HELPER: LOAD SAVED VIRMEN EXPERIMENT INTO GUI
% =====================================================================
function loadSavedExperimentIntoGui(matFile, codeHandle, vrDisp)

global guifig

S = load(matFile, 'exper');
if ~isfield(S, 'exper')
    error('File does not contain variable "exper": %s', matFile);
end

handles = guidata(guifig);
exper   = S.exper;
exper.enableCallbacks;
handles.exper = exper;

% Use the visual world from the .mat file, but override the code.
handles.exper.experimentCode   = codeHandle;
handles.exper.movementFunction = @moveWithKeyboard;

% ---- ViRMEn display window ----
handles.exper.windows = handles.exper.windows(1);

handles.exper.windows{1}.rendering3D    = true;
handles.exper.windows{1}.transformation = 1;
handles.exper.windows{1}.antialiasing   = 0;
handles.exper.windows{1}.monitor        = vrDisp.monitor;
handles.exper.windows{1}.primaryMonitor = (vrDisp.monitor == 1);

if vrDisp.fullScreen
    scr = get(0, 'ScreenSize');
    handles.exper.windows{1}.fullScreen = true;
    handles.exper.windows{1}.left   = 1;
    handles.exper.windows{1}.bottom = 1;
    handles.exper.windows{1}.width  = scr(3);
    handles.exper.windows{1}.height = scr(4);
else
    handles.exper.windows{1}.fullScreen = false;
    handles.exper.windows{1}.left   = vrDisp.left;
    handles.exper.windows{1}.bottom = vrDisp.bottom;
    handles.exper.windows{1}.width  = vrDisp.w;
    handles.exper.windows{1}.height = vrDisp.h;
end

[~, fname, ext] = fileparts(matFile);
handles.state.fileName       = [fname ext];
handles.state.selectedWorld  = 1;
handles.state.selectedObject = 0;
handles.state.selectedShape  = 1;

handles.history.position = 1;
handles.history.states{handles.history.position}.state = handles.state;
for ndx = 2:length(handles.history.states)
    handles.history.states{ndx}.state = [];
end

guidata(guifig, handles);
updateFigures('openExperiment');
figure(guifig);

fprintf('Loaded saved experiment: %s\n', [fname ext]);
fprintf('Set experimentCode to: %s\n', func2str(codeHandle));
fprintf('Window: fullScreen=%d monitor=%d %dx%d\n', ...
    handles.exper.windows{1}.fullScreen, handles.exper.windows{1}.monitor, ...
    handles.exper.windows{1}.width, handles.exper.windows{1}.height);

end
