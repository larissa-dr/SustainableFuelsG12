%% ---------------------------------------
%  NO WEIGHT IMEP/injection timing Comparison
%  ---------------------------------------
file = 'GTL_ManualData.xlsx';

M = LoadFuelData(file);

% Select emissions to include in the score
CO  = M(:,4);
CO2 = M(:,5);
HC  = M(:,6);
NOx = M(:,8);
FSN = M(:,10);

emissions = [CO CO2 HC NOx FSN];

% Substitute the rows corresponding with the to be analyzed IMEP
selectedRows = [3, 6, 9, 12]; %fill in manually

% Extract only the selected rows
emissionsSelected = emissions(selectedRows, :);

% Normalize each emission column
normEmissions = emissionsSelected ./ max(emissionsSelected);

% Compute the emission score
Score = sum(normEmissions, 2);

% Display results
disp('Normalized emission scores for selected rows:');
disp(Score);

[minScore, bestIndex] = min(Score);
fprintf('\nBest operating point among selected rows: Row %d --> Score = %.4f\n', ...
        selectedRows(bestIndex), minScore);

%% ---------------------------------------
%  WEIGHTED IMEP/injection timing Comparison
%  ---------------------------------------
% file = 'GTL_ManualData.xlsx';
% 
% M = LoadFuelData(file);
% 
% % Select emissions to include in the score
% CO  = M(:,4);
% CO2 = M(:,5);
% HC  = M(:,6);
% NOx = M(:,8);
% FSN = M(:,10);
% 
% emissions = [CO CO2 HC NOx FSN];
% 
% % Substitute the rows corresponding with the to be analyzed IMEP
% selectedRows = [3, 6, 9, 12]; %fill in manually
% 
% % Extract only the selected rows
% emissionsSelected = emissions(selectedRows, :);
% 
% % Normalize each emission column
% normEmissions = emissionsSelected ./ max(emissionsSelected);
% 
% % Compute the weighted emission score
% weights = [0.5 1.0 1.0 2.0 1.5];  % [CO CO2 HC NOx FSN]
% Score = sum(normEmissions .* weights, 2);
% 
% % Display results
% disp('Normalized emission scores for selected rows:');
% disp(Score);
% 
% [minScore, bestIndex] = min(Score);
% fprintf('\nBest operating point among selected rows: Row %d --> Score = %.4f\n', ...
%         selectedRows(bestIndex), minScore);

%% ---------------------------------------
%  WEIGHTED IMEP/injection timing Comparison for blends from other groups
%  ---------------------------------------
file = 'GTL50_ManualData.xlsx';

Z = LoadFuelD(file);

% Select emissions to include in the score
CO  = Z(:,4);
CO2 = Z(:,5);
HC  = Z(:,6);
NOx = Z(:,8);

emissions = [CO CO2 HC NOx];

% Substitute the rows corresponding with the to be analyzed IMEP
selectedRows = [12, 13, 14]; %fill in manually

% Extract only the selected rows
emissionsSelected = emissions(selectedRows, :);

% Normalize each emission column
normEmissions = emissionsSelected ./ max(emissionsSelected);

% Compute the weighted emission score
weights = [0.5 1.0 1.0 2.0];  % [CO CO2 HC NOx]
Score = sum(normEmissions .* weights, 2);

% Display results
disp('Normalized emission scores for selected rows:');
disp(Score);

[minScore, bestIndex] = min(Score);
fprintf('\nBest operating point among selected rows: Row %d --> Score = %.4f\n', ...
        selectedRows(bestIndex), minScore);

%% ---------------------------------------
%  Fuel Comparison
%  ---------------------------------------

% % Fuel names
% fuelNames = {'Diesel', 'HVO', 'GTL'};
% 
% % Emission labels
% emissionLabels = {'CO','CO2','HC','NOx','O2','Lambda','FSN'};
% 
% % Emission data matrix
% % Rows = fuels
% % Columns = emissions
% emissions = [
%     0.02  2.08 10  787  17.78 6.758 0.21;   % Fuel 1
%     0.02  2.79  9 1156  17.02 5.123 0.21;   % Fuel 2
%     0.01  3.97  9 1938  15.21 3.604 0.20    % Fuel 3
% ];
% 
% % Normalize each emission column independently
% normEmissions = emissions ./ max(emissions);
% 
% %  Plotting
% figure;
% bar(normEmissions','grouped');
% % Add labels
% set(gca,'XTickLabel', emissionLabels);
% ylabel('Normalized Emission (0–1)');
% title('Normalized Emissions Comparison Across Fuels');
% legend(fuelNames, 'Location', 'northoutside', 'Orientation', 'horizontal');
% % Improve readability
% xtickangle(45);
% grid on;

fuelFiles = {'Diesel_ManualData.xlsx', 'HVO_ManualData.xlsx', 'GTL_ManualData.xlsx'};
fuelNames = {'Diesel','HVO', 'GTL'};
numFuels = length(fuelFiles);

% Define the row numbers of the optimal IMEP/injection timing combination for each fuel
bestRows = [3, 12, 9];  % <- manually select these rows

% Preallocate matrix for emissions to compare
% Columns: CO, CO2, HC, NOx, FSN
comparisonMatrix = zeros(numFuels,5);

for i = 1:numFuels
    % Load fuel data
    fuelData = LoadFuelData(fuelFiles{i});

    % Extract the manually selected row
    r = bestRows(i);

    % Pick relevant emissions for comparison
    comparisonMatrix(i,:) = [fuelData(r,4), fuelData(r,5), fuelData(r,6), ...
                             fuelData(r,8), fuelData(r,10)];
end

% Emission labels for plotting
emissionLabels = {'CO','CO2','HC','NOx','FSN'};

% Normalize each emission column for plotting
normComparison = comparisonMatrix ./ max(comparisonMatrix);

% Create a bar plot
figure;
bar(normComparison','grouped');
set(gca,'XTickLabel',emissionLabels);
ylabel('Normalized Emission (0-1)');
title('Comparison Across Fuels for IMEP=3.5');
legend(fuelNames, 'Location', 'northoutside', 'Orientation', 'horizontal');
xtickangle(45);
grid on;

%% ---------------------------------------
%  Excel reading function
%  ---------------------------------------
function M = LoadFuelData(file)
% Reads one Excel file and returns a numeric matrix
% Output Matrix:
% [Injection_timing, IMEP, mass_flow, CO, CO2, HC, O2, NOx, Lambda, Mean_FS]

data = readtable(file);

Injection_timing = data.("InjectionTiming");
IMEP             = str2double(string(data.IMEP));
mass_flow        = str2double(string(data.("massFlow")));
CO               = str2double(string(data.CO));
CO2              = str2double(string(data.CO2));
HC               = data.HC;
O2               = str2double(string(data.O2));
NOx              = data.Nox;
Lambda           = data.Lambda;
Mean_FS          = str2double(string(data.("MeanValue_FSN_")));

M = [Injection_timing, IMEP, mass_flow, CO, CO2, HC, O2, NOx, Lambda, Mean_FS];
end

function Z = LoadFuelD(file)
% Reads one Excel file and returns a numeric matrix
% Output Matrix:
% [Injection_timing, IMEP, mass_flow, CO, CO2, HC, O2, NOx]

data = readtable(file);

Injection_timing = data.("InjectionTiming");
IMEP             = str2double(string(data.IMEP));
mass_flow        = str2double(string(data.("massFlow")));
CO               = str2double(string(data.CO));
CO2              = str2double(string(data.CO2));
HC               = data.HC;
O2               = str2double(string(data.O2));
NOx              = data.Nox;

Z = [Injection_timing, IMEP, mass_flow, CO, CO2, HC, O2, NOx];
end