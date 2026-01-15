% Calculates indicated power over cycle

% INPUTS: 
%   Cylinder pressure array [Pa]
%   Cylinder volume array [m^3]
%   Engine speed [rev/min]
%   Number of cylinders

% OUTPUT:
%   Work done per cylinder per cycle [J]
%   Total indicated power [W]
%----------------------------------------------------------------------

function [IP, Wcycle] = CalcIndicatedPower(p_cycle, V, EngineRPM, N_cyl)
% work per cycle by integrating p dV
Wcycle = trapz(V, p_cycle);   % J = Pa*m^3

% engine cycles per second (for 4-stroke engine)
cycles_per_sec = (EngineRPM/60) / 2;

% indicated power per cylinder
IP_per_cyl = Wcycle * cycles_per_sec;

% total indicated power
IP = IP_per_cyl * N_cyl;

end

