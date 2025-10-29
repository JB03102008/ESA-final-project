function StrongmanGame(deviceID, motorChannel, solenoidChannel, LEDpowerChannel, PhotoDiodeinputChannel, UltrasonicOutputChannel, UltrasonicInputChannel)
  % The strongman game - main script version 2.0
  % Calls all functions in order to run the game.
  % Made by UTWENTE-BSC-EE-ESA group 3
  % version 2.1

    if nargin < 1, deviceID = "AD3_0"; end
    if nargin < 2, motorChannel = "ao0"; end
    if nargin < 3, solenoidChannel = "dio00"; end
    if nargin < 4, LEDpowerChannel = "V+"; end
    if nargin < 5, PhotoDiodeinputChannel = "ai0"; end
    if nargin < 6, UltrasonicOutputChannel = "ao1"; end
    if nargin < 7, UltrasonicInputChannel = "ai1"; end

    disp("=== Starting The Strongman Game ===")

    % start ultrasonic in background timer
    ultrasonicData = [];
    t_ultra = timer('ExecutionMode','fixedSpacing','Period',0.05,...
        'TimerFcn',@(~,~) collectUltrasonic());

    start(t_ultra);
    disp("Ultrasonic sensing started.")

    % Motor control + light triggers parallel
    % Hammer script is called by motor control script
    disp("Starting motor control...")
    motorFuture = parfeval(@StrongmanGameMotorControl, 0, deviceID, motorChannel, solenoidChannel);

    disp("Running light triggers...")
    [t1,t2,t3] = StrongmanGameLightTriggers(deviceID, LEDpowerChannel, PhotoDiodeinputChannel);

    % Height estimation script with input from light triggers
    disp("Calculating predicted height...")
    h_predicted = StrongmanGameHeightEstimation(t1,t2,t3);
    fprintf("Predicted height: %.2f\n", h_predicted);

    % Stop ultrasonic sensing
    stop(t_ultra);
    delete(t_ultra);

    % wait for motor to finish
    wait(motorFuture);

    % Compute max measured height
    h_measured = max(ultrasonicData);
    fprintf("Measured height: %.2f\n", h_measured);

    % Rotary display driver script with input from predicted height and
    % measured height
    disp("Activating rotary display...")
    StrongmanGameRotaryDisplayDriver(h_measured);

    disp("=== Game finished ===")

    function collectUltrasonic()
        h_measured = StrongmanGameUltrasonicSensing(UltrasonicOutputChannel, UltrasonicInputChannel);
        ultrasonicData(end+1) = h_measured;
    end
end
