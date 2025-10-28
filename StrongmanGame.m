function = StrongmanGame(deviceID, motorChannel, solenoidChannel, LEDpowerChannel, PhotoDiodeinputChannel)
% The Strongman Game - main script - v0.1
% Calls all subscripts to run The Strongman Game
% Made by UTWENTE-BSC-EE-ESA group 3
% version 1.0

% Default AD3 IO configuration, will be used when no input arguments are
% supplied
if nargin < 1, deviceID = "AD3_0";
if nargin < 2, motorChannel = "ao0";
if nargin < 3, solenoidChannel = "dio00";
if nargin < 4, LEDpowerChannel = "V+";
if nargin < 5, PhotoDiodeinputChannel = "ai1";

disp("Starting The Strongman Game")

disp("Calling Motor Control script")
StrongmanGameMotorControl(deviceID, motorChannel, solenoidChannel); % Calls motor control function

disp("Calling light triggers script")
[t1, t2, t3] = StrongmanGameLightTriggers(deviceID, LEDpowerChannel, PhotoDiodeinputChannel); % Calls light triggers function

disp("Calling height estimation script")
StrongmanGameHeightEstimation() % Calls height estimation function
fprintf("Predicted height ",h_predicted) % Displays predicted height based on differential equations from height estimation script

disp("Calling ultrasonic sensing script")
StrongmanGameUltrasonicSensing() % Calls ultrasonic sensing function
fprintf("Measured height ",h_measured) % Displays measured height from ultrasonic sensor

