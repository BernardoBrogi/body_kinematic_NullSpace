function [A,minValues,maxValues] = correctSignPCA(A,minValues,maxValues)

% Example matrix
% A = randn(12, 10);  % Replace this with your actual 12x10 matrix
% 
% % Example minimum and maximum row vectors (10 elements each)
% minValues = rand(1, 10);  % Replace with your actual minimum values
% maxValues = minValues + rand(1, 10);  % Replace with your actual maximum values (max > min)

% Store whether each column's sign was flipped
signFlipped = false(1, size(A, 2));  % Logical vector to track sign changes

% Loop over each column to check for sign changes
for j = 1:size(A, 2)
    % Find the row index of the element with the greatest absolute value in the column
    [~, maxIdx] = max(abs(A(:, j)));
    
    % Find the majority sign in that row
    majoritySign = sign(sum(sign(A(maxIdx, :))));
    
    % Get the sign of the element with the greatest absolute value in the column
    maxElementSign = sign(A(maxIdx, j));
    
    % If the signs don't match, flip the sign of the entire column
    if maxElementSign ~= majoritySign
        % disp('Sign flipped of centroid:' + num2str(j));
        A(:, j) = -A(:, j);  % Flip the sign of the column
        signFlipped(j) = true;  % Mark this column as flipped
    end
end

% Now swap minimum and maximum values, and change signs for columns where the sign was flipped
for j = 1:length(signFlipped)
    if signFlipped(j)
        % Swap the corresponding min and max values and change their signs
        temp = -minValues(j);  % Change sign of min and store temporarily
        minValues(j) = -maxValues(j);  % Change sign of max and assign to min
        maxValues(j) = temp;  % Assign temp (changed sign min) to max
    end
end

% Display the modified matrix and vectors
% disp('Modified Matrix A:');
% disp(A);
% 
% disp('Modified minValues:');
% disp(minValues);
% 
% disp('Modified maxValues:');
% disp(maxValues);

end


