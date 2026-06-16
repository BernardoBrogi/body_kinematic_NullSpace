function changeSign(~, ~)
% Flip the sign multiplier stored on the active repeater figure.
figureHandle = gcbf;
signMultiplier = getappdata(figureHandle, 'signMultiplier');

if isempty(signMultiplier)
    signMultiplier = 1;
end

setappdata(figureHandle, 'signMultiplier', -signMultiplier);
end