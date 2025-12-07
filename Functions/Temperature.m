function [Temp] = Temperature(p,V, mtot, Rmix)
Temp = (p .* V) ./ (mtot * Rmix); %Ideal gas law is assumed, because course info says it can be used for aROHR

end