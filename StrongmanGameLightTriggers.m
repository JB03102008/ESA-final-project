function [t1, t2, t3] = StrongmanGameLightTriggers(dqAI)
%% Strongman Game - light triggers v2.2 (embedded version)
% polls light sensors in real time
% Made by UTWENTE-BSC-EE-ESA group 3
% version 2.2

% --- Initialize ---
t1 = NaN; t2 = NaN; t3 = NaN;
dropCount = 0;
tStart = tic;

fprintf("Monitoring signal...\n");

% Initialize plot
photoTime = [];
photoVolt = [];
window = [];

figure('Name','Photodiode Debug','NumberTitle','off');
phPlot = plot(nan, nan, 'b-');
xlabel('Time (s)');
ylabel('Photodiode Voltage (V)');
grid on;
title('Photodiode Signal Over Time');
drawnow;

bufferTime = 0.05;  % seconds per read

while dropCount < 3
    data = read(dqAI, seconds(bufferTime));
    v = data{:,1};
    tNow = toc(tStart);

    % Store and update plot
    photoTime = [photoTime; tNow];
    photoVolt = [photoVolt; mean(v)];
    set(phPlot, 'XData', photoTime, 'YData', photoVolt);
    drawnow limitrate nocallbacks;

    % Append to rolling window
    window = [window; v];
    if numel(window) > 200
        window = window(end-199:end);
    end

    % Sensitive dip detection
    if numel(window) > 10
        vs = smooth(window, 10);
        baseline = median(vs);
        dropThreshold = baseline - 0.002; % absolute 2 mV drop
        relDrop = (baseline - min(vs)) / baseline;
        if min(vs) < dropThreshold || relDrop > 0.01
            dropCount = dropCount + 1;
            switch dropCount
                case 1
                    t1 = tNow;
                    fprintf("Dip 1 at %.4f s (%.4f V min)\n", t1, min(vs));
                case 2
                    t2 = tNow;
                    fprintf("Dip 2 at %.4f s (%.4f V min)\n", t2, min(vs));
                case 3
                    t3 = tNow;
                    fprintf("Dip 3 at %.4f s (%.4f V min)\n", t3, min(vs));
            end
            window = [];
            pause(0.2); % debounce
        end
    end
end
end
