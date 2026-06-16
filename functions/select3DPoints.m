function selectedPoints = select3DPoints(ax)
    selectedPoints = [];
    lastSelectedPoint = [];
    
    % Enable data cursor mode
    dcm_obj = datacursormode(gcf);
    set(dcm_obj, 'UpdateFcn', @myupdatefcn, 'SnapToDataVertex', 'on');
    datacursormode on;

    disp('Select points in the 3D plot. Press "Return" when done.');

    % This block will allow the user to manually end the selection
    done = false;
    while ~done
        pause; % Pause until a key is pressed or mouse click occurs
        current_char = get(gcf, 'CurrentCharacter');
        
        if strcmp(current_char, char(13))  % Return key is pressed
            if isempty(selectedPoints)
                disp('No points selected. Please select at least one point.');
            else
                done = true;  % Exit the loop and return the selected points
            end
        else
            disp('Please press "Return" to confirm selection.');
        end
    end

    % Nested function to update data cursor and store points
    function txt = myupdatefcn(~, event_obj)
        pos = get(event_obj, 'Position');
        % txt = {['X: ', num2str(pos(1))], ['Y: ', num2str(pos(2))], ['Z: ', num2str(pos(3))]};

        % Set a threshold for minimum distance between points
        min_distance_threshold = 0.1;  % Adjust this value as needed

        % Check if the selected point is far enough from the last selected point
        if isempty(lastSelectedPoint) || norm(pos - lastSelectedPoint) > min_distance_threshold
            % Append the selected point to the list
            selectedPoints = [selectedPoints; pos];
            
            % Update last selected point
            lastSelectedPoint = pos;

            txt = size(selectedPoints,1);

            % Plot the selected point in red
            hold on;
            plot3(pos(1), pos(2), pos(3), 'r.', 'MarkerSize', 30);
        else
            % disp('Point too close to the last selection, skipping.');
        end

        % Small pause to avoid multiple clicks being registered in quick succession
        pause(0.2);
    end
end
