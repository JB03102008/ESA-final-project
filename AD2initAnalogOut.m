function AD2initAnalogOut(hdwf, channel, freq, ampl, offSet, funct)
% AD2initAnalogOut - function to initialize an analog output channel.
%
% AD2initAnalogOut(hdwf, channel, freq, ampl, offSet, funct)
%
% hdwf - hardware device ID of AD2
% channel - 0 or 1 identifying which channel to initialize
% freq - frequency of output signal (in Hz)
% ampl - output amplitude of signal (in volt)
% offSet - offset voltage (in volt)
% func - define type of waveform to send out. Valid values are:
%         const FUNC funcDC       = 0;
%         const FUNC funcSine     = 1;
%         const FUNC funcSquare   = 2;
%         const FUNC funcTriangle = 3;
%         const FUNC funcRampUp   = 4;
%         const FUNC funcRampDown = 5;
%         const FUNC funcNoise    = 6;
%         const FUNC funcPulse    = 7;
%         const FUNC funcTrapezium= 8;
%         const FUNC funcSinePower= 9;
%         const FUNC funcCustom   = 30;
%         const FUNC funcPlay     = 31;
%
%
%   See also AD2Init, AD2close, AD2initAnalogIn.
%
%   Author(s):
% v1.0: Mathieu Odijk - Copyright 2020
%
if ~libisloaded('dwf')
    error('dwf library not loaded, make sure to run AD2Init first');
    return
end

%printf("Configure and start first analog out channel\n");
calllib('dwf','FDwfAnalogOutEnableSet',hdwf, channel, 1); %enable channel
calllib('dwf','FDwfAnalogOutFunctionSet',hdwf, channel, funct); %define output function (waveform)
calllib('dwf','FDwfAnalogOutOffsetSet',hdwf, channel, offSet); %define offset voltage
calllib('dwf','FDwfAnalogOutFrequencySet',hdwf, channel, freq); %define output frequency
calllib('dwf','FDwfAnalogOutAmplitudeSet',hdwf, channel, ampl); %define output amplitude


return
