function AD2initPWM(hdwf,channel,dc,freq)
% AD2initPWM - function to initialize a PWM signal on a digital output
% channel of the AD2.
% 
% AD2initPWM(hdwf,channel,dc,freq)
% 
% Input arguments:
% hdwf - hardware device ID of AD2
% channel - identifying which channel to initialize
% dc - the duty cycle percentage of the PWM signal
% freq - the frequency in Herz of the PWM signal
% See also AD2StartPWM and AD2StopPWM
%
% Inspired by Python example of Digilent, Inc
% If Waveforms of Digilent is installed, it can be found at:
% C:\Program Files (x86)\Digilent\WaveFormsSDK\samples\py\DigitalOut_Duty.py
% 
%   See also AD2StartPWM and AD2StopPWM.
%
%   Author: 
% v1.0 Henk-Jan Boven - Copyright 2020

%Check if library is loaded
if ~libisloaded('dwf')
    error('dwf library not loaded, make sure to run AD2Init first');
    return
end

% Get the system frequency and the supported maximum counter value
sysfreq = libpointer('doublePtr', 0);
maxcount = libpointer('uint32Ptr', 0);

calllib('dwf','FDwfDigitalOutInternalClockInfo',hdwf, sysfreq);
calllib('dwf','FDwfDigitalOutCounterInfo',hdwf, channel, 0, maxcount);

% Divider for low frequencies to satisfy the counter limitation of 32K
div = ceil(double(sysfreq.value)/double(freq)/double(maxcount.value));
pulse = round(sysfreq.value/freq/div);

% Determine the high count and low count in one cycle
counthigh = round(pulse*dc/100);
countlow =  round(pulse-counthigh);


% Initialize the PWM signal
calllib('dwf','FDwfDigitalOutEnableSet',hdwf,channel,2); 
calllib('dwf','FDwfDigitalOutTypeSet',hdwf, channel, 0); % DwfDigitalOutTypePulse
calllib('dwf','FDwfDigitalOutDividerSet',hdwf, channel, div); % max 2147483649, for counter limitation or custom sample rate
calllib('dwf','FDwfDigitalOutCounterSet',hdwf, channel, countlow, counthigh); % max 32768

end

