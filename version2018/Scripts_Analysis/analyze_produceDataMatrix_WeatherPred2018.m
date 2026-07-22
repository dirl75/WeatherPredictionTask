%% 0. LOAD DATA

clc; clearvars;

load('DATA_pupil_BPcenter_zscore_WP2018_CHECK.mat','PUPILDATA')
load('DATA_eyeXYEpochs_BPcenter_WP2018.mat','EYETRACKDATA')

% Run spatial correction script (produces EYETRACKDATA_corr)
analyze_EyeMov_SpatialCorrection_WeatherPred2018

disp('All data loaded and spatial correction applied.');

%%

% Get IDs from the structure
% --- SETTINGS: Toggle filters here ---
applySubjectFilter = true; % Set to true to exclude participants marked in .info
applyTrialFilter   = true;   % Set to true to exclude trials marked in .qualityVector

subjects = fieldnames(PUPILDATA.data);
allData = table(); 
t_start_val = PUPILDATA.info.epoch_before_after_event_s(1); 

% Get the exclusion list from info (assuming it matches the order of fieldnames)
% If exclude_participant is a logical/numeric vector of the same length as subjects:
excludeList = PUPILDATA.info.exclude_participant;

for i = 1:numel(subjects)
    % --- 1. Participant Level Filter ---
    if applySubjectFilter && excludeList(i) == 1
        fprintf('Skipping participant %s (Excluded in info)\n', subjects{i});
        continue; 
    end

    subID = subjects{i};
    subP = PUPILDATA.data.(subID);
    subE = EYETRACKDATA_corr.data.(subID);
    
    % --- 2. Extract and Downsample ---
    pSignal = subP.pupilEpochs_blinkinterp;
    gX = subE.eyeEpochsX_raw;
    gY = subE.eyeEpochsY_raw;
    
    currentFs = subP.Fs;
    if currentFs == 1000
        pSignal = pSignal(1:2:end, :);
        gX = gX(1:2:end, :);
        gY = gY(1:2:end, :);
        effectiveFs = 500;
    else
        effectiveFs = currentFs;
    end
    
    % --- 3. Trial Level Filter ---
    % qualityVector: 1 = keep, 0 = remove
    validTrialsIdx = true(subP.n_completed_trials, 1); % Default: keep all
    if applyTrialFilter && isfield(subP, 'qualityVector')
        validTrialsIdx = logical(subP.qualityVector);
    end
    
    % Filter all behavioral and physiological matrices by trial (columns)
    % This ensures the 144 trials become, for example, 130 trials across the board
    pSignal = pSignal(:, validTrialsIdx);
    gX = gX(:, validTrialsIdx);
    gY = gY(:, validTrialsIdx);
    
    rt_filtered   = subP.RT_nomisses(validTrialsIdx);
    perf_filtered = subP.performance_nomisses(validTrialsIdx);
    nTrialsFinal  = sum(validTrialsIdx);
    
    % --- 4. Create Time Vector and Windows ---
    nSamples = size(pSignal, 1);
    tempo = (0:nSamples-1) / effectiveFs;
    tempo = tempo + t_start_val;
    
    idxPat = (tempo >= -1.0 & tempo <= 1.0);
    idxFdb = (tempo > 1.0 & tempo <= 3.0);
    
    % --- 5. Assemble Table for Subject ---
    subTable = table();
    subTable.TrialNum      = (1:nTrialsFinal)';
    subTable.BlockNum      = ceil((1:nTrialsFinal)' / 50); % Note: Block labeling may shift if trials are removed
    subTable.ParticipantID = repmat(string(subID), nTrialsFinal, 1);
    subTable.RT            = rt_filtered; 
    subTable.Performance   = perf_filtered;
    
    % Pupil Stats
    subTable.MedPupil_Pat  = median(pSignal(idxPat, :), 1, 'omitnan')';
    subTable.MedPupil_Fdb  = median(pSignal(idxFdb, :), 1, 'omitnan')';
    subTable.AUCPupil_Pat  = trapz(pSignal(idxPat, :), 1)';
    subTable.AUCPupil_Fdb  = trapz(pSignal(idxFdb, :), 1)';
    subTable.MaxPupil_Pat  = max(pSignal(idxPat, :), [], 1, 'omitnan')';
    subTable.MaxPupil_Fdb  = max(pSignal(idxFdb, :), [], 1, 'omitnan')';
    
    % Gaze Stats
    subTable.MeanGazeX_Pat = mean(gX(idxPat, :), 1, 'omitnan')';
    subTable.MeanGazeY_Pat = mean(gY(idxPat, :), 1, 'omitnan')';
    subTable.MeanGazeX_Fdb = mean(gX(idxFdb, :), 1, 'omitnan')';
    subTable.MeanGazeY_Fdb = mean(gY(idxFdb, :), 1, 'omitnan')';
    
    allData = [allData; subTable];
end

% --- 6. Save ---
filename = 'DataMatrix_Eye_Behav_WeatherPred_2019-2023.csv';
filename = 'DataMatrix_Eye_Behav_WeatherPred_2019-2023_forLMMs.csv';
writetable(allData, filename);
fprintf('Process complete. Data saved to %s\n', filename);


