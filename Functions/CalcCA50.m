function CA50 = CalcCA50(Qcum, Ca)
    Qtot = Qcum(end);                %  total heat released in the cycle
    idx = find(Qcum >= 0.5*Qtot, 1); % first index where cumulative heat is more than 50% of total

    if idx > 1                       % if not the first point, interpolate
        Q1 = Qcum(idx-1); Q2 = Qcum(idx); % heat at previous and current sample
        Ca1 = Ca(idx-1); Ca2 = Ca(idx);   % crank angle at those samples
        CA50 = Ca1 + (0.5*Qtot - Q1)*(Ca2-Ca1)/(Q2-Q1); % linear interpolation
    else
        CA50 = Ca(idx);              % if the first point is equal 50%, just take it
    end
end
