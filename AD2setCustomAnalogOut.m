function AD2setCustomAnalogOut(hdwf, channel, samples)
% AD2setCustomAnalogOut = function to define custom output signals, and
% fill the AD2 buffer.
%
%   Input arguments: 
% hdwf - hardware device ID of AD2
% channel - 0 or 1 identifying which channel to initialize
% samples, an array that contains the custom signal, normalized 
% between -1 and 1.
%
%   See also AD2Init, AD2close, AD2initAnalogIn, AD2initAnalogOut.
%
%   Author(s):
% v1.0: Mathieu Odijk - Copyright 2020

nSamples=max(size(samples)); %define size of samples
pSamples = libpointer('doublePtr',samples); %prepare pointer array
calllib('dwf','FDwfAnalogOutDataSet',hdwf, channel, pSamples, nSamples); %set buffer
return
