function MasterSwitchByDAQ600_MainScreen_FirstPulse
clc;

rootDir = 'C:\Users\S5085721\Desktop\2P-Vasilis\ViRMEn 2016-02-12';
expDir  = fullfile(rootDir, 'experiments');

portName = 'COM4';
baudRate = 115200;

exp1Mat = fullfile(expDir, 'WhiteChamber.mat');
exp2Mat = fullfile(expDir, 'WhiteChamberDots.mat');

global guifig

% Open ViRMEn if needed
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
clear WhiteChamber WhiteChamberDots

assert(exist(exp1Mat,'file')==2, 'Missing file: %s', exp1Mat);
assert(exist(exp2Mat,'file')==2, 'Missing file: %s', exp2Mat);
assert(exist(fullfile(expDir,'WhiteChamber.m'),'file')==2, 'Missing WhiteChamber.m');
assert(exist(fullfile(expDir,'WhiteChamberDots.m'),'file')==2, 'Missing WhiteChamberDots.m');

% Open shared Arduino serial once
setupSharedArduinoSerial(portName, baudRate);

% Reset shared variables
assignin('base', 'latestArduinoFrame', NaN);
assignin('base', 'lastExperimentEndReason', '');
assignin('base', 'lastExperimentEndFrame', NaN);
assignin('base', 'frameLog_WhiteChamber', []);
assignin('base', 'frameLog_WhiteChamberDots', []);
assignin('base', 'firstDAQPulseFrame', NaN);
assignin('base', 'firstDAQPulseClock', NaN);
assignin('base', 'firstDAQPulseClockStr', '');

fprintf('\nMaster script is armed.\n');
fprintf('You can start this BEFORE the DAQ starts.\n');
fprintf('Waiting for first DAQ/Arduino frame pulse on %s ...\n\n', portName);

% Wait for first pulse before starting experiment 1
[firstFrame, firstClock] = waitForFirstPulse();

assignin('base', 'firstDAQPulseFrame', firstFrame);
assignin('base', 'firstDAQPulseClock', firstClock);
assignin('base', 'firstDAQPulseClockStr', datestr(firstClock, 'yyyy-mm-dd HH:MM:SS.FFF'));

fprintf('First DAQ pulse received.\n');
fprintf('  Frame: %.0f\n', firstFrame);
fprintf('  Time: %s\n\n', datestr(firstClock, 'yyyy-mm-dd HH:MM:SS.FFF'));

% ---------- FIRST EXPERIMENT ----------
fprintf('=== Loading WhiteChamber saved experiment ===\n');
loadSavedExperimentIntoGui(exp1Mat, @WhiteChamber);

handles = guidata(guifig);
fprintf('Experiment code before run 1: %s\n', func2str(handles.exper.experimentCode));
fprintf('Movement function before run 1: %s\n', func2str(handles.exper.movementFunction));
fprintf('Number of worlds before run 1: %d\n', length(handles.exper.worlds));

fprintf('=== Running WhiteChamber ===\n');
virmenEventHandler('run', []);
fprintf('=== WhiteChamber finished ===\n');

endReason = evalin('base', 'lastExperimentEndReason');
endFrame  = evalin('base', 'lastExperimentEndFrame');

fprintf('WhiteChamber end reason: %s\n', endReason);
fprintf('WhiteChamber end frame: %.0f\n', endFrame);

if ~strcmp(endReason, 'frameThreshold')
    fprintf('Not switching because WhiteChamber did not end from frame threshold.\n');
    return
end

pause(0.5);

% ---------- SECOND EXPERIMENT ----------
fprintf('\n=== Loading WhiteChamberDots saved experiment ===\n');
loadSavedExperimentIntoGui(exp2Mat, @WhiteChamberDots);

handles = guidata(guifig);
fprintf('Experiment code before run 2: %s\n', func2str(handles.exper.experimentCode));
fprintf('Movement function before run 2: %s\n', func2str(handles.exper.movementFunction));
fprintf('Number of worlds before run 2: %d\n', length(handles.exper.worlds));

fprintf('=== Running WhiteChamberDots ===\n');
virmenEventHandler('run', []);
fprintf('=== WhiteChamberDots finished ===\n');

endReason = evalin('base', 'lastExperimentEndReason');
endFrame  = evalin('base', 'lastExperimentEndFrame');

fprintf('WhiteChamberDots end reason: %s\n', endReason);
fprintf('WhiteChamberDots end frame: %.0f\n', endFrame);

fprintf('\nAll done.\n');

end


function setupSharedArduinoSerial(portName, baudRate)
if evalin('base', 'exist(''sharedArduinoSerial'',''var'')')
    try
        s = evalin('base', 'sharedArduinoSerial');
        if strcmp(get(s, 'Status'), 'open')
            fprintf('Using existing shared Arduino serial on %s\n', portName);
            flushinput(s);
            return
        end
    catch
    end
end

instrreset;
oldObj = instrfind('Port', portName);
if ~isempty(oldObj)
    for k = 1:length(oldObj)
        try
            fclose(oldObj(k));
        catch
        end
        try
            delete(oldObj(k));
        catch
        end
    end
end

s = serial(portName);
set(s, 'BaudRate', baudRate);
set(s, 'Terminator', 'LF');
fopen(s);

% Allow Arduino reset, then clear stale lines
pause(2);
flushinput(s);

assignin('base', 'sharedArduinoSerial', s);
fprintf('Opened shared Arduino serial on %s\n', portName);
end


function [firstFrame, firstClock] = waitForFirstPulse()
s = evalin('base', 'sharedArduinoSerial');

firstFrame = NaN;
firstClock = NaN;

while true
    if s.BytesAvailable > 0
        line = fgetl(s);
        line = strtrim(line);
        parts = strsplit(line, ',');

        if numel(parts) == 2 && strcmp(parts{1}, 'FRAME')
            currentFrame = str2double(parts{2});
            if ~isnan(currentFrame)
                firstFrame = currentFrame;
                firstClock = now;
                assignin('base', 'latestArduinoFrame', currentFrame);
                break
            end
        end
    end
    pause(0.001);
end
end


function loadSavedExperimentIntoGui(matFile, codeHandle)
global guifig

S = load(matFile, 'exper');
if ~isfield(S, 'exper')
    error('File does not contain variable "exper": %s', matFile);
end

handles = guidata(guifig);
exper = S.exper;

exper.enableCallbacks;
handles.exper = exper;

% Override exactly what we want
handles.exper.experimentCode = codeHandle;
handles.exper.movementFunction = @moveWithKeyboard;

% FORCE MAIN SCREEN / FULLSCREEN FOR ALL WINDOWS
for k = 1:length(handles.exper.windows)
    handles.exper.windows{k}.primaryMonitor = true;
    handles.exper.windows{k}.fullScreen = true;
end

[~, fname, ext] = fileparts(matFile);
handles.state.fileName = [fname ext];
handles.state.selectedWorld = 1;
handles.state.selectedObject = 0;
handles.state.selectedShape = 1;

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
fprintf('Set movementFunction to: moveWithKeyboard\n');
fprintf('Forced all ViRMEn windows to primary monitor fullscreen.\n');
end