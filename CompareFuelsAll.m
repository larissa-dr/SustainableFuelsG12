function CompareFuelsAll
% Compare HVO and B7 for several emissions at different Injection Timings
% Uses the manual data Excel files in the Data folder (NOT THE ProcessingManualData.m).

%% --- Loading the data ---
HVO = LoadFuelData('Data/HVO_ManualData.xlsx');      % HVO matrix
B7  = LoadFuelData('Data/Diesel_ManualData.xlsx');   % B7 matrix

% Column indices in the matrix:
% 1: Injection_timing
% 2: IMEP
% 3: mass_flow
% 4: CO
% 5: CO2
% 6: HC
% 7: O2
% 8: NOx
% 9: Lambda
% 10: Mean_FS (FSN)

%% --- List of pollutants to plot ---
pollutants = { ...
    'NOx',     8, 'NOx vs IMEP for HVO and B7'; ...
    'CO',      4, 'CO vs IMEP for HVO and B7'; ...
    'CO₂',     5, 'CO₂ vs IMEP for HVO and B7'; ...
    'HC',      6, 'HC vs IMEP for HVO and B7'; ...
    'FSN',    10, 'Mean FSN vs IMEP for HVO and B7' ...
    };

% Loop over all pollutants and make one figure for each
for p = 1:size(pollutants,1)
    yLabel  = pollutants{p,1};
    colY    = pollutants{p,2};
    ttl     = pollutants{p,3};

    PlotPollutant(HVO, B7, colY, yLabel, ttl);
end

end  


%% ======================================================================
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


%% ======================================================================
function PlotPollutant(HVO, B7, colY, yLabel, ttl)
% Makes one figure for a given pollutant (column colY)
col_timing = 1;   % injection timing column
col_IMEP   = 2;   % IMEP column

figure('Name', yLabel); hold on; grid on;

timings = unique(HVO(:, col_timing));
nTim    = numel(timings);

colors = lines(nTim);
legendEntries = {};

for k = 1:nTim
    tim = timings(k);

    idxH = HVO(:, col_timing) == tim;
    idxB = B7(:,  col_timing) == tim;

    baseColor = colors(k,:);

    % HVO: solid, darker color
    plot(HVO(idxH, col_IMEP), HVO(idxH, colY), ...
        'o-', 'Color', baseColor, ...
        'LineWidth', 2, 'MarkerSize', 7);
    legendEntries{end+1} = sprintf('HVO %g°', tim);

    % B7: dashed, lighter version of same color
    lightColor = 0.5 + 0.5 * baseColor;
    plot(B7(idxB, col_IMEP), B7(idxB, colY), ...
        'x--', 'Color', lightColor, ...
        'LineWidth', 2, 'MarkerSize', 7);
    legendEntries{end+1} = sprintf('B7 %g°', tim);
end

xlabel('IMEP');
ylabel(yLabel);
title(ttl);
legend(legendEntries, 'Location', 'northwestoutside');

hold off;
end
