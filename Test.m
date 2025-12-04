%% init
clear all; clc;close all;
addpath( "Functions","Nasa");
%% Units
mm      = 1e-3;dm=0.1;
bara    = 1e5;
MJ      = 1e6;
kWhr    = 1000*3600;
volperc = 0.01; % Emissions are in volume percentages
ppm     = 1e-6; % Some are in ppm (also a volume- not a mass-fraction)
g       = 1e-3;
s       = 1;
%% Engine geom data (check if these are correct)
Cyl.Bore                = 104*mm;
Cyl.Stroke              = 85*mm;
Cyl.CompressionRatio    = 21.5;
Cyl.ConRod              = 136.5*mm;
Cyl.TDCangle            = 180;
% -- Valve closing events can sometimes be seen in fast oscillations in the pressure signal (due
% to the impact when the Valve hits its seat).
CaIVO = -355;
CaIVC = -135;
CaEVO = 149;
CaEVC = -344;
CaSOI = -3.2;
% Write a function [V] = CylinderVolume(Ca,Cyl) that will give you Volume
% for the given Cyl geometry. If you can do that you can create pV-diagrams
%% Load NASA maybe you need it at some point?
% Global (for the Nasa database in case you wish to use it).
global Runiv
Runiv = 8.314;
[SpS,El]        = myload('Nasa\NasaThermalDatabase.mat',{'Diesel','O2','N2','CO2','H2O'});
%% Load data (if txt file)
iselect = 10;
FullName        = fullfile('Data','ExampleDataSet.txt');
dataIn          = table2array(readtable(FullName));
[Nrows,Ncols]   = size(dataIn);                    % Determine size of array
NdatapointsperCycle = 720/0.2;                     % Nrows is a multitude of NdatapointsperCycle
Ncycles         = Nrows/NdatapointsperCycle;       % This must be an integer. If not checkwhat is going on
Ca              = reshape(dataIn(:,1),[],Ncycles); % Both p and Ca are now matrices of size (NCa,Ncycles)
p               = reshape(dataIn(:,2),[],Ncycles)*bara; % type 'help reshape' in the command window if you want to know what it does (reshape is a Matlab buit-in command
V = CylinderVolume(Ca(:,iselect),Cyl); %% in mm
%% compositions
% Air composition
Mi = [SpS.Mass];
Xair = [0 0.21 0.79 0 0];                                                   % Order is important. Note that these are molefractions
MAir = Xair*Mi';                                                            % Row times Column = inner product 
Yair = Xair.*Mi/MAir;                                                       % Vector. times vector is Matlab's way of making an elementwise multiplication
% Fuel composition
Yfuel = [1 0 0 0 0];                                                        % Only fuel

% Exhaust composition (entry mass compared to out); from literature
% Not yet calculated, but just as placeholders for now (got these values
% from ChatGPT); THIS IS THE MAIN THING FOR NEXT SSA
MO2 = 0;
MN2 = 0.7173;
MCO2 = 0.2031;
MH2O = 0.0796;

Yout = [0, MO2, MN2, MCO2, MH2O]; 
M = [0.167, 0.032 0.0280134 0.04401 0.018015];
Rmix = Runiv * sum(Yout ./ M);

%% READ DATA
measurements = extractMeasurementData(filename);
%% Miscelanious data/assumptions
AFR = 14.50; 
EngineRPM = 1500; 
gamma = 1.37;

%% Measured data (NOT YET IMPLEMENTED)
CO2_volpct = 1;
NOx_ppm = 1;
mdot_fuel_gps = 1;

%% Pre-calculations
mtotdot = Massflow(mdot_fuel_gps, AFR); %massflow per cycle (assumed!)
mtot = mtotdot / (EngineRPM / (60 * 2)); %mass per cycle
Torque = p(iselect).*V./(Ca(:,iselect).*2*pi); % might be wrong
Power = Torque .* 2*pi*(EngineRPM/60); % power in Watts

%% Assumptions
% asssume Tin is 20 degrees
% mass is based off of mass flow
% gamma is 1.37 for the whole cycle

%% IMEP
IMEP = IMEP(p(iselect), V);
figure;
hold on;
plot(IMEP)
hold off;
%% bsfc
bsfc = bsfc(mtot, Torque);
figure;
hold on;
plot(bsfc)
hold off;
%% bsCO2
mCO2 = CO2_massflow_from_fuel(CO2_volpct, mdot_fuel_gps);
bsCO2 = bsCO2(mCO2, Power);
figure;
hold on;
plot(bsCO2)
hold off;
%% bsNOx
mNOx = NOx_massflow_from_fuel(NOx_ppm, mdot_fuel_gps);
bsNOx = bsNOx(mNOx, Power);
figure;
hold on;
plot(mNOx)
hold off;
%% aROHR to Ca50
dQdTh = aROHR(p, V, Ca, gamma, iselect);
Q = cumtrapz(dQdTh);
Q50 = 0.5 * sum(Q);
i50 = find(cumsum(Q) >= Q50, 1);

figure;
hold on;
plot(Ca, Q)
xline(Ca(i50))
xlabel('Crank Angle')
ylabel('Cumulative Q release')
hold off;
