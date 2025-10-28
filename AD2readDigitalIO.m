function bits = AD2readDigitalIO(hdwf)

%int32 pointer to read all DIO pins
pRead = libpointer('uint32Ptr', zeros(1,1));
bits = zeros(1,16);

% # read state of all pins, regardless of output enable
calllib('dwf','FDwfDigitalIOInputStatus',hdwf, pRead);
% Get the bit values of all 16 DIOs
bits = bitget(pRead.value,1:16); %earlier the ' operator was included here. If you need this, please notify mathieu as it is messing with the matlab manual.