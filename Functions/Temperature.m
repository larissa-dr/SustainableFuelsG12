function [Temp] = Temperature(p,V, iselect, mtot, Rmix)
Temp = (p(:, iselect) .* V) ./ (mtot * Rmix); %Ideal gas law is assumed, because course info says it can be used for aROHR

end