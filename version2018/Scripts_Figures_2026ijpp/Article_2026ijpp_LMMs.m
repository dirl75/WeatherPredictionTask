%% 1. Load the Data
clc;clearvars
DataMat = readtable('DataMatrix_Eye_Behav_WeatherPred_2019-2023_forLMMs.csv');

% Ensure ParticipantID is treated as a categorical grouping variable
DataMat.ParticipantID = categorical(DataMat.ParticipantID);

% Ensure Performance is categorical (0 = Incorrect, 1 = Correct)
DataMat.Performance = categorical(DataMat.Performance);


%% 2. Define and Fit the Models
% We will predict Median Pupil during Feedback. 
% Formula: Pupil ~ 1 + TrialNum * Performance + (1 + TrialNum | ParticipantID)
% 
clc

pupilMetricAndPeriod='AUCPupil_Pat';

modelEq=[pupilMetricAndPeriod ' ~ 1 + TrialNum * Performance + (1 + TrialNum | ParticipantID)'];

% Breakdown of the formula:
% '1' : The intercept.
% 'TrialNum * Performance' : Main effects and their interaction.
% '(1 + TrialNum | ParticipantID)' : Random intercepts and random slopes 
%                                     per participant (accounts for individual differences).

%fprintf('Fitting Linear Mixed Model for Feedback Pupil...\n');

lme_pat = fitlme(DataMat, modelEq)

% % Extract fixed effects p-values and coefficients
stats_pat = dataset2table(lme_pat.Coefficients);
writetable(stats_pat,'Table1.xlsx')


pupilMetricAndPeriod='AUCPupil_Fdb';

modelEq=[pupilMetricAndPeriod ' ~ 1 + TrialNum * Performance + (1 + TrialNum | ParticipantID)'];

% Breakdown of the formula:
% '1' : The intercept.
% 'TrialNum * Performance' : Main effects and their interaction.
% '(1 + TrialNum | ParticipantID)' : Random intercepts and random slopes 
%                                     per participant (accounts for individual differences).

%fprintf('Fitting Linear Mixed Model for Feedback Pupil...\n');

lme_fdb = fitlme(DataMat, modelEq)

% % Extract fixed effects p-values and coefficients
stats_fdb = dataset2table(lme_fdb.Coefficients);
writetable(stats_fdb,'Table2.xlsx')



