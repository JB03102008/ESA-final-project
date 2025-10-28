function [t1, t2, t3] = StrongmanGameLightTriggers(deviceID, voltageChannel, inputChannel)
%% The Strongman Game - Light trigger script - version 1.0 (function form)
% Calculates time difference between three voltage drops (e.g. ball
% positions) using IR LEDs and photodiodes.
% Made by UTWENTE-BSC-EE-ESA group 3
% Version: 1.0 (function version)

% --- Default parameters ---------------------------------------------------
if nargin < 1, deviceID = "AD3_0"; end
if nargin < 2, voltageChannel = "V+"; end
if nargin < 3, inputChannel = "ai1"; end

daqreset;  % reset all DAQ devices

% --- Create DAQ objects ---------------------------------------------------
AI = daq("digilent");   % Analog input (for photodiode)
VP = daq("digilent");   % Power supply (V+ rail)

% --- Configure V+ as voltage output --------------------------------------
addoutput(VP, deviceID, voltageChannel, "Voltage");

% --- Configure analog input ----------------------------------------------
addinput(AI, deviceID, inputChannel, "Voltage");
AI.Rate = 10000;  % Set sample rate

% --- Set V+ to 5V --------------------------------------------------------
fprintf("Setting V+ to 5V...\n");
write(VP, 5);   % Sets 5V on v+ rail

% --- Start background acquisition ----------------------------------------
fprintf("Starting acquisition for 10 seconds...\n");
start(AI, "Duration", seconds(10));

% --- Wait for acquisition to finish --------------------------------------
while AI.Running
    pause(0.1);
end

% --- Retrieve data -------------------------------------------------------
data = read(AI, "all");
fprintf("Acquisition done.\n");

t_sec = seconds(data.Time);
v = data{:, 1};

% --- Analyze voltage drops -----------------------------------------------
fprintf("Analyzing voltage drops...\n");

vs = smooth(v, 50);  % smooth signal to reduce noise
[~, locs] = findpeaks(-vs, 'MinPeakProminence', 0.05);
locs_sec = t_sec(locs);

% --- Assign first three drop times to t1, t2, t3 -------------------------
if numel(locs_sec) >= 3
    t1 = locs_sec(1);
    t2 = locs_sec(2);
    t3 = locs_sec(3);
elseif numel(locs_sec) == 2
    t1 = locs_sec(1);
    t2 = locs_sec(2);
    t3 = NaN;
elseif numel(locs_sec) == 1
    t1 = locs_sec(1);
    t2 = NaN;
    t3 = NaN;
else
    t1 = NaN;
    t2 = NaN;
    t3 = NaN;
end

% --- Output results ------------------------------------------------------
fprintf("t1 = %.4f s\n", t1);
fprintf("t2 = %.4f s\n", t2);
fprintf("t3 = %.4f s\n", t3);

% --- Reset V+ ------------------------------------------------------------
write(VP, 0);
fprintf("V+ now reset to 0V...\n");

end