function code = BlackChamber
% BlackChamber
% Runs BlackChamber for a fixed duration, logs all Arduino TTL frame times,
% and then ends automatically.
%
% Designed to be loaded by the master script exactly like WhiteChamber:
%   loadSavedExperimentIntoGui(blackChamberMat, @BlackChamber)

code.initialization = @initializationCodeFun;
code.runtime = @runtimeCodeFun;
code.termination = @terminationCodeFun;


function vr = initializationCodeFun(vr)

disp('######################################### INITIALIZED BLACKCHAMBER #########################################');

% ------------------------------------------------------------
% Default duration
% ------------------------------------------------------------
% If the master script provides protocol.blackDurationSec, use that.
% Otherwise default to 5 minutes.
if evalin('base', 'exist(''protocol'',''var'')')
    protocol = evalin('base', 'protocol');

    if isfield(protocol, 'blackDurationSec')
        vr.blackDurationSec = protocol.blackDurationSec;
    else
        vr.blackDurationSec = 5 * 60;
    end
else
    vr.blackDurationSec = 5 * 60;
end

% ------------------------------------------------------------
% Runtime state
% ------------------------------------------------------------
vr.arduinoSerial = [];
vr.expStartClock = now;
vr.expStartTic = tic;

vr.endReason = 'manual';

vr.startFrame = NaN;
vr.lastArduinoFrame = NaN;
vr.frameLog = [];

% ------------------------------------------------------------
% Use shared Arduino serial opened by master script
% ------------------------------------------------------------
try
    if evalin('base', 'exist(''sharedArduinoSerial'',''var'')')
        s = evalin('base', 'sharedArduinoSerial');

        if strcmp(get(s, 'Status'), 'open')
            vr.arduinoSerial = s;
            disp('BlackChamber: using shared Arduino serial.');
        end
    end
catch
end

if isempty(vr.arduinoSerial)
    warning('BlackChamber: no open sharedArduinoSerial found. Frame logging will be disabled.');
end

% ------------------------------------------------------------
% Reset / export base variables
% ------------------------------------------------------------
assignin('base', 'lastExperimentEndReason', '');
assignin('base', 'lastExperimentEndFrame', NaN);

assignin('base', 'frameLog_BlackChamber', []);

assignin('base', 'BlackChamber_startClock', vr.expStartClock);
assignin('base', 'BlackChamber_startClockStr', datestr(vr.expStartClock, 'yyyy-mm-dd HH:MM:SS.FFF'));
assignin('base', 'BlackChamber_durationSec', vr.blackDurationSec);

fprintf('BlackChamber started.\n');
fprintf('BlackChamber duration: %.1f seconds, %.2f minutes.\n', ...
    vr.blackDurationSec, vr.blackDurationSec / 60);
fprintf('BlackChamber start time: %s\n', ...
    datestr(vr.expStartClock, 'yyyy-mm-dd HH:MM:SS.FFF'));


function vr = runtimeCodeFun(vr)

% ------------------------------------------------------------
% Read and log Arduino frame pulses
% ------------------------------------------------------------
if ~isempty(vr.arduinoSerial)
    while vr.arduinoSerial.BytesAvailable > 0

        line = fgetl(vr.arduinoSerial);
        line = strtrim(line);
        parts = strsplit(line, ',');

        % Accept both Arduino formats:
        %   FRAME,123
        %   FRAME,123,456789
        if numel(parts) >= 2 && strcmp(parts{1}, 'FRAME')

            currentFrame = str2double(parts{2});

            if ~isnan(currentFrame)

                currentElapsed = toc(vr.expStartTic);
                currentClock = now;

                vr.lastArduinoFrame = currentFrame;
                assignin('base', 'latestArduinoFrame', currentFrame);

                if isnan(vr.startFrame)
                    vr.startFrame = currentFrame;

                    fprintf('BlackChamber FIRST pulse | frame %.0f | %s\n', ...
                        currentFrame, datestr(currentClock, 'yyyy-mm-dd HH:MM:SS.FFF'));

                    assignin('base', 'BlackChamber_firstFrame', vr.startFrame);
                    assignin('base', 'BlackChamber_firstFrameClock', currentClock);
                    assignin('base', 'BlackChamber_firstFrameClockStr', ...
                        datestr(currentClock, 'yyyy-mm-dd HH:MM:SS.FFF'));
                end

                % Log:
                % column 1 = Arduino frame
                % column 2 = elapsed seconds since BlackChamber start
                % column 3 = MATLAB wall-clock time
                vr.frameLog(end+1,:) = [currentFrame, currentElapsed, currentClock]; %#ok<AGROW>
                assignin('base', 'frameLog_BlackChamber', vr.frameLog);

                fprintf('BlackChamber pulse | frame %.0f | t=%.3f s | %s\n', ...
                    currentFrame, currentElapsed, ...
                    datestr(currentClock, 'yyyy-mm-dd HH:MM:SS.FFF'));
            end
        end
    end
end

% ------------------------------------------------------------
% End after requested duration
% ------------------------------------------------------------
elapsed = toc(vr.expStartTic);
assignin('base', 'BlackChamber_elapsedSec', elapsed);

if elapsed >= vr.blackDurationSec
    vr.endReason = 'blackDurationTime';
    vr.experimentEnded = true;
end


function vr = terminationCodeFun(vr)

disp('BlackChamber terminated.');

endClock = now;

assignin('base', 'lastExperimentEndReason', vr.endReason);
assignin('base', 'lastExperimentEndFrame', vr.lastArduinoFrame);

assignin('base', 'BlackChamber_endClock', endClock);
assignin('base', 'BlackChamber_endClockStr', datestr(endClock, 'yyyy-mm-dd HH:MM:SS.FFF'));

fprintf('BlackChamber termination reason: %s\n', vr.endReason);
fprintf('BlackChamber last frame: %.0f\n', vr.lastArduinoFrame);
fprintf('BlackChamber stop time: %s\n', ...
    datestr(endClock, 'yyyy-mm-dd HH:MM:SS.FFF'));