function AD2StopPWM(hdwf, channel)
% Simple function to stop the digital output of a PWM channel.
% 
% AD2StopPWM(hdwf,channel)
% 
% Input arguments:
% hdwf - hardware device ID of AD2
% channel - identifying which channel to stop
%
%   See also AD2initPWM and AD2StartPWM.
%
%   Author(s):
% v1.0 Henk-Jan Boven - Copyright 2020

if ~libisloaded('dwf')
    error('dwf library not loaded, make sure to run AD2Init first');
    return
end

calllib('dwf','FDwfAnalogOutEnableSet',hdwf, channel, 0); %enable channel
calllib('dwf','FDwfDigitalOutConfigure',hdwf,0); %stop channel

return

