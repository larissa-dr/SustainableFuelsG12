clear all; clc;


%% HVO FUEL PROPERTIES AND STOICHIOMETRIC CALCULATIONS

fprintf('=== HVO FUEL PROPERTIES AND STOICHIOMETRY ===\n');

% DEFINE THE FUEL TYPE AS HVO
fuelType = 'HVO';

% Atomic weights (kg/mol)
AM.C = 12.01e-3;
AM.H = 1.008e-3;
AM.O = 15.999e-3;
AM.N = 14.007e-3;
AM.S = 32.06e-3;

% Molecular weights for combustion products (kg/mol)
M_CO2 = AM.C + 2*AM.O;  % CO2: 44.009 g/mol
M_H2O = 2*AM.H + AM.O;  % H2O: 18.015 g/mol
M_O2 = 2*AM.O;          % O2: 31.998 g/mol
M_N2 = 2*AM.N;          % N2: 28.014 g/mol
M_air = 28.97e-3;       % Approximate molar mass of air

% Air composition by mass
Y_O2_air = 0.232;  % Mass fraction of O2 in air (23.2%)
Y_N2_air = 0.768;  % Mass fraction of N2 in air (76.8%)

% Resolve fuel formula - HVO only
switch upper(fuelType)
    case 'HVO'
        % Hydrotreated vegetable oil surrogate (oxygenated paraffin)
        nC = 18; nH = 34; nO = 2; nS = 0;
        formula = 'C18H34O2';
    otherwise
        % For simplicity, just use HVO
        nC = 18; nH = 34; nO = 2; nS = 0;
        formula = 'C18H34O2';
end

% Molar mass of fuel (kg/mol)
Mf = nC*AM.C + nH*AM.H + nO*AM.O + nS*AM.S;

% Mass fractions
wC = nC*AM.C / Mf;
wH = nH*AM.H / Mf;
wO = nO*AM.O / Mf;
wS = nS*AM.S / Mf;

% Dulong correlation (HHV in MJ/kg)
HHV_MJ_kg = 33.9*wC + 144.2*(wH - wO/8) + 9.4*wS;

% Convert to LHV by subtracting latent heat of water formation (at 25°C, 2.442 MJ/kg H2O)
LHV_MJ_kg = HHV_MJ_kg - 2.442*(9*wH);
LHV = LHV_MJ_kg * 1e6; % J/kg

% Store fuel properties in structure FP for later use
FP.Mf = Mf;
FP.nC = nC;
FP.nH = nH;
FP.nO = nO;
FP.nS = nS;
FP.LHV = LHV;
FP.formula = formula;

%% Stoichiometry calculations for HVO
% Stoichiometric O2 requirement per mol fuel
% CxHyOz + (x + y/4 - z/2) O2 -> x CO2 + y/2 H2O
nuO2 = nC + nH/4 - nO/2;

% Air composition (by mol): O2: 21%; N2: 78% -> N2/O2 ratio = 3.76
nuN2 = 3.76 * nuO2;

% Products per mol fuel at stoichiometric conditions
nuCO2 = nC;
nuH2O = nH/2;

% AFR_stoich by mass (kg_air/kg_fuel)
m_air_stoich = nuO2*M_O2 + nuN2*M_N2; % kg air per mol fuel
AFR_stoich = m_air_stoich / Mf;

% Display stoichiometric results
fprintf('Fuel formula: %s\n', formula);
fprintf('Molar mass: %.4f kg/mol\n', Mf);
fprintf('AFR_stoich = %.4f kg air / kg fuel\n', AFR_stoich);
fprintf('LHV: %.2f MJ/kg\n', LHV_MJ_kg);
fprintf('==========================================\n\n');


%% LAMBDA VALUES FROM THE TABLE (15 CASES)

fprintf('=== LAMBDA VALUES FROM EXPERIMENTAL DATA ===\n');

% Lambda values from the table (using . as decimal separator)
lambda_values = [
    7.099;  % Row 1
    4.806;  % Row 2
    3.586;  % Row 3
    7.156;  % Row 4
    4.629;  % Row 5
    3.650;  % Row 6
    6.840;  % Row 7
    4.843;  % Row 8
    3.774;  % Row 9
    6.698;  % Row 10
    4.837;  % Row 11
    3.536;  % Row 12
    6.782;  % Row 13
    4.582;  % Row 14
    3.478   % Row 15
];

% Additional parameters from table for reference
injection_timings = [18; 18; 18; 15; 15; 15; 12; 12; 12; 9; 9; 9; 6; 6; 6];
imep_values = [1.5; 2.5; 3.5; 1.5; 2.5; 3.5; 1.5; 2.5; 3.5; 1.5; 2.5; 3.5; 1.5; 2.5; 3.5];
mass_flow_values = [0.106; 0.155; 0.198; 0.105; 0.158; 0.195; 0.105; 0.154; 0.196; 0.109; 0.151; 0.202; 0.107; 0.161; 0.210];

fprintf('Number of test cases: %d\n', length(lambda_values));
fprintf('Lambda range: %.3f to %.3f\n', min(lambda_values), max(lambda_values));
fprintf('=============================================\n\n');


%% CALCULATE INLET AND EXIT MIXTURES FOR EACH LAMBDA

fprintf('=== INLET AND EXIT MIXTURE PROPERTIES FOR ALL LAMBDA VALUES ===\n\n');

% Initialize storage for results
n_cases = length(lambda_values);
results = struct();

% Calculate for each lambda value
for i = 1:n_cases
    Lambda = lambda_values(i);
    
    %% --- 1. INLET MIXTURE (Fuel + Air) ---
    % Actual AFR based on lambda
    AFR_actual = Lambda * AFR_stoich;
    
    % Mass of Fuel and Air (basis: 1 kg of fuel)
    m_fuel = 1;                     % Basis: 1 kg of fuel
    m_air = AFR_actual;             % Mass of air for that 1 kg fuel
    m_total_in = m_fuel + m_air;
    
    % Mass fractions in inlet
    Y_fuel_in = m_fuel / m_total_in;
    Y_air_in  = m_air  / m_total_in;
    
    % Mass fractions of O2 and N2 from air
    m_O2_air = m_air * Y_O2_air;  % kg O2 from air
    m_N2_air = m_air * Y_N2_air;  % kg N2 from air
    
    % Calculate elemental masses in 1 kg of HVO fuel
    m_C_fuel = wC;   % kg C in 1 kg fuel
    m_H_fuel = wH;   % kg H in 1 kg fuel
    m_O_fuel = wO;   % kg O in 1 kg fuel
    
    % O2 required to burn C to CO2 (per kg fuel)
    % C + O2 → CO2: 12.01 kg C requires 32 kg O2
    O2_for_C = m_C_fuel * (M_O2 / AM.C);
    
    % O2 required to burn H to H2O (per kg fuel)
    % 2H2 + O2 → 2H2O: 4.032 kg H requires 32 kg O2
    O2_for_H = m_H_fuel * (M_O2 / (4*AM.H));
    
    % O2 already available in fuel
    O2_in_fuel = m_O_fuel;
    
    % Net O2 required from air for stoichiometric combustion
    O2_required_stoich = O2_for_C + O2_for_H - O2_in_fuel;
    
    Y_O2_in_actual = m_O2_air / m_total_in;
    Y_N2_in_actual = m_N2_air / m_total_in;

    Y_CO2_in_actual = 0;  % No CO2 in inlet (unless EGR)
    Y_H2O_in_actual = 0;  % No H2O in inlet (unless humid air)
    
    % Total inlet mass fractions (should sum to 1)
    Y_total_in_check = Y_O2_in_actual + Y_N2_in_actual + Y_CO2_in_actual + Y_H2O_in_actual;
    
    % For 1 kg of fuel, complete combustion produces:
    mass_CO2_per_kg_fuel = nuCO2 * M_CO2 / Mf;
    mass_H2O_per_kg_fuel = nuH2O * M_H2O / Mf;
    
    % For lean combustion (Lambda > 1), there is excess O2 and all N2 goes through
    if Lambda >= 1
        excess_O2_moles = (Lambda - 1) * nuO2;
        total_N2_moles = Lambda * nuN2;
    else
        % Rich combustion (Lambda < 1) - simplified
        excess_O2_moles = 0;
        total_N2_moles = Lambda * nuN2;
    end
    
    mass_excess_O2_per_kg_fuel = excess_O2_moles * M_O2 / Mf;
    mass_total_N2_per_kg_fuel = total_N2_moles * M_N2 / Mf;
    
    % Total mass of products per kg of fuel
    m_products_per_kg_fuel = mass_CO2_per_kg_fuel + mass_H2O_per_kg_fuel + ...
                             mass_total_N2_per_kg_fuel + mass_excess_O2_per_kg_fuel;
    
    % Mass fractions in exit mixture
    Y_CO2_out = mass_CO2_per_kg_fuel / m_products_per_kg_fuel;
    Y_H2O_out = mass_H2O_per_kg_fuel / m_products_per_kg_fuel;
    Y_N2_out = mass_total_N2_per_kg_fuel / m_products_per_kg_fuel;
    Y_O2_out = mass_excess_O2_per_kg_fuel / m_products_per_kg_fuel;
    
    % Calculate molar masses and mole fractions for exit mixture
    moles_CO2 = mass_CO2_per_kg_fuel / M_CO2;
    moles_H2O = mass_H2O_per_kg_fuel / M_H2O;
    moles_N2 = mass_total_N2_per_kg_fuel / M_N2;
    moles_O2 = mass_excess_O2_per_kg_fuel / M_O2;
    total_moles_out = moles_CO2 + moles_H2O + moles_N2 + moles_O2;
    
    M_out = m_products_per_kg_fuel / total_moles_out;
    
    % Mole fractions for exit mixture
    X_CO2_out = moles_CO2 / total_moles_out;
    X_H2O_out = moles_H2O / total_moles_out;
    X_N2_out = moles_N2 / total_moles_out;
    X_O2_out = moles_O2 / total_moles_out;
    
    %% --- CREATE NASA-COMPATIBLE ARRAYS ---
    % Order: [O2, N2, CO2, H2O]
    
    % NASA-compatible mass fractions
    NASA_in_mass = [Y_O2_in_actual, Y_N2_in_actual, Y_CO2_in_actual, Y_H2O_in_actual];
    NASA_out_mass = [Y_O2_out, Y_N2_out, Y_CO2_out, Y_H2O_out];
    
    % NASA-compatible mole fractions
    % For inlet: Since we only have O2 and N2
    total_moles_in_NASA = (Y_O2_in_actual/M_O2) + (Y_N2_in_actual/M_N2) + ...
                          (Y_CO2_in_actual/M_CO2) + (Y_H2O_in_actual/M_H2O);
    X_O2_in = (Y_O2_in_actual/M_O2) / total_moles_in_NASA;
    X_N2_in = (Y_N2_in_actual/M_N2) / total_moles_in_NASA;
    X_CO2_in = (Y_CO2_in_actual/M_CO2) / total_moles_in_NASA;
    X_H2O_in = (Y_H2O_in_actual/M_H2O) / total_moles_in_NASA;
    
    NASA_in_mole = [X_O2_in, X_N2_in, X_CO2_in, X_H2O_in];
    NASA_out_mole = [X_O2_out, X_N2_out, X_CO2_out, X_H2O_out];
    
    % Store results for this case
    results(i).lambda = Lambda;
    results(i).AFR_actual = AFR_actual;
    results(i).injection_timing = injection_timings(i);
    results(i).imep = imep_values(i);
    results(i).mass_flow = mass_flow_values(i);
    
    % Store NASA-compatible arrays
    results(i).NASA_in_mass = NASA_in_mass;
    results(i).NASA_out_mass = NASA_out_mass;
    results(i).NASA_in_mole = NASA_in_mole;
    results(i).NASA_out_mole = NASA_out_mole;
    
    % Store additional properties
    results(i).Y_fuel_in = Y_fuel_in;
    results(i).Y_air_in = Y_air_in;
    results(i).M_out = M_out;
    
    %% Display results for this case
    fprintf('CASE %2d: Inj=%d°, IMEP=%.1f bar, λ=%.3f\n', ...
        i, injection_timings(i), imep_values(i), Lambda);
    fprintf('  Actual AFR: %.2f kg air/kg fuel\n', AFR_actual);
    
    fprintf('  --- NASA-COMPATIBLE INLET ARRAY (before combustion) ---\n');
    fprintf('    Mass fractions: O2=%.6f, N2=%.6f, CO2=%.6f, H2O=%.6f\n', ...
        NASA_in_mass(1), NASA_in_mass(2), NASA_in_mass(3), NASA_in_mass(4));
    fprintf('    Mole fractions: O2=%.6f, N2=%.6f, CO2=%.6f, H2O=%.6f\n', ...
        NASA_in_mole(1), NASA_in_mole(2), NASA_in_mole(3), NASA_in_mole(4));
    
    fprintf('  --- NASA-COMPATIBLE EXIT ARRAY (after combustion) ---\n');
    fprintf('    Mass fractions: O2=%.6f, N2=%.6f, CO2=%.6f, H2O=%.6f\n', ...
        NASA_out_mass(1), NASA_out_mass(2), NASA_out_mass(3), NASA_out_mass(4));
    fprintf('    Mole fractions: O2=%.6f, N2=%.6f, CO2=%.6f, H2O=%.6f\n', ...
        NASA_out_mole(1), NASA_out_mole(2), NASA_out_mole(3), NASA_out_mole(4));
    fprintf('    Exit molar mass: %.5f kg/mol\n', M_out);
    fprintf('\n');
end


%% DISPLAY ALL NASA-COMPATIBLE ARRAYS

fprintf('=== ALL NASA-COMPATIBLE ARRAYS FOR USE WITH NASA POLYNOMIALS ===\n\n');
fprintf('Format: [O2, N2, CO2, H2O]\n\n');

fprintf('%-6s %-8s %-45s %-45s\n', 'Case', 'Lambda', 'Inlet Mass Fractions', 'Exit Mass Fractions');
fprintf('%-6s %-8s %-45s %-45s\n', '', '', '[O2, N2, CO2, H2O]', '[O2, N2, CO2, H2O]');
fprintf('%s\n', repmat('-', 1, 110));

for i = 1:n_cases
    fprintf('%-6d %-8.3f [%.6f, %.6f, %.6f, %.6f]  [%.6f, %.6f, %.6f, %.6f]\n', ...
        i, results(i).lambda, ...
        results(i).NASA_in_mass(1), results(i).NASA_in_mass(2), ...
        results(i).NASA_in_mass(3), results(i).NASA_in_mass(4), ...
        results(i).NASA_out_mass(1), results(i).NASA_out_mass(2), ...
        results(i).NASA_out_mass(3), results(i).NASA_out_mass(4));
end

fprintf('\n\n');
fprintf('%-6s %-8s %-45s %-45s\n', 'Case', 'Lambda', 'Inlet Mole Fractions', 'Exit Mole Fractions');
fprintf('%-6s %-8s %-45s %-45s\n', '', '', '[O2, N2, CO2, H2O]', '[O2, N2, CO2, H2O]');
fprintf('%s\n', repmat('-', 1, 110));

for i = 1:n_cases
    fprintf('%-6d %-8.3f [%.6f, %.6f, %.6f, %.6f]  [%.6f, %.6f, %.6f, %.6f]\n', ...
        i, results(i).lambda, ...
        results(i).NASA_in_mole(1), results(i).NASA_in_mole(2), ...
        results(i).NASA_in_mole(3), results(i).NASA_in_mole(4), ...
        results(i).NASA_out_mole(1), results(i).NASA_out_mole(2), ...
        results(i).NASA_out_mole(3), results(i).NASA_out_mole(4));
end



%% EXPORT NASA-COMPATIBLE DATA

% Initialize arrays for table data
NASA_in_mass_O2 = zeros(n_cases, 1);
NASA_in_mass_N2 = zeros(n_cases, 1);
NASA_in_mass_CO2 = zeros(n_cases, 1);
NASA_in_mass_H2O = zeros(n_cases, 1);
NASA_in_mole_O2 = zeros(n_cases, 1);
NASA_in_mole_N2 = zeros(n_cases, 1);
NASA_in_mole_CO2 = zeros(n_cases, 1);
NASA_in_mole_H2O = zeros(n_cases, 1);
NASA_out_mass_O2 = zeros(n_cases, 1);
NASA_out_mass_N2 = zeros(n_cases, 1);
NASA_out_mass_CO2 = zeros(n_cases, 1);
NASA_out_mass_H2O = zeros(n_cases, 1);
NASA_out_mole_O2 = zeros(n_cases, 1);
NASA_out_mole_N2 = zeros(n_cases, 1);
NASA_out_mole_CO2 = zeros(n_cases, 1);
NASA_out_mole_H2O = zeros(n_cases, 1);

% Extract data from structure
for j = 1:n_cases
    NASA_in_mass_O2(j) = results(j).NASA_in_mass(1);
    NASA_in_mass_N2(j) = results(j).NASA_in_mass(2);
    NASA_in_mass_CO2(j) = results(j).NASA_in_mass(3);
    NASA_in_mass_H2O(j) = results(j).NASA_in_mass(4);
    
    NASA_in_mole_O2(j) = results(j).NASA_in_mole(1);
    NASA_in_mole_N2(j) = results(j).NASA_in_mole(2);
    NASA_in_mole_CO2(j) = results(j).NASA_in_mole(3);
    NASA_in_mole_H2O(j) = results(j).NASA_in_mole(4);
    
    NASA_out_mass_O2(j) = results(j).NASA_out_mass(1);
    NASA_out_mass_N2(j) = results(j).NASA_out_mass(2);
    NASA_out_mass_CO2(j) = results(j).NASA_out_mass(3);
    NASA_out_mass_H2O(j) = results(j).NASA_out_mass(4);
    
    NASA_out_mole_O2(j) = results(j).NASA_out_mole(1);
    NASA_out_mole_N2(j) = results(j).NASA_out_mole(2);
    NASA_out_mole_CO2(j) = results(j).NASA_out_mole(3);
    NASA_out_mole_H2O(j) = results(j).NASA_out_mole(4);
end

% Create a comprehensive table for export
T = table(...
    injection_timings, ...
    imep_values, ...
    lambda_values, ...
    [results.AFR_actual]', ...
    [results.Y_fuel_in]', ...
    [results.Y_air_in]', ...
    NASA_in_mass_O2, ...
    NASA_in_mass_N2, ...
    NASA_in_mass_CO2, ...
    NASA_in_mass_H2O, ...
    NASA_in_mole_O2, ...
    NASA_in_mole_N2, ...
    NASA_in_mole_CO2, ...
    NASA_in_mole_H2O, ...
    NASA_out_mass_O2, ...
    NASA_out_mass_N2, ...
    NASA_out_mass_CO2, ...
    NASA_out_mass_H2O, ...
    NASA_out_mole_O2, ...
    NASA_out_mole_N2, ...
    NASA_out_mole_CO2, ...
    NASA_out_mole_H2O, ...
    [results.M_out]', ...
    'VariableNames', {...
    'Injection_Timing_deg', ...
    'IMEP_bar', ...
    'Lambda', ...
    'AFR_actual_kg_air_per_kg_fuel', ...
    'Y_fuel_in', ...
    'Y_air_in', ...
    'NASA_in_mass_O2', ...
    'NASA_in_mass_N2', ...
    'NASA_in_mass_CO2', ...
    'NASA_in_mass_H2O', ...
    'NASA_in_mole_O2', ...
    'NASA_in_mole_N2', ...
    'NASA_in_mole_CO2', ...
    'NASA_in_mole_H2O', ...
    'NASA_out_mass_O2', ...
    'NASA_out_mass_N2', ...
    'NASA_out_mass_CO2', ...
    'NASA_out_mass_H2O', ...
    'NASA_out_mole_O2', ...
    'NASA_out_mole_N2', ...
    'NASA_out_mole_CO2', ...
    'NASA_out_mole_H2O', ...
    'M_out_kg_mol'});

% Write to CSV file
writetable(T, 'HVO_NASA_arrays_complete.csv');
