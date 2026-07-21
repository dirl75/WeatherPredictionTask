%% LOAD DATA
load('DATA_pupil_BPcenter_zscore_WP2018_CHECK.mat')
%% VISUALIZE EACH PUPIL EPOCH AND DECIDE IF KEEP IT OR NOT
% 
participants = fieldnames(PUPILDATA.data); % Get names like 'S01', 'S02', etc.
numParticipants = numel(participants);

fig = figure('Name', 'Pupil Inspector (Fast + Undo)', 'NumberTitle', 'off', 'Color', 'w');
fprintf('CONTROLS:\n [Y] - Keep\n [N] - Discard\n [B] - Back\n [Q] - Save & Quit Participant\n [X] - Exit Entire Script\n');

before_after_s=PUPILDATA.info.epoch_before_after_event_s;

start_with_particip=17;

for p = start_with_particip:numParticipants
    pName = participants{p};
    fprintf('\n--- Processing Participant: %s (%d of %d) ---\n', pName, p, numParticipants);
    
    % Access the specific matrix
    currentData = PUPILDATA.data.(pName).pupilEpochs_blinkinterp;
    Fs=PUPILDATA.data.(pName).Fs;
    [numSamples, numTrials] = size(currentData);
    %timeAxis = 1:numSamples;

    timeAxis=(0:numSamples-1)./Fs;
    timeAxis=timeAxis+before_after_s(1);
    
    % Initialize or retrieve existing quality vector
    if isfield(PUPILDATA.data.(pName), 'qualityVector')
        qVec = PUPILDATA.data.(pName).qualityVector;
    else
        qVec = NaN(numTrials, 1); 
    end
    
    t = 1;
    while t <= numTrials
        % 1. Plot
        plot(timeAxis, currentData(:, t), 'LineWidth', 1.5, 'Color', [0.2 0.2 0.2]);
        grid on;
        
        status = 'Unrated';
        if qVec(t) == 1, status = 'KEEP'; end
        if qVec(t) == 0, status = 'DISCARD'; end
        
        title(sprintf('Participant: %s | Trial %d/%d\nStatus: %s ,Part# %d', pName, t, numTrials, status,p),...
            'Interpreter', 'none');
        ylabel('Pupil Diameter (Interp)');
        xlabel('Time to button press (s)');

        % 2. Input
        waitforbuttonpress;
        key = lower(get(fig, 'CurrentCharacter'));

        % 3. Logic
        switch key
            case 'y'
                qVec(t) = 1;
                t = t + 1;
            case 'n'
                qVec(t) = 0;
                t = t + 1;
            case 'b'
                t = max(1, t - 1);
            case 'q'
                fprintf('Saving current participant and moving to next...\n');
                %PUPILDATA.data.(pName).qualityVector = qVec;
                disp('data being saved...')
                
                %save('DATA_pupil_BPcenter_zscore_WP2018_CHECK.mat','PUPILDATA','-mat')
                disp('done saving')
                break;
            case 'x'
                fprintf('Exiting script. Saving progress for %s.\n', pName);
                %PUPILDATA.data.(pName).qualityVector = qVec;
                disp('data being saved...')
                %save('DATA_pupil_BPcenter_zscore_WP2018_CHECK.mat','PUPILDATA','-mat')
                disp('done saving')
                return; % Hard stop
        end
    end
    % Save the vector back into the big structure
    %PUPILDATA.data.(pName).qualityVector = qVec;
    %save('DATA_pupil_BPcenter_zscore_WP2018_CHECK.mat','PUPILDATA','-mat')
end

%save('DATA_pupil_BPcenter_zscore_WP2018_CHECK.mat','PUPILDATA','-mat')

fprintf('\n*** All participants processed and saved in PUPILDATA structure ***\n');

%%
n_trials_tot=nan(numParticipants,1);
n_trials_excluded=nan(numParticipants,1);
for p=1:numParticipants
    pName = participants{p};
    qVector=PUPILDATA.data.(pName).qualityVector;
    n_trials_excluded(p)=sum(~qVector);
    n_trials_tot(p)=numel(qVector);

end

PUPILDATA.info.n_trials_tot=n_trials_tot;
PUPILDATA.info.n_trials_excluded=n_trials_excluded;

ratio=n_trials_excluded./n_trials_tot;

PUPILDATA.info.exclude_participant=ratio>0.6;

save('DATA_pupil_BPcenter_zscore_WP2018_CHECK.mat','PUPILDATA','-mat')

