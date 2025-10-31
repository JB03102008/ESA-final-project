%% The Strongman Game - ultrasonic and rotary display script v1.0
% Combination of the ultrasonic and rotary display script. Displays the
% output of the ultrasonic sensor on the rotary display.
% Example usage: StrongmanGameUltrasonicAndRotary()
% Uses Waveforms SDK, AD2Lib required
%
% Made by Sven Heijmans and Jibbe Sutorius as part of the ESA final project group 3
% Version 1.0

%% --- Initialize device ---
AD2close();
hdwf = AD2Init();
if hdwf == 0
    error('Device failed to open.');
end

tube_length = 1.1;          % tube height in meters
loops = 100;              % number of measurement loops
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
%% --- Plot results ---
figure;

% Plot last voltage readout
subplot(2, 1, 1);
plot(t, inputData);
title('Last Voltage Readout');
xlabel('Time (s)');
ylabel('Voltage (V)');
grid on;

% Plot height measurements
subplot(2, 1, 2);
plot(1:loops, heights, '-o');
title('Height Measurements');
xlabel('Loop Number');
ylabel('Height (m)');
grid on;

%% --- Get maximum height ---
maxHeight = round(max(heights)*100);
fprintf('Maximum height measured: %.3f cm\n', maxHeight);
rotaryDisplay(maxHeight, 1);

%% --- Close device ---

AD2close();
%% 
%% Initialisation part of this file
%
% This example has been written by Henk-Jan Boven Mathieu Odijk for module ESA 2021.
% The file has been updated by Bogdan Breazu, Joep Bakker and Tom Hartman.
% Make sure to read the comments, especially when your file is causing an
% error.
%
% A fair warning in advance: UDP is a passive protocol, meaning it is not checked if packets arrive.
% A mistake often made is trying to communicate to the ESP32, while you are
% in fact connected to the wrong WiFi network. This will NOT give you an
% error, instead code will just not respond. Pressing ctrl+C in the command
% window will at least make Matlab responsive again.

%rotaryDisplay(67, 1); % first arg = input number, 2nd arg is loglevel: 0 = no logs or output, 1 = errors and warnings, 2 = debug data


function rotaryDisplay(input, loggingLevel)

% Define some constants
sPort = 4210;                                                               %The UDP port we are using for communication TO the ESP32
rPort = 4211;                                                               %The UDP port we are using for communication FROM the ESP32

ps=0.002;                                                                   %Pause between sending udp packets to ESP32. Too fast, and packets will be missed

espIP = "192.168.4.1";                                                      %IPv4 address of ESP32 (server)

%Get some image data from a file NOTE: you need to modify imageLocation to
%fit your own computer folder structure!
imageLocation = 'C:\Users\sven\Documents\img\123.png';
imagedata = imread(imageLocation); 
% For your own project, you do not have to use images, you are also allowed to create matrices with the correct data in matlab.

image = imagedata(:,:,1);

numleds = 12;                                                               %Number of leds on the PCB
numrows = size(image,1);                                                    %The height of the array
numcolumn = size(image,2);                                                  %The width of the array

%Initiate UDP sender and receiver
udps = dsp.UDPSender('RemoteIPPort',sPort,'RemoteIPAddress',espIP);
udpr = dsp.UDPReceiver('LocalIPPort',rPort);

setup(udpr); 

if numleds ~= numrows                                                       %Check the height of the image
    disp('Are you sure you have the right image size?')
end

                                                        %Send the command to the ESP32

%% This is an example to select a different sensor from the IMU

dispCommand = uint8(zeros(numleds,1));                                      %create an empty display packet to contain command
dispCommand(1)=4;                                                           %the number 4 indicates we are sending a sensor value
dispCommand(2)=1;                                                           %value 3 means we are selecting the accelerometer Z sensor
udps(dispCommand);                                                          %send the command.

%% This example shows how to receive the accelerometer data from the ESP32
%readIndex = 0;


inputNumber = input;
logLevel = loggingLevel; % 0 = no logs or output, 1 = errors and warnings, 2 = debug data
colorState = 0;
packets = 50;

for q = 1:10
    image = setImageNumberTo(inputNumber, logLevel);


    dataSend = uint8(ones(numleds,numcolumn)*250);                              %Create an empty array of display data to send to ESP32
    dataSend(1,:) = 1;                                                          %This indicates our packet contains display data
    dataSend(2,:) = 0:numcolumn-1;                                              %We fill our dataSend array with the column numbers
    dataSend(5,:) = 255 * abs(abs(mod(colorState-0,3)-1)-1);                                                          %The red value for our columns
    dataSend(6,:) = 255 * abs(abs(mod(colorState-1,3)-1)-1);                                                          %The green value for our columns
    dataSend(7,:) = 255 * abs(abs(mod(colorState-2,3)-1)-1);                                                        %The blue value for our columns
    dataSend(3,:) =  uint8(bin2dec(char([image(1:4,:)' + '0'])));               %We provide our led matrix with values of L1 to L4 to be on or off.
    dataSend(4,:) =  uint8(bin2dec(char([image(5:12,:)' + '0'])));              %We provide our led matrix with values of L5 to L12 to be on or off.
    
    colorState = colorState + 1;
    log("colorstate "+ colorState, 2, logLevel);

    for i=1:numcolumn
        udps(dataSend(:,i));                                                    %Send out the leddata, column by column.
        pause(ps);                                                              %Wait for the ESP32 to process our packet completely
    end

    %% request acceloremeter data (X axis)
    dispCommand = uint8(zeros(numleds,1));                                      %create an empty display packet to contain command
    dispCommand(1)=4;                                                           %the number 4 indicates we are sending a sensor value
    dispCommand(2)=1;                                                           %value 3 means we are selecting the accelerometer Z sensor
    udps(dispCommand); 

    %% recieve acceloremeter data
    datapointsPerPacket = 20;                                                   %Each packet contains 20 datapoints
    datapointSize = 6;                                                          % Each datapoint is 6 bytes long
    %packets = 50;                                                               % Number of packets to read
    dataRead = zeros(1,packets);                                                % Initialize sensor data array
    dataReadTimes = zeros(1,packets);                                           % Initialize sensor time array  

    resultIndex = 1;
    for i = 1:packets                                                           %Step through all the packets                                                  %Clear the data 
        dataReceived = [];
        while (size(dataReceived, 1) == 0)                                      % Check if any data was received    
            dataReceived = udpr();                                                  %Call the raw sensor data, returns [] if not available
        end
        dataReshaped = reshape(dataReceived, datapointSize, datapointsPerPacket);   % Reshape the data for easier interpretation
        for j = 1:datapointsPerPacket
            value = typecast(uint8(dataReshaped(1:2, j)), 'int16');             % Sensor output value
            time = typecast(uint8(dataReshaped(3:6, j)), 'uint32');             % Measurement time of datapoint in microseconds
            dataReadTimes(resultIndex) = time;                                  % Store time in array
            dataRead(resultIndex)=value;                                        % Store datapoint in array
            resultIndex = resultIndex + 1;                                      % Increment index by 1 for next datapoint
        end
                  %Get the sensor data
    end

    %% find timing factor
    max = islocalmax(dataRead,'MinProminence', 1000);
    maxi = find(max==1);
    Times = dataReadTimes(maxi);
    DIFF = diff(Times);
    Mean = mean(DIFF);
    timingFactor = 1000000/Mean;
    if ~(timingFactor >= 1) % error check to make sure the value is valid, especially useful to prevent erroring when not spinning
        timingFactor = 1;
        log("ERROR: timing factor is fucked, is the display spinning?", 1, logLevel);
    end
    log("timingFactor: " + timingFactor, 2, logLevel);
%% Send timing data to the ESP32, with a check for packet loss and such

    if checkLinearArray(dataReadTimes, 10000, logLevel)==1 %check for errors in the recieved data
        dispCommand = uint8(zeros(numleds,1));                                      %Create an empty display packet to contain command
        dispCommand(1)=3;                                                           %Where 3 indicates that we are going to send timing data
        timing = round((1000000) / (numcolumn*timingFactor));                                                     %Blink the image once per second, this variable should be changed accordingly
    
        tim_bin=dec2bin(timing,32);                                                 %Convert the timing into binary format
        dispCommand(2) = bin2dec(tim_bin(25:32));                                   %Since UDP can only send 8 bits, we are going to send it byte by byte, this is the low part
        dispCommand(3) = bin2dec(tim_bin(17:24));                                   %Then the next 8 bits
        dispCommand(4) = bin2dec(tim_bin(9:16));                                    %And the next
        dispCommand(5) = bin2dec(tim_bin(1:8));                                     %And finally the high byte of our timing value
        udps(dispCommand);
    else
        log("ERROR: IMU data does not have consistent timing", 1, logLevel);
    end
   
    %% plotting the figure with maxima
    if logLevel == 2
        figure(1)                                                                   %Plot the figure
        title('Data Received')
        plot(dataReadTimes, dataRead)
        plot(dataReadTimes, dataRead, dataReadTimes(max), dataRead(max), 'r*')
        xlabel('')
        ylabel('')
        %readIndex = readIndex + 1;
        pause(1.0);     % somehow necesarry for plotting the data live
    end
end
end
%%  plot figure with maxima
%max = islocalmax(dataRead,'MinProminence', 3100);
%figure(2)                                                                   %Plot the figure
%maxi = find(max==1)
%Times = dataReadTimes(maxi)
%DIFF = diff(Times)
%Mean = mean(DIFF)
%X = 1:200
%plot(X, dataRead, X(max), dataRead(max), 'r*')

%%
function image = setImageNumberTo(inputNumber, logLevel)
    imagedataDigit1 = imread('C:\Users\sven\Documents\img\1.png');
    imagedataDigit2 = imread('C:\Users\sven\Documents\img\2.png');
    imagedataDigit3 = imread('C:\Users\sven\Documents\img\3.png');
    imagedataDigit4 = imread('C:\Users\sven\Documents\img\4.png');
    imagedataDigit5 = imread('C:\Users\sven\Documents\img\5.png');
    imagedataDigit6 = imread('C:\Users\sven\Documents\img\6.png');
    imagedataDigit7 = imread('C:\Users\sven\Documents\img\7.png');
    imagedataDigit8 = imread('C:\Users\sven\Documents\img\8.png');
    imagedataDigit9 = imread('C:\Users\sven\Documents\img\9.png'); 
    imagedataDigit0 = imread('C:\Users\sven\Documents\img\0.png'); 

    imagedataDigit1 = imagedataDigit1(:,:,1);
    imagedataDigit2 = ~imagedataDigit2(:,:,1);
    imagedataDigit3 = ~imagedataDigit3(:,:,1);
    imagedataDigit4 = ~imagedataDigit4(:,:,1);
    imagedataDigit5 = ~imagedataDigit5(:,:,1); % ??????????? WTF
    imagedataDigit6 = imagedataDigit6(:,:,1);
    imagedataDigit7 = ~imagedataDigit7(:,:,1); % same thing, I got no fucking clue. btw all the other ones are redundent but oh well
    imagedataDigit8 = imagedataDigit8(:,:,1);
    imagedataDigit9 = imagedataDigit9(:,:,1);
    imagedataDigit0 = ~imagedataDigit0(:,:,1);

    imagedataSubScript = imread('C:\Users\sven\Documents\img\yay.png'); 
    imagedataSubScript = ~imagedataSubScript(:,:,1);


% For your own project, you do not have to use images, you are also allowed to create matrices with the correct data in matlab.

    %finalImage(:, 3:3+size(imagedataDigit1,2)-1) = imagedataDigit1
    %finalImage = AddDigitArrayAtColumn(finalImage, imagedataDigit1, 3)

%%

    char = num2str(inputNumber);
    %firstDigit = char(3)
    length = strlength(char);
    initialSpacing = 0;
    spacing = 1;
    finalImage = zeros(12,24);

    for i = 1:length
     %display(i);
     switch char(i)
         case "0"
             %display("0");
             finalImage = AddDigitToImage(finalImage, imagedataDigit0, i, initialSpacing, spacing);
         case "1"
             %display("1");
             finalImage = AddDigitToImage(finalImage, imagedataDigit1, i, initialSpacing, spacing);
         case "2"
             finalImage = AddDigitToImage(finalImage, imagedataDigit2, i, initialSpacing, spacing);
         case "3"
             finalImage = AddDigitToImage(finalImage, imagedataDigit3, i, initialSpacing, spacing);
         case "4"
             finalImage = AddDigitToImage(finalImage, imagedataDigit4, i, initialSpacing, spacing);
         case "5"
             finalImage = AddDigitToImage(finalImage, imagedataDigit5, i, initialSpacing, spacing);
         case "6"
             finalImage = AddDigitToImage(finalImage, imagedataDigit6, i, initialSpacing, spacing);
         case "7"
             finalImage = AddDigitToImage(finalImage, imagedataDigit7, i, initialSpacing, spacing);
         case "8"
             finalImage = AddDigitToImage(finalImage, imagedataDigit8, i, initialSpacing, spacing);
         case "9"
             finalImage = AddDigitToImage(finalImage, imagedataDigit9, i, initialSpacing, spacing);
    
        end
    end
    %finalImage = AddSubScriptToImage(finalImage, imagedataSubScript, 13)
    image = ~finalImage;
    %image(12,:) = 0;
    log(image, 2, logLevel);

end
%%
function A = AddDigitToImage(A, B, i, initialSpacing, spacing)
    x = initialSpacing+(i-1)*size(B,2)+(i-1)*spacing+1;
    A(:, x:x+size(B,2)-1) = B;
end

function A = AddSubScriptToImage(A,B, spacing)
    A(:, spacing:spacing+size(B,2)-1) = B;
end


%%
function isLinear = checkLinearArray(arr, tol, logLevel)
    % Check if the array is linear within the given tolerance
    if nargin < 2
        tol = 1e-6;  % Default tolerance if not specified
    end
    
    % Calculate the differences between consecutive elements
    diffs = diff(arr);
    
    % Check if the differences are constant (within tolerance)
    diffMean = mean(diffs);
    isLinear = all(abs(diffs - diffMean) <= tol);
    max(abs(diffs - diffMean));

    if isLinear
        log('Array is linear within tolerance.', 2, logLevel);
    else
        log('Array is not linear within tolerance.', 2, logLevel);
    end
end

%%
function log(message, importance, loglevel)
    if importance <= 0 || importance > 2
        disp("ya made a dumb dumb at the following log message!!!!!!!!!!!!!!!:");
        disp(message);
    elseif importance <= loglevel
        disp(message);
    end
end