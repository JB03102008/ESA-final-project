function [t1, t2, t3] = StrongmanGameLightTriggers(deviceID, AI, VP, voltageChannel, inputChannel)
%% Strongman Game - light triggers v2.0
% polls light sensors in real time
% Made by UTWENTE-BSC-EE-ESA group 3
% version 2.0

    % Default values if no input args are given
    if nargin < 1, AI = "AD3_0"; end
    if nargin < 2, VP = "V+"; end
    if nargin < 3, voltageChannel = "ai1"; end % FIX: Added 'end'
    if nargin < 4, inputChannel = "ai1"; end   % FIX: Assigned default value and added 'end'
    
    % DAQ sessions are configured in main script
    
    addoutput(VP, deviceID, voltageChannel, "Voltage");
    addinput(AI, deviceID, inputChannel, "Voltage");
    AI.Rate = 10000;
    sampleRate = AI.Rate;
    
    write(VP, 5);
    fprintf("V+ set to 5V\n");
    
    % --- Initialize ---
    t1 = NaN; t2 = NaN; t3 = NaN;
    dropCount = 0;
    tStart = tic;

    % Parameters (Calibrated values)
    DIP_THRESHOLD_V = 0.01; % Taken from successful test
    HYSTERESIS_V = 0.02;    % Hysteresis
    isTriggered = false;    
    
    % Pre-initializing the buffer is essential to prevent errors in the loop
    windowSize = 2 * sampleRate;
    window = zeros(windowSize, 1);
    bufferTime = 0.1;

    fprintf("Monitoring signal... (Blocking execution)\n");

    while dropCount < 3
        % Read small chunk
        data = read(AI, seconds(bufferTime));
        v = data{:,1};
        
        % Update rolling window
        if numel(v) < windowSize
            window = [window(numel(v)+1:end); v];
        else
             window = v;
        end

        % Analyze for dips
        if numel(window) > 50
            vs = smooth(window, 50);
        else
            vs = window;
        end
        
        currentBaseline = max(vs);
        detectionThreshold = currentBaseline - DIP_THRESHOLD_V;
        currentValue = vs(end);
        
        % Check for Trigger (Dip)
        if currentValue < detectionThreshold && ~isTriggered
            dropCount = dropCount + 1;
            tNow = toc(tStart);
            isTriggered = true; 

            switch dropCount
                case 1
                    t1 = tNow;
                    fprintf("Dip 1 detected at %.4f s\n", t1);
                case 2
                    t2 = tNow;
                    fprintf("Dip 2 detected at %.4f s\n", t2);
                case 3
                    t3 = tNow;
                    fprintf("Dip 3 detected at %.4f s\n", t3);
            end

        % Check for Reset (Hysteresis)
        elseif currentValue > (currentBaseline - HYSTERESIS_V) && isTriggered
            isTriggered = false; 
        end
    end

    write(VP, 0);
    fprintf("V+ reset to 0V\n");
end