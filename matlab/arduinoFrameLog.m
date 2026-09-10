function out = arduinoFrameLog(cmd, varargin)
%ARDUINOFRAMELOG  Single-owner, non-blocking Arduino frame logger for ViRMEn.
%
%   The ONLY code that should read the Arduino serial port. Everything
%   else reads the base-workspace variable 'latestArduinoFrame', which
%   this function keeps current.
%
%   Reads with fread() on exactly the bytes available and reassembles
%   lines itself, so it never blocks the ViRMEn render loop the way
%   fgetl() does when a partial line is in the buffer.
%
%   COMMANDS
%     arduinoFrameLog('init', portName, baudRate)   open + register port
%     arduinoFrameLog('attach', s)                  use an existing object
%     arduinoFrameLog('waitfirst')                  block until 1st frame
%                                                   -> [frame, clock]
%     arduinoFrameLog('phase', name)                tag subsequent frames
%     n = arduinoFrameLog('poll')                   drain buffer, n new
%     arduinoFrameLog('start')                      tell sketch to stream
%     arduinoFrameLog('stop')                       stop streaming
%     arduinoFrameLog('zero')                       zero sketch counter
%     T = arduinoFrameLog('table')                  everything so far
%     f = arduinoFrameLog('save', outdir, tag)      write CSVs
%     arduinoFrameLog('stats')                      print summary
%     arduinoFrameLog('close')                      stop, save nothing
%
%   Expects the v6 sketch line format:
%     D,seq,epoch_s,ms,micros,a0,a1,tempC,rh,missed
%
%   LINUX / R2014b NOTES:
%     * portName is a Linux device, e.g. '/dev/ttyUSB0' or '/dev/ttyACM0'.
%       Find it with:  ls /dev/ttyUSB* /dev/ttyACM*   (Arduino plugged in).
%     * Your user must be in the 'dialout' group to open the port:
%           sudo usermod -aG dialout $USER   (log out / back in after).
%     * Uses the legacy `serial` object (serial/fopen/fread/instrfind),
%       which R2014b supports. No serialport() calls here.

persistent S

if isempty(S), S = newState(); end
out = [];

switch lower(cmd)

% ------------------------------------------------------------------
case 'init'
    portName = varargin{1};
    baudRate = varargin{2};

    old = instrfind('Port', portName);
    if ~isempty(old)
        for k = 1:numel(old)
            try fclose(old(k)); catch, end
            try delete(old(k)); catch, end
        end
    end

    s = serial(portName, 'BaudRate', baudRate, 'Terminator', 'LF', ...
               'Timeout', 0.05);
    s.InputBufferSize = 262144;          % 256 kB, ~2500 frames of slack
    fopen(s);
    pause(2.2);                          % Uno auto-resets on port open
    flushinput(s);

    S = newState();
    S.s = s;
    assignin('base', 'sharedArduinoSerial', s);
    fprintf('arduinoFrameLog: opened %s at %d baud\n', portName, baudRate);

% ------------------------------------------------------------------
case 'attach'
    S = newState();
    S.s = varargin{1};
    flushinput(S.s);
    fprintf('arduinoFrameLog: attached to existing serial object\n');

% ------------------------------------------------------------------
case {'start','stop','zero','ledson','ledsoff'}
    assertOpen(S);
    map = struct('start','S','stop','X','zero','Z','ledson','1','ledsoff','0');
    fprintf(S.s, map.(lower(cmd)));

% ------------------------------------------------------------------
case 'phase'
    S.phaseName = varargin{1};
    S.phaseStartIdx = S.k + 1;
    fprintf('arduinoFrameLog: phase -> %s (from frame index %d)\n', ...
            S.phaseName, S.phaseStartIdx);

% ------------------------------------------------------------------
case 'poll'
    out = drain(S);
    % drain() mutates S via nested assignment below
    S = out.state;
    out = out.n;

% ------------------------------------------------------------------
case 'waitfirst'
    assertOpen(S);
    fprintf('arduinoFrameLog: waiting for first DAQ pulse...\n');
    t0 = tic;
    while true
        r = drain(S); S = r.state;
        if S.k > 0
            out = [S.seq(1), S.recvClock(1)];
            fprintf('arduinoFrameLog: first pulse | frame %.0f | %s\n', ...
                    S.seq(1), datestr(S.recvClock(1),'yyyy-mm-dd HH:MM:SS.FFF'));
            return
        end
        if toc(t0) > 1e6, error('Timed out waiting for first pulse.'); end
        pause(0.001);
    end

% ------------------------------------------------------------------
case 'latest'
    out = S.lastFrame;

% ------------------------------------------------------------------
case 'count'
    out = S.k;

% ------------------------------------------------------------------
case 'table'
    out = buildTable(S, 1, S.k);

% ------------------------------------------------------------------
case 'save'
    outdir = varargin{1};
    if nargin >= 3, tag = varargin{2}; else tag = 'session'; end
    if ~exist(outdir,'dir'), mkdir(outdir); end

    stamp = datestr(now,'yyyymmdd_HHMMSS');
    files = {};

    if S.k > 0
        T = buildTable(S, 1, S.k);
        fAll = fullfile(outdir, sprintf('%s_%s_allframes.csv', tag, stamp));
        writetable(T, fAll);
        files{end+1} = fAll; %#ok<AGROW>

        % one file per phase
        ph = unique(T.phase, 'stable');
        for i = 1:numel(ph)
            sel = strcmp(T.phase, ph{i});
            fP = fullfile(outdir, sprintf('%s_%s_%s.csv', tag, stamp, ph{i}));
            writetable(T(sel,:), fP);
            files{end+1} = fP; %#ok<AGROW>
        end

        % sync record: Arduino RTC vs MATLAB clock
        syncT = table(S.seq(1), S.ardClock(1), S.recvClock(1), ...
                      (S.recvClock(1)-S.ardClock(1))*86400, ...
                      S.seq(S.k), S.ardClock(S.k), S.recvClock(S.k), ...
                      (S.recvClock(S.k)-S.ardClock(S.k))*86400, ...
            'VariableNames', {'first_frame','first_arduino_time', ...
                'first_matlab_time','first_offset_s','last_frame', ...
                'last_arduino_time','last_matlab_time','last_offset_s'});
        fS = fullfile(outdir, sprintf('%s_%s_sync.csv', tag, stamp));
        writetable(syncT, fS);
        files{end+1} = fS; %#ok<AGROW>
    end

    for i = 1:numel(files), fprintf('  saved: %s\n', files{i}); end
    out = files;

% ------------------------------------------------------------------
case 'stats'
    if S.k == 0
        fprintf('arduinoFrameLog: no frames captured.\n');
        return
    end
    d = diff(S.tRel(1:S.k))*1000;
    fprintf('\n--- arduinoFrameLog summary ---\n');
    fprintf('Frames logged     : %d\n', S.k);
    fprintf('Sequence span     : %d to %d\n', S.seq(1), S.seq(S.k));
    fprintf('Dropped in transit: %d\n', S.dropped);
    fprintf('Missed by sketch  : %d\n', max(S.missed(1:S.k)));
    fprintf('Malformed lines   : %d\n', S.badLines);
    fprintf('Duration          : %.3f s\n', S.tRel(S.k));
    if ~isempty(d)
        fprintf('Frame interval    : mean %.3f ms, sd %.3f, min %.3f, max %.3f\n', ...
                mean(d), std(d), min(d), max(d));
        fprintf('Mean rate         : %.2f Hz\n', 1000/mean(d));
    end
    fprintf('First frame       : %s\n', datestr(S.recvClock(1),'HH:MM:SS.FFF'));
    fprintf('Last  frame       : %s\n', datestr(S.recvClock(S.k),'HH:MM:SS.FFF'));
    fprintf('-------------------------------\n\n');

% ------------------------------------------------------------------
case 'verbose'
    if nargin >= 2 && ~isempty(varargin{1})
        S.printEvery = varargin{1};
    else
        S.printEvery = 50;
    end
    S.printLast = 0;
    if S.printEvery > 0
        fprintf('arduinoFrameLog: console updates every %d frames\n', S.printEvery);
    else
        fprintf('arduinoFrameLog: console updates off\n');
    end

% ------------------------------------------------------------------
case 'monitor'
    if nargin >= 2 && ~isempty(varargin{1}), S.monEvery = varargin{1}; end
    S.mon = buildMonitor();
    S.monLast = 0;
    fprintf('arduinoFrameLog: live monitor open (refresh every %d frames)\n', S.monEvery);

% ------------------------------------------------------------------
case 'monitoroff'
    if ~isempty(S.mon) && ishandle(S.mon.fig), close(S.mon.fig); end
    S.mon = [];

% ------------------------------------------------------------------
case 'close'
    try if ~isempty(S.mon) && ishandle(S.mon.fig), close(S.mon.fig); end, catch, end
    try fprintf(S.s,'X'); catch, end
    try fclose(S.s); catch, end
    try delete(S.s); catch, end
    S = newState();

% ------------------------------------------------------------------
case 'reset'
    S = resetBuffers(S);

otherwise
    error('arduinoFrameLog: unknown command "%s"', cmd);
end
end


% =====================================================================
function S = newState()
S.s          = [];
S.rx         = '';          % partial-line accumulator
S.k          = 0;
S.N          = 200000;
S.seq        = nan(S.N,1);
S.ardClock   = nan(S.N,1);  % datenum from the DS3231
S.recvClock  = nan(S.N,1);  % datenum from the MATLAB clock at receipt
S.tRel       = nan(S.N,1);  % s since first frame, from Arduino micros()
S.a0         = nan(S.N,1);
S.a1         = nan(S.N,1);
S.tempC      = nan(S.N,1);
S.rh         = nan(S.N,1);
S.missed     = nan(S.N,1);
S.phaseIdx   = zeros(S.N,1);
S.phaseNames = {'unassigned'};
S.phaseName  = 'unassigned';
S.phaseStartIdx = 1;
S.us0        = [];
S.lastSeq    = [];
S.dropped    = 0;
S.badLines   = 0;
S.lastFrame  = NaN;
S.VREF       = 5.0;
S.ADCMAX     = 1023;
S.mon        = [];          % live monitor panel handles
S.monEvery   = 20;          % refresh the panel every N new frames
S.monLast    = 0;           % frame index at last refresh
S.printEvery = 0;           % 0 = off; else print a line every N frames
S.printLast  = 0;
end

% =====================================================================
function S = resetBuffers(S)
s = S.s; S = newState(); S.s = s;
end

% =====================================================================
function assertOpen(S)
if isempty(S.s) || ~strcmp(get(S.s,'Status'),'open')
    error('arduinoFrameLog: port is not open. Call init or attach first.');
end
end

% =====================================================================
function r = drain(S)
% Non-blocking: reads only the bytes already in the buffer, reassembles
% complete lines, keeps any partial tail for the next call.
r.n = 0;
if isempty(S.s) || ~strcmp(get(S.s,'Status'),'open'), r.state = S; return; end

nb = S.s.BytesAvailable;
if nb == 0, r.state = S; return; end

raw = fread(S.s, nb, 'uint8');
S.rx = [S.rx, char(raw(:)')];

nl = find(S.rx == char(10));            %#ok<CHARTEN>  LF
if isempty(nl), r.state = S; return; end

lines = cell(numel(nl),1);
start = 1;
for i = 1:numel(nl)
    lines{i} = strtrim(S.rx(start:nl(i)-1));
    start = nl(i) + 1;
end
S.rx = S.rx(start:end);                 % keep the partial tail

nowClock = now;

for i = 1:numel(lines)
    ln = lines{i};
    if isempty(ln), continue; end

    if ln(1) == '#'                     % sketch status line
        continue
    end

    if numel(ln) < 3 || ~strncmp(ln,'D,',2)
        S.badLines = S.badLines + 1;
        continue
    end

    v = sscanf(ln(3:end), '%f,', [1 Inf]);
    if numel(v) < 9
        S.badLines = S.badLines + 1;
        continue
    end

    S.k = S.k + 1;
    if S.k > S.N, error('arduinoFrameLog: buffer full (%d frames).', S.N); end

    S.seq(S.k)   = v(1);
    S.ardClock(S.k) = datenum(1970,1,1) + (v(2) + v(3)/1000)/86400;
    S.recvClock(S.k) = nowClock;
    if isempty(S.us0), S.us0 = v(4); end
    S.tRel(S.k)  = (v(4) - S.us0)/1e6;
    S.a0(S.k)    = v(5) * S.VREF / S.ADCMAX;
    S.a1(S.k)    = v(6) * S.VREF / S.ADCMAX;
    S.tempC(S.k) = v(7);
    S.rh(S.k)    = v(8);
    S.missed(S.k)= v(9);

    % phase tag
    pIdx = find(strcmp(S.phaseNames, S.phaseName), 1);
    if isempty(pIdx)
        S.phaseNames{end+1} = S.phaseName;
        pIdx = numel(S.phaseNames);
    end
    S.phaseIdx(S.k) = pIdx;

    if ~isempty(S.lastSeq) && S.seq(S.k) > S.lastSeq + 1
        S.dropped = S.dropped + (S.seq(S.k) - S.lastSeq - 1);
    end
    S.lastSeq   = S.seq(S.k);
    S.lastFrame = S.seq(S.k);
    r.n = r.n + 1;
end

if r.n > 0
    assignin('base', 'latestArduinoFrame', S.lastFrame);

    % ---- console progress (throttled) ----
    if S.printEvery > 0 && (S.k - S.printLast) >= S.printEvery
        S.printLast = S.k;
        kk = S.k;
        sel = max(1,kk-49):kk;
        dsel = diff(S.tRel(sel))*1000;
        dsel = dsel(~isnan(dsel));
        if isempty(dsel), hz = NaN; else hz = 1000/max(mean(dsel),eps); end
        fprintf('[%s] frames %-7d seq %-8d %6.2f Hz  dropped %-4d missed %-4d  %.1fC %.0f%%RH\n', ...
            S.phaseName, kk, S.seq(kk), hz, S.dropped, max(S.missed(1:kk)), ...
            S.tempC(kk), S.rh(kk));
    end

    % ---- live monitor refresh (throttled, cheap) ----
    if ~isempty(S.mon) && ishandle(S.mon.fig)
        if (S.k - S.monLast) >= S.monEvery
            S.monLast = S.k;
            refreshMonitor(S);
        end
    end
end
r.state = S;
end

% =====================================================================
function m = buildMonitor()
m.fig = figure('Name','DAQ live monitor','NumberTitle','off','Color','w', ...
               'Units','normalized','Position',[0.30 0.55 0.42 0.38], ...
               'MenuBar','none','ToolBar','none');

m.txt = uicontrol('Parent',m.fig,'Style','text','Units','normalized', ...
        'Position',[0.03 0.62 0.94 0.34],'BackgroundColor','w', ...
        'FontName','FixedWidth','FontSize',11,'FontWeight','bold', ...
        'HorizontalAlignment','left','String','waiting for frames...');

m.ax = axes('Parent',m.fig,'Position',[0.10 0.12 0.86 0.42]);
hold(m.ax,'on'); grid(m.ax,'on');
m.line = plot(m.ax, NaN, NaN, 'Color',[0.2 0.2 0.2], 'LineWidth',1.0);
ylabel(m.ax,'frame interval (ms)');
xlabel(m.ax,'elapsed (s)');
title(m.ax,'DAQ frame timing');
drawnow;
end

% =====================================================================
function refreshMonitor(S)
if S.k < 1, return; end

k   = S.k;
sel = max(1,k-499):k;                 % rolling window, last 500 frames
t   = S.tRel(sel);
d   = [NaN; diff(t)*1000];

dv = d(~isnan(d));
if isempty(dv)
    mn = NaN; sd = NaN; hz = NaN;
else
    mn = mean(dv); sd = std(dv); hz = 1000/max(mn,eps);
end

set(S.mon.line,'XData',t,'YData',d);
if numel(t) > 1
    set(S.mon.ax,'XLim',[t(1) max(t(end), t(1)+eps)]);
end

set(S.mon.txt,'String', sprintf([ ...
    'frames %-8d  seq %d..%d\n' ...
    'rate   %6.2f Hz   (dt mean %.2f ms, sd %.2f)\n' ...
    'dropped in transit %-6d  sketch-missed %d\n' ...
    'bad lines %-6d  T %.1f C   RH %.1f %%\n' ...
    'phase: %s'], ...
    k, S.seq(1), S.seq(k), hz, mn, sd, ...
    S.dropped, max(S.missed(1:k)), S.badLines, ...
    S.tempC(k), S.rh(k), S.phaseName));
drawnow limitrate;
end

% =====================================================================
function T = buildTable(S, i1, i2)
if S.k == 0, T = table(); return; end
idx = i1:i2;
dtms = [NaN; diff(S.tRel(idx))*1000];
phase = S.phaseNames(max(S.phaseIdx(idx),1))';

T = table(phase, S.seq(idx), ...
          datestr(S.ardClock(idx), 'yyyy-mm-dd HH:MM:SS.FFF'), ...
          datestr(S.recvClock(idx),'yyyy-mm-dd HH:MM:SS.FFF'), ...
          S.tRel(idx), dtms, S.a0(idx), S.a1(idx), ...
          S.tempC(idx), S.rh(idx), S.missed(idx), ...
    'VariableNames', {'phase','frame','arduino_time','matlab_time', ...
                      't_rel_s','dt_ms','A0_V','A1_V','tempC','RH_pct', ...
                      'sketch_missed'});
end
