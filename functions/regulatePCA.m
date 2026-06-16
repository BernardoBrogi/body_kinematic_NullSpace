function [max_calibration_signal, min_calibration_signal] = regulatePCA(calibration_signal, calibration_signal_01)

% Refine Scaling
[max_pks, max_indxs] = findpeaks(calibration_signal_01);
[min_pks, min_indxs] = findpeaks(-calibration_signal_01);
min_pks = -min_pks;

max_indxs(max_pks < 0.5) = [];
max_pks(max_pks < 0.5) = [];

min_indxs(min_pks > 0.5) = [];
min_pks(min_pks > 0.5) = [];

indxs_to_check = find(diff(max_indxs)<5);
if(~isempty(indxs_to_check))
    for i = 1:length(indxs_to_check)
        indx_ = indxs_to_check(i);
        [val, indx] = max(max_pks(indx_:indx_+1));
        indxs_to_mantain(i,1) = indx_-1 + indx;
    end
    indxs_to_delete = (indxs_to_check==indxs_to_mantain) + indxs_to_mantain;
    max_indxs(indxs_to_delete) = [];
    max_pks(indxs_to_delete) = [];
    indxs_to_mantain = [];
    indxs_to_delete = [];
end

indxs_to_check = find(diff(min_indxs)<5);
if(~isempty(indxs_to_check))
    for i = 1:length(indxs_to_check)
        indx_ = indxs_to_check(i);
        [val, indx] = min(min_pks(indx_:indx_+1));
        indxs_to_mantain(i,1) = indx_-1 + indx;
    end
    indxs_to_delete = (indxs_to_check==indxs_to_mantain) + indxs_to_mantain;
    min_indxs(indxs_to_delete) = [];
    min_pks(indxs_to_delete) = [];
end

new_scaling_val = 0.5; % Questo valore può essere al minimo 0.5 (sotto non fa differenza)

% Find the max peaks considering the scaling value of the signal
max_pks_scaled = max_pks(max_pks > new_scaling_val);
min_pks_scaled = min_pks(min_pks < (1-new_scaling_val));

if isempty(max_pks_scaled)
    max_pks_scaled = max_pks(max_pks > 0.4); % prendo tutto
end
if isempty(min_pks_scaled)
    min_pks_scaled = min_pks(min_pks < (1-0.4));
end

% Delete the absolute max and min for the computation of the mean
if(length(max_pks_scaled)>1)
    max_pks_scaled(max_pks_scaled == max(max_pks_scaled)) = NaN;
end
if(length(min_pks_scaled)>1)
    min_pks_scaled(min_pks_scaled == min(min_pks_scaled)) = NaN;
end

% Calculate the new max and min based on the mean of the old max and min values in the 01 range
max_calibration_signal_01 = mean(max_pks_scaled,"omitnan");
min_calibration_signal_01 = mean(min_pks_scaled,"omitnan");

% Fallback if mean is NaN or not enough peaks: use percentiles or global max/min
if isnan(max_calibration_signal_01) || isnan(min_calibration_signal_01)
    % Use percentiles for robustness
    max_calibration_signal_01 = prctile(calibration_signal_01,95);
    min_calibration_signal_01 = prctile(calibration_signal_01,5);
end

% Convert max and min previously computed back to the original scale
max_calibration_signal = max_calibration_signal_01 * (max(calibration_signal) - min(calibration_signal)) + min(calibration_signal);
min_calibration_signal = min_calibration_signal_01 * (max(calibration_signal) - min(calibration_signal)) + min(calibration_signal);

% Fallback if still invalid (e.g., flat signal)
if isnan(max_calibration_signal) || isnan(min_calibration_signal)
    max_calibration_signal = max(calibration_signal);
    min_calibration_signal = min(calibration_signal);
end

% Enforce max > min, add epsilon if needed
epsilon = 1e-6;
if max_calibration_signal <= min_calibration_signal
    % If flat, force a small separation
    max_calibration_signal = min_calibration_signal + epsilon;
end

% New calibration signal based on the max and min previously computed
calibration_signal_n01 = (calibration_signal - min_calibration_signal)/(max_calibration_signal - min_calibration_signal);


% Optionally clamp calibration_signal_n01 to [0,1] if needed
% calibration_signal_n01 = min(max(calibration_signal_n01,0),1);

% Control plot for the original signal and the estimated average levels
signal_idx = 1:numel(calibration_signal);
figure('Name','regulatePCA check','Color','w');
plot(signal_idx, calibration_signal, 'b', 'LineWidth', 1.2);
hold on;
plot(signal_idx, max_calibration_signal * ones(size(signal_idx)), 'r--', 'LineWidth', 1.2);
plot(signal_idx, min_calibration_signal * ones(size(signal_idx)), 'g--', 'LineWidth', 1.2);
grid on;
xlabel('Samples');
ylabel('Signal');
title('Original signal with average max and min levels');
legend('Original signal', 'Average max', 'Average min', 'Location', 'best');

end