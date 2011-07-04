function sendPacket(obj,id,code,request,size,body)
    if(~exist('id','var') || ~exist('code','var') || ...
            ~exist('request','var') || ~exist('size','var'))
        disp('ERROR: Malformed packet');
        return;
    end

    if((size > 0) && ~exist('body','var'))
        disp('ERROR: Size > 0 but no body specified');
        return;
    end

    packet = zeros(12,1,'uint8');

    packet(1:4) = id;
    packet(5:6) = fliplr(typecast(int16(code),'int8'));
    packet(7:8) = fliplr(typecast(int16(request),'int8'));
    packet(9:12) = fliplr(typecast(int32(size),'int8'));

    fwrite(obj,packet);

    if(size>0)
        fwrite(obj,body);
    end