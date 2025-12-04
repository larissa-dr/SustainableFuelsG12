function mCO2 = CO2_massflow_from_fuel(CO2_volpct, mdot_fuel_gps)

AFR = 14.5;
MW_exh = 29e-3; %this is a value found in literature

mdot_fuel = mdot_fuel_gps / 1000; % kg/s
mdot_air = AFR * mdot_fuel;
mexh = mdot_air + mdot_fuel;

xCO2 = CO2_volpct / 100; % mol fraction
MW_CO2 = 44e-3;           % kg/mol , two atoms of oxygen and one of carbon

YCO2 = xCO2 * (MW_CO2 / MW_exh); % mass fraction

mCO2 = YCO2 * mexh;
end