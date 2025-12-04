function [bsNOx] = bsNOx(mNOx, Power)
% bsNOx  : brake-specific NOx emissions [kg/(W*s)]
% mNOx   : NOx mass flow [kg/s] (output from NOx_massflow_from_fuel)
% Power  : engine brake power [W]

bsNOx = mNOx ./ Power;
end