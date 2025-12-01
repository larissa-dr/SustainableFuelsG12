function p_avg = AveragePressure(p_raw)
% Averages cycle pressure over all cycles

% INPUT:
%   p_raw : matrix (N_CA × N_cycles)

% OUTPUT:
%   p_avg : column vector (N_CA×1)

p_avg = mean(p_raw, 2);

end
