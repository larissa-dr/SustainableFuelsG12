%% =========================================================
%   Fuel KPI Comparison Script (Diesel vs HVO vs GTL)
%   IMEP = 1.5 / 2.5 / 3.5 bar
%   Optimal injection timing per fuel
% =========================================================

%% Init
clearvars; clc; close all;
addpath("Functions","Nasa");

%% Units
mm = 1e-3;
bara = 1e5;

%% Load NASA data (needed by some functions)
global Runiv
Runiv = 8.314;
[SpS, El] = myload('Nasa\NasaThermalDatabase.mat', ...
                  {'Diesel','O2','N2','CO2','H2O'});

%% Engine geometry
Cyl.Bore = 104*mm;
Cyl.Stroke = 85*mm;
Cyl.CompressionRatio = 21.5;
Cyl.ConRod = 136.5*mm;
Cyl.TDCangle = 0;

CaIVC = -135;
EngineRPM = 1500;
N_cyl = 1;

%% Load fdaq pressure data (common reference)
FullName = fullfile('Data','20251125_0000001_imep_1.5_injection_18_fdaq.txt');
dataIn = table2array(readtable(FullName));

NdatapointsperCycle = 720/0.2;
Ncycles = size(dataIn,1) / NdatapointsperCycle;

Ca = reshape(dataIn(:,1),[],Ncycles);
p_raw = reshape(dataIn(:,2),[],Ncycles)*bara;

p_avg = AveragePressure(p_raw);

%% Load sdaq intake pressure
sDaq = fullfile('Data','20251125_0000001_imep_1.5_injection_18_sdaq.txt');
IntakeData = table2array(readtable(sDaq));
p_intake = mean(IntakeData(:,4)) * bara;

%%   Fuels IMEP and Injection timing

IMEP_levels = [1.5, 2.5, 3.5];
Fuels = ["Diesel", "HVO", "GTL"];

FuelFiles = struct( ...
    'Diesel', "Data/Diesel_ManualData.xlsx", ...
    'HVO',    "Data/HVO_ManualData.xlsx", ...
    'GTL',    "Data/GTL_ManualData.xlsx" );

OptimalInjection.Diesel = [9, 18, 18];
OptimalInjection.HVO    = [9, 9, 9];
OptimalInjection.GTL    = [12, 18, 12];

FuelProps.Diesel.LHV = 43e6;
FuelProps.HVO.LHV    = 44e6;
FuelProps.GTL.LHV    = 44e6;

FuelProps.Diesel.CI = 0.000015932; % B7
FuelProps.HVO.CI    = 0.000010291; % Yellow Grease
FuelProps.GTL.CI    = 0.000026962; % GTL (NA)

%%   KPI storage

nIMEP = numel(IMEP_levels);
nFuel = numel(Fuels);

eta_b  = zeros(nIMEP,nFuel);
BSFC   = zeros(nIMEP,nFuel);
BSEC   = zeros(nIMEP,nFuel);
GHG    = zeros(nIMEP,nFuel);
bsCO2  = zeros(nIMEP,nFuel);
bsNOx  = zeros(nIMEP,nFuel);
CA50_v = zeros(nIMEP,nFuel);

%%   Main KPI loop

for i = 1:nIMEP
    target_IMEP = IMEP_levels(i);

    for j = 1:nFuel
        fuel = Fuels(j);

        data = readtable(FuelFiles.(fuel));

        target_inj = OptimalInjection.(fuel)(i);
        LHV = FuelProps.(fuel).LHV;
        CI  = FuelProps.(fuel).CI;

        Injection = data.InjectionTiming;
        IMEP_col  = str2double(string(data.IMEP));

        idx = find(Injection == target_inj & IMEP_col == target_IMEP);

        if isempty(idx)
            error("Missing operating point for %s at IMEP %.1f", fuel, target_IMEP);
        end

        % Manual data
        mFuel_gps = str2double(string(data.massFlow(idx)));
        CO2_pct   = str2double(string(data.CO2(idx)));
        NOx_ppm   = str2double(string(data.Nox(idx)));

        % Emission mass flows
        mCO2 = CO2_massflow_from_fuel(CO2_pct, mFuel_gps);
        mNOx = NOx_massflow_from_fuel(NOx_ppm, mFuel_gps);

        % Pressure & power
        [p_avg_pegged,~,~] = PegPressure(Ca,p_avg,p_intake,CaIVC);
        iselect = 1;

        V = CylinderVolume(Ca(:,iselect),Cyl);
        p_cycle = p_avg_pegged(:,iselect);

        [IP,~] = CalcIndicatedPower(p_cycle,V,EngineRPM,N_cyl);

        % KPIs
        eta_b(i,j) = IP / ((mFuel_gps/1000) * LHV);
        BSFC(i,j)  = (mFuel_gps * 3600) / (IP/1000);
        BSEC(i,j)  = 3.6 / eta_b(i,j);
        GHG(i,j)   = CI * BSEC(i,j) * 1e6;

        bsCO2(i,j) = (mCO2 * 3600) / (IP/1000);
        bsNOx(i,j) = (mNOx * 3600) / (IP/1000);

        gamma = 1.39;
        [~,Qcum] = CalcHRR(p_cycle,V,gamma);
        CA50_v(i,j) = CalcCA50(Qcum,Ca(:,iselect));
    end
end

%%   BAR PLOTS

KPI_names = {'Engine efficiency', 'BSFC [g/kWh]','BSEC [MJ/kWh]','GHG [gCO2e/kWh]','bsCO2 [g/kWh]', 'bsNOx [g/kWh]', 'CA50'};
KPI_data  = {eta_b, BSFC, BSEC, GHG, bsCO2, bsNOx, CA50_v};

for k = 1:numel(KPI_names)
    figure;
    for i = 1:nIMEP
        subplot(1,nIMEP,i)
        bar(KPI_data{k}(i,:))
        title(sprintf('%s @ IMEP %.1f bar', KPI_names{k}, IMEP_levels(i)))
        xticklabels(Fuels)
        grid on
    end
end
