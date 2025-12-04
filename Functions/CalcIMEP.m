function [IMEP, Wcycle] = CalcIMEP(p, V)
%  calculates Indicated Mean Effective Pressure for a cycle
%
%   p - cylinder pressure 
%   V - cylinder volume 
% outputs:
%   IMEP - indicated mean effective pressure
%   Wcycle - indicated work per cycle

% integration of pdV over the cycle
Wcycle = trapz(V, p);    % J

% displacement volume 
Vd = max(V) - min(V);    % m^3

% Compute IMEP
IMEP = Wcycle / Vd;       % Pa

end
