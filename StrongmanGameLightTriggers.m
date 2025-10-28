% Beam-break detection on AD3 without calllib (Data Acquisition Toolbox)
% Requirements:
% - MATLAB Data Acquisition Toolbox
% - "MATLAB Support Package for Digilent Analog Discovery Hardware"
% - AD3 connected; receiver on CH1+ (ai1), CH1- tied to GND

observeSeconds = 10;
breakThresh_V  = 0.150;     % beam break below this voltage
Fs             = 10000;     % sample rate (Hz)

% Create Digilent DAQ object
d = daq("digilent");        % discovers first AD device (AD3)
d.Rate = Fs;

% Turn on +5 V rail (V+). Property/method names vary slightly by release.
% Try common options; ignore ones not present.
try
    % Newer releases use powerSupply property
    d.PowerSupplyEnabled = true;
    d.PowerSupplyPositiveVoltage = 5.0;
catch
end
try
    % Some releases expose a helper to configure supplies
    configurePowerSupply(d, "on", 5.0, "off", 0.0);  % VS+, VS-
catch
end

% Add AI1 voltage channel (single‑ended to ground)
ch = addinput(d, "AD3_0", "ai0", "Voltage");
ch.Range = [-0.5 0.5];      % tighten for better resolution if supported

fprintf("Watching AI1 for %.1f s (break < %.0f mV)...\n", observeSeconds, breakThresh_V*1e3);

% Acquire in one read (simple) — fast enough for thresholding
T = read(d, seconds(observeSeconds), "OutputFormat", "Matrix");  % returns Nx1 double
v = T(:,1);

if any(v < breakThresh_V)
    firstIdx = find(v < breakThresh_V, 1, "first");
    tBreak = (firstIdx-1)/Fs;
    fprintf("Beam BREAK detected at t=%.3f s. Min=%.0f mV\n", tBreak, 1e3*min(v));
else
    fprintf("No beam break detected in %.1f s. Min=%.0f mV\n", observeSeconds, 1e3*min(v));
end

% Optional: turn supply off at end (comment to keep on)
try
    d.PowerSupplyEnabled = false;
catch
end