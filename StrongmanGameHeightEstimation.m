%% 
% BALL HEIGHT ANALYSIS UNDER LINEAR DRAG
% This script estimates motion constants and maximum height
% for a vertically launched ball, given two (time, position) points.



% Keep multiple variables
clearvars -except h0 h1 h2 time1 time2 t0 hmax; close all; clc;

%% --- Known physical parameters ---
m = 3.5121e-3;        % mass [kg]
g = 9.81;             % gravity [m/s²]
k = 3.096e-06;       % Stokes drag coefficient [N·s/m]
alpha = k/m;          % k/m [1/s]
C = m*g/k;            % mg/k [m/s]

fprintf('--- Parameters ---\n');
fprintf('alpha = %.3e, C = %.6f\n\n', alpha, C);

%% --- INPUT YOUR TWO SENSOR MEASUREMENTS HERE ---
% (Time in seconds, position in meters)
% Example: lower sensor at t=0.03 s, y=0 m
%          upper sensor at t=0.075 s, y=0.15 m
t1 =0.0;   y1 = 0;     % <-- input 1st sensor reading
t2 =0.0351;   y2 = 0.15;% <-- input 2nd sensor reading
t3 =0.0765;   y3=0.3;%<---3rd sensor

%% --- Solve for integration constants A and B ---
% From y(t) = A + B*exp(-alpha*t) - C*t
coeff = [1, exp(-alpha*t1);
         1, exp(-alpha*t2)];
rhs = [y1 + C*t1; y2 + C*t2];
AB = coeff \ rhs;

A = AB(1);
B = AB(2);

fprintf('--- Integration constants ---\n');
fprintf('A = %.6f\nB = %.6f\n\n', A, B);

%% Compute t_max robustly
% alpha = k/m;  C = m*g/k;

log_arg = -alpha * B / C;   % NOTE: alpha*B inside log

if log_arg > 0 && isreal(log_arg)
    t_max = (1/alpha) * log(log_arg);
else
    % fallback: compute v0 and use fzero or the v0/g approximation
    v0 = -alpha*B - C;
    fprintf('Warning: analytic log argument <=0 (log_arg=%.3g). Using v0 to find t_max.\n', log_arg);
    if v0 > 0
        % approximate for small alpha:
        t_max = v0 / g;
    else
        % try numeric root find (look for root near the second sensor time)
        vfun = @(t) -alpha*B.*exp(-alpha*t) - C;
        try
            t_max = fzero(vfun, max([t1, t2, 0.01]));
        catch
            % last resort: set t_max to something reasonable
            t_max = max([t1, t2]);
        end
    end
end
y_max = A + B.*exp(-alpha*t_max) - C.*t_max;
fprintf('Initial max estimation = %.4f meters\n', y_max);
%% % ---  compute local average velocities ---
v21 = (y2 - y1) / (t2 - t1);
v32 = (y3 - y2) / (t3 - t2);

% --- acceleration at middle sensor (general unequal time formula) ---
y2_ddot = (2 / (t3 - t1)) * (v32 - v21);

% ---  velocity at middle sensor ---
y2_dot = (y3 - y1) / (t3 - t1);

% ---  effective friction coefficient (air drag + wall friction) ---
k_eff = -m * (y2_ddot + g) / y2_dot;

% Display results
fprintf('Estimated effective drag coefficient (k_eff) = %.6e N·s/m\n', k_eff);
fprintf('Intermediate values:\n  y_dot(t2) = %.5f m/s\n  y_ddot(t2) = %.5f m/s²\n', y2_dot, y2_ddot);
%% %% --- Solve for A_eff and B_eff (distinct variables) ---
alpha_eff = k_eff / m;
C_eff = m * g / k_eff;
coeff_eff = [1, exp(-alpha_eff*t1);
             1, exp(-alpha_eff*t2)];

rhs_eff = [y1 + C_eff*t1;
            y2 + C_eff*t2];

AB_eff = coeff_eff \ rhs_eff;
A_eff = AB_eff(1);
B_eff = AB_eff(2);

fprintf('\nA_eff = %.6f\nB_eff = %.6f\n', A_eff, B_eff);

%% --- Compute time of max height (y'(t_max) = 0) ---
t_max = -(1/alpha_eff) * log(-m*g / (k_eff * B_eff * alpha_eff));

%% --- Compute max height ---
y_max = A_eff + B_eff*exp(-alpha_eff*t_max) - C_eff*t_max;

%% --- Display Results ---
fprintf('\nFinal predicted maximum height: %.4f m\n', y_max);
fprintf('Time to reach max height: %.4f s\n', t_max);


%% --- Plot position and velocity ---
t_plot = linspace(0, 2*t_max, 300);
y_plot = A_eff + B_eff*exp(-alpha_eff*t_plot) - C_eff*t_plot;
v_plot = -B_eff*alpha_eff*exp(-alpha_eff*t_plot) - g;

figure;
subplot(2,1,1);
plot(t_plot, y_plot, 'b-', 'LineWidth', 2);
xlabel('Time (s)');
ylabel('Height (m)');
title('Predicted Height vs Time');
grid on;

