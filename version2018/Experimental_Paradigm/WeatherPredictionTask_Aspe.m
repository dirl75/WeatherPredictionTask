
function WeatherPredictionTask_Aspe
%%
%checkpoint
temp=regexp(pwd,filesep,'split');
if strcmp(temp{end},'WeatherPredictionTask_UDP')
else
    clc
    warning('Change your directory to the ''WeatherPredictionTask_UDP'' folder')
    WaitSecs(2)
    cd(uigetdir())
end

settings_WeatherPredictionTask_ASPE

Screen('Preference', 'SkipSyncTests', 1); % skip sync-tests for retina display

screenNumber=max(Screen('Screens'));
% winNumber=Screen('OpenWindow', screenNumber);

[winPointer, winRect] = Screen('OpenWindow', screenNumber);

w = winRect(RectRight); %screen width, pixels
h = winRect(RectBottom); %screen height, pixels
flipInterval=Screen('GetFlipInterval',winPointer)/2;
  
txtTitle='Tarea: Prediccion del Clima'; 
txtSpace='PRESIONE LA BARRA DE ESPACIO PARA CONTINUAR';

% txtTitle='Weather Prediction Task'; 
% txtSpace='PRESS SPACE BAR TO START';

Screen('TextSize',winPointer, 65);
  
DrawFormattedText(winPointer,txtTitle,'center','center')

Screen('TextSize',winPointer,35);
DrawFormattedText(winPointer,txtSpace,'center',0.85*h);
Screen('Flip',winPointer);
KbStrokeWait(device2useID);

txt='PRESIONE LA BARRA DE ESPACIO PARA INICIAR CALIBRACION DE EYE-TRACKING';
% txt='PRESS SPACE BAR TO START EYE-TRACKING CALIBRATION';

Screen('TextSize',winPointer, 60);

DrawFormattedText(winPointer,txt,'center','center',0,35)

Screen('Flip',winPointer);

if dummyMode_Eyelink
    
    Screen('TextSize',winPointer, 60);
    DrawFormattedText(winPointer,'Skipping eye-tracking calibration..','center','center',0,35)
    Screen('Flip',winPointer);
    WaitSecs(1.5);
else
    
    edfFile=[data.info.Subject_ID(1:2) '_' data.info.Subject_ID(4:5) '_' data.info.Subject_ID(7:8) '.edf']; %#ok<NODEF,NASGU>
    % edfFile='data_Zm.edf'; %'data_Zm_2019_01_04_11-58.edf';
    startAndCalibrateEyeLink
    
end
% specify form sizes in screen units
form_width=0.07*w;
form_height=0.1*h;

sep=0.015*w;
xpos_left=w*0.35;
xpos_center=xpos_left+form_width+sep;
xpos_right=xpos_center+form_width+sep;

ypos_bottom=h*0.45;

position_form_left=[xpos_left ypos_bottom xpos_left+form_width ypos_bottom+form_height];
position_form_center=[xpos_center ypos_bottom xpos_center+form_width ypos_bottom+form_height];
position_form_right=[xpos_right ypos_bottom xpos_right+form_width ypos_bottom+form_height];

position_Weather=[w*0.45 h*0.43 w*0.55 h*0.57];

% position_Weather=[w*0.35 h*0.3 w*0.7 h*0.85];

Screen_color=ones(3,1)*100;
Screen('FillRect',winPointer, Screen_color);

% start task
Resp_seq=nan(n_trials,n_blocks);
Perform_seq=nan(n_trials,n_blocks);
RT_seq=nan(n_trials,n_blocks);  

for thisBlock=1:n_blocks
    blockperf=nan(n_trials,1);
    disp(['%%%%%%%%%%%% BLOCK ' num2str(thisBlock)])
    if ~dummyMode_Eyelink;Eyelink('Message', ['BLOCK' num2str(thisBlock)]);end
    for thisTrial=1:n_trials
        ListenChar(2);
        leave=false;
        
        disp(['trial ' num2str(thisTrial)])
        
        Screen('FrameOval',winPointer,[170,170,170],...  
            CenterRect([0,0,40,40],winRect),10,10);
        fixOnset=Screen('Flip',winPointer);
        if ~dummyMode_Eyelink; Eyelink('Message', 'FIXOVAL'); end
        
        Priority(0); %changed from 9 to 0, DRL (08/10/2018)
        
        currPair=Form_pairs(Stim_seq(thisTrial),:); %#ok<NODEF>
        disp(currPair)
        currWeather=Weather{Stim_seq(thisTrial)}; %#ok<USENS>
        
        %load images
        empty=nan;
        for ii=1:numel(currPair)
            if strcmpi(currPair{ii},'Empty')
                empty=ii;
            else
                temp=imread(['.' filesep 'images' filesep currPair{ii} '.png']); %#ok<NASGU>
                eval(['img' num2str(ii) '=temp;'])
            end
        end
        
        % Display images
        if empty==1
            imgA=img2;
            imgB=img3;
            Screen('PutImage', winPointer, imgA, position_form_center)
            Screen('PutImage', winPointer, imgB, position_form_right)
        elseif empty==3
            imgA=img1;
            imgB=img2;
            Screen('PutImage', winPointer, imgA, position_form_left)
            Screen('PutImage', winPointer, imgB, position_form_center)
        end
        
%         Screen('TextSize',winPointer, 40);
%         txtPrompt='PREDIGA:  LLUVIA (L)   o   SOL (S)';
%         DrawFormattedText(winPointer, txtPrompt, 'center', 0.9*h, 1);
        trial_start=Screen('Flip',winPointer,(fixOnset-(flipInterval))+ITI_s);
        
        if ~dummyMode_Eyelink; Eyelink('Message', 'STIM'); end
        
        kk=false;
        while kk==false
            [~,~, keyCode] = KbCheck(device2useID);
            if keyCode(KbName('ESCAPE')) || keyCode(KbName('S')) || keyCode(KbName('L'))
                kk=true;
                flag_noanswer=false;
            end 
            if GetSecs-trial_start>=Wait_time_s
                flag_noanswer=true;
                kk=true;
                
            end
        end
       
        if flag_noanswer
            
%             disp('CONTESTE!')
%             Screen('TextSize',winPointer, 50);
%             DrawFormattedText(winPointer, 'CONTESTE!', 'center', 0.2*h, 240);
%             Screen('TextSize',winPointer, 40);
%             DrawFormattedText(winPointer, txtPrompt, 'center', 0.9*h, 1);
%             Screen('PutImage', winPointer, imgA, position_form_left)
%             Screen('PutImage', winPointer, imgB, position_form_center)
            
%             if empty==1
%                 Screen('PutImage', winPointer, imgA, position_form_center)
%                 Screen('PutImage', winPointer, imgB, position_form_right)
%             elseif empty==3
%                 Screen('PutImage', winPointer, imgA, position_form_left)
%                 Screen('PutImage', winPointer, imgB, position_form_center)
%             end
            
%             second_start=Screen('Flip',winPointer);
%             kk=false;
%             while kk==false
%                 [~,~, keyCode] = KbCheck(device2useID);
%                 if keyCode(KbName('ESCAPE')) || keyCode(KbName('S')) || keyCode(KbName('L'))
%                     kk=true;
%                 end
%                 if GetSecs-second_start>=Wait2_time_s
%                     flag_noanswer=true;
%                     kk=true;
                    txtFeedback='INCORRECT';
                    feedback_color=[170; 170; 170];
                    if strcmp(currWeather,'R')  % RAIN was correct
                        Weather_img=img_RAIN;
                    elseif strcmp(currWeather,'S')
                        Weather_img=img_SUN;
                    end
                    rt=GetSecs-trial_start;
%                 end
%             end
        end
        
        if keyCode(KbName('ESCAPE')) %leave task, first confirm choice
            Screen('TextSize',winPointer, 55);
            textRUsure='Confirma que desea abandonar la tarea? (S o N)';
%             textRUsure='Are you sure you are leaving? (S o N)';
            DrawFormattedText(winPointer, textRUsure, 'center', 'center', [0;0;0], 85);
            Screen('Flip',winPointer)
            dumm=false;
            while dumm==false
                [~,~, keyCode] = KbCheck(device2useID);
                if keyCode(KbName('S'))
                    dumm=true;
                    leave=true;
                elseif keyCode(KbName('N'))
                    dumm=true;
                    leave=false;
                end
            end
        end
        
        if keyCode(KbName('L')) || keyCode(KbName('S')) % participant presses either key
            if keyCode(KbName('L'))
                Resp_seq(thisTrial,thisBlock)=1;
                if ~dummyMode_Eyelink; Eyelink('Message', 'BP1'); end
            elseif keyCode(KbName('S'))
                Resp_seq(thisTrial,thisBlock)=2;
                if ~dummyMode_Eyelink; Eyelink('Message', 'BP2'); end
            end
            rt=GetSecs-trial_start;
            WaitSecs(Wait_After_Response_s)
            
            if strcmp(currWeather,'S')  % SUN was correct
                Weather_img=img_SUN;
                if keyCode(KbName('L'))
                    Perform_seq(thisTrial,thisBlock)=0;
                    txtFeedback='INCORRECT';
                    feedback_color=[170; 170; 170];
                elseif keyCode(KbName('S'))
                    Perform_seq(thisTrial,thisBlock)=1;
                    txtFeedback='CORRECT';
                    feedback_color=[170; 170; 170];
                end
            elseif strcmp(currWeather,'R')  % RAIN was correct
                Weather_img=img_RAIN;
                if keyCode(KbName('L'))
                    Perform_seq(thisTrial,thisBlock)=1;
                    txtFeedback='CORRECT';
                    feedback_color=[170; 170; 170];
                elseif keyCode(KbName('S'))
                    Perform_seq(thisTrial,thisBlock)=0;
                    txtFeedback='INCORRECT';
                    feedback_color=[170; 170; 170];
                end
            end
        end
        
        blockperf(thisTrial)=Perform_seq(thisTrial,thisBlock);
        
        if leave
            Screen('TextSize',winPointer, 60);
            textThanks='Muchas gracias';
            DrawFormattedText(winPointer, textThanks, 'center', 'center',[0; 0; 0], 85);
            Screen('Flip',winPointer)
            WaitSecs(2.5);
            Screen(winPointer,'Close');
            clear screen
            if thisTrial>=10
                temp1=Perform_seq(:);
                temp2=RT_seq(:);
                temp2=round(temp2*1000)/1000; % 3 decimals
                temp3=Resp_seq(:);
                data.vars.Perform_seq=temp1;
                data.vars.RT_seq=temp2;
                data.vars.Resp_seq=temp3;
                data.info.txtPerf=['Participant cancels task in block ' num2str(thisBlock) ', trial ' num2str(thisTrial)];
                
                saveBehavData_Weather(data, data_filename);
            end
            break
        else
            Screen('TextSize',winPointer, 45);
            DrawFormattedText(winPointer, txtFeedback, 'center',...
                0.2*h, feedback_color);
            Screen('PutImage', winPointer, Weather_img, position_Weather)
            trial_endtime=Screen('Flip',winPointer);
            if ~dummyMode_Eyelink; Eyelink('Message', 'FEEDB'); end
            WaitSecs(Feedback_durat_s);
            RT_seq(thisTrial,thisBlock)=rt;
        end
        
        %if last trial, display goodbye screen
        if thisTrial==n_trials && thisBlock==n_blocks
            WaitSecs(1.5);
            text_goodbye='Muchas Gracias';
            Screen('TextSize',winPointer, 90);
            DrawFormattedText(winPointer, text_goodbye, 'center', 'center', [50; 50; 50], 185);
            Screen('Flip',winPointer);
            WaitSecs(3);
        end
        
        if thisTrial==10  
            temp1=Perform_seq(:);
            temp2=RT_seq(:);
            temp2=round(temp2*1000)/1000; % 2 decimals
            data.vars.Perform_seq=temp1;
            data.vars.RT_seq=temp2;
            data.info.txtPerf='';
            saveBehavData_Weather(data, data_filename);
        end
        
    end
    
    if sum(blockperf)>=47
        WaitSecs(1.5);
        text_goodbye='Muchas Gracias';
        Screen('TextSize',winPointer, 90);
        DrawFormattedText(winPointer, text_goodbye, 'center', 'center', [50; 50; 50], 185);
        Screen('Flip',winPointer);
        WaitSecs(3);
        Screen(winPointer,'Close');
        txtPerf=['Session ended. Block ' num2str(thisBlock) ' has more than 47 correct.'];
        temp1=Perform_seq(:);
        temp2=RT_seq(:);
        temp2=round(temp2*1000)/1000; % 2 decimals
        data.vars.Perform_seq=temp1;
        data.vars.RT_seq=temp2;
        data.info.txtPerf=txtPerf;
        
        saveBehavData_Weather(data, data_filename);
        break
    else
        txtPerf='';
    end
    if leave
        break
    end
    
    temp1=Perform_seq(:);
    temp2=RT_seq(:);
    temp2=round(temp2*1000)/1000;  % 2 decimals
    temp3=Resp_seq(:);
    data.vars.Perform_seq=temp1;
    data.vars.RT_seq=temp2;
    data.vars.Resp_seq=temp3;  
    
    
    data.info.txtPerf=txtPerf;
    
    saveBehavData_Weather(data, data_filename);
    if thisBlock<n_blocks
        Screen('TextSize',winPointer,70)
        DrawFormattedText(winPointer,'Pausa (1 min). Espere por favor','center','center',[245;245;245])
        Screen('Flip',winPointer);
        
        %waiting time in between blocks
        WaitSecs(Wait_time_between_blocks_s);
    end
        
end

WaitSecs(2);
if dummyMode_Eyelink
else 
    disp('Closing Eyelink...')
    stopAndCloseEyeLink
end
ListenChar(0);
sca


