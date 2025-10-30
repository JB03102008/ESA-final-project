function StrongmanGameMotorControl(dqMotor, dqSolenoid)
%% The Strongman Game - Motor control script v1.0 (First final version)
% Strongman Game - Motor (clocked square wave) + Solenoid (digital)
% Uses separate DAQ sessions to keep clocked AO active
% Made by UTWENTE-BSC-EE-ESA group 3
% Version: 1.0

%% ================= SETUP PARAMETERS =================
PWMfreq = 1e3;                     % Square-wave frequency [Hz]
minDuty = 20;                      % Minimum duty cycle [%]
maxDuty = 70;                      % Maximum duty cycle [%]
solenoidTime = 0.3;                % Solenoid activation duration [s]
sampleRate = 5e3;                  % Analog output sample rate [Hz]

%% ================= INITIALIZE DEVICES =================

% DAQ sessions init happens in main script

% --- Motor session (clocked AO) ---
sampleRate = dqMotor.Rate; % Use the Rate from the passed session

% --- Solenoid session (on-demand DO) ---

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
disp('Devices released. Sequence complete.');
end