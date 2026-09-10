%% daq_frame_monitor_v2.m
%  Live capture of DAQ frames from daq_frame_logger_v6.ino
%  ---- MATLAB R2014b compatible, Linux (legacy `serial` object) ----
%
%  Standalone tester: open the Arduino, stream frames, plot live,
%  save a CSV on close. Tests the DAQ/Arduino pipeline WITHOUT ViRMEn.
%
%  R2014b notes:
%    * legacy serial()/fopen/fgetl (no serialport).
%    * NO local functions -- scripts cannot define functions before R2016b.
%      epoch->datenum and nan-safe mean/std are inlined.
%    * MATLAB on Linux only sees /dev/ttyS* ports. For an Arduino on
%      /dev/ttyACM0, first run:  sudo ln -s /dev/ttyACM0 /dev/ttyS101
%
%  Close the figure window to stop and save.

clear; clc;

%% ---------------- user settings ---------------------------------
PORT       = '/dev/ttyS101';   % symlink to /dev/ttyACM0 (see note above)
BAUD       = 115200;           % must match BAUD in the sketch
VREF       = 5.0;
ADC_MAX    = 1023;
MAX_FRAMES = 50000;
PLOT_EVERY = 10;               % refresh graphics every N frames
WINDOW_S   = 30;               % seconds of history on the live axes
PRINT_EVERY= 0;                % echo to command window every N frames (0=off)
OUTFILE    = ['daq_log_' datestr(now,'yyyymmdd_HHMMSS') '.csv'];

%% ---------------- open the port ---------------------------------
old = instrfind('Port', PORT);
if ~isempty(old), fclose(old); delete(old); end

s = serial(PORT, 'BaudRate', BAUD, 'Terminator', 'LF', 'Timeout', 1);
s.InputBufferSize = 131072;
fopen(s);
warning('off','MATLAB:serial:fgetl:unsuccessfulRead');

pause(2.5);                % Uno auto-resets when the port opens
flushinput(s);

fprintf(s, 'Z');           % zero the sketch's frame counter
fprintf(s, '1');           % illuminator full on
fprintf(s, 'H');           % silence the 1 Hz heartbeat during capture
fprintf(s, 'S');           % start streaming
fprintf('Streaming from %s. Close the figure to stop.\n\n', PORT);

%% ---------------- pre-allocate ----------------------------------
N      = MAX_FRAMES;
seq    = nan(N,1);  epoch = nan(N,1);  tRel = nan(N,1);
a0     = nan(N,1);  a1    = nan(N,1);
tempC  = nan(N,1);  rh    = nan(N,1);  missed = nan(N,1);
k = 0;  us0 = [];  dropped = 0;  lastSeq = [];

%% ---------------- figure ----------------------------------------
fig = figure('Name','DAQ frame monitor','NumberTitle','off','Color','w', ...
             'Units','normalized','Position',[0.06 0.10 0.86 0.78]);

ax1 = axes('Parent',fig,'Position',[0.08 0.70 0.86 0.22]); hold(ax1,'on'); grid(ax1,'on');
l0 = plot(ax1, NaN, NaN, 'Color',[0.00 0.45 0.74],'LineWidth',1.2);
l1 = plot(ax1, NaN, NaN, 'Color',[0.85 0.33 0.10],'LineWidth',1.2);
ylabel(ax1,'DAQ input (V)'); ylim(ax1,[0 VREF]);
legend(ax1,{'A0','A1'},'Location','northwest');
t1 = title(ax1,'DAQ analog channels');

ax2 = axes('Parent',fig,'Position',[0.08 0.40 0.86 0.22]); hold(ax2,'on'); grid(ax2,'on');
lT = plot(ax2, NaN, NaN, 'Color',[0.47 0.67 0.19],'LineWidth',1.4);
lH = plot(ax2, NaN, NaN, 'Color',[0.49 0.18 0.56],'LineWidth',1.4,'LineStyle','--');
ylabel(ax2,'T (\circC) / RH (%)');
legend(ax2,{'Temp','RH'},'Location','northwest');
t2 = title(ax2,'DHT22');

ax3 = axes('Parent',fig,'Position',[0.08 0.09 0.86 0.22]); hold(ax3,'on'); grid(ax3,'on');
lD = plot(ax3, NaN, NaN, 'Color',[0.3 0.3 0.3],'LineWidth',1.0);
ylabel(ax3,'Frame interval (ms)');
xlabel(ax3,'Elapsed time (s)');
t3 = title(ax3,'Timing');

hHdr = uicontrol('Parent',fig,'Style','text','Units','normalized', ...
        'Position',[0.08 0.945 0.86 0.04],'BackgroundColor','w', ...
        'FontName','FixedWidth','FontSize',10,'FontWeight','bold', ...
        'HorizontalAlignment','left','String','waiting for first frame...');

%% ---------------- acquisition loop ------------------------------
tWall = tic;
try
    while ishandle(fig) && k < N

        if s.BytesAvailable == 0
            pause(0.005);
            continue
        end

        ln = fgetl(s);
        if ~ischar(ln) || isempty(ln), continue; end
        ln = strtrim(ln);

        if ln(1) == '#'
            fprintf('  %s\n', ln);
            continue
        end
        if numel(ln) < 3 || ~strncmp(ln,'D,',2), continue; end

        v = sscanf(ln(3:end), '%f,', [1 Inf]);
        if numel(v) < 9, continue; end

        k = k + 1;
        seq(k)    = v(1);
        epoch(k)  = v(2) + v(3)/1000;
        if isempty(us0), us0 = v(4); end
        tRel(k)   = (v(4) - us0) / 1e6;
        a0(k)     = v(5) * VREF / ADC_MAX;
        a1(k)     = v(6) * VREF / ADC_MAX;
        tempC(k)  = v(7);
        rh(k)     = v(8);
        missed(k) = v(9);

        if ~isempty(lastSeq) && seq(k) > lastSeq + 1
            dropped = dropped + (seq(k) - lastSeq - 1);
        end
        lastSeq = seq(k);

        if PRINT_EVERY > 0 && mod(k,PRINT_EVERY) == 0
            fprintf('frame %d  t=%.3f  A0=%.3f A1=%.3f  T=%.1f RH=%.1f\n', ...
                seq(k), tRel(k), a0(k), a1(k), tempC(k), rh(k));
        end

        if mod(k, PLOT_EVERY) == 0 || k == 1
            idx = 1:k;
            set(l0, 'XData', tRel(idx), 'YData', a0(idx));
            set(l1, 'XData', tRel(idx), 'YData', a1(idx));
            set(lT, 'XData', tRel(idx), 'YData', tempC(idx));
            set(lH, 'XData', tRel(idx), 'YData', rh(idx));
            if k > 1
                dvec = [NaN; diff(tRel(idx))*1000];
                set(lD, 'XData', tRel(idx), 'YData', dvec);
            end

            tNow = tRel(k);
            xl = [max(0, tNow-WINDOW_S), max(WINDOW_S, tNow)];
            set([ax1 ax2 ax3], 'XLim', xl);

            elapsed = tRel(k);
            rateNow = (k-1)/max(elapsed,eps);
            acqStr  = datestr(datenum(1970,1,1) + epoch(k)/86400,'HH:MM:SS.FFF');
            set(hHdr,'String', sprintf( ...
              '%s  |  frames %d  |  %.1f Hz avg  |  elapsed %6.2f s  |  dropped %d  |  sketch-missed %d  |  %.1f C  %.1f %%RH', ...
               acqStr, k, rateNow, elapsed, dropped, missed(k), tempC(k), rh(k)));
            set(t1,'String',sprintf('DAQ analog channels  -  %d frames read', k));
            set(t2,'String',sprintf('DHT22  -  T = %.1f C, RH = %.1f %%', tempC(k), rh(k)));
            set(t3,'String',sprintf('Timing  -  %d frames cumulative', k));
            drawnow;
        end
    end
catch ME
    fprintf(2,'\nAcquisition stopped: %s\n', ME.message);
end
wallElapsed = toc(tWall);

%% ---------------- stop + save -----------------------------------
try
    fprintf(s,'X');
    fprintf(s,'H');            % heartbeat back on
    fclose(s);
catch
end
delete(s); clear s

if k == 0
    fprintf('No frames received. Check the trigger wiring and the port name.\n');
    return
end

% acquisition-time strings (inline epoch -> datenum, R2014b safe)
acqStrs = cell(k,1);
for i = 1:k
    acqStrs{i} = datestr(datenum(1970,1,1) + epoch(i)/86400,'yyyy-mm-dd HH:MM:SS.FFF');
end
dtms = [NaN; diff(tRel(1:k))*1000];

T = table(seq(1:k), acqStrs, tRel(1:k), dtms, a0(1:k), a1(1:k), ...
          tempC(1:k), rh(1:k), missed(1:k), ...
    'VariableNames', {'frame','acq_time','t_rel_s','dt_ms','A0_V','A1_V', ...
                      'tempC','RH_pct','sketch_missed'});
writetable(T, OUTFILE);

% inline nan-safe stats (no local functions, no Stats toolbox)
d      = dtms(2:end);
dvalid = d(~isnan(d));
if isempty(dvalid)
    dMean = NaN; dStd = NaN; dMin = NaN; dMax = NaN;
else
    dMean = mean(dvalid); dStd = std(dvalid);
    dMin  = min(dvalid);  dMax = max(dvalid);
end

fprintf('\n===== acquisition summary =====\n');
fprintf('Frames received   : %d\n', k);
fprintf('Sequence span     : %d to %d\n', seq(1), seq(k));
fprintf('Dropped in transit: %d\n', dropped);
fprintf('Missed by sketch  : %d\n', max(missed(1:k)));
fprintf('Capture duration  : %.3f s (wall clock %.3f s)\n', tRel(k), wallElapsed);
fprintf('Mean rate         : %.2f Hz\n', (k-1)/max(tRel(k),eps));
fprintf('Frame interval    : mean %.3f ms, sd %.3f ms, min %.3f, max %.3f\n', ...
        dMean, dStd, dMin, dMax);
fprintf('Saved to          : %s\n', OUTFILE);
fprintf('===============================\n');
