%% CALCULATE BEHAVIORAL RESULTS

if ~exist('behaviorAnalysisDone', 'var') || ~behaviorAnalysisDone
    analyze_behav_WeatherPred2018
    
    %import drawings/diagrams
    img_AB=imread('FIG_01_AB.png');
    img_C=imread('FIG_01_C.png');

else
    disp('analysis of behavioral files already DONE.')
    disp('all relevant variables are in the worskpace.')
end


%% PLOT FIGURE

w1=1.45;
h1=0.53;
left=-0.2;
w2=0.4;


posits=[left 0.46 w1 h1;
    left-left+0.01 -0.24 1.2*w2 1.8*h1;
    left+1.9*w2 0.07 0.43*w2 0.63*h1;
    left+2.5*w2 0.07 0.43*w2 0.63*h1];

fsize=8;
fsizeBig=fsize+9;
fname='Verdana';

fig=figure;
%diagram in A and B
ax1=axes('Parent',fig,'Position',posits(1,:),'Visible','off');
hold(ax1,'on')

imshow(img_AB)

% diagram in C
ax2=axes('Parent',fig,'Position',posits(2,:),'Visible','off');
hold(ax2,'on')

imshow(img_C)

% plot in D
ax3=axes('Parent',fig,'Position',posits(3,:),...
    'tickdir','out',...
    'FontSize',fsize,'FontName',fname);
hold(ax3,'on')

H=histogram(Sess_durat_min,10);
H.FaceColor=[0.9 0.4 0.1];

text(31,14,['n = ' num2str(numel(Sess_durat_min)) ' participants'],...
    'fontname',fname,'FontSize',fsize-2)

xlabel('Session duration (min)')
ylabel('Number of participants')

%plot in E
ax4=axes('Parent',fig,'Position',posits(4,:),...
    'XTick',1:6,'tickdir','out',...
    'FontSize',fsize,'FontName',fname);
hold(ax4,'on')

bar(Block_N_particip(:,1),Block_N_particip(:,2))

xlabel('50-trial blocks')
ylabel('Number of participants')

xlim([0.7 6.4])


xLeft=0.02;
xRight=0.49;
yPosBottAB=0.94;
yposBottCD=0.46;
lettW=0.03;
lettH=0.06;

annotation(fig,'textbox', [xLeft yPosBottAB lettW lettH],'String','A','fontweight','bold',...
    'HorizontalAlignment','center','FontSize',fsizeBig,'FitBoxToText','off','EdgeColor','none',...
    'fontname',fname);
annotation(fig,'textbox', [xRight yPosBottAB lettW lettH],'String','B','fontweight','bold',...
    'HorizontalAlignment','center','FontSize',fsizeBig,'FitBoxToText','off','EdgeColor','none',...
    'fontname',fname);
annotation(fig,'textbox', [xLeft yposBottCD lettW lettH],'String','C','fontweight','bold',...
    'HorizontalAlignment','center','FontSize',fsizeBig,'FitBoxToText','off','EdgeColor','none',...
    'fontname',fname);
annotation(fig,'textbox', [xRight yposBottCD lettW lettH],'String','D','fontweight','bold',...
    'HorizontalAlignment','center','FontSize',fsizeBig,'FitBoxToText','off','EdgeColor','none',...
    'fontname',fname);

annotation(fig,'textbox', [xRight+0.23 yposBottCD lettW lettH],'String','E','fontweight','bold',...
    'HorizontalAlignment','center','FontSize',fsizeBig,'FitBoxToText','off','EdgeColor','none',...
    'fontname',fname);

set(fig,'PaperUnits','inches')
set(fig, 'PaperPosition', [0 0 8 5])
print(fig,'FIG_01','-dpng','-r400')