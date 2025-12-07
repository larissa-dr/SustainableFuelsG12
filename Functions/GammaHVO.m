function gamma_mix = GammaHVO(p, V, mtot)
%% Compositions

[SpS]        = myload('Nasa\NasaThermalDatabase.mat',{'O2','N2','CO2','H2O'});
Mi = [SpS.Mass];
global Runiv
Runiv = 8.314;
%% Combustin composition
M_N2  = 0.0280134;
M_O2  = 0.0319988;
M_CO2 = 0.0440095;
M_H2O = 0.0180153;

% In
Y_in = [0.2281, 0.7552];
M_in = [M_O2, M_N2];

% Out
Y_out = [0.1808, 0.7542, 0.0469, 0.0181];
M_out = [M_O2, M_N2, M_CO2, M_H2O];

Y_in0 = [0.2281, 0.7552, 0, 0];
Y_avg = (Y_in0 + Y_out)/2;

% Mixture 
Mmix_in = 1/sum(Y_in ./M_in);
Mmix_out = 1/sum(Y_out ./M_out);

% Gas constant
Rmix_in = Runiv/Mmix_in; %in kg
Rmix_out = Runiv/Mmix_out; %in kg
Rmix_avg = (Rmix_in + Rmix_out)/2; %in kg

%% Calculations
T = Temperature(p, V, mtot, Rmix_avg);
figure;
plot(T)
title("T")

Cp = zeros(1, length(T));
Cv = zeros(1, length(T));

for i=1:length(SpS)
    Cp(i,:)    = CpNasa(T,SpS(i));
    Cv(i,:)    = CvNasa(T,SpS(i));
end

Cp_mix = Y_avg * Cp;
Cv_mix = Y_avg * Cv;

gamma_mix = Cp_mix ./ Cv_mix;
%gamma_in = (Y_in * Cp) ./ (Y_in * Cv);
%gamma_out = (Y_out * Cp) ./ (Y_out * Cv);
