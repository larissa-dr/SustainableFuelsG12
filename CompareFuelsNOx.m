%% CompareFuelsNOx
% NOx vs IMEP for HVO and B7 at different injection timings
% This script does NOT use ProcessingManualData.m

clc; clear; close all;

% --- Load data directly from the Excel files ---
HVO = readFuelFile('Data/HVO_ManualData.xlsx');        % HVO matrix
B7  = readFuelFile('Data/Diesel_ManualData.xlsx');     % B7 matrix (B7 diesel)

% Column indices in the matrix:
col_timing = 1;   % Injection timing [deg]
col_IMEP   = 2;   % IMEP
col_NOx    = 8;   % NOx

% --- Plot NOx vs IMEP for each timing, HVO vs B7 ---
figure;
hold on; grid on;

timings = unique(HVO(:, col_timing));   % all injection timings present
nTim = numel(timings);

colors = lines(nTim);
legendEntries = {};

for k = 1:nTim
    tim = timings(k);

    % rows for this injection timing
    idxH = HVO(:, col_timing) == tim;
    idxB = B7(:,  col_timing) == tim;

    baseColor  = colors(k,:);                         % darker (HVO)
    lightColor = baseColor + 0.4*(1 - baseColor);     % lighter (B7)

    % HVO: solid line, circles, darker
    plot(HVO(idxH, col_IMEP), HVO(idxH, col_NOx), ...
        'o-', 'Color', baseColor, 'LineWidth', 1.8, 'MarkerSize', 7);
    legendEntries{end+1} = sprintf('HVO %g°', tim);

    % B7: dashed line, crosses, lighter
    plot(B7(idxB, col_IMEP), B7(idxB, col_NOx), ...
        'x--', 'Color', lightColor, 'LineWidth', 1.8, 'MarkerSize', 7);
    legendEntries{end+1} = sprintf('B7 %g°', tim);
end

xlabel('IMEP');
ylabel('NOx');
title('NOx vs IMEP for HVO and B7 at different injection timings');
legend(legendEntries, 'Location', 'northwestoutside');
hold off;


%% -------- Local function (does the same job as ProcessingManualData, but only for this script) --------
function M = readFuelFile(file)
    % Read one of the *_ManualData.xlsx files and return numeric matrix
    % Columns: [Injection_timing, IMEP, mass_flow, CO, CO2, HC, O2, NOx, Lambda, Mean_FS]

    data = readtable(file);

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

    M = [Injection_timing, IMEP, mass_flow, CO, CO2, HC, ...
         O2, Nox, Lambda, Mean_FS];
end
