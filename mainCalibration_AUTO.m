%% Calibration script

% Loads a recorded calibration session, extracts relative tracker motion,
% clusters the calibration poses, and stores the PCA kernel parameters used
% by the online repeater.

close all
clear
clc

addpath("functions\")

%% Get Data from Tracking System

disp("Collecting data...")

global tracker_data

tracker_udp = udpport("datagram","LocalPort",8051);
configureCallback(tracker_udp,"datagram",1,@calibrationCallBack);

MessageBox = msgbox('Stop DataStream', 'HARIA KNS');

while ishandle(MessageBox)
    pause(0.01)
end

flush(tracker_udp,"input")
clear tracker_udp


% Prompt user for a filename
prompt = {'Enter name of subject to save data (without extension):'};
dlgtitle = 'Save Data';
dims = [1 50];
definput = {'name_1'};
answer = inputdlg(prompt, dlgtitle, dims, definput);

% Check if user provided a name, otherwise use the default name
if isempty(answer) || isempty(answer{1})
    % User did not provide a filename, do nothing
    disp('No filename provided. Data not saved but script continues.');
else
    % Get filename prefix
    filename_prefix = answer{1};
    
    % Get current date and time
    currentDateTime = datestr(now, 'yyyy_mm_dd_HHMMSS');
    
    % Construct full filename with timestamp
    filename = ['Test/' filename_prefix '_' currentDateTime '.mat'];
    
    % Save data
    save(filename, 'tracker_data');
    
    % Display confirmation message
    disp(['Data saved to ' filename]);
end

%% Extract RelativeRotation

% If you want to load presaved data start from here
load calib_example.mat

tracked_data = tracker_data;

% Keep only samples where all four trackers were detected.
tracked_data(find(tracked_data(:,2) ~= 4),:) = [];

% Consider 4 trackers
numActiveTracker = (tracked_data(:,2));
if (length(unique( numActiveTracker ))>1)
    disp('error')
    return
else
    numActiveTracker = unique(numActiveTracker);
end

% Extract relativeRotation
quatRelative = [];
eulRelative = [];
rotRelative = [];


for i= 1:size(tracked_data,1)
    data = reshape(tracked_data(i,3:end),[],numActiveTracker)';  % row = x, y, z, quaternion(w, x, y, z)
    [quatRelative_, eulRelative_, rotRelative_] = getRelativeRotation(data); %% n rows, n = numtracker -- angle in degrees with respect to tracker world
    
    % Store relative quaternions
    quatRelative_  = [quatRelative_(:).compact];
    quatRelative = [quatRelative;  reshape(quatRelative_',1,[])];
    
    % Store relative euler
    eulRelative = [eulRelative;  reshape(eulRelative_',1,[])];
    
    % Store relative rotation matrices
    rotRelative = [rotRelative; reshape(rotRelative_(1,:),3,[])', reshape(rotRelative_(2,:),3,[])', reshape(rotRelative_(3,:),3,[])'];
end

% Unwrap
eulRelative = unwrap(eulRelative*pi/180)*180/pi;

% Relative positions wrt chest
chest_pos = tracked_data(:,end-6:end-4);
chest_orientation = conj(quaternion(tracked_data(:,end-3:end)));

for i = 1:numActiveTracker
    
    tracked_data_world = tracked_data (:,(3+(i-1)*7 : 5+(i-1)*7) ) - chest_pos;
    tracked_data_chest = rotatepoint(chest_orientation,tracked_data_world);
    tracked_data (:,(3+(i-1)*7 : 5+(i-1)*7) ) = tracked_data_chest;
end


%% Data clustering and PCA calibration


disp("Data Clustering")
% Build the feature vector used to detect calibration clusters.
to_clusterize = [tracked_data(:,3:5) quatRelative tracked_data(:,1)];

% Select only samples acquired while the user was holding the known points.
[data_within_clusters, idx_within_clusters, centroids, time_data_within_clusters] = dataClustering_dragDrop(to_clusterize);

n_centroids = size(centroids,1);
mean_hand_moving_cluster = zeros(1,n_centroids);
max_hand_moving_cluster = zeros(1,n_centroids);

thr_velocity_percentage = 10/100;

for i = 1:n_centroids
    hand_within_clusters = data_within_clusters(idx_within_clusters==i,1:3);
    time_within_clusters = time_data_within_clusters(idx_within_clusters==i);
    
    hand_moving = vecnorm(hand_within_clusters,2,2); % 2-norm
    vel_hand_pos = abs((diff(hand_moving)))./diff(time_within_clusters); % successivo - precedente / sampling time
    vel_hand_pos_filtered = medfilt1(vel_hand_pos,3);
    
    % Ensure index is at least 1
    start_index = max(1, floor(length(vel_hand_pos_filtered) / 10));
    end_index = max(1, length(vel_hand_pos_filtered) - start_index);
    
    % Calculate mean and max for velocity in the cluster
    mean_hand_moving_cluster(i) = mean(vel_hand_pos_filtered(start_index:end_index));
    max_hand_moving_cluster(i) = max(vel_hand_pos_filtered(start_index:end_index));
    
    thr_velocity(i) = max_hand_moving_cluster(i) - (max_hand_moving_cluster(i) - mean_hand_moving_cluster(i))*thr_velocity_percentage;
    
end

not_moving_hand = mean(thr_velocity);

data_within_clusters = data_within_clusters(:,4:end);   % Only joints values

mu_all = [];
calibration_signal_n01_all = zeros(length(data_within_clusters),1);
centroids_all = zeros(length(data_within_clusters),1);

not_enough_variance = false; % initialize variable

for i = 1:size(centroids,1)
    
    [coeff, score, latent, ~, explained, mu] = pca(data_within_clusters(idx_within_clusters==i,:),'Centered',true);
    
    score_computed = (quatRelative(idx_within_clusters==i,:)-mu)*coeff;
    
    %Calibration Signal
    n_components = find(cumsum(explained) > 80);
    
    if ~isempty(n_components) && n_components(1) == 1
        
    else
        disp("The first PC does of cluster " + i + " not describe the 80% of the variance. You should calibrate again.")
        not_enough_variance = true;
    end
    
    % Build the 1D calibration signal from the first principal component.
    
    calibration_signal = score_computed(:,1);
    
    calibration_signal_01 = (calibration_signal - min(calibration_signal))/(max(calibration_signal) - min(calibration_signal));
    
    % Regulate thresholds for the PCA
    [ker_max_value,ker_min_value] = regulatePCA(calibration_signal, calibration_signal_01);
    
    kernel_max_values(i) = ker_max_value;
    kernel_min_values(i) = ker_min_value;
    
    kernel_coeff_values(:,i) = coeff(:,1);
    
    mu_all(:,i) = mu; % usare la reference estratta da calibrazione statica
    
    calibration_signal_n01_all(idx_within_clusters==i,:) = (calibration_signal - ker_min_value)/(ker_max_value - ker_min_value);
    centroids_all(idx_within_clusters==i,:) = i*ones(length(calibration_signal),1);
    
end

% Check if ker_max_value and ker_min_value are equal or min is greater than max
if any(kernel_max_values <= kernel_min_values) || any(isnan(kernel_max_values) | isnan(kernel_min_values))
    if exist('pcaClusteredValues.mat', 'file')
        delete('pcaClusteredValues.mat');
    end
    error('Error: ker_max_value is less than or equal to ker_min_value in one or more clusters. Calibrate again.');
end

% Decide whether to handle the low variance or not
if not_enough_variance
    choice = questdlg('Not enough variance detected. Do you want to save the data or repeat the calibration?', ...
        'Variance Warning', ...
        'Save Data', 'Repeat Calibration', 'Repeat Calibration');
    
    % Handle user choice
    switch choice
        case 'Save Data'
            disp('Continuing script...');
            % Continue with script execution
            
        case 'Repeat Calibration'
            disp('Exiting...');
            if exist('pcaClusteredValues.mat', 'file')
                delete('pcaClusteredValues.mat');
            end
            return;
    end
end


kernel_coordinates = centroids;

% Make the PCA sign consistent across clusters before saving.
[kernel_coeff_values,kernel_min_values,kernel_max_values] = correctSignPCA(kernel_coeff_values,kernel_min_values,kernel_max_values);

pcaSavedData = strcat('pcaClusteredValues','.mat');

disp("Data are saved in: " + pcaSavedData)
save(pcaSavedData, 'kernel_coordinates', 'kernel_coeff_values', 'mu_all', 'kernel_max_values', 'kernel_min_values', 'not_moving_hand');