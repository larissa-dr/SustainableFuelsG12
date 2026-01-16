%% =========================================================
%   Fuel KPI Comparison Script
%   Fuels: Diesel, HVO, GTL, HVO50, GTL50
%   IMEP: 1.5 / 2.5 / 3.5 bar
%   Injection timing: fuel-dependent optimum
% =========================================================

clearvars; clc; close all;
addpath("Functions","Nasa");

%% Units
mm   = 1e-3;
bara = 1e5;

%% NASA (needed for HRR etc.)
global Runiv
Runiv = 8.314;
[~,~] = myload('Nasa\NasaThermalDatabase.mat', ...
               {'Diesel','O2','N2','CO2','H2O'});

%% Engine geometry
Cyl.Bore = 104*mm;
Cyl.Stroke = 85*mm;
Cyl.CompressionRatio = 21.5;
Cyl.ConRod = 136.5*mm;
Cyl.TDCangle = 0;

CaIVC    = -135;
EngineRPM = 1500;
N_cyl     = 1;

%% ---------------------------------------------------------
%  Operating points
%% ---------------------------------------------------------
IMEP_levels = [1.5, 2.5, 3.5];
Fuels = ["Diesel","HVO","GTL","HVO50","GTL50"];


%% Manual data files 
FuelFiles = struct( ...
    'Diesel',"Data/Diesel_ManualData.xlsx", ...
    'HVO',   "Data/HVO_ManualData.xlsx", ...
    'GTL',   "Data/GTL_ManualData.xlsx", ...
    'HVO50', "Data/HVO50_ManualData.xlsx", ...
    'GTL50', "Data/GTL50_ManualData.xlsx");


%% Optimal injection timing per fuel
OptimalInjection.Diesel = [9, 18, 18];
OptimalInjection.HVO    = [9, 9, 9];
OptimalInjection.GTL    = [12,18,12];
OptimalInjection.HVO50  = [10,6, 6];
OptimalInjection.GTL50  = [10,10,10];

%% Fuel properties
FuelProps.Diesel.LHV = 43e6;
FuelProps.HVO.LHV    = 44e6;
FuelProps.GTL.LHV    = 44e6;
FuelProps.HVO50.LHV  = 43.5e6; % Might need to be changed
FuelProps.GTL50.LHV  = 43.5e6; % Might need to be changed

FuelProps.Diesel.CI = 1.5932e-5;
FuelProps.HVO.CI    = 1.0291;    % Yellow grease
FuelProps.GTL.CI    = 2.6962e-5;
FuelProps.HVO50.CI  = 2.5720e-5; % Might need to be changed
FuelProps.GTL50.CI  = 2.1500e-5; % Might need to be changed

%% ---------------------------------------------------------
%  KPI storage
%% ---------------------------------------------------------
nIMEP = numel(IMEP_levels);
nFuel = numel(Fuels);

eta_b = zeros(nIMEP,nFuel);
BSFC  = zeros(nIMEP,nFuel);
BSEC  = zeros(nIMEP,nFuel);
GHG   = zeros(nIMEP,nFuel);
bsCO2 = zeros(nIMEP,nFuel);
bsNOx = zeros(nIMEP,nFuel);
CA50  = zeros(nIMEP,nFuel);

%% ---------------------------------------------------------
%  MAIN LOOP
%% ---------------------------------------------------------
for i = 1:nIMEP
    target_IMEP = IMEP_levels(i);

    for j = 1:nFuel
        fuel = Fuels(j);
        inj  = OptimalInjection.(fuel)(i);

        fprintf("Processing %s | IMEP %.1f | inj %d\n", fuel, target_IMEP, inj);

        %% ---------- Load fDAQ ----------
        fdaqFile = sprintf("Data/%s_imep_%.1f_injection_%d_fdaq.txt", ...
                            fuel, target_IMEP, inj);

        dataIn = table2array(readtable(fdaqFile));
        Npts = 720/0.2;
        Ncycles = size(dataIn,1)/Npts;

        Ca = reshape(dataIn(:,1),[],Ncycles);
        p_raw = reshape(dataIn(:,2),[],Ncycles)*bara;
        p_avg = AveragePressure(p_raw);

        %% ---------- Load sDAQ ----------
        sdaqFile = sprintf("Data/%s_imep_%.1f_injection_%d_sdaq.txt", ...
                            fuel, target_IMEP, inj);

        sDAQ = table2array(readtable(sdaqFile));

        % ASSUMPTIONS (adjust if needed)
        mFuel_gps = mean(sDAQ(:,1));       % g/s
        p_intake  = mean(sDAQ(:,4))*bara;  % Pa

        %% ---------- Manual emissions (if available) ----------
        if FuelFiles.(fuel) ~= ""
            T = readtable(FuelFiles.(fuel));
            idx = find(T.InjectionTiming == inj & ...
                       str2double(string(T.IMEP)) == target_IMEP);

            CO2_pct = str2double(string(T.CO2(idx)));
            NOx_ppm = str2double(string(T.Nox(idx)));
        else
            CO2_pct = NaN;
            NOx_ppm = NaN;
        end

        %% ---------- Pressure processing ----------
        [p_avg_pegged,~,~] = PegPressure(Ca,p_avg,p_intake,CaIVC);

        iselect = 1;
        V = CylinderVolume(Ca(:,iselect),Cyl);
        p_cycle = p_avg_pegged(:,iselect);

        %% ---------- Power ----------
        [IP,~] = CalcIndicatedPower(p_cycle,V,EngineRPM,N_cyl);

        %% ---------- KPIs ----------
        LHV = FuelProps.(fuel).LHV;
        CI  = FuelProps.(fuel).CI;

        eta_b(i,j) = IP / ((mFuel_gps/1000)*LHV);
        BSFC(i,j)  = (mFuel_gps*3600)/(IP/1000);
        BSEC(i,j)  = 3.6/eta_b(i,j);
        GHG(i,j)   = CI*BSEC(i,j)*1e6;

        if ~isnan(CO2_pct)
            mCO2 = CO2_massflow_from_fuel(CO2_pct,mFuel_gps);
            bsCO2(i,j) = (mCO2*3600)/(IP/1000);
        end

        if ~isnan(NOx_ppm)
            mNOx = NOx_massflow_from_fuel(NOx_ppm,mFuel_gps);
            bsNOx(i,j) = (mNOx*3600)/(IP/1000);
        end

        %% ---------- CA50 ----------
        gamma = 1.34;
        [~,Qcum] = CalcHRR(p_cycle,V,gamma);

        % Combustion window (degrees aTDC)
        Ca_vec = Ca(:,iselect);
        combIdx = Ca_vec > -20 & Ca_vec < 40;
        Qcomb = Qcum(combIdx);
        Cacomb = Ca_vec(combIdx);
        % Normalize heat release
        Qnorm = Qcomb - Qcomb(1);
        Qnorm = Qnorm / Qnorm(end);
        % CA50 location
        idx50 = find(Qnorm >= 0.5, 1, 'first');
        CA50_v(i,j) = Cacomb(idx50);


        % CA50(i,j) = CalcCA50(Qcum,Ca(:,iselect));
    end
end

%% ---------------------------------------------------------
%  BAR PLOTS
%% ---------------------------------------------------------
KPI_names = {'Efficiency','BSFC','BSEC','GHG','bsCO2','bsNOx','CA50'};
KPI_data  = {eta_b,BSFC,BSEC,GHG,bsCO2,bsNOx,CA50_v};

for k = 1:numel(KPI_names)
    figure('Name',KPI_names{k});
    for i = 1:nIMEP
        subplot(1,nIMEP,i)
        bar(KPI_data{k}(i,:))
        xticklabels(Fuels)
        title(sprintf('%s @ IMEP %.1f',KPI_names{k},IMEP_levels(i)))
        grid on
    end
end

CompareFuelsAll