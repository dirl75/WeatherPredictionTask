StrategyData=readtable('WeatherPred_2019-2023_StrategiesByParticip.xlsx',...
    'Sheet','ALL_DATA');

ST=StrategyData.STRATEGY;
Scores_Last2Blocks=StrategyData.last_two;
temp_IDs=StrategyData.PARTICIP;
Scores_ByStrategy=nan(6,1);
pnames=cell(1,1);
c=0;
for j=1:6:size(Scores_Last2Blocks,1)
    win=j:j+5;
    c=c+1;
    pnames{c}=unique(temp_IDs(win));
    Scores_ByStrategy(:,c)=Scores_Last2Blocks(win);

end

%get block performance 
BlocksMean_perf_Strategy=nan(size(BlocksMean_perf));
for j=1:numel(pnames)
    currID1=pnames{j}{1,1}(1:2);
    
    where=strcmp(currID1,particip_IDs);
    
    BlocksMean_perf_Strategy(:,j)=BlocksMean_perf(:,where);
end


Strategy_Code=(1:6)';
Strategy_Description={'Spatial + non-spatial associative';...
    'Single shape';...
    'Single position';...
    'Non-spatial associative + random';...
    'Spatial associative + random';...
    'Random'};

% Combine the variables into a single data matrix/cell array for the table
tableData = [num2cell(Strategy_Code), Strategy_Description];

% Define column headers
columnNames = {'Strategy Code', 'Strategy Description'};

disp(' ############# done importing strategies data')

%%

