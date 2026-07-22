%% CALCULATE BEHAVIORAL RESULTS

if ~exist('behaviorAnalysisDone', 'var') || ~behaviorAnalysisDone
    analyze_behav_WeatherPred2018
else
    disp('analysis of behavioral files already DONE.')
    disp('all relevant variables are in the worskpace.')
end


%% PLOT FIGURE 
%%%%%%%%%%%%%%%%%%% plot settings

rt_MEDIAN=true;

clc
fsize=9;
fsizeBig=fsize+9;

col_gray = [0.7 0.7 0.7];
col_correct=[0 0 0.7];
col_incorrect=[0.8 0.2 0.2];

lw_boxpl=2;
lw_plot=0.5;
ms=14;

bott1=0.08;
left1=0.07;
left2=0.5;
left3=0.87;
w1=0.33;
w2=0.12;
bott2=0.59;
h=0.35;


if exist('NullPerf','var')
else %build null model for performance
    P=mean(randi([0 1],300,1e4),1);
    NullPerf=prctile(P,[5 50 95]);
end

positions=[left1 bott2 w1 h;... % A
    left2 bott2 w1 h;...  % B
    left3 bott2 w2 h;...  % C
    
    left1 bott1 w1 h;...  % D
    left2 bott1 w1 h;...  % E
    left3 bott1 w2 h]; % F

ylimi_rt=[0.43 1.65];
ylimi_perf=[0.29 1.03];

xlimi_blocks=[0.5 6.5];
xlimi_trials=[0.5 301];
xlimi_FirstLast=[-0.5 1.5];

fig1=figure('color','w','position',[200 200 1200 800]);
fname='verdana';

ax1=axes('parent',fig1,'tickdir','out','xgrid','on','xtick',0:50:300,...
    'ytick',10:10:60,'position',positions(1,:),'fontsize',fsize,'fontname',fname);
hold(ax1,'on')

maxRT=1.99;

%transform nans into zeros, to plot
%mat2plot=RTMat_sort;
mat2plot=RTMat_sort_resort;
for r=1:size(mat2plot,1)
    for c=1:size(mat2plot,2)
        if isnan(mat2plot(r,c))
            mat2plot(r,c)=0;
        end
    end
end

% Create the plot
imagesc(mat2plot');
colorbar; % Optional, adds a colorbar for reference
axis xy
% Get the parula colormap
cmap = parula(256); % Generate 256 colors

% Find the index for the color corresponding to zero
% Assuming the data is normalized between the min and max values
cmin = min(RTMat_sort(:));
cmax = max(RTMat_sort(:));
zeroIndex = round((0 - cmin) / (cmax - cmin) * (size(cmap, 1) - 1)) + 1;

% Set the color for zero to white
cmap(zeroIndex, :) = [1, 1, 1]; % White color

% Apply the modified colormap
colormap(cmap);
clim([0.1 2])
cb=colorbar('ytick',[0.1 2],'fontsize',fsize-2,'fontname',fname);
set(cb,'Position',[0.35 0.9 0.01 0.06])

text(216,n_participants-1,'RT (s)','fontsize',fsize-1,'fontname',fname)


% ylabel(cb,'RT (s)','fontsize',fsize-1)

xlabel('Trial')
ylabel('Participant')

ylim([0.5 n_participants+0.5])
xlim(xlimi_trials)

%%%%%%% figure B

ax2=axes('parent',fig1,'tickdir','out','position',positions(2,:),'xtick',1:6,...
    'fontsize',fsize,'fontname',fname);
hold(ax2,'on')

if rt_MEDIAN
    mat2plot=BlocksMedian_rt;
else
    mat2plot=BlocksMean_rt;
end


mat2plot(5,9)=nan;

X=1:6;

for ii = 1:size(mat2plot,2)
    r=randn(1,1)./20;
    plot(X+r,mat2plot(:,ii),'linewidth',lw_plot,'marker','.','markersize',ms,...
        'color',col_gray)

end

plot(X, median(mat2plot,2, 'omitnan'),'linewidth',lw_boxpl,'marker','o','markersize',ms-4,...
    'markerfacecolor','w','color',[0.05 0.05 0.05])

xlim(xlimi_blocks)
ylim(ylimi_rt)
% title('Weather Prediction Task - UDP')
ylabel({'Response time (s)'})
xlabel('50-trial Blocks')

%%%%%%% figure C

if rt_MEDIAN
    data1=RT_first_median;
    data2=RT_last_median;
else
    data1=RT_first_mean;
    data2=RT_last_mean;
end
box1 = prctile(data1,[25, 50, 75]);
iqr1=box1(3)-box1(1);  %inter-quartile range
bounds1=[box1(1)-1.5*iqr1 box1(3)+1.5*iqr1];
logi1=data1>bounds1(1) & data1<bounds1(2);
low_whisk1=min(data1(logi1));
up_whisk1=max(data1(logi1));

box2 = prctile(data2,[25, 50, 75]);
iqr2=box2(3)-box2(1);  %inter-quartile range
bounds2=[box2(1)-1.5*iqr2 box2(3)+1.5*iqr2];
logi2=data2>bounds2(1) & data2<bounds2(2);
low_whisk2=min(data2(logi2));
up_whisk2=max(data2(logi2));

Mat2plot=horzcat(data1,data2);

xLocations=[0 1];

ax3=axes('parent',fig1,'tickdir','out','xtick',xLocations,'xticklabel',{'First', 'Last'},...
    'position',positions(3,:),'fontsize',fsize,'fontname',fname);
hold(ax3,'on')

% boxplot RT of first session

Xbox=[xLocations(1)-0.35 xLocations(1)-0.1];
plot(Xbox,[box1(1) box1(1)],'linewidth',lw_boxpl, 'color', 'k')
plot(Xbox,[box1(2) box1(2)],'linewidth',lw_boxpl, 'color', 'r')
plot(Xbox,[box1(3) box1(3)],'linewidth',lw_boxpl, 'color', 'k')
plot([Xbox(1) Xbox(1)],[box1(1)-0.005 box1(3)+0.005],'linewidth',lw_boxpl, 'color', 'k')
plot([Xbox(2) Xbox(2)],[box1(1)-0.005 box1(3)+0.005],'linewidth',lw_boxpl, 'color', 'k')
plot([mean(Xbox) mean(Xbox)],[box1(3) up_whisk1],'linewidth',lw_boxpl,'linestyle','-', 'color', 'k')
plot([mean(Xbox) mean(Xbox)],[low_whisk1 box1(1)],'linewidth',lw_boxpl,'linestyle','-', 'color', 'k')
for jj = 1 : size(Mat2plot,1)

    plot([xLocations(1) xLocations(2)], [Mat2plot(jj,1) Mat2plot(jj,2)], 'marker', '.', 'MarkerSize',12,...
        'linewidth',lw_plot, 'color', col_gray)

end

% boxplot RT last session
Xbox=[xLocations(2)+0.1 xLocations(2)+0.35];
plot(Xbox,[box2(1) box2(1)],'linewidth',lw_boxpl, 'color', 'k')
plot(Xbox,[box2(2) box2(2)],'linewidth',lw_boxpl, 'color', 'r')
plot(Xbox,[box2(3) box2(3)],'linewidth',lw_boxpl, 'color', 'k')

plot([Xbox(1) Xbox(1)]*1.02,[box2(1) box2(3)],'linewidth',lw_boxpl, 'color', 'k')
plot([Xbox(2) Xbox(2)]*0.983,[box2(1) box2(3)],'linewidth',lw_boxpl, 'color', 'k')

plot([mean(Xbox) mean(Xbox)],[box2(3) up_whisk2],'linewidth',lw_boxpl,'linestyle','-', 'color', 'k')
plot([mean(Xbox) mean(Xbox)],[low_whisk2 box2(1)],'linewidth',lw_boxpl,'linestyle','-', 'color', 'k')

pval=PermutePairedTest(Mat2plot(:,2),Mat2plot(:,1),1000,'tstat','both');
%Hg.hedgesg=(mean(Mat2plot(:,2))-mean(Mat2plot(:,1)))./PooledStd(Mat2plot(:,1),Mat2plot(:,2));
Hg=mes(Mat2plot(:,2),Mat2plot(:,1),'hedgesg','nBoot',1000);


pval=round(pval*100)/100;
if pval<0.001
    pvaltext='p < 0.001';
else
    pvaltext=['p = ' num2str(pval)];
end


ylim(ylimi_rt)
xlim(xlimi_FirstLast)

temp=round(Hg.hedgesg*100)/100;

Hgtext=['g = ' num2str(temp)];

annotation(fig1,'textbox', [0.88 0.93 0.1 0.05],'String',pvaltext,...
    'HorizontalAlignment','left','FontSize',fsize-1,'FitBoxToText','off','EdgeColor','none',...
    'fontname',fname);
annotation(fig1,'textbox', [0.88 0.91 0.1 0.05],'String',Hgtext,...
    'HorizontalAlignment','left','FontSize',fsize-1,'FitBoxToText','off','EdgeColor','none',...
    'fontname',fname);
xlabel ('Block')


%%%%%%%%%%%%%%%%%%%%%%% figures D-E-F

%%%%%%% figure D

ax4=axes('parent',fig1,'tickdir','out','xgrid','on','xtick',0:50:300,...
    'ytick',10:10:60,'position',positions(4,:),'fontsize',fsize,'fontname',fname);
hold(ax4,'on')


imagesc(PerfMat_sort_resort')

% Define the custom colormap
% The order corresponds to the values: -1 -> white, 0 -> red, 1 -> blue
cmap = vertcat([1, 1, 1], col_incorrect, col_correct);  
% Set the colormap
colormap(ax4,cmap);

% Set the color limits
caxis([-1 1]); % Ensure the color axis matches your data range

xlabel('Trial')
ylabel('Participant')

ylim([0.5 size(BlocksMean_perf,2)+0.2])
xlim(xlimi_trials)

text(230,n_participants-1,'Correct','color',col_correct,'fontsize',fsize,'fontname',fname, 'fontweight', 'bold')
text(230,n_participants-5,'Incorrect','color',col_incorrect,'fontsize',fsize,'fontname',fname, 'fontweight', 'bold')



%%%%%%% figure E

ax5=axes('parent',fig1,'tickdir','out','position',positions(5,:),'xtick',1:6,...
    'fontsize',fsize,'fontname',fname);
hold(ax5,'on')

%plot 94% criterion (Kumaran et al 2007)
plot(xlimi_blocks,[0.94 0.94],'color','k')

mat2plot=BlocksMean_perf;
mat2plot(5,11)=nan;

L=(Perf_last)'>=0.08;


for ii = 1:size(mat2plot,2)
    r=randn(1,1)./20;
    plot(X+r,mat2plot(:,ii),'linewidth',lw_plot,'marker','.','markersize',ms,...
        'color',col_gray)

end


plot(X,median(mat2plot,2, 'omitnan'),'linewidth',lw_boxpl,'marker','o','markersize',ms-4,...
    'markerfacecolor','w','color',[0.05 0.05 0.05])

plot(xlimi_blocks,[NullPerf(1) NullPerf(1)], '--k')
plot(xlimi_blocks,[NullPerf(2) NullPerf(2)], 'k')
plot(xlimi_blocks,[NullPerf(3) NullPerf(3)], '--k')

text(0.62,0.965,'Criterion','fontweight','bold','fontsize', fsize-1, 'fontname', fname)
text(3.8, 0.52, 'Chance','fontweight','bold','fontsize', fsize-1, 'fontname', fname)

xlim(xlimi_blocks)
ylim(ylimi_perf)
% title('Weather Prediction Task - UDP')
ylabel({'Performance' '(fraction correct)'})
xlabel('50-trial Blocks')

%%%%%%% figure F
data1=Perf_first;
data2=Perf_last;

box1 = prctile(data1,[25, 50, 75]);
iqr1=box1(3)-box1(1);  %inter-quartile range
bounds1=[box1(1)-1.5*iqr1 box1(3)+1.5*iqr1];
logi1=data1>bounds1(1) & data1<bounds1(2);
low_whisk1=min(data1(logi1));
up_whisk1=max(data1(logi1));

box2 = prctile(data2,[25, 50, 75]);
iqr2=box2(3)-box2(1);  %inter-quartile range
bounds2=[box2(1)-1.5*iqr2 box2(3)+1.5*iqr2];
logi2=data2>bounds2(1) & data2<bounds2(2);
low_whisk2=min(data2(logi2));
up_whisk2=max(data2(logi2));

Mat2plot=horzcat(data1,data2);
lw=1.5;
xLocations=[0 1];


%%%%%% F

ax6=axes('parent',fig1,'tickdir','out','xtick',xLocations,'xticklabel',{'First', 'Last'},...
    'position',positions(6,:),'fontsize',fsize,'fontname',fname);
hold(ax6,'on')

%plot criterion line
plot(xlimi_FirstLast,[0.94 0.94],'color','k')

% boxplot Perf of first session
X2=randn(size(Mat2plot,1),1).*0.25;

Xbox=[xLocations(1)-0.35 xLocations(1)-0.1];
plot(Xbox,[box1(1) box1(1)],'linewidth',lw_boxpl, 'color', 'k')
plot(Xbox,[box1(2) box1(2)],'linewidth',lw_boxpl, 'color', 'r')
plot(Xbox,[box1(3) box1(3)],'linewidth',lw_boxpl, 'color', 'k')
plot([Xbox(1) Xbox(1)],[box1(1)-0.005 box1(3)+0.005],'linewidth',lw_boxpl, 'color', 'k')
plot([Xbox(2) Xbox(2)],[box1(1)-0.005 box1(3)+0.005],'linewidth',lw_boxpl, 'color', 'k')
plot([mean(Xbox) mean(Xbox)],[box1(3) up_whisk1],'linewidth',lw_boxpl,'linestyle','-', 'color', 'k')
plot([mean(Xbox) mean(Xbox)],[low_whisk1 box1(1)],'linewidth',lw_boxpl,'linestyle','-', 'color', 'k')

for jj = 1 : size(Mat2plot,1)

    plot([xLocations(1) xLocations(2)], Mat2plot, 'marker', '.', 'MarkerSize',12,...
        'linewidth',lw_plot, 'color', col_gray)
end

% plot boxplot Perf last session
Xbox=[xLocations(2)+0.1 xLocations(2)+0.35];
plot(Xbox,[box2(1) box2(1)],'linewidth',lw_boxpl, 'color', 'k')
plot(Xbox,[box2(2) box2(2)],'linewidth',lw_boxpl, 'color', 'r')
plot(Xbox,[box2(3) box2(3)],'linewidth',lw_boxpl, 'color', 'k')

plot([Xbox(1) Xbox(1)]*1.02,[box2(1) box2(3)],'linewidth',lw_boxpl, 'color', 'k')
plot([Xbox(2) Xbox(2)]*0.983,[box2(1) box2(3)],'linewidth',lw_boxpl, 'color', 'k')

plot([mean(Xbox) mean(Xbox)],[box2(3) up_whisk2],'linewidth',lw_boxpl,'linestyle','-', 'color', 'k')
plot([mean(Xbox) mean(Xbox)],[low_whisk2 box2(1)],'linewidth',lw_boxpl,'linestyle','-', 'color', 'k')

pval=PermutePairedTest(Perf_last,Perf_first,1000,'tstat','both');
pval=round(pval*100)/100;
if pval<0.001
    pvaltext='p < 0.001';
else
    pvaltext=num2str(pval);
end

plot(xlimi_FirstLast,[NullPerf(1) NullPerf(1)], '--k')
plot(xlimi_FirstLast,[NullPerf(2) NullPerf(2)], 'k')
plot(xlimi_FirstLast,[NullPerf(3) NullPerf(3)], '--k')

% Hg=mes(Perf_final, Perf_first,'hedgesg','isDep',1);
Hg.hedgesg=(mean(Perf_last)-mean(Perf_first))./PooledStd(Perf_first,Perf_last);

temp=round(Hg.hedgesg*100)/100;

Hgtext=['g = ' num2str(temp)];

annotation(fig1,'textbox', [0.88 0.44 0.1 0.05],'String',pvaltext,...
    'HorizontalAlignment','left','FontSize',fsize-1,'FitBoxToText','off','EdgeColor','none',...
    'fontname',fname);
annotation(fig1,'textbox', [0.88 0.42 0.1 0.05],'String',Hgtext,...
    'HorizontalAlignment','left','FontSize',fsize-1,'FitBoxToText','off','EdgeColor','none',...
    'fontname',fname);

xlim(xlimi_FirstLast)
ylim(ylimi_perf)
% ylabel('Performance (fraction correct)')
xlabel('Block')

% plot letters
lettW=0.03;
lettH=0.06;
yPosTop=0.941;
yPosBott=0.47;
xLeft=0.01;
xMiddle=0.42;
xRight=0.83;

annotation(fig1,'textbox', [xLeft yPosTop lettW lettH],'String','A','fontweight','bold',...
    'HorizontalAlignment','center','FontSize',fsizeBig,'FitBoxToText','off','EdgeColor','none',...
    'fontname',fname);
annotation(fig1,'textbox', [xMiddle yPosTop lettW lettH],'String','B','fontweight','bold',...
    'HorizontalAlignment','center','FontSize',fsizeBig,'FitBoxToText','off','EdgeColor','none',...
    'fontname',fname);
 annotation(fig1,'textbox', [xRight yPosTop lettW lettH],'String','C','fontweight','bold',...
     'HorizontalAlignment','center','FontSize',fsizeBig,'FitBoxToText','off','EdgeColor','none',...
     'fontname',fname);
 annotation(fig1,'textbox', [xLeft yPosBott lettW lettH],'String','D','fontweight','bold',...
     'HorizontalAlignment','center','FontSize',fsizeBig,'FitBoxToText','off','EdgeColor','none',...
     'fontname',fname);
annotation(fig1,'textbox', [xMiddle yPosBott lettW lettH],'String','E','fontweight','bold',...
    'HorizontalAlignment','center','FontSize',fsizeBig,'FitBoxToText','off','EdgeColor','none',...
    'fontname',fname);
annotation(fig1,'textbox', [xRight yPosBott lettW lettH],'String','F','fontweight','bold',...
    'HorizontalAlignment','center','FontSize',fsizeBig,'FitBoxToText','off','EdgeColor','none',...
    'fontname',fname);

set(fig1,'PaperUnits','inches')
set(fig1, 'PaperPosition', [0 0 8.5 5.5])
print(fig1,'FIG_02','-dpng','-r450')