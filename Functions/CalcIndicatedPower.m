function [IP, Wcycle] = CalcIndicatedPower(p_cycle, V, EngineRPM, N_cyl)

% inputs:
%   cylinder pressure array [Pa]
%   cylinder volume array [m^3]
%  engine speed [rev/min]
%   number of cylinders
%
% Outputs:
%  work done per cylinder per cycle [J]
%  total indicated power [W]

% work per cycle by integrating p dV
Wcycle = trapz(V, p_cycle);   % J = Pa*m^3

% engine cycles per second (for 4-stroke engine)
cycles_per_sec = (EngineRPM/60) / 2;

% indicated power per cylinder
IP_per_cyl = Wcycle * cycles_per_sec;

% total indicated power
IP = IP_per_cyl * N_cyl;

end

