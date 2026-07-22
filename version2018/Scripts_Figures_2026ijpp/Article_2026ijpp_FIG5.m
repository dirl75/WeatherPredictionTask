home;clearvars

load('DATA_pupil_BPcenter_zscore_WP2018_CHECK.mat')

analyze_behav_WeatherPred2018


%% CALCULATE METRICS OF PUPIL SIZE, per trial

% choose a method to summarize pupil signal during relevant periods
METRICS={'MAX' 'MEDIAN' 'AUC'};

% 1. IDENTIFY PARTICIPANTS TO EXCLUDE GLOBALLY
% This vector (1 = exclude, 0 = keep) must match the order of fieldnames
exclude_global = PUPILDATA.info.exclude_participant; 

for thisMetric=1:numel(METRICS)

    metric=METRICS{thisMetric};

    % estimate event locations within epoch
    Fs=500;
    beforeDecision_s=abs(PUPILDATA.info.epoch_before_after_event_s(1));
    decisionPoint_samples=round(beforeDecision_s*Fs);
    feedbDurat_samples=round(2*Fs);
    patternDurat_samples=Fs;

    particip_IDs_pupilFiles=fieldnames(PUPILDATA.data);

    % preallocate
    pupil_metric_pattern=nan(300,numel(particip_IDs_pupilFiles));
    pupil_metric_feedb=nan(300,numel(particip_IDs_pupilFiles));
    partIDs=cell(1,1);
    for thisParticipant=1:numel(particip_IDs_pupilFiles)
      
        
        thisID = particip_IDs_pupilFiles{thisParticipant};
        Fs = PUPILDATA.data.(thisID).Fs;
        
        partIDs{thisParticipant,1}=thisID;

          % --- STEP 1: GLOBAL PARTICIPANT EXCLUSION ---
        if exclude_global(thisParticipant) == 1
            partIDs{thisParticipant,1}=[thisID ' - excluded'];
            continue; % Skip to the next participant in the loop
        end

        % 2. PULL RAW PUPIL MATRIX
        currPupilMat = PUPILDATA.data.(thisID).pupilEpochs_blinkinterp;

        % --- STEP 2: TRIAL-LEVEL QUALITY FILTER ---
        % Replace columns (trials) where quality is 0 with NaN to preserve 300-trial structure
        if isfield(PUPILDATA.data.(thisID), 'qualityVector')
            qualityVec = PUPILDATA.data.(thisID).qualityVector;
            badTrials = (qualityVec(:)' == 0); 
            currPupilMat(:, badTrials) = NaN;
        end

        % 3. DOWNSAMPLE IF NECESSARY
        if Fs==1e3
            currPupilMat=downsample(currPupilMat,2);
            Fs=500;
        end

        % pull behav vars
        rt=PUPILDATA.data.(thisID).RT_nomisses;

        for thisTrial=1:size(currPupilMat,2)
            
            pupilTrial=currPupilMat(:,thisTrial);
            
            % Skip calculation if the trial was masked as NaN
            if all(isnan(pupilTrial))
                pupil_metric_pattern(thisTrial,thisParticipant) = NaN;
                pupil_metric_feedb(thisTrial,thisParticipant) = NaN;
                continue; 
            end

            rt_samples=round(rt(thisTrial)*Fs);

            pattern_onset=decisionPoint_samples-rt_samples;
            pattern_offset=decisionPoint_samples+patternDurat_samples;
            
            % Final safety check for indexing bounds
            %if pattern_onset < 1, pattern_onset = 1; end
            
            pupil_epoch_pattern=pupilTrial(pattern_onset:pattern_offset);

            feedback_offset=pattern_offset+feedbDurat_samples;
            pupil_epoch_feedb=pupilTrial(pattern_offset+1:feedback_offset);

            if strcmp(metric,'AUC')
                pupil_metric_pattern(thisTrial,thisParticipant)=trapz(pupil_epoch_pattern);
                pupil_metric_feedb(thisTrial,thisParticipant)=trapz(pupil_epoch_feedb);

            elseif strcmp(metric, 'MAX')
                pupil_metric_pattern(thisTrial,thisParticipant)=max(pupil_epoch_pattern);
                pupil_metric_feedb(thisTrial,thisParticipant)=max(pupil_epoch_feedb);

            elseif strcmp(metric,'MEDIAN')
                pupil_metric_pattern(thisTrial,thisParticipant)=median(pupil_epoch_pattern,'omitmissing');
                pupil_metric_feedb(thisTrial,thisParticipant)=median(pupil_epoch_feedb,'omitmissing');
            end
        end
        
    end
    % compute everything per Block
%
    BlocksMean_pupil_feedb=nan(6,n_participants);
    BlocksMean_pupil_pattern=nan(6,n_participants);

    TrPerBlock=50;
    Nstep=50;
    blockStart=1:Nstep:300-TrPerBlock+1;  %collection of window start points (samples)
    nw=length(blockStart);

    for bl=1:nw  %loop through blocks
        indx=blockStart(bl):blockStart(bl)+TrPerBlock-1;

        currBlock=pupil_metric_pattern(indx,:);
        BlocksMean_pupil_pattern(bl,:)=median(currBlock,1,'omitmissing');

        currBlock=pupil_metric_feedb(indx,:);
        BlocksMean_pupil_feedb(bl,:)=median(currBlock,1,'omitmissing');
        
    end

    betas_pupil_feedb=nan(n_participants,2);
    betas_pupil_pattern=nan(n_participants,2);
    for ii=1:n_participants
        
        Y=BlocksMean_pupil_feedb(:,ii);
        Y=Y(~isnan(Y));
        X=1:numel(Y);
        [b,b0]=LeastSquaresLine(X,Y');
        betas_pupil_feedb(ii,1)=b;
        betas_pupil_feedb(ii,2)=b0;

        Y=BlocksMean_pupil_pattern(:,ii);
        Y=Y(~isnan(Y));
        X=1:numel(Y);
        [b,b0]=LeastSquaresLine(X,Y');
        betas_pupil_pattern(ii,1)=b;
        betas_pupil_pattern(ii,2)=b0;

    end

    if strcmp(metric,'AUC')
        AUC_pupil_pattern=pupil_metric_pattern;
        AUC_pupil_feedb=pupil_metric_feedb;
        AUC_BlocksMean_pupil_pattern=BlocksMean_pupil_pattern;
        AUC_BlocksMean_pupil_feedb=BlocksMean_pupil_feedb;
        betas_AUC_pupil_pattern=betas_pupil_pattern;
        betas_AUC_pupil_feedb=betas_pupil_feedb;
    elseif strcmp(metric, 'MAX')
        MAX_pupil_pattern=pupil_metric_pattern;
        MAX_pupil_feedb=pupil_metric_feedb;
        MAX_BlocksMean_pupil_pattern=BlocksMean_pupil_pattern;
        MAX_BlocksMean_pupil_feedb=BlocksMean_pupil_feedb;
        betas_MAX_pupil_pattern=betas_pupil_pattern;
        betas_MAX_pupil_feedb=betas_pupil_feedb;
    elseif strcmp(metric,'MEDIAN')
        MEDIAN_pupil_pattern=pupil_metric_pattern;
        MEDIAN_pupil_feedb=pupil_metric_feedb;
        MEDIAN_BlocksMean_pupil_pattern=BlocksMean_pupil_pattern;
        MEDIAN_BlocksMean_pupil_feedb=BlocksMean_pupil_feedb;
        betas_MEDIAN_pupil_pattern=betas_pupil_pattern;
        betas_MEDIAN_pupil_feedb=betas_pupil_feedb;
    end

end


disp('done computing metrics of pupil size.')


% IMPORTANT. map ID names from behav to physiol(pupil) dataset

num_IDs = numel(particip_IDs_pupilFiles);
map_indices = zeros(num_IDs, 1); % Pre-allocate the result vector

for i = 1:num_IDs
    % Find the index 'j' in IDs_behav where the string matches IDs_pupil{i}
    % strcmp returns 1 for a match. find returns the index of the match.
    j = find(strcmp(particip_IDs_behavFiles, particip_IDs_pupilFiles{i}));
    
    % Store the found index
    if ~isempty(j)
        % We assume each ID is unique; take the first match if multiple are found
        map_indices(i) = j(1); 
    else
        % Handle cases where an ID is missing (shouldn't happen if sets are the same)
        warning('Participant ID %s not found in particip_IDs_behavFiles', particip_IDs_pupilFiles{i});
        map_indices(i) = NaN; % Use NaN or 0 to mark missing IDs
    end
end

% now reorder behav data so its columns match the IDs of physiol data

BlocksMean_perf=BlocksMean_perf(:,map_indices);
BlocksMean_rt=BlocksMean_rt(:,map_indices);
BlocksStd_perf=BlocksStd_perf(:,map_indices);
BlocksStd_rt=BlocksStd_rt(:,map_indices);

Perf_first=Perf_first(map_indices);
Perf_last=Perf_last(map_indices);
deltaP_LastFirst=deltaP_LastFirst(map_indices);
n_blocks2finish=n_blocks2finish(map_indices);

RTMat=RTMat(:,map_indices);
PerfMat=PerfMat(:,map_indices);

% reorder other vars

Female = Female(map_indices);
StimWeatherMap = StimWeatherMap(map_indices);
StimMat = StimMat(:, map_indices);
Age=Age(map_indices);



%compute learning metric
% Get IDs
subjects = fieldnames(PUPILDATA.data);

% Pre-allocate a table for the results
learningSummary = table('Size', [numel(subjects), 4], ...
    'VariableTypes', {'string', 'double', 'double', 'double'}, ...
    'VariableNames', {'ParticipantID', 'MeanPerf_Block1', 'MeanPerf_BlockFINAL', 'LearningGain'});

for i = 1:numel(subjects)
    subID = subjects{i};
    subP = PUPILDATA.data.(subID);
    
    % Extract performance vectors
    % (Assuming 1 = Correct, 0 = Incorrect)
    p1    = subP.perf_Block1;
    pFinal = subP.perf_BlockFINAL;
    
    % Calculate Means (using 'omitnan' just in case)
    m1     = mean(p1, 'omitnan');
    mFinal = mean(pFinal, 'omitnan');
    
    % Store in table
    learningSummary.ParticipantID(i) = string(subID);
    learningSummary.MeanPerf_Block1(i) = m1;
    learningSummary.MeanPerf_BlockFINAL(i) = mFinal;
    learningSummary.LearningGain(i) = mFinal - m1;
end

% Display the top of the table
disp('--- Learning Performance Summary ---');
disp(head(learningSummary));

% Optional: Quick Histogram of Learning Gains
figure('Color', 'w');
histogram(learningSummary.LearningGain, 10, 'FaceColor', [0.2 0.6 0.8]);
xline(0, 'r--', 'LineWidth', 2); % Line at 0 (no learning)
xlabel('Change in Mean Performance (Final - First)');
ylabel('Number of Participants');
title('Distribution of Learning Gains across the Sample');

%%
X=[-0.2 1];
figure; hold on
plot(learningSummary.LearningGain,betas_AUC_pupil_feedb(:,1),'ok')
[b,b0,r]=LeastSquaresLine(learningSummary.LearningGain,betas_AUC_pupil_feedb(:,1));
plot(X,b0+b*X,'LineWidth',2,'Color','r')
title('FEEDBACK')
ylabel('Beta - AUC')
xlabel('Delta Performance last-first (fraction corr)')
figure;hold on
plot(learningSummary.LearningGain,betas_MAX_pupil_feedb(:,1),'ok')
[b,b0,r]=LeastSquaresLine(learningSummary.LearningGain,betas_MAX_pupil_feedb(:,1));
plot(X,b0+b*X,'LineWidth',2,'Color','r')
title('FEEDBACK')
ylabel('Beta - MAX')
xlabel('Delta Performance last-first (fraction corr)')
figure;hold on
plot(learningSummary.LearningGain,betas_MEDIAN_pupil_feedb(:,1),'ok')
[b,b0,r]=LeastSquaresLine(learningSummary.LearningGain,betas_MEDIAN_pupil_feedb(:,1));
plot(X,b0+b*X,'LineWidth',2,'Color','r')
title('FEEDBACK')
ylabel('Beta - MEDIAN')
xlabel('Delta Performance last-first (fraction corr)')

%%
figure;hold on
plot(learningSummary.LearningGain,betas_AUC_pupil_pattern(:,1),'ok')
[b,b0,r]=LeastSquaresLine(learningSummary.LearningGain,betas_AUC_pupil_pattern(:,1));
plot(X,b0+b*X,'LineWidth',2,'Color','r')
title('PATTERN')
ylabel('Beta - AUC')
xlabel('Delta Performance last-first (fraction corr)')
figure;hold on
plot(learningSummary.LearningGain,betas_MAX_pupil_pattern(:,1),'ok')
[b,b0,r]=LeastSquaresLine(learningSummary.LearningGain,betas_MAX_pupil_pattern(:,1));
plot(X,b0+b*X,'LineWidth',2,'Color','r')
title('PATTERN')
ylabel('Beta - MAX')
xlabel('Delta Performance last-first (fraction corr)')
figure;hold on
plot(learningSummary.LearningGain,betas_MEDIAN_pupil_pattern(:,1),'ok')
[b,b0,r]=LeastSquaresLine(learningSummary.LearningGain,betas_MEDIAN_pupil_pattern(:,1));
plot(X,b0+b*X,'LineWidth',2,'Color','r')
title('PATTERN')
ylabel('Beta - MEDIAN')
xlabel('Delta Performance last-first (fraction corr)')


%% PLOT FIGURE

metric2plot='AUC';
%metric2plot='MEDIAN';
%metric2plot='MAX';

if strcmp(metric2plot,'MEDIAN')
    B_f=betas_MEDIAN_pupil_feedb;
    B_p=betas_MEDIAN_pupil_pattern;
    yL='Median pupil (z-score)';
    yLimi=[-1 1.3];
elseif strcmp(metric2plot,'MAX')
    B_f=betas_MAX_pupil_feedb;
    B_p=betas_MAX_pupil_pattern;
    yL='Max pupil (z-score)';
    yLimi=[0.2 3.8];
elseif strcmp(metric2plot,'AUC')
    B_f=betas_AUC_pupil_feedb;
    B_p=betas_AUC_pupil_pattern;
    yL='AUC pupil (z·s)';
    yLimi=[-610 1100];
end

% 1. Functional Colors (Slope Sign: Used in Top Plots)

% 2. Categorical Colors (Condition: Used in Bottom Plots)
%    Relating intensity: Vibrant Blue (Pattern) vs. Duller Orange (Feedback)
color_patt = [0.4 0.6 0.8];   
color_feedb = [0.8 0.6 0.4]; 

color_up_patt = color_patt-0.2;    
color_down_patt = color_patt+0.2;  

color_up_feedb = color_feedb-0.2;    
color_down_feedb = color_feedb+0.2;  

ms=12;
fsize=11;
fsizeBig=21;
fname='verdana';

xlimi_hist=1.05*[min([B_f(:,1);B_p(:,1)]) 1.05*max([B_f(:,1);B_p(:,1)])];
xlimi_blocks=[0.6 6.4];

lw=1.5;

left=0.13;
bott_up=0.58;
bott_bott=0.11;
bott_mid=0.18;
w=0.34;
h=0.33;

posits=[left bott_up w h;
    left+1.5*w bott_up w h;
    1.8*left bott_mid 1.8*w 0.74*h;
    1.8*left bott_bott 1.8*w 0.2*h];

posits_insets=[1.4*left 0.86 0.17*w 0.19*h;
    5.4*left 0.86 0.17*w 0.19*h];

fig=figure;

ax1=axes('Parent',fig,'TickDir','out','position',posits(1,:),...
    'XTick',1:6,...
    'FontSize',fsize,'FontName',fname);
hold(ax1,'on')
X=[0.8 6.2];
for j=1:size(B_p,1)
    Y=B_p(j,2) + B_p(j,1)*X;

    if B_p(j,1)>0
        col=color_up_patt;
    elseif B_p(j,1)<0
        col=color_down_patt;
    end

    plot(X,Y, 'linewidth',lw,'color',col)
end
ylabel(yL)
xlim(xlimi_blocks)
ylim(yLimi)
xlabel('50-trial Blocks')
title({'pattern' ''},'fontweight','normal')

text(4.1,1100,'Increase','FontWeight','bold',...
    'FontSize',fsize-2,'FontName',fname, 'color',color_up_patt)
text(4.1,1000,'Decrease','FontWeight','bold',...
    'FontSize',fsize-2,'FontName',fname,'Color',color_down_patt)


ax1_inset=axes('parent',fig,'Position',posits_insets(1,:),...
    'visible','off');
hold(ax1_inset,'on')

temp=B_p(:,1)>0; %goes down
y=[sum(temp) sum(~temp)]; %n of cases [down up]
P1=pie(y);
P1(1).FaceColor=color_up_patt;
P1(3).FaceColor=color_down_patt;

P1(2).FontName=fname;
P1(2).Position=[-1 -0.6 0];
P1(2).FontSize=fsize-4;

P1(4).FontName=fname;
P1(4).Position=[0.9 0.7 0];
P1(4).FontSize=fsize-4;


ax2=axes('Parent',fig,'TickDir','out','position',posits(2,:),...
    'XTick',1:6,...
    'FontSize',fsize,'FontName',fname);
hold(ax2,'on')
X=[0.8 6.2];
for j=1:size(B_f,1)
    Y=B_f(j,2) + B_f(j,1)*X;

    if B_f(j,1)>0
        col=color_up_feedb;
    elseif B_f(j,1)<0
        col=color_down_feedb;
    end

    plot(X,Y, 'linewidth',lw,'color',col)
end
xlim(xlimi_blocks)

ylabel(yL)
xlabel('50-trial Blocks')
title({'feedback' ''},'fontweight','normal')

text(4.1,2000,'Increase','FontWeight','bold',...
    'FontSize',fsize-2,'FontName',fname, 'color',color_up_feedb)
text(4.1,1800,'Decrease','FontWeight','bold',...
    'FontSize',fsize-2,'FontName',fname,'Color',color_down_feedb)
ylim(yLimi)



ax2_inset=axes('parent',fig,'Position',posits_insets(2,:),...
    'visible','off');
hold(ax2_inset,'on')

temp=B_f(:,1)>0; %goes down
y=[sum(temp) sum(~temp)]; %n of cases [down up]
P1=pie(y);
P1(1).FaceColor=color_up_feedb;
P1(3).FaceColor=color_down_feedb;

P1(2).FontName=fname;
P1(2).Position=[-1 0.5 0];
P1(2).FontSize=fsize-4;

P1(4).FontName=fname;
P1(4).Position=[0.6 -1 0];
P1(4).FontSize=fsize-4;


ax3=axes('parent',fig,'TickDir','out', 'position', posits(3,:),...
    'XColor','none',...
    'FontSize',fsize,'FontName',fname);
set(ax3, 'Box', 'off');
hold(ax3,'on')

minVal = min([B_p(:,1); B_f(:,1)]);
maxVal = max([B_p(:,1); B_f(:,1)]);
numBins = 23;
binEdges = linspace(minVal, maxVal, numBins + 1);

% betas pattern
histogram(B_p(:,1), 'BinEdges', binEdges, ...
    'Normalization', 'count', ...
    'FaceColor', color_patt, ...
    'FaceAlpha', 0.7, ...
    'DisplayName', 'pattern',...
    'LineStyle','none');

% betas feedback
histogram(B_f(:,1), 'BinEdges', binEdges, ...
    'Normalization', 'count', ...
    'FaceColor', color_feedb, ...
    'FaceAlpha', 0.7, ...
    'DisplayName', 'feedback',...
    'LineStyle','none');

ylabel({'Number of' 'participants'})
L=legend;
L.Position=[0.75 0.34 0.1 0.05];
L.EdgeColor='none';
L.FontSize=fsize-3;
L.IconColumnWidth=12;
xlim(xlimi_hist)

ax4=axes('parent',fig,'TickDir','out', 'position', posits(4,:),...
    'ycolor','none',...
    'FontSize',fsize,'FontName',fname);
hold(ax4,'on')
jitter_factor = 1.0; 
offset = jitter_factor / 2; 
jitter_p = jitter_factor * rand(size(B_p(:,1))) - offset; % Random value between -0.25 and 0.25
jitter_f = jitter_factor * rand(size(B_f(:,1))) - offset;

% Scatter Plot pattern betas (at y=1)
yCenter_patt=1;
plot(B_p(:,1), yCenter_patt + jitter_p,...
    'linestyle','none',...
    'marker','.','markersize',ms,...
    'color', color_patt);
yCenter_feedb=2;
% Scatter Plot feedback betas (at y=2)
plot(B_f(:,1), yCenter_feedb + jitter_f, 'linestyle','none',...
    'marker','.','markersize',ms,...
    'color', color_feedb);

lo=min([yCenter_feedb + jitter_f;yCenter_patt + jitter_p]);
hi=max([yCenter_feedb + jitter_f;yCenter_patt + jitter_p]);

ylim([lo-0.15 hi+0.1])
xlim(xlimi_hist)
xlabel('Beta values (AUC units/block)')


xLeft=0.01;
xRight=0.47;
yPosUP=0.94;
yPosBOTT=0.43;
lettW=0.03;
lettH=0.06;

annotation(fig,'textbox', [xLeft yPosUP lettW lettH],'String','A','fontweight','bold',...
    'HorizontalAlignment','center','FontSize',fsizeBig,'FitBoxToText','off','EdgeColor','none',...
    'fontname',fname);
annotation(fig,'textbox', [xRight yPosUP lettW lettH],'String','B','fontweight','bold',...
    'HorizontalAlignment','center','FontSize',fsizeBig,'FitBoxToText','off','EdgeColor','none',...
    'fontname',fname);

annotation(fig,'textbox', [xLeft*4 yPosBOTT lettW lettH],'String','C','fontweight','bold',...
    'HorizontalAlignment','center','FontSize',fsizeBig,'FitBoxToText','off','EdgeColor','none',...
    'fontname',fname);



set(fig,'PaperUnits','centimeters')
set(fig, 'PaperPosition', [0 0 14 13])

print(fig,'FIG_05','-dpng','-r750')