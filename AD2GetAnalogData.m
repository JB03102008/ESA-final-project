function data = AD2GetAnalogData(hdwf, channel, nSamples)
% AD2GetAnalogData - get the analog data from the AD2 buffer.
%
% AD2GetAnalogData(hdwf, channel, nSamples)
%
%   Input arguments: 
% hdwf - hardware device ID of AD2
% channel - analog input channel
% nSamples - the number of samples expected (see AD2initAnalogIn function)
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

pData = libpointer('doublePtr', zeros(1,nSamples)); %initialize variable to store data
% % get the acquired samples for first channel (0)
calllib('dwf', 'FDwfAnalogInStatusData', hdwf, channel, pData, nSamples);
data = pData.Value;

return;