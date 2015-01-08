function result = cass_imageget(cid, attribute, opt)
   error(nargchk(2, 3, nargin, 'struct'));
   handle = cass_handle();
   if iscell(cid), cid = cid{1}; end

   if (nargin>2) handle = optmerge(handle, opt); end;
   switch (attribute)
     case {'image', 'thumb'}
       result = typecast2(imtools.imtools.byte2im(handle.ca.getraw(cid, handle.cf, attribute, handle.retry_count)), 'uint8');
     case {'image:raw', 'thumb:raw'}
       result = typecast2(handle.ca.getraw(cid, handle.cf, strtok(attribute, ':'), handle.retry_count), 'uint8');
     otherwise
       result = handle.ca.get(cid, handle.cf, attribute, handle.retry_count);
   end
end