function [data_within_clusters, idx_within_clusters, centroids, time_data_within_clusters] = dataClustering_dragDrop(data, n_clusters, cluster_radius, flag_visualize_plot)

arguments
    data (:,:) double
    n_clusters (1,1) double = 10
    cluster_radius (1,1) double = 0.03
    flag_visualize_plot (1,1) double = 0
end

wrist_pose = data(:,1:3);
time = data(:,end); % Data time stamp
data = data(:,1:end-1);

% Create bounding box to guess the calibration points
[~,corners] = minboundbox(wrist_pose(:,1),wrist_pose(:,2),wrist_pose(:,3),'v',3);
corners = sortrows(corners,2); % Sort wrt y components

center_left_plane = mean(corners(1:4,:));
center_right_plane = mean(corners(5:end,:));

cent = [];
for i = 1:length(corners)
    cent_indx = dsearchn(wrist_pose, corners(i,:));
    cent(i,:) = wrist_pose(cent_indx, :);
end

right_cent = mean(cent(1:4,:));
left_cent = mean(cent(5:end,:));

cent_indx = dsearchn(wrist_pose, right_cent);
cent(end+1,:) = wrist_pose(cent_indx, :);

cent_indx = dsearchn(wrist_pose, left_cent);
cent(end+1,:) = wrist_pose(cent_indx, :);

starting_centroids = cent;

% Plot and ask for confirmation
figure_handle = figure;
ax = axes;
plot3(wrist_pose(:,1), wrist_pose(:,2), wrist_pose(:,3), 'b.');
hold on;
h = plot3(starting_centroids(:,1), starting_centroids(:,2), starting_centroids(:,3), 'ro', 'LineWidth', 2);
grid on
title('Initial Centroids');
rotate3d on
% Add a button to the figure to continue
uicontrol('Style', 'pushbutton', 'String', 'End check', ...
    'Position', [20 20 120 40], ...  % Position the button in the figure
    'Callback', 'uiresume(gcbf)');  % Resume the figure once the button is pressed

uiwait(figure_handle);  % Wait for the user to press the button

% Close the figure with the button after confirmation
close(figure_handle);

% Proceed with the rest of the script after confirmation (no button now)
figure; % Open a new figure for further visualization
ax = axes;
plot3(wrist_pose(:,1), wrist_pose(:,2), wrist_pose(:,3), 'b.');
hold on;
plot3(starting_centroids(:,1), starting_centroids(:,2), starting_centroids(:,3), 'ro', 'LineWidth', 2);
grid on
title('Confirmed Centroids and Wrist Pose');

% Confirmation dialog
choice = questdlg('Is the initial guess of centroids fine?', 'Centroid Confirmation', 'Yes', 'No', 'Yes');

switch choice
    case 'No'
        % Remove previous centroids from the plot
        delete(h);
        
        % Allow the user to select and confirm centroids
        validSelection = false;
        while ~validSelection
            % Clear any previously selected points and plot elements
            delete(findobj(ax, 'Marker', 'r.'));  % Clear previous red markers
            
            % Clear previous plot and replot the original data points
            cla(ax);  % Clear the axes
            scatter3(wrist_pose(:,1), wrist_pose(:,2), wrist_pose(:,3), 'b.');  % Replot original data points
            grid on
            title('Select new centroids manually. Press "Return" when done.');
            
            % Let user select points via `select3DPoints` (waits for the user to hit "Return")
            selectedPoints = select3DPoints(ax);
            
            % Check if any points were selected
            if isempty(selectedPoints)
                % If no points are selected, inform the user and continue the loop
                disp('No centroids selected. Please select centroids.');
                continue;  % Skip confirmation and loop back for new selection
            end
            
            % Ask for confirmation after the selection is made
            choice = questdlg(['You selected ' num2str(size(selectedPoints, 1)) ' centroids. Are you fine with this selection?'], ...
                'Centroid Confirmation', 'Yes', 'No', 'Yes');
            
            if strcmp(choice, 'Yes')
                % If the user is satisfied, update the centroids and break the loop
                starting_centroids = selectedPoints;
                n_clusters = size(starting_centroids,1);
                validSelection = true;
            else
                % User is not satisfied, reset the selection and replot
                disp('Please reselect the centroids.');
                selectedPoints = [];  % Reset the selected points array
                % Loop back to let the user select again
            end
        end
end

close(gcf); % Close the plot

% Clustering with (possibly modified) starting centroids
[idx_centroid, centroids] = kmedoids(wrist_pose, n_clusters, 'Distance', 'sqeuclidean', 'Start', starting_centroids); % before was kmeans

% Remove data out of clusters
flag_within_cluster = false(length(wrist_pose),1);
for i = 1:length(wrist_pose)
    if norm(wrist_pose(i,:) - centroids(idx_centroid(i),:)) < cluster_radius
        flag_within_cluster(i) = true;
    end
end

data_within_clusters = data(flag_within_cluster, :);
idx_within_clusters = idx_centroid(flag_within_cluster);
time_data_within_clusters = time(flag_within_cluster);

% save flag_idx_temp.mat flag_within_cluster idx_centroid
%%%%%%%%%%%%%%%%%%%%%% -- DEBUG -- %%%%%%%%%%%%%%%%%%%%%%

% Figures for data visualization
if flag_visualize_plot
    
    % Bounding Box
    figure
    plot3(wrist_pose(:,1),wrist_pose(:,2),wrist_pose(:,3))
    axis equal
    grid on
    xlabel('x')
    ylabel('y')
    zlabel('z')
    title("Data in chest tracker reference frame")
    
    hold on
    
    % Plot the corners of the bounding box
    plot3(corners(:,1), corners(:,2), corners(:,3), 'ro', 'MarkerSize', 10, 'LineWidth', 2);
    
    % Plot the vertex numbers
    for i = 1:size(corners, 1)
        text(corners(i, 1), corners(i, 2), corners(i, 3), num2str(i), 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k');
    end
    
    % Define the edges of the bounding box
    edges = [
        1 2; 1 3; 3 4; 4 2; % One plane
        5 6; 5 7; 7 8; 8 6; % Other plane
        1 5; 2 6; 3 7; 4 8  % Connecting edges
        ];
    
    % Plot the edges of the bounding box
    for i = 1:size(edges, 1)
        plot3(corners(edges(i,:), 1), corners(edges(i,:), 2), corners(edges(i,:), 3), 'b-', 'LineWidth', 2);
    end
    
    % Plot the centers of the left and right planes
    plot3(center_left_plane(1), center_left_plane(2), center_left_plane(3), 'gs', 'MarkerSize', 10, 'LineWidth', 2);
    plot3(center_right_plane(1), center_right_plane(2), center_right_plane(3), 'ms', 'MarkerSize', 10, 'LineWidth', 2);
    
    % Set plot labels and title
    xlabel('X');
    ylabel('Y');
    zlabel('Z');
    title('Bounding Box and Center Points');
    grid on;
    axis equal;
    
    % Actual point of the bounding box
    figure
    plot3(wrist_pose(:,1),wrist_pose(:,2),wrist_pose(:,3))
    axis equal
    grid on
    xlabel('x')
    ylabel('y')
    zlabel('z')
    title("Actual point of the bounding box")
    hold on
    plot3(cent(:,1), cent(:,2), cent(:,3), 'r.', 'MarkerSize', 30, 'LineWidth', 2);
    
    %  % Plot the vertex numbers
    % for i = 1:size(cent, 1)
    %     text(cent(i, 1), cent(i, 2), cent(i, 3), num2str(i), 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k');
    % end
    
    
    % Wrist trajectory with clusters
    figure
    hold on
    [Xs,Ys,Zs] = sphere;
    
    for i = 1:n_clusters
        plot3(wrist_pose(idx_centroid==i,1),wrist_pose(idx_centroid==i,2),wrist_pose(idx_centroid==i,3),'.','MarkerSize',12)
        
        X2 = Xs * cluster_radius;
        Y2 = Ys * cluster_radius;
        Z2 = Zs * cluster_radius;
        
        hSurface = surf(X2+centroids(i,1),Y2+centroids(i,2),Z2+centroids(i,3));
        set(hSurface,'FaceColor',[0 0 1], 'FaceAlpha',0.5,'FaceLighting','gouraud','EdgeColor','none')
    end
    
    plot3(centroids(:,1),centroids(:,2),centroids(:,3),'kx','MarkerSize',15,'LineWidth',3)
    title 'Cluster Assignments and Centroids'
    axis equal
    grid on
    xlabel('x')
    ylabel('y')
    zlabel('z')
    hold off
    
    % Data assigned to each cluster
    [GC,G_idx] = groupcounts(idx_within_clusters);
    
    figure
    bar(G_idx,GC);
    title 'Data assigned to each cluster'
    
end

end


