function StrongmanGame(deviceID, motorChannel, solenoidChannel, LEDpowerChannel, PhotoDiodeinputChannel, UltrasonicOutputChannel, UltrasonicInputChannel)
  % The strongman game - main script version 3.0
  % Calls all functions in order to run the game.
  % Made by UTWENTE-BSC-EE-ESA group 3
  % version 3.0

    if nargin < 1, deviceID = "AD3_0"; end
    if nargin < 2, motorChannel = "ao0"; end
    if nargin < 3, solenoidChannel = "dio00"; end
    if nargin < 4, LEDpowerChannel = "V+"; end
    if nargin < 5, PhotoDiodeinputChannel = "ai0"; end
    if nargin < 6, UltrasonicOutputChannel = "ao1"; end
    if nargin < 7, UltrasonicInputChannel = "ai1"; end

    % Sample rate
    sampleRate = 5000; % Set the sample rate to 5 kHz for PWM

disp("Starting The Strongman Game")

disp("Initializing Analog Discovery 3")

% Create daq sessions and add outputs
    dqAO = daq("digilent");
    dqAO.Rate = sampleRate;
    addoutput(dqAO, deviceID, motorChannel, "Voltage");   % motor
    addoutput(dqAO, deviceID, UltrasonicOutputChannel, "Voltage");   % ultrasonic out

    dqAI = daq("digilent");
    dqAI.Rate = 10000;
    addinput(dqAI, deviceID, PhotoDiodeinputChannel, "Voltage");    % photodiode in
    addinput(dqAI, deviceID, UltrasonicInputChannel, "Voltage");    % ultrasonic in

    dqDigital = daq("digilent"); % On-demand IO
    addoutput(dqDigital, deviceID, solenoidChannel, "Digital");     % solenoid digital output

    % Put 5V on V+ rail for photodiode supply
    dqVplus = daq("digilent");
    addoutput(dqVplus, deviceID, LEDpowerChannel, "Voltage");
    write(dqVplus, 5);

%% ================= BACKGROUND LIGHT TRIGGERS =================
disp("Starting light trigger monitoring in background...")
[t1, t2, t3] = StrongmanGameLightTriggers(dqAI); % Calls separate light trigger function

%% ================= BACKGROUND ULTRASONIC =================
disp("Starting ultrasonic sensing in background...")
ultrasonicData = [];
t_ultra = timer('ExecutionMode','fixedSpacing','Period',0.05,...
    'TimerFcn',@(~,~)collectUltrasonic());
start(t_ultra);

%% ================= MOTOR CONTROL =================
disp("Calling Motor Control script")
StrongmanGameMotorControl(dqAO, dqDigital); % Calls motor control script

%% ================= STOP ULTRASONIC =================
stop(t_ultra);
delete(t_ultra);
h_measured = max(ultrasonicData);

disp("Calling height estimation script")
h_predicted = StrongmanGameHeightEstimation(t1, t2, t3);
fprintf("Predicted height: %.2f\n", h_predicted);
fprintf("Measured height: %.2f\n", h_measured);

disp("Calling rotary display driver script")
StrongmanGameRotaryDisplayDriver(h_measured);

% Clean up and release the DAQ session
write(dqVplus, 0);
release(dqAO);
release(dqAI);
release(dqDigital);
release(dqVplus);
daqreset;
disp("DAQ sessions released. Game ended.");

%% ================= CALLBACK =================
    function collectUltrasonic()
        h = StrongmanGameUltrasonicSensing(UltrasonicOutputChannel, UltrasonicInputChannel);
        ultrasonicData(end+1) = h;
    end
end
