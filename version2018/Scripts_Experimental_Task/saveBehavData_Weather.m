function saveBehavData_Weather(data, data_filename)

% generate file name
datetimestr=GetCurrDateTime();

temp=regexp(datetimestr,'_','split');

data.info.timefinish=temp{4};

% write data
fileID = fopen([data_filename '.txt'],'w');
fprintf(fileID,'%s\t%s\r\n','Fecha (yyyy_mm_dd):',datetimestr(1:10));
fprintf(fileID,'%s\t%s\r\n','Hora inicio:',data.info.timestart);
fprintf(fileID,'%s\t%s\r\n','Hora fin:',temp{4});
fprintf(fileID,'%s\t%s\r\n','Tarea:', data.info.Task);
fprintf(fileID,'%s\t%s\r\n','Participante:',data.info.Subject_ID);
fprintf(fileID,'%s\t%s\r\n','Genero:',data.info.Subject_Gender);
fprintf(fileID,'%s\t%s\r\n','Edad:',data.info.Subject_Age);
% fprintf(fileID,'%s\t%s\r\n\r\n','Proyecto:', data.info.Project);



fprintf(fileID,'%s\t%s\t%s\t%s\t%s\r\n','Block','Stimulus', 'Performance','RT (s)');
fprintf(fileID,'%g\t%g\t%g\t%g\t%g\r\n',([data.vars.Block_dumm data.vars.Stim_seq data.vars.Perform_seq data.vars.RT_seq])');
% fprintf(fileID,'%.50s\r\n', data.info.txtPerf)
fprintf(fileID,'%s %s\r\n','======', '======');
fprintf(fileID,'%s\t%s\t%s\r\n','Stim','Tones','Weather');
for e=1:8
    fprintf(fileID,'%g\t%s\t%s\r\n',e, [data.info.Form_pairs{e,1} '-' data.info.Form_pairs{e,2} '-' data.info.Form_pairs{e,3}],...
        data.info.Weather{e});
end




fclose(fileID);

BehavData=data; %#ok<NASGU>
save([data_filename '.mat'],'BehavData')
