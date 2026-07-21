%% LIST DATA FILES, GET PARTICIPANTS' ID
clc;clearvars

msg = sprintf(['1. SELECT THE FOLDER CONTAINING THE PHYSIOLOGICAL DATA (PUPIL) FILES.\n',...
               'If you do not have the data, download it from Figshare: \n',...
               'https://doi.org/10.6084/m9.figshare.32209329'])

% Ask user to select the 'data' folder containing the .mat files
pupilDatapath = uigetdir(pwd, 'Select the folder containing the physiological (.asc) files');

% Check if the user pressed 'Cancel'
if isequal(pupilDatapath, 0)
    error('User cancelled folder selection. Analysis cannot proceed.');
end

%two kinds of data files, *.asc and *.mat
dir_asc=dir([pupilDatapath filesep '*.asc']);
%sort by date
[~,idx] = sort([dir_asc.datenum]);
dir_asc = dir_asc(idx);

disp([num2str(numel(dir_asc)) ' asc datafiles (eye data) found'])



msg = sprintf(['2. SELECT THE FOLDER CONTAINING THE BEHAVIORAL-DATA FILES.\n',...
               'If you do not have the data, download it from Figshare: \n',...
               'https://doi.org/10.6084/m9.figshare.32209329'])

% Ask user to select the 'data' folder containing the .mat files
behavDatapath = uigetdir(pwd, 'Select the folder containing the behavioral (.mat) files');

% Check if the user pressed 'Cancel'
if isequal(behavDatapath, 0)
    error('User cancelled folder selection. Analysis cannot proceed.');
end



dir_mat=dir([behavDatapath filesep '*.mat']);
%sort by date
[~,idx] = sort([dir_mat.datenum]);
dir_mat = dir_mat(idx);

disp([num2str(numel(dir_mat)) ' mat datafiles (behavioral data) found'])


%get participant's ID from mat files
particip_initials=cell(numel(dir_mat),1);
for j=1:numel(dir_mat)
    particip_initials{j}=dir_mat(j).name(6:7);
end
clear j
%list events of interest
eventnames={'FIXOVAL','STIM','BP1','BP2','FEEDB'};

before_after=[-3.1 3.1];  % epoch times before/after event (in s)
%% PRODUCE PERI-EVENT EPOCH MATRICES - PUPIL DATA
home
%choose event of reference
eventEpochCenter='BP'; %button press
%eventEpochCenter='STIM'; %stimulus (pattern) onset
% eventEpochCenter='FEEDB';
% choose normalization method for pupil
% normalizMethod='none'; descript='no normalization applied';   
% normalizMethod='zscore';   descript='z-score of entire epoch';
normalizMethod='subtract';  descript='subtract baseline from entire epoch';
% normalizMethod='divide1';  descript='divide entire epoch by baseline';

savePupilStruct=true;


%REQUIRES:
% - custiom-built functions 'GetEventsFromAscii' and 'GetEyeDataFromAscii'
% - toolbox 'PRET' for pupil data processing

baseline_s=0.04; %baseline duration, in s, required for some pupil normalizations

min_n_trials=50;

%preallocate
particip_ID=cell(1,1);
particip_filename_behav=cell(1,1);
particip_filename_eyetrack=cell(1,1);
Final_participants=true;

c=0;  % initialize counter 
for thisParticipant=1:numel(dir_asc) %loop through ASC (eyelink) data files, one per participant
    disp('=======')
    disp(['participant ' num2str(thisParticipant)])
    tic
    eyelinkfile=dir_asc(thisParticipant).name;
    
    %find current participant's Matlab (BehavData) file
    where=strfind(particip_initials, eyelinkfile(1:2));
    logi=false(numel(where),1);
    for j=1:numel(where)
        if ~isempty(where{j})
            logi(j)=true;
        end
    end
    
    if sum(logi)==0 %means initials from filename aren't in list with particip initials from behav data.
        disp('no eyelink file counterpart among behavioral files')
        disp('cannot match eye data and behavior')
        disp(['eyelink file: ' eyelinkfile ' (' num2str(dir_asc(thisParticipant).bytes/1e6) ' Mbytes)'])
        
    else % proceed with analysis
        
        c=c+1; %count 
        disp(['eyelink file: ' eyelinkfile ' (' num2str(dir_asc(thisParticipant).bytes/1e6) ' Mbytes)'])
        
        behavfile=dir_mat(logi);
        behavfile=behavfile.name;
        %load matlab BehavData file
        load([pupilDatapath filesep 'data' filesep behavfile])
        
        %mark if participant has few trials
        n_valid_trials=sum(~isnan(BehavData.vars.Perform_seq));
        if n_valid_trials<min_n_trials
            Final_participants(c,1)=false;
        else
            Final_participants(c,1)=true;
        end
        
        % get timestamps of events' occurrence
        time_allEvents=GetEventsFromAscii_Optimized([pupilDatapath filesep 'data_edf' filesep eyelinkfile], eventnames);
        % get eye mov & pupil size data matrix
        [EyeDataMatrix, Fs]=GetEyeDataFromAscii_optimized([pupilDatapath filesep 'data_edf' filesep eyelinkfile]);
        
        %save file & ID data
        particip_ID{thisParticipant}=BehavData.info.Subject_ID;
        particip_filename_behav{thisParticipant}=behavfile;
        particip_filename_eyetrack{thisParticipant}=eyelinkfile;
        
        
        % PRODUCE MATRIX OF PERI-EVENT PUPIL EPOCHS
        
        if strcmp(eventEpochCenter,'BP')
            EV=[3 4];  %indices of events in 'eventnames'
        elseif strcmp(eventEpochCenter,'STIM')
            EV=[2 2];
        elseif strcmp(eventEpochCenter,'FEEDB')
            EV=[5 5];
        end
        
        %get times of events of interest
        logi_event=time_allEvents(:,2)==EV(1)| time_allEvents(:,2)==EV(2);
        timeofevents=time_allEvents(logi_event,1);
        
        logi_event_STIM=time_allEvents(:,2)==2;
        timeofevents_STIM=time_allEvents(logi_event_STIM);

        %get events' indices
        idcs_events=nan(numel(timeofevents),1);
        for ii=1:numel(idcs_events)
            [a, where]=min(abs(timeofevents(ii,1)-EyeDataMatrix(:,1)));
            idcs_events(ii)=where;

        end
        
        idcs_events_STIM=nan(numel(timeofevents_STIM),1);
        for ii=1:numel(idcs_events_STIM)
            [a, where2]=min(abs(timeofevents_STIM(ii,1)-EyeDataMatrix(:,1)));
            idcs_events_STIM(ii)=where2;
        end


        % 50 ms of baseline recommended by MAthot. Behavior Research Methods (2023) 55:3055–3077  page 3065
        
        pupilTimeseries=EyeDataMatrix(:,4);

        pupilTimeseries(isnan(pupilTimeseries))=0;  %change nans to zeros
        
        %pupilTimeseries_blInterp=blinkinterp(pupilTimeseries', Fs, 5, 3, 50, 75);



        [pupilEpochs_raw, time_vector]=EpochTimeSeries(pupilTimeseries, idcs_events,before_after, Fs);
        
        % get performance from behavioral mat file
        Perf=BehavData.vars.Perform_seq;
        Misses=isnan(Perf);
        %Perf(Misses)=0;
        %Perf=logical(Perf);
        
        %only pupil epochs for which there's behavior concurrently recorded
        %pupilEpochs_raw=pupilEpochs_raw(:,~Misses);
        
        RT=BehavData.vars.RT_seq;

        STIM=BehavData.vars.Stim_seq;
        
        %filter behavioral data: ONLY trials in which participant did respond
        Perf2=Perf(~Misses);
        RT2=RT(~Misses);
        STIM2=STIM(~Misses);

        if n_valid_trials>=50 && n_valid_trials <=100
            nBlocks=2;
        elseif n_valid_trials>100 && n_valid_trials <=150
            nBlocks=3;
        elseif n_valid_trials>150 && n_valid_trials <=200
            nBlocks=4;
        elseif n_valid_trials>200 && n_valid_trials <=250
            nBlocks=5;
        elseif n_valid_trials>250 && n_valid_trials <=300
            nBlocks=6;
        end


        PUPILDATA.data.(eyelinkfile(1:end-4)).performance=Perf;
        PUPILDATA.data.(eyelinkfile(1:end-4)).misses=Misses;
        PUPILDATA.data.(eyelinkfile(1:end-4)).performance_nomisses=Perf2;
        PUPILDATA.data.(eyelinkfile(1:end-4)).RT_nomisses=RT2;
        PUPILDATA.data.(eyelinkfile(1:end-4)).pattern=STIM;
        PUPILDATA.data.(eyelinkfile(1:end-4)).pattern_nomisses=STIM2;
        PUPILDATA.data.(eyelinkfile(1:end-4)).n_completed_trials=n_valid_trials;
        PUPILDATA.data.(eyelinkfile(1:end-4)).n_completed_blocks=nBlocks;
        % apply algorithm to remove blinks
        
        %preallocate
        pupilEpochs_blinkinterp=nan(size(pupilEpochs_raw));
         
        pupilEpochs_blinks=nan(size(pupilEpochs_raw)); %blinks
        
        for thisEpoch=1:size(pupilEpochs_raw, 2) % loop through epochs (aka trials)
            
            blInterpPupil=blinkinterp(pupilEpochs_raw(:,thisEpoch)', Fs, 5, 3, 50, 75);
            
            nSamplesBaseline=round(Fs*baseline_s);

            pupilbaseline=blInterpPupil(1:nSamplesBaseline);

            if strcmp(normalizMethod, 'none')
                pupilEpochs_blinkinterp(:,thisEpoch)=blInterpPupil;
            elseif strcmp(normalizMethod, 'zscore')
                pupilEpochs_blinkinterp(:,thisEpoch)=zscore(blInterpPupil);
            elseif strcmp(normalizMethod, 'subtract')
                pupilEpochs_blinkinterp(:,thisEpoch)=blInterpPupil-median(pupilbaseline);
            elseif strcmp(normalizMethod, 'divide1')
                pupilEpochs_blinkinterp(:,thisEpoch)=blInterpPupil./median(pupilbaseline);
            end
            %     fig1=figure('color','w');
            %     ax=axes('parent', fig1,'tickdir', 'out', 'fontsize', fsize);
            %     hold(ax,'all')
            %     plot(ti+before_after(1), pupilEpochs_blinkinterp(:,thisEpoch),'linewidth',2,'color',[0 0.6 0])
            %     plot(ti+before_after(1), pupilEpochs_raw(:,thisEpoch),'linewidth',2,'color',[0.6 0.6 0.7])
            %     xlabel(['Time to ' num2str(eventnames{EV(1)}) ' or ' num2str(eventnames{EV(2)}) ' (s)'])
            %     ylabel('Pupil diameter (au)')
            %     pause
            %     clf
            
            %fill matrix with eyeblink occurrences
            currEpoch=pupilEpochs_raw(:,thisEpoch);
            currEpoch(currEpoch~=0)=-2;
            currEpoch(currEpoch==0)=1;
            currEpoch(currEpoch==-2)=0;
            
            pupilEpochs_blinks(:,thisEpoch)=currEpoch;
                     
        end
        % calculate number of effective trials (ie, particip responded) for first and last blocks
        % First for first block
        temp=Perf(1:50);
        F=~isnan(temp);
        nTrials_block1=sum(F);
        perf_Block1=temp(F);

        temp2=RT(1:50);
        rt_Block1=temp2(F);
        
        %Then for last block. First we need to find that block
        trialsPerBlock=50;
        % Find the index of the last non-NaN value
        lastTrialIdx = find(~isnan(Perf), 1, 'last');

        % Calculate the block number
        if isempty(lastTrialIdx)
            lastBlock = 0; % Participant has no data at all
        else
            lastBlock = ceil(lastTrialIdx / trialsPerBlock);
        end


        finT=lastBlock*trialsPerBlock;

        temp=Perf((finT-50)+1:finT);
        F=~isnan(temp);
        nTrials_blockEND=sum(F);
        perf_BlockFINAL=temp(F);

        temp2=RT((finT-50)+1:finT);
        rt_BlockFINAL=temp2(F);

        pupilEpochs_blinkinterp_Block1=pupilEpochs_blinkinterp(:,1:nTrials_block1);
        pupilEpochs_blinkinterp_BlockFINAL=pupilEpochs_blinkinterp(:,end-nTrials_blockEND+1:end);
        
        PUPILDATA.data.(eyelinkfile(1:end-4)).pupilEpochs_raw=pupilEpochs_raw;

        PUPILDATA.data.(eyelinkfile(1:end-4)).pupilEpochs_blinkinterp=pupilEpochs_blinkinterp;
        
        PUPILDATA.data.(eyelinkfile(1:end-4)).pupilEpochs_blinkinterp_Block1=pupilEpochs_blinkinterp_Block1;
        PUPILDATA.data.(eyelinkfile(1:end-4)).pupilEpochs_blinkinterp_BlockFINAL=pupilEpochs_blinkinterp_BlockFINAL;

        PUPILDATA.data.(eyelinkfile(1:end-4)).perf_Block1=perf_Block1;
        PUPILDATA.data.(eyelinkfile(1:end-4)).perf_BlockFINAL=perf_BlockFINAL;
        
        PUPILDATA.data.(eyelinkfile(1:end-4)).rt_Block1=rt_Block1;
        PUPILDATA.data.(eyelinkfile(1:end-4)).rt_BlockFINAL=rt_BlockFINAL;
        
        PUPILDATA.data.(eyelinkfile(1:end-4)).pupilEpochs_blinks=pupilEpochs_blinks;
        PUPILDATA.data.(eyelinkfile(1:end-4)).Fs=Fs;
        
        % PLOT
        
        %     fsize=15;
        %     fig1=figure('color','w');
        %     ax=axes('parent', fig1,'tickdir', 'out', 'fontsize', fsize);
        %     hold(ax,'all')
        %
        %     ti=(0:size(pupilEpochs_raw, 1)-1)./Fs;
        %
        %     plot(1e5,1e5,'linewidth',5,'color',[0 0 0.9])
        %     plot(1e5,1e5,'linewidth',5,'color',[0.9 0 0])
        %     legend({'Correct', 'Incorrect'},'location','northwest')
        %     plot(ti+before_after(1), pupilEpochs_blinkinterp_Norm(:, Perf2), 'color', [0.75 0.75 0.9])
        %     plot(ti+before_after(1), pupilEpochs_blinkinterp_Norm(:, ~Perf2), 'color', [0.9 0.75 0.75])
        %     plot(ti+before_after(1), nanmean(pupilEpochs_blinkinterp_Norm(:, Perf2),2),...
        %         'linewidth',4,'color', [0 0 0.9])
        %     plot(ti+before_after(1), nanmean(pupilEpochs_blinkinterp_Norm(:, ~Perf2),2),...
        %         'linewidth',4,'color', [0.9 0 0])
        %     xlabel(['Time to ' num2str(eventnames{EV(1)}) ' or ' num2str(eventnames{EV(2)}) ' (s)'])
        %     ylabel('Pupil diameter (au)')
        %
        %
        %     ma=max(max([nanmean(pupilEpochs_blinkinterp_Norm(:, ~Perf2),2)...
        %         nanmean(pupilEpochs_blinkinterp_Norm(:, Perf2),2)]));
        %     mi=min(min([nanmean(pupilEpochs_blinkinterp_Norm(:, ~Perf2),2)...
        %         nanmean(pupilEpochs_blinkinterp_Norm(:, Perf2),2)]));
        %
        %     title(eyelinkfile(1:end-4), 'interpreter', 'none')
        %
        %     xlim(before_after)
        %     ylim([mi ma].*1.05)
        %
        %     print(fig1, eyelinkfile(1:end-4), '-dpng', '-r250')
        toc
        disp('=======')
    end
end

if strcmp(eventEpochCenter,'BP')
    event='Button Press';
elseif strcmp(eventEpochCenter,'STIM')
    event='Pattern onset';
elseif strcmp(eventEpochCenter,'FEEDB')
    event='Feedback onset';
end




PUPILDATA.info.events_of_ref=event;
PUPILDATA.info.eventCodenames=eventnames(EV);
PUPILDATA.info.epoch_before_after_event_s=before_after;
PUPILDATA.info.particip_ID=particip_ID;
PUPILDATA.info.particip_filename_behav=particip_filename_behav;
PUPILDATA.info.particip_filename_eyetrack=particip_filename_eyetrack;
PUPILDATA.info.filter_min_n_trials=Final_participants;
PUPILDATA.info.min_n_trials=min_n_trials;
PUPILDATA.info.DateTimeAnalysis=clock;
PUPILDATA.info.whoDidThis='DRL';
PUPILDATA.info.PupilNormalization={normalizMethod descript};
if strcmp(normalizMethod,'subtract') || strcmp(normalizMethod,'divide')
    PUPILDATA.info.PupilBaseline=['median of first ' num2str(baseline_s) 's'];
end
PUPILDATA.info.PupilMatrixDims={'Time' 'Trials'};

if savePupilStruct
    save([path2savedata filesep 'DATA_pupil_' eventEpochCenter 'center_' normalizMethod '_WP2018'], 'PUPILDATA', '-v7.3');
end
%clearvars -except PUPILDATA
disp('done!!')



