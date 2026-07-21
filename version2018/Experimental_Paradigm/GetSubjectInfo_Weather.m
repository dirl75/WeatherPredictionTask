function subInfo=GetSubjectInfo_Weather
%%
tit='Ingrese Informacion';
instrBox={'\fontsize{15} ID del participante','\fontsize{15} Genero (F o M)','\fontsize{15} Edad (anios)',...
    '\fontsize{15} Investigador a cargo del registro'};
opt.Resize='on';
opt.WindowStyle='normal';
% opt.WindowSize=100;
opt.Interpreter='tex';
wSize=repmat([1 50],size(instrBox,3),1);
defaultInfo={'Nombre y Apellido','F','18','Soledad Aspe'};

subInfo=struct;
% write info
instrBox2=horzcat(instrBox,{'Fecha','LocalHost'});
for ii=1:numel(instrBox2)
    subInfo.id{ii,1}=instrBox2{ii};
end

subInfo.data=inputdlg(instrBox,tit,wSize,defaultInfo,opt);

% append date
rn=size(subInfo.data,1);
datetimestr=GetCurrDateTime();
subInfo.data{rn+1}=datetimestr;


% append computer info
% computerInfo=Screen('Computer');
[~,host]=system('hostname');
rn=size(subInfo.data,1);
subInfo.data{rn+1}=host;
% subInfo.data{rn+2}=computerInfo.processUserShortName;
% subInfo.data{rn+3}=computerInfo.localHostName;
end