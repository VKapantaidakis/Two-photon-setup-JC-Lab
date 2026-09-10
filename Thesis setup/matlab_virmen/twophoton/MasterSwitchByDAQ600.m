function MasterSwitchByDAQ600
clc;

rootDir = 'C:\Users\S5085721\Desktop\2P-Vasilis\ViRMEn 2016-02-12';
expDir  = fullfile(rootDir, 'experiments');

portName = 'COM4';
baudRate = 115200;

global guifig

% Open ViRMEn only if needed
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

% Open shared Arduino serial once
setupSharedArduinoSerial(portName, baudRate);

% Reset shared state
assignin('base', 'latestArduinoFrame', NaN);
assignin('base', 'lastExperimentEndReason', '');
assignin('base', 'lastExperimentEndFrame', NaN);

% ---------- RUN WHITECHAMBER ----------
fprintf('\n=== Loading WhiteChamber ===\n');
loadExperimentCode(@WhiteChamber, 'WhiteChamber.m');

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

pause(1);

% ---------- RUN WHITECHAMBERDOTS ----------
fprintf('\n=== Loading WhiteChamberDots ===\n');
loadExperimentCode(@WhiteChamberDots, 'WhiteChamberDots.m');

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
pause(2);

assignin('base', 'sharedArduinoSerial', s);
fprintf('Opened shared Arduino serial on %s\n', portName);
end


function loadExperimentCode(codeHandle, fileName)
global guifig
handles = guidata(guifig);

handles.exper.experimentCode  = codeHandle;
handles.exper.movementFunction = @moveWithKeyboard;

handles.state.fileName = fileName;
handles.state.selectedWorld = 1;
handles.state.selectedObject = 0;
handles.state.selectedShape = 1;

guidata(guifig, handles);
updateFigures('openExperiment');
figure(guifig);

fprintf('Loaded experiment code: %s\n', func2str(codeHandle));
fprintf('Movement function: %s\n', func2str(handles.exper.movementFunction));
end