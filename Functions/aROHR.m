function [dQdTh] = aROHR(p,V, Ca, gamma, iselect)
dpdTh = gradient(p, 20/720000);
dVdTh = gradient(V, 20/720000);

dQdTh = zeros(1, length(gamma));

for i = 1:length(gamma)
    dQdTh(i) = gamma(i)/(gamma(i)-1).*p(i).*dVdTh(i) + 1/(gamma(i)-1).*V(i).*dpdTh(i);
end
figure;
plot(dpdTh)
title("p")

figure;
plot(dVdTh)
title("V")
end