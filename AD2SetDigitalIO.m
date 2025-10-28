function AD2SetDigitalIO(hdwf,value)

calllib('dwf','FDwfDigitalIOOutputSet',hdwf, value);
return;