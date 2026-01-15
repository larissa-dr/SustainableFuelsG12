% Calculates Indicated Mean Effective Pressure for a cycle

% INPUTS:
%   p - cylinder pressure 
%   V - cylinder volume 
% Outputs:
%   IMEP - indicated mean effective pressure
%   Wcycle - indicated work per cycle
%----------------------------------------------------------------------

function [IMEP, Wcycle] = CalcIMEP(p, V)

% integration of pdV over the cycle
Wcycle = trapz(V, p);    % J

% displacement volume 
Vd = max(V) - min(V);    % m^3

% Compute IMEP
IMEP = Wcycle / Vd;       % Pa

end
