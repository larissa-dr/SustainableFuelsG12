% load the file
file = 'HVO_ManualData.xlsx';   % change 'Diesel' to other fuels

% Automatically extract fuel name from filename
[~, fuelName, ~] = fileparts(file);
fuelName = extractBefore(fuelName, "_");
disp(['Fuel: ', fuelName]);

data = readtable(file);

% extracting each column into separate variables:
Injection_timing = data.("InjectionTiming");
IMEP            = str2double(string(data.IMEP));
mass_flow       = str2double(string(data.("massFlow")));
CO              = str2double(string(data.CO));
CO2             = str2double(string(data.CO2));
HC              = data.HC;
O2              = str2double(string(data.O2));
Nox             = data.Nox;
Lambda          = data.Lambda;
Mean_FS         = str2double(string(data.("MeanValue_FSN_")));

% Creating a matrix with all data for one fuel
allData = [Injection_timing, IMEP, mass_flow, CO, CO2, HC, O2, Nox, Lambda, Mean_FS]

% Create a variable with the same name as fuelName
eval([fuelName ' = allData;']);

% Test
disp(['Matrix "' fuelName '" created with size: ' num2str(size(eval(fuelName)))]);


% =======================================================================
% plotting data for fun

vars = {mass_flow, CO, CO2, HC, O2, Nox, Lambda, Mean_FS};
varNames = {"Mass flow", "CO", "CO₂", "HC", "O₂", "NOx", "Lambda", "FSN"};

vars_norm = cellfun(@(x) (x - min(x)) / (max(x) - min(x)), vars, 'UniformOutput', false); % normalizing variables so they all fit on one graph

figure('Position',[200 100 1200 500]);

subplot(1,2,1); hold on; % plotting against IMEP
for i = 1:numel(vars_norm)
    plot(IMEP, vars_norm{i}, 'o-', 'DisplayName', varNames{i});
end
xlabel('IMEP');
ylabel('Normalized Values');
title('Variables vs IMEP (Normalized)');
legend('show'); grid on; hold off;

subplot(1,2,2); hold on; % plotting against injection timing
for i = 1:numel(vars_norm)
    plot(Injection_timing, vars_norm{i}, 'o-', 'DisplayName', varNames{i});
end
xlabel('Injection Timing');
ylabel('Normalized Values');
title('Variables vs Injection Timing (Normalized)');
legend('show'); grid on; hold off;
