% This function uses the Ideal gas law to get the temperature at every
% crank angle in the engine cycle

% INPUT: pressure and volume over engine cycle, total mass, mixed R 

% OUTPUT: temperature over every measured crank angle
%----------------------------------------------------------------------

function [Temp] = Temperature(p,V, mtot, Rmix)
Temp = (p .* V) ./ (mtot * Rmix); %Ideal gas law is assumed, because course info says it can be used for aROHR
end