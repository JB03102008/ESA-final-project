%% The Strongman Game - Light triggers script version 1.0
% Analog readout and live plotting for light triggers
% Uses the daq toolbox
% Example usage: StrongmanGameLightTriggers("AD3", "V+", "ai0")
%
% Made by Jasper Bloemendal as part of the ESA final project group 3
% Version 1.0

function [t1, t2, t3] = StrongmanGameLightTriggers(deviceID, voltageChannel, inputChannel)

% Default values if no input arguments are supplied
if nargin < 1, deviceID = "AD3_0"; end
if nargin < 2, voltageChannel = "V+"; end
if nargin < 3, inputChannel = "ai0"; end

daqreset;

AI = daq("digilent");
VP = daq("digilent");

addoutput(VP, deviceID, voltageChannel, "Voltage");
addinput(AI, deviceID, inputChannel, "Voltage");
AI.Rate = 10000;

write(VP, 5);
fprintf("V+ set to 5V\n");

% --- Initialize ---
t1 = NaN; t2 = NaN; t3 = NaN;
dropCount = 0;
tStart = tic;

fprintf("Monitoring signal...\n");

bufferTime = 0.1;  % seconds per read
window = [];
timeWindow = [];

% --- Setup live plot ---
figure;
hPlot = plot(NaN, NaN, 'b-');
xlabel('Time (s)');
ylabel('Voltage (V)');
title('Strongman Game Signal');
grid on;

while dropCount < 3
    % Read small chunk
    data = read(AI, seconds(bufferTime));
    v = data{:,1};
    tChunk = toc(tStart) + linspace(-bufferTime, 0, numel(v))';

    % Append new data
    window = [window; v];
    timeWindow = [timeWindow; tChunk];

    % Keep ~2 seconds of recent data
    if numel(window) > 2*AI.Rate
        window = window(end-2*AI.Rate+1:end);
        timeWindow = timeWindow(end-2*AI.Rate+1:end);
    end

    % --- Update plot ---
    set(hPlot, 'XData', timeWindow, 'YData', window);
    drawnow limitrate nocallbacks;

    % --- Analyze for dips ---
    vs = smooth(window, 50);
    [~, locs] = findpeaks(-vs, 'MinPeakProminence', 0.05);

    if numel(locs) > dropCount
        dropCount = numel(locs);
        tNow = toc(tStart);
        switch dropCount
            case 1
                t1 = tNow;
                fprintf("Dip 1 at %.4f s\n", t1);
            case 2
                t2 = tNow;
                fprintf("Dip 2 at %.4f s\n", t2);
            case 3
                t3 = tNow;
                fprintf("Dip 3 at %.4f s\n", t3);
        end
    end
end

write(VP, 0);
fprintf("V+ reset to 0V\n");
end
