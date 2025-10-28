function AD2StartPWM(hdwf,channel)
% Simple function to start the digital output of a PWM channel.
% 
% AD2StartPWM(hdwf,channel)
% 
% Input arguments:
% hdwf - hardware device ID of AD2
% channel - identifying which channel to start
%
%   See also AD2initPWM and AD2StopPWM.
%
%   Author(s):
% v1.0 Henk-Jan Boven - Copyright 2020

if ~libisloaded('dwf')
    error('dwf library not loaded, make sure to run AD2Init first');
    return
end

calllib('dwf','FDwfDigitalOutConfigure',hdwf,1); %start channel

return
