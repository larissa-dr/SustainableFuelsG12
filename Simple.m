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


%% Filtering pressure (already averaged and pegged)

% Savitzky–Golay filter parameters
dCa        = Ca(2,1) - Ca(1,1);   % crank-angle step
polyOrder = 2;
window_deg = 4;               % smooth over 2 crank-angle degrees

Nwin = round(window_deg / dCa);   % convert to number of points
if mod(Nwin,2) == 0               % SG window length must be odd
    Nwin = Nwin + 1;
end

% Filtered mean pressure

p_avg_peg_filt = sgolayfilt(p_avg_pegged, polyOrder, Nwin);


% pV-diagrams(with noise reduction and averaging)
V = CylinderVolume(Ca(:,iselect),Cyl);
f4 = figure(4);
set(f4,'Position',[ 200 400 600 800]);           
subplot(2,1,1)
plot(V/dm^3,p_avg_peg_filt/bara);
xlabel('V [dm^3]');ylabel('p [bar]');             
xlim([0 0.8]);ylim([0.5 60]);                    
set(gca,'XTick',[0:0.1:0.8],'XGrid','on','YGrid','on');      
title({'pV (filtered)'})
subplot(2,1,2)
loglog(V/dm^3,p_avg_peg_filt/bara);
xlabel('V [dm^3]');ylabel('p [bar]');              
xlim([0.02 0.8]);ylim([0 60]);                      
set(gca,'XTick',[0.02 0.05 0.1 0.2 0.5 0.8],...
    'YTick',[0.5 1 2 5 10 20 50],'XGrid','on','YGrid','on');       
title({'pV (filtered)   LOG scale'})
