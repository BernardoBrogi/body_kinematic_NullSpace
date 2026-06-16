function [td,timestamp,numOfTrackers] = unpackData(rawData)
%Unpack tracking data
% input: rawData packet
% [1][timestamp][num of trackers][P1][Q1]....[Pn][Qn]
%  4      4            4          8   8        8   8
%
% output:
% td = Nx7; [Px Py Pz Qx Qy Qz Qz], N trackers
% 


byteIndex = 1;

%start packet
startPacket_bytes = rawData(byteIndex:byteIndex+3);
byteIndex = byteIndex +4;
%startPacket = swapbytes(typecast(header,'int32'));
startPacket = (typecast(uint8(startPacket_bytes),'int32'));

if(startPacket ~= 1)
    display("Wrong Endianness")
    return
end

%timestamp
timestamp_bytes = rawData(byteIndex:byteIndex+3);
byteIndex = byteIndex+4;
timestamp = (typecast(uint8(timestamp_bytes),'single'));
timestamp = double(timestamp);

% num of trackers
numOfTrackers = rawData(byteIndex:byteIndex+3);
%numOfTrackers = 4;
byteIndex = byteIndex+4;
numOfTrackers = (typecast(uint8(numOfTrackers),'int32'));
numOfTrackers = double(numOfTrackers);

for(iTracker = 1:4)%numOfTrackers) % 4 are the number of tracker that we want 
    for iValue = 1:7 % because of 3 values of positions and 4 of quaternions
        startByte = byteIndex+(8*7*(iTracker-1)+(iValue-1)*8);
        endByte = startByte+7;
        valueBytes = rawData(startByte:endByte);
        td(iTracker, iValue)  = (typecast(uint8(valueBytes),'double'));
    end
end
%disp("ricevuto!")
byteIndex= endByte;







end