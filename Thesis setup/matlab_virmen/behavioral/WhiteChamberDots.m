function code = WhiteChamberDots
% WhiteChamberDots   Ends after 600 new Arduino TTL pulses and logs all frame times.

code.initialization = @initializationCodeFun;
code.runtime = @runtimeCodeFun;
code.termination = @terminationCodeFun;


function vr = initializationCodeFun(vr)
disp('######################################### INITIALIZED WHITECHAMBERDOTS #########################################');

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
            disp('WhiteChamberDots: using shared Arduino serial.');
        end
    end
catch
end

assignin('base', 'lastExperimentEndReason', '');
assignin('base', 'lastExperimentEndFrame', NaN);
assignin('base', 'WhiteChamberDots_startClock', vr.expStartClock);
assignin('base', 'WhiteChamberDots_startClockStr', datestr(vr.expStartClock, 'yyyy-mm-dd HH:MM:SS.FFF'));


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
                    fprintf('WhiteChamberDots start frame: %.0f\n', vr.startFrame);
                    fprintf('WhiteChamberDots first frame time: %s\n', datestr(currentClock, 'yyyy-mm-dd HH:MM:SS.FFF'));
                    assignin('base', 'WhiteChamberDots_firstFrame', vr.startFrame);
                    assignin('base', 'WhiteChamberDots_firstFrameClock', currentClock);
                    assignin('base', 'WhiteChamberDots_firstFrameClockStr', datestr(currentClock, 'yyyy-mm-dd HH:MM:SS.FFF'));
                end

                vr.frameLog(end+1,:) = [currentFrame, currentElapsed, currentClock]; %#ok<AGROW>
                assignin('base', 'frameLog_WhiteChamberDots', vr.frameLog);

                if mod(currentFrame - vr.startFrame, 100) == 0
                    fprintf('WhiteChamberDots frame %.0f at %s\n', currentFrame, datestr(currentClock, 'yyyy-mm-dd HH:MM:SS.FFF'));
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
disp('WhiteChamberDots terminated.');

assignin('base', 'lastExperimentEndReason', vr.endReason);
assignin('base', 'lastExperimentEndFrame', vr.lastArduinoFrame);
assignin('base', 'WhiteChamberDots_endClock', now);
assignin('base', 'WhiteChamberDots_endClockStr', datestr(now, 'yyyy-mm-dd HH:MM:SS.FFF'));

fprintf('WhiteChamberDots termination reason: %s\n', vr.endReason);
fprintf('WhiteChamberDots last frame: %.0f\n', vr.lastArduinoFrame);
fprintf('WhiteChamberDots stop time: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS.FFF'));
