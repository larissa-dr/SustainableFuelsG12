%% 1. Setup and Constants
clear; clc; close all;

% ENGINE GEOMETRY ( values from Project Handbook)
Bore_mm   = 104;    %  Cylinder Bore in mm
Stroke_mm = 85;    %  Stroke length in mm
ConRod_mm = 136.5;    %  Connecting Rod length in mm
CompressionRatio = 21.5; % 

RPM = 1500;         % Fixed value
LHV_HVO = 43800;    % Lower Heating Value (kJ/kg)

% Derived Geometry
B = Bore_mm / 1000; % Convert to meters
S = Stroke_mm / 1000;
R = S / 2;          % Crank Radius
L = ConRod_mm / 1000;
V_disp = (pi * B^2 / 4) * S; % Displacement Volume (in m3)
V_clearance = V_disp / (CompressionRatio - 1);

% DATA LOADING SETUP
folderPath = 'Extracted_Data'; % here you indicate the path
sdaqFiles = dir(fullfile(folderPath, '**', '*sdaq*')); 
sdaqFiles = sdaqFiles(~startsWith({sdaqFiles.name}, '._'));

HVO_Results = struct();

%% 2. Processing Loop
fprintf('Processing %d tests...\n', length(sdaqFiles));

for i = 1:length(sdaqFiles)
    
    
    sdaqName = sdaqFiles(i).name;
    parts = split(sdaqName, '_');   %this splits the file names at the "_" symbol
                                     
  
    try
        Timing = str2double(parts{3});
        Target_IMEP = str2double(parts{4});
    catch
        Timing = NaN; Target_IMEP = NaN;
    end
    
    % Loads SDAQ (Slow Data) ---
    sdaqPath = fullfile(sdaqFiles(i).folder, sdaqName);
    sdaqData = readmatrix(sdaqPath, 'FileType', 'text');
    
    % SDAQ Columns: 
    % 1: Fuel (g/s), 2: T_in, 3: T_ex, 4: P_in (bar_a)
    if isempty(sdaqData), continue; end
    
    FuelFlow_gs = mean(sdaqData(:,1));
    P_intake_abs = mean(sdaqData(:,4)); % We need this for PEGGING
    
    % Load FDAQ (Fast Data)
    fdaqName = strrep(sdaqName, 'sdaq', 'fdaq');
    fdaqPath = fullfile(sdaqFiles(i).folder, fdaqName);
    
    if ~exist(fdaqPath, 'file')
        warning('No FDAQ for %s', sdaqName);
        continue;
    end
    
    fdaqData = readmatrix(fdaqPath, 'FileType', 'text');
    
    % FDAQ Columns: 1: CA, 2: Pressure(raw), 3: Current
    % Data is 100 cycles stacked vertically.
    % Resolution 0.2 CA -> 3600 points per 720 degree cycle
    pointsPerCycle = 3600;
    
    % Extract Raw Pressure Vector
    P_raw_vec = fdaqData(:, 2);
    
    % Reshape into Matrix [3600 rows x 100 columns
    numCycles = floor(length(P_raw_vec) / pointsPerCycle);
    if numCycles < 1, continue; end
    
    P_matrix_raw = reshape(P_raw_vec(1:pointsPerCycle*numCycles), pointsPerCycle, numCycles);
    
    % Extract Crank Angle vector (just one cycle's worth is needed for calc)
    CA_vector = fdaqData(1:pointsPerCycle, 1); 
    
    % PEGGING THE PRESSURE ---
    % At BDC Intake (-180 deg), Cyl Pressure = Intake Manifold Pressure
    % Find index where CA is closest to -180
    [~, idx_peg] = min(abs(CA_vector - (-180)));
    
    % Calculate Offset for each cycle
    % Offset = Known_Pressure - Measured_Pressure_at_Ref_Point
    Offsets = P_intake_abs - P_matrix_raw(idx_peg, :);
    
    % Apply Offset to entire matrix
    P_matrix_pegged = P_matrix_raw + Offsets;
    
    % Average over 100 cycles for a "Representative Trace"
    P_avg = mean(P_matrix_pegged, 2); % Average pressure trace
    
    % CALCULATE IMEP (Indicated Mean Effective Pressure) 
    % 1. Calculate Cylinder Volume at every CA step
    theta_rad = deg2rad(CA_vector);
    
    % Slider-Crank Formula for Volume
    term1 = R * (1 - cos(theta_rad));
    term2 = sqrt(L^2 - R^2 * sin(theta_rad).^2);
    s_dist = term1 + L - term2; % Piston distance from TDC
    
    V_inst = V_clearance + (pi * B^2 / 4) .* s_dist;
    
    % 2. Integrate P dV to get Indicated Work (Joules) per cycle
    % Convert Pressure bar -> Pascal (1 bar = 100,000 Pa)
    Work_Indicated_J = trapz(V_inst, P_avg * 1e5); 
    
    % 3. Calculate IMEP (bar)
    % IMEP = Work / Displacement
    Calculated_IMEP_bar = (Work_Indicated_J / V_disp) / 1e5;
    
    % --- F. CALCULATE EFFICIENCY (Indicated Thermal Efficiency - ITE) ---
    % Power_Ind (kW) = Work (J/cycle) * (RPM / 60) * (1/2 for 4-stroke) / 1000
    Power_Ind_kW = Work_Indicated_J * (RPM / 120) / 1000;
    
    % Fuel Energy (kW) = MassFlow (g/s) / 1000 * LHV (kJ/kg)
    Fuel_Energy_kW = (FuelFlow_gs / 1000) * LHV_HVO;
    
    ITE_Percent = (Power_Ind_kW / Fuel_Energy_kW) * 100;
    
    %  STORE RESULTS 
    HVO_Results(i).Name = sdaqName;
    HVO_Results(i).Timing = Timing;
    HVO_Results(i).Target_IMEP = Target_IMEP;
    HVO_Results(i).Calc_IMEP = Calculated_IMEP_bar;
    HVO_Results(i).ITE = ITE_Percent;
    HVO_Results(i).P_trace = P_avg; % Store the trace for plotting later
    HVO_Results(i).CA = CA_vector;

    fprintf('Processed: IMEP %.1f | Timing %d | Calc IMEP: %.2f bar | ITE: %.2f%%\n', ...
        Target_IMEP, Timing, Calculated_IMEP_bar, ITE_Percent);
end

%% 3. Visualization
% Plot Efficiency vs Timing for different Loads
timings = [HVO_Results.Timing];
ites = [HVO_Results.ITE];
imeps = [HVO_Results.Target_IMEP];

figure;
scatter(timings, ites, 100, imeps, 'filled');
colorbar; ylabel(colorbar, 'Target IMEP (bar)');
colormap(jet);
xlabel('Injection Timing (deg BTDC)');
ylabel('Indicated Thermal Efficiency (%)');
title('HVO Combustion Efficiency (ITE)');
grid on;

%% 4. Advanced Visualization: Efficiency Contour Map

% Extract vectors
timings = [HVO_Results.Timing];
imeps   = [HVO_Results.Calc_IMEP]; % Use Calculated IMEP for accuracy
ites    = [HVO_Results.ITE];

% 1. Create a Grid for the Contour Plot
% We create a mesh of 100x100 points to make the lines smooth
timing_range = linspace(min(timings), max(timings), 100);
imep_range   = linspace(min(imeps), max(imeps), 100);
[grid_T, grid_I] = meshgrid(timing_range, imep_range);

% 2. Interpolate the scattered data onto the grid
% 'natural' interpolation works well for engine maps
F = scatteredInterpolant(timings', imeps', ites', 'natural');
grid_ITE = F(grid_T, grid_I);

% 3. Generate the Contour Plot
figure('Color', 'w');
[C, h] = contourf(grid_T, grid_I, grid_ITE, 20); % 20 levels of color
clabel(C, h, 'FontSize', 10, 'Color', 'k'); % Label the lines
colormap(jet);
c = colorbar;
ylabel(c, 'Indicated Thermal Efficiency (%)', 'FontSize', 12);

hold on;
% Plot original data points as black dots so you know where you actually tested
plot(timings, imeps, 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 5);

% 4. Find and Plot the "Sweet Spots" (Max Efficiency per Load)
unique_Loads = unique(round([HVO_Results.Target_IMEP]*2)/2); % Round to nearest 0.5

fprintf('\n--- OPTIMAL SETTINGS FOR HVO ---\n');

for k = 1:length(unique_Loads)
    target = unique_Loads(k);
    
    % Find indices that match this target load (roughly)
    % We accept a tolerance of +/- 0.2 bar
    idx = find(abs([HVO_Results.Target_IMEP] - target) < 0.2);
    
    if ~isempty(idx)
        % Get data for this load line
        local_timings = [HVO_Results(idx).Timing];
        local_ite     = [HVO_Results(idx).ITE];
        
        % Find Max
        [max_ite, max_idx] = max(local_ite);
        best_timing = local_timings(max_idx);
        
        % Plot a Red Star at the best point
        plot(best_timing, [HVO_Results(idx(max_idx)).Calc_IMEP], 'rp', ...
            'MarkerFaceColor', 'r', 'MarkerSize', 15);
        
        fprintf('Load %.1f Bar: Best Timing = %d deg BTDC (Efficiency: %.2f%%)\n', ...
            target, best_timing, max_ite);
    end
end

xlabel('Injection Timing (deg BTDC)', 'FontSize', 12);
ylabel('IMEP (bar)', 'FontSize', 12);
title('HVO Efficiency Map (Iso-Efficiency Contours)', 'FontSize', 14);
grid on;
set(gca, 'XDir', 'reverse'); % Engine maps usually have timing going 20 -> 0 left to right
hold off;