%% LOAD DATA, CALCULATE BEHAVIORAL VARIABLES

if ~exist('behaviorAnalysisDone', 'var') || ~behaviorAnalysisDone
    analyze_behav_WeatherPred2018
else
    disp('analysis of behavioral files already DONE.')
    disp('all relevant variables are in the worskpace.')
end

load('DATA_pupil_BPcenter_zscore_WP2018_CHECK.mat') %mat file produced by script 'analyze_Pupil_WeatherPred2018'

%% PRODUCE PERI-EVENT PUPIL EPOCHS 
% (requires having loaded PUPILDATA structure array)

baseline_s=0.5;  %duration of baseline, in seconds

pnames_pupil=fieldnames(PUPILDATA.data);
%preallocate
pupilEpochs_BP=nan(1,numel(particip_IDs));
performance_lastBlock=nan(1,numel(particip_IDs));


% counter
c=0;
for thisParticip = 1 : numel(pnames_pupil)
    %check if participant is in behavior database
    id=pnames_pupil{thisParticip}(1:2);
    F=strcmp(id,particip_IDs);
    if sum(F)>0
        c=c+1;
        
        pupilMat=PUPILDATA.data.(pnames_pupil{thisParticip}).pupilEpochs_blinkinterp;
        FILT=logical(PUPILDATA.data.(pnames_pupil{thisParticip}).qualityVector);
        pupilMat=pupilMat(:,FILT);

        pupilVector=median(pupilMat,2,'omitmissing');
        %check Fs and correct if needed
        if PUPILDATA.data.(pnames_pupil{thisParticip}).Fs==1000
            pupilVector=downsample(pupilVector,2);
        end
        pupilEpochs_BP(1:numel(pupilVector),c)=pupilVector;
        performance_lastBlock(c)=mean(PUPILDATA.data.(pnames_pupil{thisParticip}).performance_nomisses(end-49:end));
    end
end

Fs=500;

%tempo=(0:size(pupilEpochs,1)-1)./Fs;
%tempo_EvRelat=tempo+PUPILDATA.info.epoch_before_after_event_s(1);

% calculate pupil maxima times
pnames_pupil=fieldnames(PUPILDATA.data);

pnames_pupil=pnames_pupil(PUPILDATA.info.filter_min_n_trials);

AUC_pattern=nan(numel(pnames_pupil),1);  % area under the curve
AUC_feedback=nan(numel(pnames_pupil),1);
TAB_pattern=nan(numel(pnames_pupil),1); % fraction of time above baseline
TAB_feedback=nan(numel(pnames_pupil),1);

AUC_PATTERN=nan(numel(pnames_pupil),1);  % area under the curve
AUC_FEEDB=nan(numel(pnames_pupil),1);

Maxima_feedb=nan(300,numel(pnames_pupil));
Maxima_patt=nan(300,numel(pnames_pupil));


for thisP = 1:numel(pnames_pupil)

    PM=PUPILDATA.data.(pnames_pupil{thisP}).pupilEpochs_blinkinterp;
    FILT=logical(PUPILDATA.data.(pnames_pupil{thisP}).qualityVector);
    PM=PM(:,FILT);


    tempo=(0:size(PM,1)-1)./PUPILDATA.data.(pnames_pupil{thisP}).Fs;
    tempo_EvRelat_BP=tempo+PUPILDATA.info.epoch_before_after_event_s(1);
    auc_patt=nan(size(PM,2),1);
    auc_feedb=nan(size(PM,2),1);
    fract_time_aboveBaseline_patt=nan(size(PM,2),1);
    fract_time_aboveBaseline_feedb=nan(size(PM,2),1);
 
    for j=1:size(PM,2) %loop through trials
        pupil=PM(:,j);
        
        pupil=MovMean_DRL(pupil,20);
        
        rt=PUPILDATA.data.(pnames_pupil{thisP}).RT_nomisses(j);
        logi_pattern=tempo_EvRelat_BP<=1 & tempo_EvRelat_BP>-rt;
        logi_feedback=tempo_EvRelat_BP>1;

        logi_beforePattern=tempo_EvRelat_BP<-rt;
        
        %find the index where pattern starts
        t_patternStart=-rt;
        distances=abs(tempo_EvRelat_BP - t_patternStart);
        distances(tempo_EvRelat_BP>=0)=nan; %exclude positive values
        [~, idx_PatternStart] = min(distances);
       
        nSamples_baseline=round(Fs*baseline_s);
        if sum(logi_beforePattern)<nSamples_baseline
            warning('there are not enough samples before pattern to form the baseline')
            disp(['trial = ' num2str(j)])
            disp(pnames_pupil{thisP})
        end
        
        % now build baseline: right before pattern start
        logi_baseline=false(size(tempo_EvRelat_BP));
        logi_baseline(idx_PatternStart-nSamples_baseline:idx_PatternStart)=true;


        auc_patt(j)=trapz(pupil(logi_pattern),tempo(logi_pattern));
        auc_feedb(j)=trapz(pupil(logi_feedback),tempo(logi_feedback));
        
        BL=mean(pupil(logi_baseline));
        
        aboveBL_pattern=sum(pupil(logi_pattern)>BL);
        aboveBL_feedb=sum(pupil(logi_feedback)>BL);

        fract_time_aboveBaseline_patt(j)=aboveBL_pattern./sum(logi_pattern);
        fract_time_aboveBaseline_feedb(j)=aboveBL_feedb./sum(logi_feedback);

        p1=pupil(logi_pattern);
        [max_val1, max_idx1] = max(p1);
        Maxima_patt(j,thisP)=max_val1;
        
        p2=pupil(logi_feedback);
        [max_val2, max_idx2] = max(p2);
        Maxima_feedb(j,thisP)=max_val2;
        
    end
    AUC_pattern(thisP)=mean(auc_patt,'omitmissing');
    AUC_feedback(thisP)=mean(auc_feedb,'omitmissing');
    TAB_pattern(thisP)=mean(fract_time_aboveBaseline_patt);
    TAB_feedback(thisP)=mean(fract_time_aboveBaseline_feedb);
    
    %get block (50-trial) values
    N=50;
    L=numel(auc_patt);
    numBlocks=floor(L/N);
    %auc_temp=reshape(auc_patt,N,numBlocks);
    
    AUC_PATTERN(1:numel(auc_patt),thisP)=auc_patt;
    AUC_FEEDB(1:numel(auc_patt),thisP)=auc_feedb;
    
end

MAX_pattern=mean(Maxima_patt,1,'omitnan');
MAX_feedback=mean(Maxima_feedb,1,'omitnan');

disp('done processing pupil data.')

%% PLOT FIGURE


fsize=13;
fsizeBig=fsize+10;
fname='verdana';

w=0.39;
h=0.42;
left=0.08;
bott_up=0.53;
bott_bott=0.05;


positions=[left bott_up w h;
    left+1.24*w bott_up w h;
    left*2 bott_bott w*0.7 h*0.73;
    left+1.4*w bott_bott w*0.7 h*0.73];


ms=18;

yLAB='Pupil size (z-score)';
ylimi1=[-1.27 1.45];
%ylimi1=[-200 800];
xlimi=[-1.8 3.02];



boxPlotYwidth=[1 1.18];

fig=figure('color','w');

lw=1;

%%%%%%%%%%% A

ax1=axes('parent',fig, 'position', positions(1,:),'tickdir','out','fontsize',fsize,...
    'fontname', fname,'xtick',-2:3,'xgrid','on');
hold(ax1,'on')


greycol_patt=[0.93 0.93 0.93];
greycol_feedb=[0.82 0.82 0.82];

feedb_area=true(size(tempo_EvRelat_BP));
feedb_area(tempo_EvRelat_BP<1)=false;
feedb_area(tempo_EvRelat_BP>3)=false;

area(tempo_EvRelat_BP,feedb_area*ylimi1(2),'EdgeColor','none','facecolor',greycol_feedb)
area(tempo_EvRelat_BP,feedb_area*(ylimi1(1)*0.99),'EdgeColor','none','facecolor',greycol_feedb)

patt_area=true(size(tempo_EvRelat_BP));
patt_area(tempo_EvRelat_BP<-1.05)=false;
patt_area(tempo_EvRelat_BP>1)=false;

area(tempo_EvRelat_BP,patt_area*ylimi1(2),'EdgeColor','none','facecolor',greycol_patt)
area(tempo_EvRelat_BP,patt_area*(ylimi1(1)*0.99),'EdgeColor','none','facecolor',greycol_patt)

[box,low_whisk,high_whisk]=data4boxplot(-median(RTMat,'omitmissing'));

Y=[zeros(size(box))+boxPlotYwidth(1); zeros(size(box))+boxPlotYwidth(2)];
%plot distribution of onset times
plot([box; box],Y,'linewidth',lw,'color','k')
plot([box(2) box(2)],Y(:,1),'linewidth',lw,'color','r')
plot([box(1) box(3)],[min(min(Y)) min(min(Y))],'linewidth',lw,'color','k')
plot([box(1) box(3)],[max(max(Y)) max(max(Y))],'linewidth',lw,'color','k')
plot([low_whisk box(1)],[mean(mean(Y)) mean(mean(Y))],'linewidth',lw,'color','k')
plot([box(3) high_whisk],[mean(mean(Y)) mean(mean(Y))],'linewidth',lw,'color','k')

annotation(fig,'textbox', [0.04 0.81 0.15 0.15],'String',{'pattern' 'onset'},...
    'HorizontalAlignment','center','FontSize',fsize-4,'FitBoxToText','off','EdgeColor','none',...
    'fontname',fname);

grey_cols=[0.7 0.7 0.7;
    0.6 0.6 0.6;
    0.5 0.5 0.5];

%plot individual participants
for i=1:size(pupilEpochs_BP,2)
    yy=pupilEpochs_BP(:,i);
    yy=MovMean_DRL(yy,35);
    %plot(tempo, yy,'color',[0.35 0.35 0.35])
    
    R=randi([1 3],1,1);
    c=grey_cols(R,:);

    plot(tempo_EvRelat_BP, yy,'color',c)

end
lw=4;


m=mean(pupilEpochs_BP,2,'omitnan');
%cosmetics
win=25;
m=movmean(m,win);

plot(tempo_EvRelat_BP,m,'linewidth',lw+2,'color',[0.99 0.89 0])

plot(xlimi,[0 0], 'k')


xlabel('Time to button press (s)')
ylabel(yLAB)


annotation(fig,'textbox', [0.15 0.84 0.15 0.15],'String','pattern',...
    'HorizontalAlignment','center','FontSize',fsize,'FitBoxToText','off','EdgeColor','none',...
    'fontname',fname);
annotation(fig,'textbox', [0.32 0.84 0.15 0.15],'String','feedback',...
    'HorizontalAlignment','center','FontSize',fsize,'FitBoxToText','off','EdgeColor','none',...
    'fontname',fname);

xlim(xlimi)
ylim(ylimi1)


%%%%%%%%%%%%%%%%%%%  B

ax2=axes('parent',fig,'TickDir','out',...
    'position',positions(2,:),...
    'FontName',fname,'FontSize',fsize);
hold(ax2,'on')

imagesc(tempo_EvRelat_BP,1:size(pupilEpochs_BP,2),pupilEpochs_BP')

plot([1 1],[1 size(pupilEpochs_BP,2)],'linewidth',3,'color','w')

xlabel('Time to button press (s)')
ylabel('Participant')
cb=colorbar;
colormap('jet')
ylabel(cb,'Pupil size (z-score)')

xlim(xlimi)
ylim([1 size(pupilEpochs_BP,2)])


annotation(fig,'textbox', [0.58 0.84 0.15 0.15],'String','pattern',...
    'HorizontalAlignment','center','FontSize',fsize,'FitBoxToText','off','EdgeColor','none',...
    'fontname',fname);
annotation(fig,'textbox', [0.73 0.84 0.15 0.15],'String','feedback',...
    'HorizontalAlignment','center','FontSize',fsize,'FitBoxToText','off','EdgeColor','none',...
    'fontname',fname);



xlimi_CD=[-0.7 1.7];


%%%%%%%%%%%%%  C

ax3=axes('Parent',fig,'TickDir','out', 'position', positions(3,:),...
    'XTick',[0 1],'XTickLabel',{'pattern' 'feedback'},...
    'FontSize',fsize,'FontName',fname);
hold(ax3,'on')
X=randn(size(MAX_pattern))./15;
X2=randn(size(MAX_feedback))./15;

%plot(xlimi_CD,[0 0], ':k')

% plot the pattern period data

plot(X,MAX_pattern,'linestyle','none','marker','.','markersize',ms,'Color',[0.75 0.75 0.75])

[box,low_whisk,high_whisk]=data4boxplot(MAX_pattern);

xRange=[-0.2 0.2];
% 
plot(xRange,[box(1) box(1)],'linewidth',2,'color','k')
plot(xRange,[box(2) box(2)],'linewidth',2,'color','r')
plot(xRange,[box(3) box(3)],'linewidth',2,'color','k')
 
plot([xRange(1) xRange(1)]*0.95,[box(1) box(3)],'linewidth',2,'color','k')
plot([xRange(2) xRange(2)]*0.95,[box(1) box(3)],'linewidth',2,'color','k')
 
plot([mean(xRange) mean(xRange)],[box(1) low_whisk],'linewidth',2,'linestyle','-','color','k')
plot([mean(xRange) mean(xRange)],[box(3) high_whisk],'linewidth',2,'linestyle','-','color','k')

% now the feedback period data

plot((X2+1),MAX_feedback,'linestyle','none','marker','.','markersize',ms,'Color',[0.75 0.75 0.75])

[box,low_whisk,high_whisk]=data4boxplot(MAX_feedback);
xRange=[-0.2 0.2]+1;
% 
plot(xRange,[box(1) box(1)],'linewidth',2,'color','k')
plot(xRange,[box(2) box(2)],'linewidth',2,'color','r')
plot(xRange,[box(3) box(3)],'linewidth',2,'color','k')
 
plot([xRange(1) xRange(1)]*1.015,[box(1) box(3)],'linewidth',2,'color','k')
plot([xRange(2) xRange(2)]*0.9895,[box(1) box(3)],'linewidth',2,'color','k')
 
plot([mean(xRange) mean(xRange)],[box(1) low_whisk],'linewidth',2,'linestyle','-','color','k')
plot([mean(xRange) mean(xRange)],[box(3) high_whisk],'linewidth',2,'linestyle','-','color','k')

ylabel({'Mean pupil maxima' '(z-score)'})

xlim(xlimi_CD)

temp=vertcat(MAX_feedback',MAX_pattern');
ylim([-0.1 1.1*max(temp)])

%%%%%%%% D


ax=axes('Parent',fig,'TickDir','out', 'position', positions(4,:),...
    'XTick',[0 1],'XTickLabel',{'pattern' 'feedback'},...
    'YTick',[0 50 100],...
    'FontSize',fsize,'FontName',fname);
hold(ax,'on')
X=randn(size(TAB_pattern))./15;
X2=randn(size(TAB_feedback))./15;

plot(xlimi_CD,[50 50], ':k')

plot(X,TAB_pattern.*100,'linestyle','none','marker','.','markersize',ms,'Color',[0.75 0.75 0.75])

[box,low_whisk,high_whisk]=data4boxplot(TAB_pattern.*100);
xRange=[-0.2 0.2];
% 
plot(xRange,[box(1) box(1)],'linewidth',2,'color','k')
plot(xRange,[box(2) box(2)],'linewidth',2,'color','r')
plot(xRange,[box(3) box(3)],'linewidth',2,'color','k')
 
plot([xRange(1) xRange(1)]*0.95,[box(1) box(3)],'linewidth',2,'color','k')
plot([xRange(2) xRange(2)]*0.95,[box(1) box(3)],'linewidth',2,'color','k')
 
plot([mean(xRange) mean(xRange)],[box(1) low_whisk],'linewidth',2,'linestyle','-','color','k')
plot([mean(xRange) mean(xRange)],[box(3) high_whisk],'linewidth',2,'linestyle','-','color','k')


plot((X2+1),TAB_feedback.*100,'linestyle','none','marker','.','markersize',ms,'Color',[0.75 0.75 0.75])

[box,low_whisk,high_whisk]=data4boxplot(TAB_feedback.*100);
xRange=[-0.2 0.2]+1;
% 
plot(xRange,[box(1) box(1)],'linewidth',2,'color','k')
plot(xRange,[box(2) box(2)],'linewidth',2,'color','r')
plot(xRange,[box(3) box(3)],'linewidth',2,'color','k')
 
plot([xRange(1) xRange(1)]*1.015,[box(1) box(3)],'linewidth',2,'color','k')
plot([xRange(2) xRange(2)]*0.9895,[box(1) box(3)],'linewidth',2,'color','k')
 
plot([mean(xRange) mean(xRange)],[box(1) low_whisk],'linewidth',2,'linestyle','-','color','k')
plot([mean(xRange) mean(xRange)],[box(3) high_whisk],'linewidth',2,'linestyle','-','color','k')

ylabel({'Mean time pupil spent' 'above baseline (%)'})

xlim(xlimi_CD)

ylim([0 101])

xLeft=0.01;
xRight=0.49;
yPosBottAB=0.94;
yposBottCD=0.39;
lettW=0.03;
lettH=0.06;

annotation(fig,'textbox', [xLeft yPosBottAB lettW lettH],'String','A','fontweight','bold',...
    'HorizontalAlignment','center','FontSize',fsizeBig,'FitBoxToText','off','EdgeColor','none',...
    'fontname',fname);
annotation(fig,'textbox', [xRight yPosBottAB lettW lettH],'String','B','fontweight','bold',...
    'HorizontalAlignment','center','FontSize',fsizeBig,'FitBoxToText','off','EdgeColor','none',...
    'fontname',fname);
annotation(fig,'textbox', [xLeft+0.05 yposBottCD lettW lettH],'String','C','fontweight','bold',...
    'HorizontalAlignment','center','FontSize',fsizeBig,'FitBoxToText','off','EdgeColor','none',...
    'fontname',fname);
annotation(fig,'textbox', [xRight+0.01 yposBottCD lettW lettH],'String','D','fontweight','bold',...
    'HorizontalAlignment','center','FontSize',fsizeBig,'FitBoxToText','off','EdgeColor','none',...
    'fontname',fname);

set(fig,'PaperUnits','inches')
set(fig, 'PaperPosition', [0 0 10.5 7.5])
print(fig,'FIG_04','-dpng','-r450')