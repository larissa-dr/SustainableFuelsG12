function [IMEP] = IMEP(pi, V)
W = trapz(V, pi);
Vd = V(end) - V(1);
IMEP = W/Vd;
end