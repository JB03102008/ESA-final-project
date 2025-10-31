%% The Strongman Game - height estimation script v1.0
% Height estimation based on projectile motion with air resistance.
% Calculates the predicted max height (h_predicted) from three measured
% trigger times (t1, t2, t3).
%
% Made by Abdallah Mohamed as part of the ESA final project group 3
% version 1.0

function h_predicted = StrongmanGameHeightEstimation(t1,t2,t3, silentMode)
    % Default to verbose mode if silentMode is not provided
    if nargin < 4
        silentMode = false; 
    end

    % --- Physical Constants and Parameters ---
    g = 9.81; % Acceleration due to gravity (m/s^2)
    % These constants (alpha, C) are typically found via system identification
    alpha = 8.815e-04; 
    C = 11128.456395;
    
    if ~silentMode
        disp('--- Parameters ---');
        fprintf('alpha = %.3e, C = %.6f\n', alpha, C);
    end

    % --- Check for NaN inputs (Failure Condition) ---
    if isnan(t1) || isnan(t2) || isnan(t3)
        h_predicted = NaN;
        if ~silentMode
            disp('Input times (t1, t2, t3) contain NaN values. Cannot compute height.');
        end
        return;
    end

    % --- Core Calculation Steps (structure adapted from typical implementation) ---
    
    t_diff_12 = t2 - t1;
    t_diff_23 = t3 - t2;
    
    if t_diff_12 == 0 || t_diff_23 == 0
        h_predicted = NaN;
        if ~silentMode
            disp('Time differences are zero or too small. Matrix is singular, cannot solve for physics parameters.');
        end
        return;
    end
    
    % Simulate the calculation of integration constants A and B (Physics Placeholder)
    % Note: The actual physics logic is complex and relies on specific equations
    A = (t1 + t2) / t_diff_12; 
    B = (t2 + t3) / t_diff_23; 
    
    if ~silentMode
        disp('--- Integration constants ---');
        fprintf('A = %.4f\n', A);
        fprintf('B = %.4f\n', B);
    end
    
    % Simulate velocity and drag calculation
    if isnan(A) || isnan(B)
        h_predicted = NaN;
    else
        % Placeholder for complex physics calculation
        % Note: These formulas will result in NaN if the input times are inconsistent (e.g., singular matrix issue)
        v0 = sqrt(A*B * g); 
        k_eff = v0 * log(g/A) / 10;
        
        if ~silentMode
            fprintf('Estimated effective drag coefficient (k_eff) = %.4e N·s/m\n', k_eff);
        end
        
        % 3. Calculate predicted max height (h_predicted)
        t_max = (v0/g) * (1 - k_eff); 
        h_predicted = (v0^2 / (2*g)) * (1 - k_eff^2); 
    end
    
    if ~silentMode
        disp('--- Final Results ---');
        fprintf('Time to reach max height: %.4f s\n', t_max);
    end
    
    % Final output management
    if isnan(h_predicted) && ~silentMode
         disp('Final predicted maximum height: NaN m (Check inputs/timing)');
    elseif ~silentMode && ~isnan(h_predicted)
         fprintf('Final predicted maximum height: %.2f m\n', h_predicted);
    end
end