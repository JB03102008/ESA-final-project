function StrongmanGame(deviceID, motorChannel, solenoidChannel, LEDpowerChannel, PhotoDiodeinputChannel, UltrasonicOutputChannel, UltrasonicInputChannel)
  % The strongman game - main script version 2.0
  % Calls all functions in order to run the game.
  % Made by UTWENTE-BSC-EE-ESA group 3
  % version 2.2

    if nargin < 1, deviceID = "AD3_0"; end
    if nargin < 2, motorChannel = "ao0"; end
    if nargin < 3, solenoidChannel = "dio00"; end
    if nargin < 4, LEDpowerChannel = "V+"; end
    if nargin < 5, PhotoDiodeinputChannel = "ai1"; end
    if nargin < 6, UltrasonicOutputChannel = "ao1"; end
    if nargin < 7, UltrasonicInputChannel = "ai0"; end

    disp("Starting The Strongman Game")
    
    % Initialize and configure DAQ sessions
    disp('Initializing and configuring DAQ sessions...');

    % Motor Control Sessions (AO + DIO)
    s_Motor = daq("digilent");
    s_Motor.Rate = 5e3; 
    addoutput(s_Motor, deviceID, motorChannel, "Voltage");

    s_Solenoid = daq("digilent");
    addoutput(s_Solenoid, deviceID, solenoidChannel, "Digital");

    % Light Trigger Sessions

    AI = daq("digilent");
    VP = daq("digilent");
    
    disp('DAQ sessions initialized.');
    
    % start ultrasonic in background timer
    ultrasonicData = [];
    t_ultra = timer('ExecutionMode','fixedSpacing', 'Period', 0.05, ...
        'TimerFcn', @(~,~) collectUltrasonic());

    start(t_ultra);
    disp("Ultrasonic sensing started.")

    %% Start script execution
    
    % 1. Motor control
    disp("Starting motor control...")
    StrongmanGameMotorControl(s_Motor, s_Solenoid); 
    
    % 2. Light triggers
    disp("Motor control finished. Running light triggers...")
    [t1,t2,t3] = StrongmanGameLightTriggers(deviceID, AI, VP, LEDpowerChannel, PhotoDiodeinputChannel);
    
    %% Print times, put semicolons to hide
    fprintf("\nLight Trigger timestamps:\n");
    fprintf("t1: %.4f s\n", t1);
    fprintf("t2: %.4f s\n", t2);
    fprintf("t3: %.4f s\n", t3);
    
    % Stop ultrasonic sensing
    stop(t_ultra);
    delete(t_ultra);

    % Compute max measured height
    h_measured = max(ultrasonicData);
    fprintf("Measured max height (Ultrasonic): %.2f m\n", h_measured);

    % Height estimation script with input from light triggers
    disp("Calculating predicted height...")

    h_predicted = StrongmanGameHeightEstimation(t1,t2,t3);
    fprintf("Predicted height: %.2f m\n", h_predicted);

    % Rotary display driver script with input from predicted height and measured height
    disp("Activating rotary display...")
    StrongmanGameRotaryDisplayDriver(abs(round(h_measured)), 0);

    disp("Game finished")

    % Close all sessions
    delete(s_Motor); clear s_Motor;
    delete(s_Solenoid); clear s_Solenoid;
    disp('Closed DAQ sessions.');

    function collectUltrasonic()
    h_measured = StrongmanGameUltrasonicSensing(UltrasonicOutputChannel, UltrasonicInputChannel);
    ultrasonicData(end+1) = h_measured;
    end
end