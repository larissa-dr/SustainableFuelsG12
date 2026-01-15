% Calculates IMEP based on pressure and volume measurements

% INPUTs: 
%   pi (pressure over a chosen cycle i)
%   V (volume over crank angle)

% OUTPUT: 
%   IMEP
%----------------------------------------------------------------------

function [IMEP] = IMEP(pi, V)
W = trapz(V, pi);
Vd = V(end) - V(1);
IMEP = W/Vd;
end