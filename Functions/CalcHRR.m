function [HRR, Qcum] = CalcHRR(p, V, gamma)
% CalcHRR: Calculates apparent heat release rate and cumulative heat release
% 
%   gamma - ratio of specific heats (it needs to be dynamic)
%   HRR  - apparent heat release rate [J/deg]
%   Qcum - cumulative heat release [J]

% Ensure column vectors
p = p(:);
V = V(:);

% crank angle step 
N = length(V);
dtheta = 720/(N-1); % 4-stroke engine, degrees per step

% Derivatives
dV = [diff(V); V(end)-V(end-1)];        % m^3
dp = [diff(p); p(end)-p(end-1)];        % Pa

% Apparent heat release rate (J/deg)
HRR = (gamma/(gamma-1)) * p .* dV + (1/(gamma-1)) * V .* dp;

% Cumulative heat release (J)
Qcum = cumsum(HRR);

end
