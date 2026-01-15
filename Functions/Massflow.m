% Calculates mass flow from the fuel mixed with air

% INPUTS: 
%   AFR (air to fuel ratio), 
%   Mdotfuel (mass flow of fuel)

% OUTPUT:
%   mdottot (total massflow)
%----------------------------------------------------------------------

function [mdottot] = Massflow(mdotfuel, AFR)
mdotair = mdotfuel*AFR;
mdottot = mdotair + mdotfuel;
end