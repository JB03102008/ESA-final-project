function AD2initAnalogIn(hdwf, channel, sampleFreq, range, bufferSize,acqMode)
% AD2initAnalogIn - function to initialize analog input.
%
% AD2initAnalogIn(hdwf, channel, sampleFreq, range, bufferSize)
% hdwf - hardware device ID of AD2
% channel - 0 or 1 identifying which channel to initialize (-1 for both?)
% sampleFreq - sampling frequency (Hz)
% range - Input range (volts)
% bufferSize - number of samples to buffer
% acqMode - acquisition mode, see text below.
%   0 - Perform a single buffer acquisition and rearm the instrument for 
%        next capture after the data is fetched to host. This is the
%        default setting.
%   1 - Perform a continuous acquisition in FIFO style. The trigger setting
%        is ignored. The last sample is at the end of buffer.
%   2 - Perform continuous acquisition circularly writing samples into the 
%        buffer. The trigger setting is ignored. 
%   3 - erform acquisition for length of time set by FDwfAnalogInRecordLengthSet.
%   5 - Perform a single buffer acquisition.
%
%   See also AD2Init, AD2close, AD2initAnalogOut.
%
%   Author(s):
% v1.0: Mathieu Odijk - Copyright 2020
%
if ~libisloaded('dwf')
    error('dwf library not loaded, make sure to run AD2Init first');
    return
end

if ~exist('acqMode','var')
    acqMode=0; 
end
   
%    printf("Configure analog in\n");
calllib('dwf','FDwfAnalogInReset',hdwf); %reset all settings to default
%set sampling frequency
calllib('dwf','FDwfAnalogInFrequencySet',hdwf, sampleFreq);
%    // set range
calllib('dwf','FDwfAnalogInChannelRangeSet',hdwf, channel, range);
% set buffersize
calllib('dwf','FDwfAnalogInBufferSizeSet',hdwf, bufferSize);
% set acquisition mode
calllib('dwf','FDwfAnalogInAcquisitionModeSet',hdwf, acqMode);

return;