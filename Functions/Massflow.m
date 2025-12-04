function [mdottot] = Massflow(mdotfuel, AFR)
mdotair = mdotfuel*AFR;
mdottot = mdotair + mdotfuel;
end