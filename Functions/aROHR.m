function [dQdTh] = aROHR(p,V, Ca, gamma, iselect)
pi = p(:, iselect);
Cai = Ca(:, iselect);
Vi = V;

dpdTh = gradient(pi, Cai);
dVdTh = gradient(Vi, Cai);

dQdTh = gamma/(gamma-1).*pi.*dVdTh + 1/(gamma-1).*Vi.*dpdTh;
end