function mNOx = NOx_massflow_from_fuel(NOx_ppm, mdot_fuel_gps)
% calculates NOx mass flow from fuel mass flow and NOx concentration

%  parameters
AFR     = 14.5;       % air to fuel ratio
MW_exh  = 29e-3;      % molecular weight of exhaust 
MW_NOx  = 46e-3;      % molecular weight of NOx (NO + NO2)

% Convert fuel mass flow to kg/s
mdot_fuel = mdot_fuel_gps / 1000;

% Estimate exhaust mass flow
mdot_air = AFR * mdot_fuel;
mexh = mdot_air + mdot_fuel;

% Convert NOx ppm → mole fraction
xNOx = NOx_ppm * 1e-6;

% Convert mole fraction → mass fraction
YNOx = xNOx * (MW_NOx / MW_exh);

% Compute NOx mass flow
mNOx = YNOx * mexh;
end