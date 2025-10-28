function [Voltage, t] = StrongmanGameHammer()
% The Strongman Game - random hammer impact signal - version 2.0
% Simulates a realistic hammer/accelerometer impact signal
% Produces random amplitude and duration per run for testing motor control
%
% Output:
%   Voltage - Simulated accelerometer output (in microvolts)
%   t       - Time vector (seconds)
%
% Made by UTWENTE-BSC-EE-ESA group 3
% Version: 2.0

    rng('shuffle'); % ensure variation every call

    % --- Time base ---
    dt = 0.002;
    t  = 0:dt:2;
    N  = numel(t);

    % --- Randomized impact timing ---
    tImpact = 0.4 + 0.4*rand;          % impact moment (0.4–0.8 s)
    impactIdx = round(tImpact/dt);

    % --- Random amplitude and shape parameters ---
    A_peak = 50 + 250*rand;            % peak amplitude in microvolts (50–300 µV)
    riseTime = 0.02 + 0.03*rand;       % rise duration
    decayTime = 0.2 + 0.3*rand;        % decay duration

    % --- Generate waveform ---
    Voltage = zeros(1, N);
    for k = 1:N
        tk = t(k);
        if tk < tImpact
            Voltage(k) = 0;            % pre-impact idle
        elseif tk < tImpact + riseTime
            Voltage(k) = A_peak * ((tk - tImpact)/riseTime);  % linear rise
        elseif tk < tImpact + riseTime + decayTime
            Voltage(k) = A_peak * exp(-(tk - (tImpact + riseTime))/decayTime) ...
                                   .* cos(10*pi*(tk - tImpact)); % damped oscillation
        else
            Voltage(k) = 0;
        end
    end

    % --- Add small random noise ---
    Voltage = Voltage + 5*randn(size(Voltage));  % ±5 µV noise

end
