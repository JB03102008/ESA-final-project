%% The Strongman Game - Motor control script v2.0
% Strongman Game - Motor (clocked square wave) + Solenoid (digital)
% Uses separate DAQ sessions to keep clocked AO active
% Example usage: StrongmanGameMotorControl("AD3", "ao1", "dio00")
% Device ID is AD3, motor connected to ao1 and solenoid connected to dio00
%
% Made by Jasper Bloemendal as part of the ESA final project group 3
% Version: 2.0

function StrongmanGameMotorControl(deviceID, motorChannel, solenoidChannel)

if nargin < 3
    error('Not enough input arguments. Please provide deviceID, motorChannel, and solenoidChannel.');
end
%% ================= SETUP PARAMETERS =================
PWMfreq = 1e3;                     % Square-wave frequency [Hz]
minDuty = 20;                      % Minimum duty cycle [%]
maxDuty = 70;                      % Maximum duty cycle [%]
solenoidTime = 0.3;                % Solenoid activation duration [s]
sampleRate = 5e3;                  % Analog output sample rate [Hz]

%% ================= INITIALIZE DEVICES =================
disp('Initializing Analog Discovery 3 for clocked AO and digital DO...');

% --- Motor session (clocked AO) ---
dqMotor = daq("digilent");
dqMotor.Rate = sampleRate;
addoutput(dqMotor, deviceID, motorChannel, "Voltage");

% --- Solenoid session (on-demand DO) ---
dqSolenoid = daq("digilent");
addoutput(dqSolenoid, deviceID, solenoidChannel, "Digital");

disp('Devices initialized successfully.');

%% ================= HAMMER INPUT (SIMULATED) =================
rng('shuffle');
[Voltage, t] = StrongmanGameHammer();

%% ================= PROCESS HAMMER DATA =================
peakValue = max(Voltage);
fprintf('Peak hammer voltage: %.2f µV\n', peakValue);

% Map hammer impact to duty cycle only
normVal = min(max(peakValue / 300, 0), 1);
dutyCycle = minDuty + normVal * (maxDuty - minDuty);   % [%]
amplitude = 5.0;                                       % always 5 V

fprintf('Mapped duty cycle: %.1f%%\n', dutyCycle);
fprintf('Fixed amplitude: %.2f V\n', amplitude);

%% ================= GENERATE CLOCKED WAVEFORM =================
runTime = 0.4 + 0.004 * dutyCycle;     % total motor run time [s]
t_ac = (0:1/sampleRate:runTime)';      % time vector

% Generate 0–5 V PWM (unipolar)
motorSignal = amplitude * ((square(2*pi*PWMfreq*t_ac, dutyCycle) + 1) / 2);

disp(['Generating ', num2str(PWMfreq), ' Hz PWM, ', ...
      num2str(dutyCycle, '%.1f'), '% duty, amplitude ', ...
      num2str(amplitude, '%.2f'), ' V (unipolar)...']);

%% ================= ACTUATE MOTOR AND SOLENOID (OVERLAP) =================
disp('Starting motor and solenoid sequence...');

preload(dqMotor, motorSignal);
start(dqMotor);   % Non-blocking start

pause(0.2);      % optional sync delay
disp('Activating solenoid...');
write(dqSolenoid, true);
pause(solenoidTime);
write(dqSolenoid, false);
disp('Solenoid released.');

pause(runTime);
write(dqMotor, 0);
disp('Motor stopped.');

%% ================= CLEANUP =================
clear dqMotor dqSolenoid;
disp('Devices released. Sequence complete.');
clear all;
end