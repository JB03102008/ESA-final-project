%% The Strongman Game - height estimation script v1.0
% Height estimation based on projectile motion with air resistance.
% Calculates the predicted max height (h_predicted) from three measured
% trigger times (t1, t2, t3).
%
% Made by Abdallah Mohamed as part of the ESA final project group 3
% version 1.0

function h_predicted = StrongmanGameHeightEstimation(t1, t2, t3)

%% BALL HEIGHT ANALYSIS UNDER LINEAR DRAG
clc;

%% --- Known physical parameters ---
m = 3.5121e-3;       % mass [kg]
g = 9.81;            % gravity [m/s²]
k = 3.096e-06;       % Stokes drag coefficient [N·s/m]
alpha = k/m;         % k/m [1/s]
C = m*g/k;           % mg/k [m/s]

fprintf('--- Parameters ---\n');
fprintf('alpha = %.3e, C = %.6f\n\n', alpha, C);

%% --- Sensor height readings (modify as needed) ---
% These heights correspond to each sensor position
y1 = 0.00;           % [m]
y2 = 0.15;           % [m]
y3 = 0.30;           % [m]

%% --- Solve for integration constants A and B ---
coeff = [1, exp(-alpha*t1);
         1, exp(-alpha*t2)];
rhs = [y1 + C*t1;
       y2 + C*t2];
AB = coeff \ rhs;
A = AB(1);
B = AB(2);

fprintf('--- Integration constants ---\n');
fprintf('A = %.6f\nB = %.6f\n\n', A, B);

%% --- Compute t_max robustly ---
log_arg = -alpha * B / C;   % NOTE: alpha*B inside log

if log_arg > 0 && isreal(log_arg)
    t_max = (1/alpha) * log(log_arg);
else
    v0 = -alpha*B - C;
    fprintf('Warning: analytic log argument <=0 (log_arg=%.3g). Using v0 to find t_max.\n', log_arg);
    if v0 > 0
        t_max = v0 / g;
    else
        vfun = @(t) -alpha*B.*exp(-alpha*t) - C;
        try
            t_max = fzero(vfun, max([t1, t2, 0.01]));
        catch
            t_max = max([t1, t2]);
        end
    end
end

y_max = A + B.*exp(-alpha*t_max) - C.*t_max;
fprintf('Initial max estimation (air drag only) = %.4f meters\n', y_max);

%% --- Compute local average velocities ---
v21 = (y2 - y1) / (t2 - t1);
v32 = (y3 - y2) / (t3 - t2);

% --- acceleration at middle sensor (general unequal time formula) ---
y2_ddot = (2 / (t3 - t1)) * (v32 - v21);

% --- velocity at middle sensor ---
y2_dot = (y3 - y1) / (t3 - t1);

% --- effective friction coefficient (air drag + wall friction) ---
k_eff = -m * (y2_ddot + g) / y2_dot;

fprintf('Estimated effective drag coefficient (k_eff) = %.6e N·s/m\n', k_eff);
fprintf('Intermediate values:\n  y_dot(t2) = %.5f m/s\n  y_ddot(t2) = %.5f m/s²\n', y2_dot, y2_ddot);

%% --- Solve for A_eff and B_eff (distinct variables) ---
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
t_max_eff = -(1/alpha_eff) * log(-m*g / (k_eff * B_eff * alpha_eff));

%% --- Compute max height ---
y_max_eff = A_eff + B_eff*exp(-alpha_eff*t_max_eff) - C_eff*t_max_eff;

%% --- Display Results ---
fprintf('\nFinal predicted maximum height: %.4f m\n', y_max_eff);
fprintf('Time to reach max height: %.4f s\n', t_max_eff);

%% --- Plot position and velocity ---
t_plot = linspace(0, 2*t_max_eff, 300);
y_plot = A_eff + B_eff*exp(-alpha_eff*t_plot) - C_eff*t_plot;
v_plot = -B_eff*alpha_eff*exp(-alpha_eff*t_plot) - g;

figure;
subplot(2,1,1);
plot(t_plot, y_plot, 'b-', 'LineWidth', 2);
xlabel('Time (s)');
ylabel('Height (m)');
title('Predicted Height vs Time');
grid on;

subplot(2,1,2);
plot(t_plot, v_plot, 'r-', 'LineWidth', 2);
xlabel('Time (s)');
ylabel('Velocity (m/s)');
title('Predicted Velocity vs Time');
grid on;

%% --- Return final predicted height ---
h_predicted = y_max_eff;

end
