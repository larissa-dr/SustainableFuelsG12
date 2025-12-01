function [p_avg_pegged, p_shift, idxIVC] = PegPressure(Ca, p_avg, p_intake, CaIVC)

% Pegs averaged cylinder pressure at IVC to intake pressure

% INPUTS:
%   Ca        : crank angle matrix (N_CA × N_cycles)
%   p_avg     : averaged pressure trace
%   p_intake  : intake pressure in Pa
%   CaIVC     : intake valve closing angle

% OUTPUTS:
%   p_avg_pegged : pegged pressure trace
%   p_shift       : pressure offset applied
%   idxIVC        : index of the IVC crank angle

[~, idxIVC] = min(abs(Ca(:,1) - CaIVC)); % finds sample closest to IVC

p_shift = p_intake - p_avg(idxIVC); % Computes shift

p_avg_pegged = p_avg + p_shift; % applies shift

end