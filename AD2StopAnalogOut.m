function AD2StopAnalogOut(hdwf,channel)
%AD2StartAnalogOut - very simple function to get the analog output to start.
%
% AD2StartAnalogOut(hdwf)
%
%   Input arguments: 
% hdwf - hardware device ID of AD2
%
%
%   See also AD2Init, AD2close, AD2initAnalogIn, AD2initAnalogOut.
%
%   Author(s):
% v1.0: Mathieu Odijk - Copyright 2020
%

if ~libisloaded('dwf')
    error('dwf library not loaded, make sure to run AD2Init first');
    return
end
calllib('dwf','FDwfAnalogOutEnableSet',hdwf, channel, 0); %enable channel
calllib('dwf','FDwfAnalogOutConfigure',hdwf, channel, 0); %start channel
return