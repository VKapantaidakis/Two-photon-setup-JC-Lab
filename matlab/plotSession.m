function plotSession(sessionDir)
%PLOTSESSION  Plot the DAQ frame logs from one experiment session.
%
%   plotSession                 % pick the most recent session automatically
%   plotSession(sessionDir)     % plot a specific session folder
%
%   Reads the *_allframes.csv written by arduinoFrameLog('save', ...) and
%   produces: frame timing, cumulative frames per phase, analog channels,
%   and temperature / humidity. Prints a per-phase summary table.
%
%   MATLAB R2014b compatible (no datetime, no yyaxis, no local-fn-in-script).

if nargin < 1 || isempty(sessionDir)
    sessionDir = findLatestSession();
    if isempty(sessionDir)
        error('No session folders found under ~/Documents/MATLAB/ExperimentData');
    end
    fprintf('Using most recent session:\n  %s\n\n', sessionDir);
end

if ~exist(sessionDir,'dir')
    error('Session folder not found: %s', sessionDir);
end

% ---- find the all-frames CSV -------------------------------------
d = dir(fullfile(sessionDir,'*_allframes.csv'));
if isempty(d)
    d = dir(fullfile(sessionDir,'*.csv'));
end
if isempty(d)
    error('No CSV files found in %s', sessionDir);
end
[~,newest] = max([d.datenum]);
csvFile = fullfile(sessionDir, d(newest).name);
fprintf('Reading %s\n', csvFile);

T = readtable(csvFile);
if isempty(T)
    error('CSV is empty: %s', csvFile);
end

% ---- metadata, if present ----------------------------------------
metaTxt = '';
mfile = fullfile(sessionDir,'metadata.txt');
if exist(mfile,'file')
    fid = fopen(mfile,'r');
    if fid > 0
        c = textscan(fid,'%s','Delimiter','\n','Whitespace','');
        fclose(fid);
        metaTxt = strjoin(c{1}', '   |   ');
    end
end

% ---- columns ------------------------------------------------------
frame = T.frame;
tRel  = T.t_rel_s;
dtms  = T.dt_ms;
if ismember('phase', T.Properties.VariableNames)
    phase = T.phase;
else
    phase = repmat({'all'}, height(T), 1);
end
hasAnalog = all(ismember({'A0_V','A1_V'}, T.Properties.VariableNames));
hasEnv    = all(ismember({'tempC','RH_pct'}, T.Properties.VariableNames));

phases  = unique(phase,'stable');
nPhases = numel(phases);
cols    = lines(max(nPhases,3));

% ---- figure -------------------------------------------------------
figure('Name',['Session: ' sessionDir],'NumberTitle','off','Color','w', ...
       'Units','normalized','Position',[0.06 0.08 0.86 0.82]);

% 1. frame interval, coloured by phase
subplot(4,1,1); hold on; grid on;
for i = 1:nPhases
    sel = strcmp(phase, phases{i});
    plot(tRel(sel), dtms(sel), '.', 'Color', cols(i,:), 'MarkerSize', 6);
end
ylabel('frame interval (ms)');
title('Frame timing (colour = phase)');
legend(phases,'Location','northeast','Interpreter','none');

% 2. cumulative frames
subplot(4,1,2); hold on; grid on;
for i = 1:nPhases
    sel = strcmp(phase, phases{i});
    plot(tRel(sel), find(sel), '-', 'Color', cols(i,:), 'LineWidth', 1.4);
end
ylabel('frames received');
title('Cumulative frames');

% 3. analog channels
subplot(4,1,3); hold on; grid on;
if hasAnalog
    plot(tRel, T.A0_V, 'Color',[0.00 0.45 0.74], 'LineWidth',1.0);
    plot(tRel, T.A1_V, 'Color',[0.85 0.33 0.10], 'LineWidth',1.0);
    legend({'A0','A1'},'Location','northeast');
    ylabel('DAQ input (V)');
else
    text(0.5,0.5,'no analog channels in CSV','Units','normalized', ...
         'HorizontalAlignment','center');
end
title('DAQ analog channels');

% 4. environment
subplot(4,1,4); hold on; grid on;
if hasEnv
    plot(tRel, T.tempC,  'Color',[0.47 0.67 0.19], 'LineWidth',1.4);
    plot(tRel, T.RH_pct, 'Color',[0.49 0.18 0.56], 'LineWidth',1.4,'LineStyle','--');
    legend({'T (\circC)','RH (%)'},'Location','northeast');
    ylabel('T / RH');
else
    text(0.5,0.5,'no environment data in CSV','Units','normalized', ...
         'HorizontalAlignment','center');
end
xlabel('elapsed time (s)');
title('DHT22 temperature / humidity');

if ~isempty(metaTxt)
    annotation('textbox',[0.02 0.955 0.96 0.04],'String',metaTxt, ...
        'EdgeColor','none','FontSize',8,'Interpreter','none', ...
        'HorizontalAlignment','left');
end

% ---- console summary ---------------------------------------------
fprintf('\n===== SESSION SUMMARY =====\n');
fprintf('Folder : %s\n', sessionDir);
fprintf('Frames : %d   (seq %d..%d)\n', height(T), min(frame), max(frame));
fprintf('Duration: %.2f s\n', max(tRel)-min(tRel));
fprintf('\n%-16s %8s %10s %10s %10s %10s\n', ...
    'phase','frames','dur (s)','rate (Hz)','dt mean','dt sd');
for i = 1:nPhases
    sel = strcmp(phase, phases{i});
    tt  = tRel(sel);
    dd  = dtms(sel);
    dd  = dd(~isnan(dd));
    if numel(tt) > 1
        dur  = tt(end)-tt(1);
        rate = (numel(tt)-1)/max(dur,eps);
    else
        dur = 0; rate = NaN;
    end
    if isempty(dd), mn = NaN; sd = NaN; else mn = mean(dd); sd = std(dd); end
    fprintf('%-16s %8d %10.2f %10.2f %10.3f %10.3f\n', ...
        phases{i}, sum(sel), dur, rate, mn, sd);
end

% gaps in the sequence number = frames lost in transit
gaps = diff(frame);
lost = sum(gaps(gaps > 1) - 1);
fprintf('\nFrames lost in transit (sequence gaps): %d\n', lost);
if ismember('sketch_missed', T.Properties.VariableNames)
    fprintf('Max sketch-missed counter            : %d\n', max(T.sketch_missed));
end
fprintf('===========================\n\n');

end


% =====================================================================
function sdir = findLatestSession()
root = fullfile(getenv('HOME'),'Documents','MATLAB','ExperimentData');
sdir = '';
if ~exist(root,'dir'), return; end

days = dir(root);
days = days([days.isdir] & ~ismember({days.name},{'.','..'}));
best = -inf;
for i = 1:numel(days)
    ss = dir(fullfile(root, days(i).name));
    ss = ss([ss.isdir] & ~ismember({ss.name},{'.','..'}));
    for j = 1:numel(ss)
        p = fullfile(root, days(i).name, ss(j).name);
        c = dir(fullfile(p,'*.csv'));
        if isempty(c), continue; end
        if max([c.datenum]) > best
            best = max([c.datenum]);
            sdir = p;
        end
    end
end
end
