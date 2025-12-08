%% Info
% Toerental: 1500 RPM
% SOA van 4.2º voor TDC
% Resolutie van 0.2º CA
% Data voor 69 cycles (maximale van de Smetec, de OGO gensets kunnen in principe "onbeperkt" aan)
% 
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
%% Load NASA maybe you need it at some point?
% Global (for the Nasa database in case you wish to use it).
global Runiv
Runiv = 8.314;
[SpS,El]        = myload('Nasa\NasaThermalDatabase.mat',{'Diesel','O2','N2','CO2','H2O'});
%% Engine geom data (check if these are correct)
Cyl.Bore                = 104*mm;
Cyl.Stroke              = 85*mm;
Cyl.CompressionRatio    = 21.5;
Cyl.ConRod              = 136.5*mm;
Cyl.TDCangle            = 0;
% -- Valve closing events can sometimes be seen in fast oscillations in the pressure signal (due
% to the impact when the Valve hits its seat).
CaIVO = -355;
CaIVC = -135;
CaEVO = 149;
CaEVC = -344;
CaSOI = -3.2;
% Write a function [V] = CylinderVolume(Ca,Cyl) that will give you Volume
% for the given Cyl geometry. If you can do that you can create pV-diagrams
%% Load fdaq data (if txt file)
FullName        = fullfile('Data','20251125_0000001_imep_1.5_injection_18_fdaq.txt');
dataIn          = table2array(readtable(FullName));
[Nrows,Ncols]   = size(dataIn);                    % Determine size of array
NdatapointsperCycle = 720/0.2;                     % Nrows is a multitude of NdatapointsperCycle
Ncycles         = Nrows/NdatapointsperCycle;       % This must be an integer. If not checkwhat is going on
Ca              = reshape(dataIn(:,1),[],Ncycles); % Both p and Ca are now matrices of size (NCa,Ncycles)
p_raw           = reshape(dataIn(:,2),[],Ncycles)*bara; % type 'help reshape' in the command window if you want to know what it does (reshape is a Matlab buit-in command

%% Average the raw data
p_avg = AveragePressure(p_raw); % Calculate the average pressure for each crank angle

%% Load sdaq data
sDaq        = fullfile('Data','20251125_0000001_imep_1.5_injection_18_sdaq.txt');
IntakeData  = table2array(readtable(sDaq));
p_intake = mean(IntakeData(:,4))*bara; % average intake pressure in Pa

%% Pegging
[p_avg_pegged, p_shift, idxIVC] = PegPressure(Ca, p_avg, p_intake, CaIVC);

%% Plotting 
f1=figure(1);
set(f1,'Position',[ 200 800 1200 400]);             % Just a size I like. Your choice
pp = plot(Ca,p_avg_pegged/bara,'LineWidth',1);                 % Plots the whole matrix
xlabel('Ca');ylabel('p [bar]');                     % Always add axis labels
xlim([-360 360]);ylim([0 60]);                      % Matter of taste
iselect = 10;                                    % Plot cycle 10 again in the same plot to emphasize it. Just to show how to access individual cycles.
line(Ca(:,iselect),p_avg_pegged/bara,'LineWidth',2,'Color','r');
YLIM = ylim;
% Add some extras to the plot
%line([CaIVC CaIVC],YLIM,'LineWidth',1,'Color','b'); % Plot a vertical line at IVC. Just for reference not a particular reason.
%line([CaEVO CaEVO],YLIM,'LineWidth',1,'Color','r'); % Plot a vertical line at EVO. Just for reference not a particular reason.
set(gca,'XTick',[-360:60:360],'XGrid','on','YGrid','on');        % I like specific axis labels. Matter of taste
title('All cycles in one plot.')
%% pV-diagram
V = CylinderVolume(Ca(:,iselect),Cyl);
f2 = figure(2);
set(f2,'Position',[ 200 400 600 800]);              % Just a size I like. Your choice
subplot(2,1,1)
plot(V/dm^3,p_avg_pegged/bara);
xlabel('V [dm^3]');ylabel('p [bar]');               % Always add axis labels
xlim([0 0.8]);ylim([0.5 60]);                      % Matter of taste
set(gca,'XTick',[0:0.1:0.8],'XGrid','on','YGrid','on');        % I like specific axis labels. Matter of taste
title({'pV-diagram'})
subplot(2,1,2)
loglog(V/dm^3,p_avg_pegged/bara);
xlabel('V [dm^3]');ylabel('p [bar]');               % Always add axis labels
xlim([0.02 0.8]);ylim([0 60]);                      % Matter of taste
set(gca,'XTick',[0.02 0.05 0.1 0.2 0.5 0.8],...
    'YTick',[0.5 1 2 5 10 20 60],'XGrid','on','YGrid','on');        % I like specific axis labels. Matter of taste
title({'pV-diagram'})

figure;
yyaxis left
plot(Ca, V); ylabel('Volume');
yyaxis right
plot(Ca, p_avg); ylabel('Pressure');
xline(0,'k--','TDC');
grid on;

%% Read excel files
measurements_HVO = extractMeasurementData("Data/HVO_ManualData.xlsx");

nMeas = numel(measurements_HVO);

%mdot
for i = 1:nMeas
    mdot(:,i) = str2double(measurements_HVO(i).massFlow);
end

mdot_fuel_gps = mean(mdot(:)); % in g/s
%THIS IS AN AVERAGE FOR NOW, NEEDS TO BE CHANGED FOR TESTING

%% Values for functions
EngineRPM = 1500; 

AFR = 43; %included from Boscos code

mtotdot = Massflow(mdot_fuel_gps, AFR)/1000; % in kg/s
cycles_per_sec = EngineRPM / 60 / 2;  
mtot = mtotdot / cycles_per_sec; 
%% IMEP
%IMEP = IMEP(p_avg, V);
%figure;
%hold on;
%plot(IMEP)
%hold off;
%% bsfc
%bsfc = bsfc(mtot, Torque);
%figure;
%hold on;
%plot(bsfc)
%hold off;
%% bsCO2
%mCO2 = CO2_massflow_from_fuel(CO2_volpct, mdot_fuel_gps);
%bsCO2 = bsCO2(mCO2, Power);
%figure;
%hold on;
%plot(bsCO2)
%hold off;
%% bsNOx
%mNOx = NOx_massflow_from_fuel(NOx_ppm, mdot_fuel_gps);
%bsNOx = bsNOx(mNOx, Power);
%figure;
%hold on;
%plot(mNOx)
%hold off;
%% aROHR to Ca50
Vm = V; % convert to m^3; was already in m3 i think

%Smoothen data
window = 11; % take an uneven value, then it is half-1 points before, 1 center and half-1 points after

p_smooth  = smoothdata(p_avg, 'movmean', window);  % smoothens the p_avg with movmean = replaces value with average of window around it
Vm_smooth = smoothdata(Vm, 'movmean', window);

% Recompute gamma using smoothed signals
gammad = GammaHVO(p_smooth, Vm_smooth, mtot);
figure;
plot(Ca(:,1),gammad)
xlabel("Crank angle [°]")
ylabel("Gamma (\gamma) [-]","Interpreter","tex")
title("Dynamic gamma (\gamma) over a cycle","Interpreter","tex")

% aROHR using smoothed inputs
dQdThd = aROHR(p_smooth, Vm_smooth, Ca, gammad, iselect);
Qd     = cumtrapz(dQdThd);
Q50d   = 0.5 * sum(Qd);
i50d   = find(cumsum(Qd) >= Q50d, 1);

gamma = 1.39 * ones(1, length(gammad));
dQdTh = aROHR(p_smooth, Vm_smooth, Ca, gamma, iselect);
Q     = cumtrapz(dQdTh);
Q50   = 0.5 * sum(Q);
i50   = find(cumsum(Q) >= Q50, 1);

% Plot
figure;
plot(Ca(:, 1), Qd); hold on;
plot(Ca(:, 1), Q);
%plot(Ca(:, 1), dQdThd);
%plot(Ca(:, 1), dQdTh);
%legend("Qd", "Qs", "dQd", "dQs")
legend("Qd", "Qs (γ = 1.39 [-])")
xlabel("Crank angle [°]")
ylabel("Q [J/s]")
title("Cumulative heat release over one cycle")
grid on;