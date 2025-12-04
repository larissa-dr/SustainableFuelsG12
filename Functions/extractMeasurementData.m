function measurements = extractMeasurementData(filename)

T = readtable(filename);

% detect column names
colNames = T.Properties.VariableNames;

% identify columns
measCol  = colNames{1};   % first column is measurement number
dataCols = colNames(2:end); % rest of the columns are data

measList = unique(T.(measCol)); % unique measurement numbers

measurements = struct; % create empty struct array

% loop through each measurement
for i = 1:length(measList)
    m = measList(i);
    
    rows = T.(measCol) == m; % select rows for this measurement
    
    for d = 1:length(dataCols)
        measurements(i).(dataCols{d}) = T{rows, dataCols{d}};
    end
    
    measurements(i).measurement = m; % store measurement ID
end

end