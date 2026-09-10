function code = WhiteChamber
% WhiteChamber   Ends after 600 new Arduino TTL pulses and logs all frame times.

code.initialization = @initializationCodeFun;
code.runtime = @runtimeCodeFun;
code.termination = @terminationCodeFun;


function vr = initializationCodeFun(vr)
disp('######################################### INITIALIZED WHITECHAMBER #########################################');

vr.frameThreshold = 600;
vr.startFrame = NaN;
vr.lastArduinoFrame = NaN;
vr.endReason = 'manual';

vr.arduinoSerial = [];
vr.expStartClock = now;
vr.expStartTic = tic;
vr.frameLog = [];

try
    if evalin('base', 'exist(''sharedArduinoSerial'',''var'')')
        s = evalin('base', 'sharedArduinoSerial');
        if strcmp(get(s, 'Status'), 'open')
            vr.arduinoSerial = s;
            disp('WhiteChamber: using shared Arduino serial.');
        end
    end
catch
end

assignin('base', 'lastExperimentEndReason', '');
assignin('base', 'lastExperimentEndFrame', NaN);
assignin('base', 'WhiteChamber_startClock', vr.expStartClock);
assignin('base', 'WhiteChamber_startClockStr', datestr(vr.expStartClock, 'yyyy-mm-dd HH:MM:SS.FFF'));


function vr = runtimeCodeFun(vr)

if ~isempty(vr.arduinoSerial)
    while vr.arduinoSerial.BytesAvailable > 0
        line = fgetl(vr.arduinoSerial);
        line = strtrim(line);
        parts = strsplit(line, ',');

        if numel(parts) == 2 && strcmp(parts{1}, 'FRAME')
            currentFrame = str2double(parts{2});
            if ~isnan(currentFrame)
                currentElapsed = toc(vr.expStartTic);
                currentClock = now;

                vr.lastArduinoFrame = currentFrame;
                assignin('base', 'latestArduinoFrame', currentFrame);

                if isnan(vr.startFrame)
                    vr.startFrame = currentFrame;
                    fprintf('WhiteChamber start frame: %.0f\n', vr.startFrame);
                    fprintf('WhiteChamber first frame time: %s\n', datestr(currentClock, 'yyyy-mm-dd HH:MM:SS.FFF'));
                    assignin('base', 'WhiteChamber_firstFrame', vr.startFrame);
                    assignin('base', 'WhiteChamber_firstFrameClock', currentClock);
                    assignin('base', 'WhiteChamber_firstFrameClockStr', datestr(currentClock, 'yyyy-mm-dd HH:MM:SS.FFF'));
                end

                vr.frameLog(end+1,:) = [currentFrame, currentElapsed, currentClock]; %#ok<AGROW>
                assignin('base', 'frameLog_WhiteChamber', vr.frameLog);

                if mod(currentFrame - vr.startFrame, 100) == 0
                    fprintf('WhiteChamber frame %.0f at %s\n', currentFrame, datestr(currentClock, 'yyyy-mm-dd HH:MM:SS.FFF'));
                end
            end
        end
    end
end

if ~isnan(vr.startFrame) && ~isnan(vr.lastArduinoFrame)
    if (vr.lastArduinoFrame - vr.startFrame) >= vr.frameThreshold
        vr.endReason = 'frameThreshold';
        vr.experimentEnded = true;
    end
end


function vr = terminationCodeFun(vr)
disp('WhiteChamber terminated.');

assignin('base', 'lastExperimentEndReason', vr.endReason);
assignin('base', 'lastExperimentEndFrame', vr.lastArduinoFrame);
assignin('base', 'WhiteChamber_endClock', now);
assignin('base', 'WhiteChamber_endClockStr', datestr(now, 'yyyy-mm-dd HH:MM:SS.FFF'));

fprintf('WhiteChamber termination reason: %s\n', vr.endReason);
fprintf('WhiteChamber last frame: %.0f\n', vr.lastArduinoFrame);
fprintf('WhiteChamber stop time: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS.FFF'));
