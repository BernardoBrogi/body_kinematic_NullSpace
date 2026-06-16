function [qRelative, rpyRelative, rotRelative] = getRelativeRotation(data)

    numActiveTracker = size(data,1);

    for iTracker = 1:numActiveTracker
        qTrackers(iTracker) = quaternion(data(iTracker,4:7));
    end

    if(numActiveTracker >1)
        for iTracker = 1:numActiveTracker-1
            qRelative(iTracker) = conj(qTrackers(iTracker+1))*(qTrackers(iTracker)); % calculate the relative rotation with quaternions
            rpyRelative(iTracker,:) = quat2eul(qRelative(iTracker),"XYZ")*180/pi; % angle in degrees
            rotRelative(iTracker,:) = reshape(quat2rotm(qRelative(iTracker))',1,[]);
        end
    else
        rpyRelative = NaN;
        qRelative = NaN;
        rotRelative = NaN;
    end

