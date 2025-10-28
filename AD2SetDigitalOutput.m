function AD2SetDigitalOutput(hdwf,value)

calllib('dwf','FDwfDigitalIOOutputEnableSet',hdwf, value);
return