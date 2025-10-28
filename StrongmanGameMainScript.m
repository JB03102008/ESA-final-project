% The Strongman Game - main script - v0.1
% Calls all subscripts to run The Strongman Game
% Made by UTWENTE-BSC-EE-ESA group 3
% version 0.1
disp("Starting The Strongman Game")

disp("Calling Motor Control script")
StrongmanGameMotorControl() % Calls motor control script

disp("Calling light triggers script")
StrongmanGameLightTriggers() % Calls light triggers script

disp("Calling height estimation script")
StrongmanGameHeightEstimation() % Calls height estimation script
fprintf("Predicted height ",h_predicted)

disp("Calling ultrasonic sensing script")
StrongmanGameUltrasonicSensing() % Calls ultrasonic sensing script
fprintf("Measured height ",h_measured)

