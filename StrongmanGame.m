% The Strongman Game - main script - v0.1
% Calls all subscripts to run The Strongman Game
% Made by UTWENTE-BSC-EE-ESA group 3
% version 0.1

% AD3 IO configuration
deviceID = "AD3_0";
motorChannel = "ao0";
solenoidChannel = "dio00";
LEDpowerChannel = "V+";
PhotoDiodeinputChannel = "ai1";

disp("Starting The Strongman Game")

disp("Calling Motor Control script")
StrongmanGameMotorControl(deviceID, motorChannel, solenoidChannel); % Calls motor control script

disp("Calling light triggers script")
[t1, t2, t3] = StrongmanGameLightTriggers(deviceID, LEDpowerChannel, PhotoDiodeinputChannel); % Calls light triggers script

disp("Calling height estimation script")
StrongmanGameHeightEstimation() % Calls height estimation script
fprintf("Predicted height ",h_predicted)

disp("Calling ultrasonic sensing script")
StrongmanGameUltrasonicSensing() % Calls ultrasonic sensing script
fprintf("Measured height ",h_measured)

