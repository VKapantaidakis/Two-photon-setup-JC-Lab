function code = cillinder
% cillinder   Code for the ViRMEn experiment cillinder.
%   code = cillinder   Returns handles to the functions that ViRMEn
%   executes during engine initialization, runtime and termination.


% Begin header code - DO NOT EDIT
code.initialization = @initializationCodeFun;
code.runtime = @runtimeCodeFun;
code.termination = @terminationCodeFun;
% End header code - DO NOT EDIT



% --- INITIALIZATION code: executes before the ViRMEn engine starts.
function vr = initializationCodeFun(vr)



% --- RUNTIME code: executes on every iteration of the ViRMEn engine.
function vr = runtimeCodeFun(vr)

nowHour = hour(datetime('now'));

if nowHour < 11 || nowHour >= 22 
    vr.worlds{1}.backgroundColor = [0 0 0];
    vr.worlds{1}.surface.visible(:) = false;
end


% --- TERMINATION code: executes after the ViRMEn engine stops.
function vr = terminationCodeFun(vr)
