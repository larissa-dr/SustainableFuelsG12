function [bsCO2] = bsCO2(mCO2, Power)
% bsCO2  : brake-specific CO2 emissions [kg/(W*s)]
% mCO2   : CO2 mass flow [kg/s] (output from CO2_massflow_from_fuel)
% Power  : engine brake power [W]

bsCO2 = mCO2 ./ Power;
end