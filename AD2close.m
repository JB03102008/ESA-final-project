function AD2close()
% AD2close - This function will call the DeviceCloseAll SDK function and 
% unload the library 'dwf'.

%check if library is loaded, or if it is already closed.
if libisloaded('dwf')
    calllib('dwf','FDwfDeviceCloseAll');
    unloadlibrary('dwf');
    display('Device closed!');
else
    display('library/device seems already closed.');
end
return;