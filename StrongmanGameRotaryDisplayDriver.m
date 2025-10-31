% The Strongman Game - rotary display driver script version 1.0
% Displays a number defined in the input variable on a rotary display
% Example usage: StrongmanGameRotaryDisplayDriver(67, 0) 
% 67 is displayed, logging level is set to 0
%
% Made by Jibbe Sutorius as part of the ESA final project group 3
% version 1.0

% Example usage:
StrongmanGameRotaryDisplayDriver(67, 0);     % first argument is input number, second is log level where 0 = no logs or output, 1 = errors and warnings, 2 = debug data

function StrongmanGameRotaryDisplayDriver(input, loggingLevel)
% Define some constants
sPort = 4210;                                                               %The UDP port we are using for communication TO the ESP32
rPort = 4211;                                                               %The UDP port we are using for communication FROM the ESP32

ps=0.002;                                                                   %Pause between sending udp packets to ESP32. Too fast, and packets will be missed

espIP = "192.168.4.1";                                                      %IPv4 address of ESP32 (server)

%Get some image data from a file NOTE: you need to modify imageLocation to
%fit your own computer folder structure!
imageLocation = 'RotaryDisplayIMG\123.png';
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



inputNumber = input;
logLevel = loggingLevel; % 0 = no logs or output, 1 = errors and warnings, 2 = debug data
colorState = 0;
packets = 50;

while true
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
    imagedataDigit1 = imread('RotaryDisplayIMG\1.png');
    imagedataDigit2 = imread('RotaryDisplayIMG\2.png');
    imagedataDigit3 = imread('RotaryDisplayIMG\3.png');
    imagedataDigit4 = imread('RotaryDisplayIMG\4.png');
    imagedataDigit5 = imread('RotaryDisplayIMG\5.png');
    imagedataDigit6 = imread('RotaryDisplayIMG\6.png');
    imagedataDigit7 = imread('RotaryDisplayIMG\7.png');
    imagedataDigit8 = imread('RotaryDisplayIMG\8.png');
    imagedataDigit9 = imread('RotaryDisplayIMG\9.png'); 
    imagedataDigit0 = imread('RotaryDisplayIMG\0.png'); 

    imagedataDigit1 = imagedataDigit1(:,:,1);
    imagedataDigit2 = ~imagedataDigit2(:,:,1);
    imagedataDigit3 = ~imagedataDigit3(:,:,1);
    imagedataDigit4 = ~imagedataDigit4(:,:,1);
    imagedataDigit5 = ~imagedataDigit5(:,:,1);
    imagedataDigit6 = imagedataDigit6(:,:,1);
    imagedataDigit7 = ~imagedataDigit7(:,:,1);
    imagedataDigit8 = imagedataDigit8(:,:,1);
    imagedataDigit9 = imagedataDigit9(:,:,1);
    imagedataDigit0 = ~imagedataDigit0(:,:,1);

    imagedataSubScript = imread('RotaryDisplayIMG\yay.png'); 
    imagedataSubScript = ~imagedataSubScript(:,:,1);

    char = num2str(inputNumber);
    length = strlength(char);
    initialSpacing = 0;
    spacing = 1;
    finalImage = zeros(12,24);

    for i = 1:length
     switch char(i)
         case "0"
             finalImage = AddDigitToImage(finalImage, imagedataDigit0, i, initialSpacing, spacing);
         case "1"
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
    image = ~finalImage;
    log(image, 2, logLevel);

end

function A = AddDigitToImage(A, B, i, initialSpacing, spacing)
    x = initialSpacing+(i-1)*size(B,2)+(i-1)*spacing+1;
    A(:, x:x+size(B,2)-1) = B;
end

function A = AddSubScriptToImage(A,B, spacing)
    A(:, spacing:spacing+size(B,2)-1) = B;
end



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


function log(message, importance, loglevel)
    if importance <= 0 || importance > 2
        disp("ya made a dumb dumb at the following log message!!!!!!!!!!!!!!!:");
        disp(message);
    elseif importance <= loglevel
        disp(message);
    end

end
