function [vq] = computeKernelInterpolationMatrices(kernelCoordinates, kernelValues, actualPosition, prev_vq)

numKernels = size(kernelCoordinates,1);
cluster_radius = 0.03;

for i=1:numKernels
    X(i) = kernelCoordinates(i,1);
    Y(i) = kernelCoordinates(i,2);
    Z(i) = kernelCoordinates(i,3);
    V(:,i) = kernelValues(:,i);
end

xq = actualPosition(1);
yq = actualPosition(2);
zq = actualPosition(3);

% Compute distances from actualPosition to all kernels
distances = vecnorm((actualPosition - [X' Y' Z']),2,2);

% Moving average smoothing factor (0.1-0.3 for stronger filtering)
% alpha = 0.2; 

if any(distances < cluster_radius) % If within calibration cluster
    
    vq = V(:,distances < cluster_radius)';

else

    for j = 1: size(V,1)

        vq(j) = griddatan([X' Y' Z'],V(j,:)', [xq yq zq],'linear'); % with velocity use 'nearest'
        if( isnan(vq(j)) )
            vq(j) = griddatan([X' Y' Z'],V(j,:)', [xq yq zq],'nearest'); % with velocity use 'nearest'

        end

        % F = scatteredInterpolant(X', Y', Z', V(j,:)', 'natural', 'nearest'); 
        % interpolated_value = F(xq, yq, zq);
        % 
        % if isnan(interpolated_value)
        %         % If interpolation fails, use weighted averaging for smoothness
        %         weights = exp(-distances.^2 / (2 * cluster_radius^2)); % Gaussian weights
        %         weights = weights / sum(weights); % Normalize
        % 
        %         interpolated_value = sum(weights .* V(j,:)'); % Weighted sum
        % end

        % vq(j) = interpolated_value;

        % Apply Exponential Moving Average (EMA)
        % if isempty(prev_vq)  
        %     vq(j) = interpolated_value; % No previous values, take current
        % else
        %     vq(j) = alpha * interpolated_value + (1 - alpha) * prev_vq(j);
        % end


    end
end


end


