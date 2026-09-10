function code = WhiteBack
% WhiteBack   Phase 1 (white background). Ends after frameThreshold frames.
%   SINGLE-READER: does NOT read the serial port. arduinoFrameLog owns
%   the port; this polls it and reads 'latestArduinoFrame' from base.

code.initialization = @initializationCodeFun;
code.runtime        = @runtimeCodeFun;
code.termination    = @terminationCodeFun;


function vr = initializationCodeFun(vr)
disp('===== INITIALIZED WHITEBACK (single-reader) =====');

vr.frameThreshold   = 600;       % frames this phase runs for
vr.startFrame       = NaN;
vr.lastArduinoFrame = NaN;
vr.endReason        = 'manual';
vr.expStartClock    = now;
vr.expStartTic      = tic;

assignin('base','lastExperimentEndReason','');
assignin('base','lastExperimentEndFrame', NaN);
assignin('base','WhiteBack_startClock', vr.expStartClock);
assignin('base','WhiteBack_startClockStr', ...
    datestr(vr.expStartClock,'yyyy-mm-dd HH:MM:SS.FFF'));


function vr = runtimeCodeFun(vr)

% Defensive: make sure the fields exist even if init was skipped.
if ~isfield(vr,'startFrame'),       vr.startFrame = NaN;       end
if ~isfield(vr,'lastArduinoFrame'), vr.lastArduinoFrame = NaN; end
if ~isfield(vr,'endReason'),        vr.endReason = 'manual';   end
if ~isfield(vr,'frameThreshold'),   vr.frameThreshold = 600;   end

% Let the single reader drain the port, then read what it published.
if exist('arduinoFrameLog','file') == 2
    try
        arduinoFrameLog('poll');
    catch
    end
end
try
    currentFrame = evalin('base','latestArduinoFrame');
catch
    currentFrame = NaN;
end

if ~isempty(currentFrame) && isnumeric(currentFrame) && ~isnan(currentFrame)
    vr.lastArduinoFrame = currentFrame;

    if isnan(vr.startFrame)
        vr.startFrame = currentFrame;
        assignin('base','WhiteBack_firstFrame', vr.startFrame);
        assignin('base','WhiteBack_firstFrameClock', now);
        fprintf('WhiteBack FIRST frame | %.0f | %s\n', ...
            currentFrame, datestr(now,'yyyy-mm-dd HH:MM:SS.FFF'));
    end
end

if ~isnan(vr.startFrame) && ~isnan(vr.lastArduinoFrame)
    if (vr.lastArduinoFrame - vr.startFrame) >= vr.frameThreshold
        vr.endReason = 'frameThreshold';
        vr.experimentEnded = true;
    end
end


function vr = terminationCodeFun(vr)
disp('WhiteBack terminated.');
if ~isfield(vr,'endReason'),        vr.endReason = 'manual';   end
if ~isfield(vr,'lastArduinoFrame'), vr.lastArduinoFrame = NaN; end
assignin('base','lastExperimentEndReason', vr.endReason);
assignin('base','lastExperimentEndFrame', vr.lastArduinoFrame);
assignin('base','WhiteBack_endClock', now);
fprintf('WhiteBack termination reason: %s\n', vr.endReason);
fprintf('WhiteBack last frame: %.0f\n', vr.lastArduinoFrame);
fprintf('WhiteBack stop time: %s\n', datestr(now,'yyyy-mm-dd HH:MM:SS.FFF'));
