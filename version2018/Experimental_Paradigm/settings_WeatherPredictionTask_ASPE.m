%%%%%%%%%%%%%%% General task Parameters %%%%%%%%%%%%%%%%%%%%%%%

rng('shuffle')

 
ITI_s=2;  %inter- trial interval (seconds)
Wait_time_s=2; %Max time to wait for subject's response within a trial (seconds)
Wait2_time_s=1;%Max time to wait for subject's response within a trial after warning (seconds)
Wait_After_Response_s=1;
Feedback_durat_s=2; % time duration
Wait_time_between_blocks_s=60;  %time to wait between blocks (Seconds)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

dummyMode_EEG=true;
dummyMode_Eyelink=false;

%define which keyboard
taskInputKb='';
% taskInputKb='USB KVM';
% taskInputKb='USB Keyboard';

%%%%%%%%%%% Eye-tracking device  %%%%%%%%%%%

%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%% WeatherTask-specific Parameters %%%%%%%%%%%%%%%%%%%%%%%

Form_pairs={'Triangle', 'Star', 'Empty';'Empty', 'Star', 'Triangle'; 'Triangle', 'Ellipse','Empty'; 'Empty', 'Ellipse', 'Triangle';...
    'Square', 'Star', 'Empty'; 'Empty', 'Star', 'Square'; 'Square', 'Ellipse', 'Empty'; 'Empty', 'Ellipse', 'Square'};
if randi([1 100],1)>50
    forms_weather_assoc=1;
    Weather={'S';'R';'S';'R';'S';'S';'R';'R'};
else
    forms_weather_assoc=2;
    Weather={'R';'S';'R';'S';'R';'R';'S';'S'};        
end

% build trials sequence

% Build 7 blocks with 50 trials/block:
% 1) roughly equal amounts of each stimuli (1-8) on each block
% 2) no stimulus repeat on contiguous trials

%first, 48 stimuli, 6 of each
stimblock=nan(6,8);
for i=1:8
    stimblock(:,i)=ones(6,1)*i;
end
stimblock=stimblock(:);
%second, 2 stimuli (randomly chosen) to obtain 50 total
stimblock(end+1:50)=randi([1 8],1,2);

%build blocks
Stim_seq=nan(50,6);
Block_dumm=nan(50,6);
for bl=1:size(Stim_seq,2) %loop through blocks
    %randomize temporary sequence
    stimblock=stimblock(randperm(numel(stimblock)));
    %check for stim repeats
    a=diff(stimblock)==0;
    if sum(a)~=0 %there are repeats
        while sum(a)~=0
            stimblock=stimblock(randperm(numel(stimblock)));
            a=diff(stimblock)==0;
        end
    end
    Stim_seq(:,bl)=stimblock;
    Block_dumm(:,bl)=bl;
end

n_blocks=size(Stim_seq,2);
n_trials=size(Stim_seq,1);

%%%%%%%% specify form sizes in screen

% img_RAIN=imread(['.' filesep 'images'  filesep 'rain_color_2_bckgrn.png']);
% img_SUN=imread(['.' filesep 'images'  filesep 'sun_color_2_bckgrn.png']);

img_RAIN=imread(['.' filesep 'images'  filesep 'rain_bw.png']);
img_SUN=imread(['.' filesep 'images'  filesep 'sun_bw.png']);

%%%%%%%%%%%%% create data structure from user input and task parameters

participantInfo=GetSubjectInfo_Weather;

data.info.Subject_ID_actual=participantInfo.data{1};
data.info.Subject_ID=GenRandomString;
data.info.Subject_Age=participantInfo.data{3};
data.info.Subject_Gender=participantInfo.data{2};
data.info.ExpInCharge=participantInfo.data{4};

data.info.Task='Weather Prediction Task';
data.info.Form_pairs=Form_pairs;
data.info.Weather=Weather;

data.info.datetime=participantInfo.data{5};

temp=regexp(participantInfo.data{5},'_','split');

data.info.timestart=temp{4};

data.vars.Stim_seq=Stim_seq(:);
data.vars.Block_dumm=Block_dumm(:);

folder=['.' filesep 'data'];
data_filename=[folder filesep 'data_' data.info.Subject_ID(1:2) '_' data.info.datetime];


%%%%%%% settings %%%%%%%%%%%%
KbName('UnifyKeyNames');    % keynames for all types of keyboard
% buttons to press
responseKeys={'S','L','R','space','ESCAPE', 'C', 'V'};
KbCheckList=nan(size(responseKeys));
for k=1:length(responseKeys)
    KbCheckList(k)=KbName(responseKeys{k});
end
RestrictKeysForKbCheck(KbCheckList);
[deviceIdKey,deviceNameKey]=GetKeyboardIndices;

whichKb=strcmp(taskInputKb,deviceNameKey);

device2useID=deviceIdKey(whichKb);