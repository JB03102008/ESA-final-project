function StrongmanGame(deviceID, motorChannel, solenoidChannel, LEDpowerChannel, PhotoDiodeinputChannel, UltrasonicOutputChannel, UltrasonicInputChannel)
  % The strongman game - main script version 2.5
  % Calls all functions in order to run the game.
  % Made by UTWENTE-BSC-EE-ESA group 3
  % version 2.5

    if nargin < 1, deviceID = "AD3_0"; end
    if nargin < 2, motorChannel = "ao0"; end
    if nargin < 3, solenoidChannel = "dio00"; end
    if nargin < 4, LEDpowerChannel = "V+"; end
    if nargin < 5, PhotoDiodeinputChannel = "ai0"; end
    if nargin < 6, UltrasonicOutputChannel = "ao1"; end
    if nargin < 7, UltrasonicInputChannel = "ai1"; end

disp("Starting The Strongman Game")

disp("Calling Motor Control script")
StrongmanGameMotorControl(deviceID, motorChannel, solenoidChannel); % Calls motor control script

disp("Calling light triggers script")
[t1, t2, t3] = StrongmanGameLightTriggers(deviceID, LEDpowerChannel, PhotoDiodeinputChannel); % Calls light triggers script


disp("Calling height estimation script")
h_predicted = StrongmanGameHeightEstimation(t1, t2, t3) % Calls height estimation script with input from light triggers
fprintf("Predicted height ",h_predicted)

disp("Calling ultrasonic sensing script")
h_measured = StrongmanGameUltrasonicSensing(UltrasonicOutputChannel, UltrasonicInputChannel) % Calls ultrasonic sensing script

fprintf("Measured height ",h_measured)

disp("Calling rotary display driver script")
StrongmanGameRotaryDisplayDriver(h_measured); % Calls rotary display driver script

end