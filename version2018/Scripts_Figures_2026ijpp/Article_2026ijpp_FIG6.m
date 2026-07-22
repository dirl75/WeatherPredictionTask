%% 0. LOAD DATA

load('DATA_pupil_BPcenter_zscore_WP2018_CHECK.mat','PUPILDATA')


%% 1. CONFIGURATION & TIME VECTOR

Fs = 500;

blueCol = [0.2 0.2 0.7]; redCol = [0.7 0.2 0.2]; win = 15;
fname = 'Verdana';
fsize = 13; fsizeBig=fsize+8;

part_names = fieldnames(PUPILDATA.data);
nParts = numel(part_names);
epoch_limits = PUPILDATA.info.epoch_before_after_event_s;

% Determine number of samples
pRef = part_names{1};
numSamples = size(PUPILDATA.data.(pRef).pupilEpochs_blinkinterp, 1);
if PUPILDATA.data.(pRef).Fs == 1000, numSamples = numSamples / 2; end

tempo = linspace(epoch_limits(1), epoch_limits(2), numSamples);

%% 2. PART 1: PUPIL ANALYSIS (Robust Slicing)

exclude_global=PUPILDATA.info.exclude_participant;

pupilMat_perf1 = nan(numSamples, nParts);
pupilMat_perf0 = nan(numSamples, nParts);

for p = 1:nParts


    if exclude_global(p) == 1
        continue; % Skip to the next participant in the loop
    end

    pName = part_names{p}; dP = PUPILDATA.data.(pName);
    pData = dP.pupilEpochs_blinkinterp;
    if dP.Fs == 1000, pData = pData(1:2:end, :); end

    totalT = size(pData, 2);

    % Define the target trial indices
    idx2b = [1:min(50, totalT), max(1, totalT-49):totalT];

    % Slice Data
    pData_slice = pData(:, idx2b);

    % Slice Metadata & Force to Column Vectors
    pPerf_slice = dP.performance_nomisses(idx2b);
    pQual_slice = dP.qualityVector(idx2b);

    % Ensure 1x100 becomes 100x1 before the '&'
    meanData = mean(pData_slice, 1, 'omitnan');
    validTrialMask = pQual_slice(:) & ~isnan(meanData(:));

    % Final Performance Masks (100x1)
    perf1_mask = pPerf_slice(:) & validTrialMask;
    perf0_mask = ~pPerf_slice(:) & validTrialMask;

    % Average across trials for this participant
    if any(perf1_mask)
        pupilMat_perf1(:,p) = mean(pData_slice(:, perf1_mask), 2, 'omitnan');
    end
    if any(perf0_mask)
        pupilMat_perf0(:,p) = mean(pData_slice(:, perf0_mask), 2, 'omitnan');
    end
end

[final_mask_pupil, diff_pupil] = run_cluster_stats(pupilMat_perf1, pupilMat_perf0, Fs, tempo);


%% PLOT



left=0.1;
bott=0.15;
w=0.41;
h=0.74;

posits=[left bott w h;
    left+1.37*w bott 0.78*w h];

ylimi1=[-0.62 1.1];
ylimi2=[-0.45 0.38];
xlimi=[-2 3];

% Plot Pupil
fig1 = figure('Color', 'w', 'Position', [100 100 1100 450], 'Name', 'Pupil Analysis');

ax1=axes('Parent',fig1,'TickDir','out', 'position', posits(1,:),...
    'FontSize',fsize,'FontName',fname);
hold(ax1, 'on')
plot_windows(ylimi1);
plot_with_ci(tempo, pupilMat_perf1, blueCol, win, nParts);
plot_with_ci(tempo, pupilMat_perf0, redCol, win, nParts);
ylabel('Pupil size (z-score)');
xlim(xlimi);
ylim(ylimi1)
xlabel('Time to button press (s)')

text(0,-0.3,'Incorrect','FontName',fname,'FontWeight','bold',...
    'color',redCol)
text(-0.9,0.7,'Correct','FontName',fname,'FontWeight','bold',...
    'color',blueCol)

annotation(fig1,'textbox', [0.17 0.87 0.2 0.1],'String','pattern',...
    'HorizontalAlignment','center','FontSize',fsize,'FitBoxToText','off','EdgeColor','none',...
    'fontname',fname);
annotation(fig1,'textbox', [0.32 0.87 0.2 0.1],'String','feedback',...
    'HorizontalAlignment','center','FontSize',fsize,'FitBoxToText','off','EdgeColor','none',...
    'fontname',fname);



ax2=axes('Parent',fig1,'TickDir','out', 'position', posits(2,:),...
    'FontSize',fsize,'FontName',fname);
hold(ax2, 'on')
plot_windows(ylimi2);
plot_with_ci(tempo, diff_pupil, [0.5 0.8 0.5], win, nParts);
plot_significance(tempo, final_mask_pupil, 0.3);
plot([-2 3], [0 0], 'k--');
xlim(xlimi);
ylim(ylimi2)
ylabel({'Difference' 'correct minus incorrect (z-score)'});
xlabel('Time to button press (s)')

annotation(fig1,'textbox', [0.67 0.87 0.2 0.1],'String','pattern',...
    'HorizontalAlignment','center','FontSize',fsize,'FitBoxToText','off','EdgeColor','none',...
    'fontname',fname);
annotation(fig1,'textbox', [0.82 0.87 0.2 0.1],'String','feedback',...
    'HorizontalAlignment','center','FontSize',fsize,'FitBoxToText','off','EdgeColor','none',...
    'fontname',fname);



xLeft=0.01;
xRight=0.51;
yPos=0.94;
lettW=0.03;
lettH=0.06;

annotation(fig1,'textbox', [xLeft yPos lettW lettH],'String','A','fontweight','bold',...
    'HorizontalAlignment','center','FontSize',fsizeBig,'FitBoxToText','off','EdgeColor','none',...
    'fontname',fname);
annotation(fig1,'textbox', [xRight yPos lettW lettH],'String','B','fontweight','bold',...
    'HorizontalAlignment','center','FontSize',fsizeBig,'FitBoxToText','off','EdgeColor','none',...
    'fontname',fname);


set(fig1,'PaperUnits','centimeters')
set(fig1, 'PaperPosition', [0 0 20 10])

print(fig1,'FIG_06','-dpng','-r750')


%%
%% --- HELPER FUNCTIONS (Must be at end of script) ---
function [mask, diff_mat, labels] = run_cluster_stats(m1, m0, Fs, tempo)
cluster_threshold = 0.01; final_alpha = 0.05; n_perms = 5000;
min_samples = ceil(0.1 * Fs);
diff_mat = m1 - m0; [nT, nS] = size(diff_mat);

t_obs = mean(diff_mat, 2, 'omitnan') ./ (std(diff_mat, 0, 2, 'omitnan') ./ sqrt(nS));
p_obs = 2 * (1 - tcdf(abs(t_obs), nS-1));
labels = bwlabel(p_obs < cluster_threshold);
for c = 1:max(labels), if sum(labels==c) < min_samples, labels(labels==c)=0; end; end
labels = bwlabel(labels > 0);

max_null = zeros(n_perms, 1);
for p = 1:n_perms
    flip = sign(randn(1, nS));
    t_perm = mean(diff_mat .* flip, 2) ./ (std(diff_mat .* flip, 0, 2) ./ sqrt(nS));
    p_labels = bwlabel(abs(t_perm) > tinv(1-cluster_threshold/2, nS-1));
    masses = [0];
    for pc = 1:max(p_labels)
        if sum(p_labels==pc) >= min_samples, masses(end+1) = sum(abs(t_perm(p_labels==pc))); end
    end
    max_null(p) = max(masses);
end

mask = false(nT, 1);
for c = 1:max(labels)
    if mean(max_null >= sum(abs(t_obs(labels==c)))) < final_alpha, mask(labels==c)=true; end
end

fprintf('\n--- Cluster Analysis Results ---\n');
fprintf('Total clusters initially identified ( > min_samples): %d\n', max(labels));

for c = 1:max(labels)
    % Calculate the observed mass for this specific cluster
    cluster_indices = (labels == c);
    obs_mass = sum(abs(t_obs(cluster_indices)));
    
    % Calculate p-value based on the permutation distribution
    p_val = mean(max_null >= obs_mass);
    
    % Get time range for the cluster
    time_start = tempo(find(cluster_indices, 1, 'first'));
    time_end   = tempo(find(cluster_indices, 1, 'last'));
    
    % Output stats
    fprintf('Cluster #%d: Time [%.2fs to %.2fs], Mass = %.2f, p = %.4f %s\n', ...
        c, time_start, time_end, obs_mass, p_val, repmat('*', 1, p_val < 0.05));
end





end

function plot_with_ci(x, data, col, win, N)
mu = movmean(mean(data, 2, 'omitnan'), win);
ci = 1.96 * std(data, 0, 2, 'omitnan') / sqrt(N);
fill([x, fliplr(x)], [mu-ci; flipud(mu+ci)], col, 'FaceAlpha', 0.2, 'EdgeColor', 'none');
plot(x, mu, 'Color', col, 'LineWidth', 2);
end

function plot_windows(yl)
patch([-1 1 1 -1], [yl(1) yl(1) yl(2) yl(2)], [0.95 0.95 0.95], 'EdgeColor', 'none');
patch([1 3 3 1], [yl(1) yl(1) yl(2) yl(2)], [0.85 0.85 0.85], 'EdgeColor', 'none');
end

function plot_significance(x, mask, y_pos)
if any(mask)
    plot(x(mask), ones(sum(mask),1)*y_pos, 'ks', 'MarkerSize', 4, 'MarkerFaceColor', 'k');
    lbls = bwlabel(mask);
    for i = 1:max(lbls), text(median(x(lbls==i)), y_pos*1.1, '*', 'FontSize', 18, 'Horiz','center'); end
end
end