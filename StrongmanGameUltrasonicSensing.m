%% The Strongman Game - Ultrasonic sensing script v1.0
% Reads out maximum height from an ultrasonic sensor using an AD3 and the
% Waveforms SDK. AD2Lib files are required.
%
% Made by Sven Heijmans as part of the ESA final project group 3
% Version: 1.0

function maxHeight = StrongmanGameUltrasonicSensing()
%% --- Initialize device ---
AD2close();
hdwf = AD2Init();
if hdwf == 0
    error('Device failed to open.');
end

tube_length = 1;          % tube height in meters
loops = 500;              % number of measurement loops
heights = NaN(1, loops);  % preallocate array for heights

%% --- Prepare waveform ---
flat = zeros(1, 39500);
y = sin(10*pi*(0:499)/500);
wave = [y, flat];         % 40,000 samples
bufferSize = length(wave);

%% --- Configure analog output ---
AD2initAnalogOut(hdwf, 0, 100, 5, 0, 30);
AD2setCustomAnalogOut(hdwf, 0, wave);

%% --- Configure analog input ---
AD2initAnalogIn(hdwf, 0, 1e6, 0.5, bufferSize, 5);

%% --- Measurement loop ---
minimumEchoDelay = 1.25e-3;   % 1.25 ms
minimumEchoVoltage = 0.01;    % avoid noise
speedOfSound = 343;           % m/s

for k = 1:loops
    % Start acquisition
    AD2StartAnalogIn(hdwf);
    AD2StartAnalogOut(hdwf, 0);

    % Wait until full buffer is acquired
    samplesAcquired = 0;
    inputData = [];
    while samplesAcquired < bufferSize
        temp = AD2GetAnalogData(hdwf, 0, bufferSize - samplesAcquired);
        if ~isempty(temp)
            inputData = [inputData, temp];
            samplesAcquired = length(inputData);
        end
        pause(0.001);
    end

    % Time vector
    t = (0:bufferSize-1)/1e6;

    % Find all peaks
    [pks, locs] = findpeaks(inputData, t,'MinPeakProminence', minimumEchoVoltage,'MinPeakDistance', 0.001);

    if isempty(pks)
        continue;  % skip if no peaks
    end

    % Transmit peak: first peak in the signal (up to first 10 peaks)
    nCheck = min(10, length(pks));
    [transmitVoltage, idxTransmit] = max(pks(1:nCheck));
    transmitTime = locs(idxTransmit);

    % Echo peak: first strong peak after minimum echo delay
    echoCandidates = find(locs > (transmitTime + minimumEchoDelay) & pks >= minimumEchoVoltage);
    if ~isempty(echoCandidates)
        [echoVoltage, strongest] = max(pks(echoCandidates));
        echoTime = locs(echoCandidates(strongest));

        % Compute height
        timeOfFlight = echoTime - transmitTime;
        distance = (timeOfFlight * speedOfSound) / 2;
        heights(k) = tube_length - distance;
    end
end

%% --- Get maximum height ---
maxHeight = max(heights);
fprintf('Maximum height measured: %.3f m\n', maxHeight);

%% --- Close device ---

AD2close();

end