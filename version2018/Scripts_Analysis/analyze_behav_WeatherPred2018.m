%% files' location

msg = sprintf(['SELECT THE FOLDER CONTAINING THE BEHAVIORAL-DATA FILES.\n',...
               'If you do not have the data, download it from Figshare: \n',...
               'https://doi.org/10.6084/m9.figshare.32209329'])

% Ask user to select the 'data' folder containing the .mat files
behavDatapath = uigetdir(pwd, 'Select the folder containing the behavioral (.mat) files');

% Check if the user pressed 'Cancel'
if isequal(behavDatapath, 0)
    error('User cancelled folder selection. Analysis cannot proceed.');
end


%% list data files
dir_mat = dir([behavDatapath filesep '*.mat']);
%sort by date
[~,idx] = sort([dir_mat.datenum]);
dir_mat = dir_mat(idx);

% get participant's ID from mat files
particip_IDs=cell(numel(dir_mat),1);
for j=1:numel(dir_mat)
    particip_IDs{j}=dir_mat(j).name(6:7);
end

home
if numel(dir_mat)==0
    error('BEHAVIORAL DATA FILES ARE MISSING')
    disp('check if path to data is correct')
    disp(['curr Path used: ' behavDatapath])
    
else
    disp([num2str(numel(dir_mat)) ' behavioral data files found'])
end
%% compute variables

n_trialsTOT=300;
n_trialsPerBlock=50;
stim=1:8;

%preallocate matrices
PerfMat=nan(n_trialsTOT,numel(dir_mat));
RTMat=nan(n_trialsTOT,numel(dir_mat));
StimMat=nan(n_trialsTOT,numel(dir_mat));
StimSpatialMat=nan(n_trialsTOT,numel(dir_mat));
Female=false(numel(dir_mat),1);
Age=nan(numel(dir_mat),1);
StimWeatherMap=false(numel(dir_mat),1);
Sess_durat_min=nan(numel(dir_mat),1);
particip_IDs_behavFiles=cell(1,1);
YYYY=nan(numel(dir_mat),1);
for j=1:numel(dir_mat) %loop through files (i.e., participants)
    fileName=[dir_mat(j).folder filesep dir_mat(j).name];
    %load mat file containing behavioral data
    load(fileName)
    
    %check what's inside
    varsInFile = who('-file', fileName);
    %if not a BehavData file, scream
    if ~any(strcmp(varsInFile, 'BehavData'))
        error(['FATAL ERROR: The file "%s" is not a valid behavioral data file. ' ...
               'Valid files contain a "BehavData" structure array. Please check your folder selection.'], ...
               dir_mat(j).name);
    end
    
    y=regexp(BehavData.info.datetime,'_','split');
    y=y{1};
    YYYY(j)=str2double(y);

    temp=BehavData.info.Subject_ID;
    temp=strrep(temp,'-','_');
    particip_IDs_behavFiles{j,1}=temp;
    
    temp=regexp(BehavData.info.timestart,'-','split');
    if numel(temp)>1
        hour_start=str2double(temp{1});
        min_start=str2double(temp{2});
    
        temp=regexp(BehavData.info.timefinish,'-','split');

        hour_finish=str2double(temp{1});
        min_finish=str2double(temp{2});

        if hour_start==hour_finish
            Sess_durat_min(j)=min_finish-min_start;
        elseif hour_finish-hour_start==1
            Sess_durat_min(j)=min_finish+(60-min_start);

        end
    end


    %collect data
    PerfMat(1:numel(BehavData.vars.Perform_seq),j)=BehavData.vars.Perform_seq; %performance
    RTMat(1:numel(BehavData.vars.RT_seq),j)=BehavData.vars.RT_seq; % response time
    StimMat(1:numel(BehavData.vars.Stim_seq),j)=BehavData.vars.Stim_seq;  %stimuli


    %get pattern type (spatial / nonspatial) info
    spatial=false(8,1); %preallocate
    Form_pairs=BehavData.info.Form_pairs;
    for jj=1:size(Form_pairs,1)
        if sum(strcmpi('Triangle',Form_pairs(jj,:))) > 0 % if triangle present
            spatial(jj)=true;
        end
    end
    
    % use previous info to write down which stim are spatial
    stim_spatial=stim(spatial);
    
    %save info about stim type (spatial or non-spatial)
    
    temp=StimMat(:,j)==stim_spatial;
    temp=logical(sum(temp,2));
    StimSpatialMat(1:numel(temp),j)=temp;
    
    if isfield(BehavData.info, 'Subject_Gender')
        if strcmp(BehavData.info.Subject_Gender, 'F')
            Female(j)=true;
        end
        Age(j)=str2double(BehavData.info.Subject_Age);
    elseif isfield(BehavData.info, 'Gender')
        if strcmp(BehavData.info.Gender, 'F')
            Female(j)=true;
        end
        Age(j)=str2double(BehavData.info.Age);
    end
    
    if strcmp(BehavData.info.Weather{1},'R')
        StimWeatherMap(j)=true;
    end
    
end

% remove RT if there's no performance (means did not respond)

for r = 1:size(RTMat,1)
    for c = 1:size(RTMat,2)
        if isnan(PerfMat(r,c))
            RTMat(r,c)=nan;
        end
    end
end


%remove participants with very few trials
min_n_trials=n_trialsPerBlock;   %1 block = 50 trials. Each participants must do at least 1 block

temp=sum(~isnan(PerfMat),1);
Final_particip=temp>=min_n_trials;

RTMat=RTMat(:,Final_particip);
PerfMat=PerfMat(:,Final_particip);
StimMat=StimMat(:,Final_particip);
StimSpatialMat=StimSpatialMat(:,Final_particip);

% check for participants with small number of completed trials on first block
% if so, remove first block
for thisP=1:size(PerfMat,2)
    p_temp=PerfMat(:,thisP);
    rt_temp=RTMat(:,thisP);
    nnan=sum(isnan(p_temp(1:50)));
    if nnan>30 %if more than 30 omitted trials on first block
        p_temp=p_temp(51:end);
        p_temp(end+1:300)=nan;
        rt_temp=rt_temp(51:end);
        rt_temp(end+1:300)=nan;

        PerfMat(:,thisP)=p_temp;
        RTMat(:,thisP)=rt_temp;

    end
    
end




n_participants=sum(Final_particip);

Female=Female(Final_particip);

dir_mat_final=dir_mat(Final_particip);

Age=Age(Final_particip);

Sess_durat_min=Sess_durat_min(Final_particip);

particip_IDs=particip_IDs(Final_particip);

meanAge=round(mean(Age)*10)/10;
stdAge=round(std(Age)*10)/10;

disp('Weather Prediction Task - Behavioral files')
disp(['n tot = ' num2str(n_participants) ' participants'])
disp(['n females = ' num2str(sum(Female))])
disp(['Age (yrs): M = ' num2str(meanAge) '; SD = ' num2str(stdAge)])

uniqueYears=unique(YYYY);
for i=1:numel(uniqueYears)
    uniqueYears(i,2)=sum(YYYY==uniqueYears(i,1));
end
disp(' - ')
disp('        Year -------  n Files')
disp(uniqueYears)
% compute everything per Block
BlocksMean_perf=nan(6,n_participants);
BlocksMean_Spatialperf=nan(6,n_participants);
BlocksMean_Nonspatialperf=nan(6,n_participants);

BlocksStd_perf=nan(6,n_participants);
BlocksMean_rt=nan(6,n_participants);
BlocksMedian_rt=nan(6,n_participants);
BlocksStd_rt=nan(6,n_participants);
X=nan(6,n_participants);

Nstep=n_trialsPerBlock;
blockStart=1:Nstep:n_trialsTOT - n_trialsPerBlock+1;  %collection of window start points (samples)
nw=length(blockStart);

for bl=1:nw  %loop through blocks
    indx=blockStart(bl):blockStart(bl) + n_trialsPerBlock-1;
    currBlock=PerfMat(indx,:);
    stimBlock=StimMat(indx,:);
    
    BlocksMean_perf(bl,:)= mean(currBlock,1, 'omitnan');
    
    %check if a given particip has a block with mean zero
    L=mean(currBlock,1,'omitnan')==0;


    if sum(L)>0
        find(L)
    end


    BlocksStd_perf(bl,:)= std(currBlock,[],1, 'omitnan');
    X(bl,:)=bl;
    
    %sort by stim type
    currSpatialStim=logical(StimSpatialMat(indx,:));
    
    for ii=1:size(currBlock,2)
        perfdata=currBlock(:,ii);
        BlocksMean_Spatialperf(bl,ii)=mean(perfdata(currSpatialStim(:,ii)),'omitmissing');
        BlocksMean_Nonspatialperf(bl,ii)=mean(perfdata(~currSpatialStim(:,ii)),'omitmissing');
    end
    
   %RT = 2 s means subject did not answer, so use only trials with less than 2
    RTMat_below2=nan(size(RTMat));
    
    for k=1:size(RTMat,1)
        for h=1:size(RTMat,2)
            if RTMat(k,h)<2
                RTMat_below2(k,h)=RTMat(k,h);
            else
                RTMat_below2(k,h)=nan;
            end
        end
    end
                
    
    
    currBlock=RTMat_below2(indx,:);
    
    BlocksMean_rt(bl,:) = mean(currBlock,1, 'omitnan');
    BlocksMedian_rt(bl,:) = median(currBlock,1, 'omitnan');
    BlocksStd_rt(bl,:)=std(currBlock,[],1,'omitnan');
    
    
end

%remove blocks for people that passed criterion but kept going

L=BlocksMean_perf>=0.94;

for j=1:size(BlocksMean_perf,2)
   
    if sum(L(:,j))==1
        %it's ok. only one session above criterion (that should be the
        %last)
    else
        %find the first session above criterion and kept only that
        idx=find(L(:,j),1);
        
        BlocksMean_perf(idx+1:end,j)=nan;
        BlocksMean_rt(idx+1:end,j)=nan;
        BlocksMedian_rt(idx+1:end,j)=nan;
        
        
        
    end
    
end


Perf_last=nan(n_participants,1);
Perf_first=nan(n_participants,1);
RT_last_mean=nan(n_participants,1);
RT_first_mean=nan(n_participants,1);
RT_last_median=nan(n_participants,1);
RT_first_median=nan(n_participants,1);
for thisParticipant=1:n_participants
    
    p=BlocksMean_perf(:,thisParticipant);
    p=p(~isnan(p));
    Perf_last(thisParticipant)=p(end);
    Perf_first(thisParticipant)=p(1);
    
    r=BlocksMean_rt(:,thisParticipant);
    r=r(~isnan(r));
    RT_last_mean(thisParticipant)=r(end);
    RT_first_mean(thisParticipant)=r(1);
    
    r=BlocksMedian_rt(:,thisParticipant);
    r=r(~isnan(r));
    RT_last_median(thisParticipant)=r(end);
    RT_first_median(thisParticipant)=r(1);
    
end


n_blocks2finish=sum(isnan(BlocksMean_perf));


% temp=sum(isnan(PerfMat));

nTrials_byParticip=nan(1, n_participants);
for j=1:n_participants
    v=PerfMat(:,j);
    nTrials_byParticip(j)=find(~isnan(v),1, 'last');
end

%small correction
f=nTrials_byParticip==299;
nTrials_byParticip(f)=300;

[nTrials_byParticip_sort, sortIndex1] = sort(nTrials_byParticip, 'descend');
PerfMat_sort = PerfMat(:, sortIndex1);
RTMat_sort=RTMat(:, sortIndex1); 


Perf_last_sortedbynTrials=Perf_last(sortIndex1);

% now sort again, based on last-block performance

% Find the unique trial counts and the starting index for each group
[uniqueTrials, firstIndices] = unique(nTrials_byParticip_sort, 'stable');

% Determine the end index of each group (using the corrected vertical concatenation)
lastIndices = [firstIndices(2:end) - 1; length(nTrials_byParticip_sort)]'; % Transpose to match rows/columns

sortIndex2 = [];

% Transpose the index vectors if they are columns (ensure firstIndices and lastIndices are row vectors for easier indexing)
firstIndices = firstIndices';
lastIndices = lastIndices';

for i = 1:length(uniqueTrials)
    startCol = firstIndices(i);
    endCol = lastIndices(i);

    % Get the current group slice of last performance
    group_last_perf = Perf_last_sortedbynTrials(startCol:endCol);

    % Get the absolute column indices for this group in the original matrix
    original_group_indices = startCol:endCol;

    % Find the sorting indices for the current group (descending performance)
    % The output 'I' is the index (permutation) vector for sorting
    [~, sort_indices] = sort(group_last_perf, 'ascend');

    % Apply the sort indices to the absolute original indices
    % This is the core mapping: where each new column came from
    sorted_absolute_indices = original_group_indices(sort_indices);

    % Concatenate the sorted absolute indices
    sortIndex2 = [sortIndex2, sorted_absolute_indices];
end


PerfMat_sort_resort = PerfMat_sort(:, sortIndex2);

RTMat_sort_resort = RTMat_sort(:, sortIndex2);


nBlocksPerformed=(sum(~isnan(BlocksMean_perf)))';

% null model for performance
nSims=1e4;

if exist('NullPerf', 'var')
else
    temp_null=mean(randi([0 1], nSims, n_trialsTOT),2);
    NullPerf=prctile(temp_null, [2.5 50 97.5]);
end


deltaP_LastFirst=Perf_last-Perf_first;
deltaRT_LastFirst_median=RT_last_median-RT_first_median;


B=(1:6)';
Ss=nan(size(B));
for j=1:numel(B)
    Ss(j,1)=sum(nBlocksPerformed==j);
end

Block_N_particip=[B Ss];


behaviorAnalysisDone=true;

disp('######## done calculating behavioral results')


clear temp k j i bl jj ii idx c f nw r p currSpatialStim L varsInFile thisP thisParticipant ...
    sortIndex1 sortIndex2 sort_indices sorted_absolute_indices startCol endCol ...
    stimBlock rt_temp perfdata p_temp original_group_indices temp_null