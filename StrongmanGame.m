function StrongmanGame(deviceID, motorChannel, solenoidChannel, LEDpowerChannel, PhotoDiodeinputChannel)
  % The strongman game - main script version 2.0
  % Calls all functions in order to run the game.
  % Made by UTWENTE-BSC-EE-ESA group 3
  % version 2.0

    if nargin < 1, deviceID = "AD3_0"; end
    if nargin < 2, motorChannel = "ao0"; end
    if nargin < 3, solenoidChannel = "dio00"; end
    if nargin < 4, LEDpowerChannel = "V+"; end
    if nargin < 5, PhotoDiodeinputChannel = "ai1"; end

    disp("=== Starting The Strongman Game ===")

    % start ultrasonic in background timer
    ultrasonicData = [];
    t_ultra = timer('ExecutionMode','fixedSpacing','Period',0.05,...
        'TimerFcn',@(~,~) collectUltrasonic());

    start(t_ultra);
    disp("Ultrasonic sensing started.")

    % motor + light triggers "parallel"
    disp("Starting motor control...")
    motorFuture = parfeval(@StrongmanGameMotorControl, 0, deviceID, motorChannel, solenoidChannel);

    disp("Running light triggers...")
    [t1,t2,t3] = StrongmanGameLightTriggers(deviceID, LEDpowerChannel, PhotoDiodeinputChannel);

    % height estimation
    disp("Calculating predicted height...")
    h_predicted = StrongmanGameHeightEstimation(t1,t2,t3);

    % stop ultrasonic sensing
    stop(t_ultra);
    delete(t_ultra);

    % wait for motor to finish
    wait(motorFuture);

    % compute max measured height
    h_measured = max(ultrasonicData);
    fprintf("Predicted height: %.2f\n", h_predicted);
    fprintf("Measured height: %.2f\n", h_measured);

    disp("Activating rotary display...")
    StrongmanGameRotaryDisplayDriver(h_measured);

    disp("=== Game finished ===")

    function collectUltrasonic()
        h = StrongmanGameUltrasonicSensing();
        ultrasonicData(end+1) = h;
    end
end
