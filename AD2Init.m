function [hdwf] = AD2Init(varargin)
% AD2Init - load the library provided by the software development
%kit (SDK) of the Analog Discovery 2 (Waveforms) by Digilent. It will check
%the location of the SDK, load the library, and check if the AD2 is
%present. If all is well, it will return a device ID for further use.
%   Input arguments: 
% hdwf = AD2Init();
%
% hdwf = AD2Init(SDKpath);
%
% By default, this function will assume a windows environment, where the
% SDK is installed in program files. In this case, you can call AD2Init 
% without arguments. If you are working on a Mac, or Linux  system, or if 
% you have provided a non-default installation path, you can provide one 
% yourself, by calling AD2Init(SDKPath) where SDKPath is a string that 
% references to the SDK location. Make sure to include the full path 
% to the dwf.h file, including a trailing / or \!
%
%   See also AD2close, AD2initAnalogIn, AD2initAnalogOut.
%
%   Author(s):
% v1.0: Mathieu Odijk - Copyright 2020

%check if file location exists
if(size(varargin)==1) %user provided a path
    if isfolder(varargin{1}) %check if path is valid.
        hfile=[varargin{1},'dwf.h'];
    else
        error(['provided folder path: "',varargin{1},'" does not exist!']);
        return
    end
elseif isfolder('C:Program Files\Digilent\WaveFormsSDK\inc') %default 32-bit system
    hfile='C:Program Files\Digilent\WaveFormsSDK\inc\dwf.h';
elseif isfolder('C:\Program Files (x86)\Digilent\WaveFormsSDK\inc') %default 64-bit system
    hfile='C:\Program Files (x86)\Digilent\WaveFormsSDK\inc\dwf.h';
elseif isfolder('/usr/local/include/digilent/waveforms/') %Linux header location according to docs
    hfile='/usr/local/include/digilent/waveforms/dwf.h';
elseif isfolder('/usr/include/digilent/waveforms/') %header location on my system
    hfile='/usr/include/digilent/waveforms/dwf.h';
else
    error('unkown path or OS type');
    return
end

display(['Set variable hfile: ' hfile]);

%check if header file is present.
if ~isfile(hfile)
    error('hfile not found!');
end

%check if library is not already loaded.
if ~libisloaded('dwf')
    loadlibrary('dwf', hfile);
else
    display('library seems already loaded.');
end

islibloaded = libisloaded('dwf');
fprintf('Check if dwf library is loaded: islibloaded = %dn',islibloaded)

% This pBuffer variable declaration is necessary to get the character strings
pBuffer = libpointer('int8Ptr',zeros(32,1)); %create a buffer of length 32, type int8Ptr to store version in next call.

calllib('dwf','FDwfGetVersion',pBuffer);
display(['Version: ' char(pBuffer.Value')]);

%Just opening and making sure the device is in a known state
phdwf = libpointer('int32Ptr',0);
calllib('dwf','FDwfDeviceOpen',-1,phdwf);
display(['FDwfDeviceOpen returned: ' num2str(phdwf.Value)])

hdwf = phdwf.Value; %obtain device ID for use in subsequent functions that operate the device.

return;