function AD2SetPower(hdwf,pschannel,voltage)
% 
% Function to set and start the power supply ports (V+ and V-).
% Syntax:
% hdwf - device ID
% pschannel - Power Supply Channel: 0 for V+, 1 for V-
% voltage - Specifies the voltage of the channel
% 
% Author: Henk-Jan Boven 

if ~libisloaded('dwf')
    error('dwf library not loaded, make sure to run AD2Init first');
    return
end

calllib('dwf','FDwfAnalogIOChannelNodeSet',hdwf, pschannel, 0, 1); %enable pschannel
calllib('dwf','FDwfAnalogIOChannelNodeSet',hdwf, pschannel, 1, voltage); %set voltage
calllib('dwf','FDwfAnalogIOEnableSet',hdwf, 1); %Master enable
return