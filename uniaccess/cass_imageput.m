function cass_imageput(cid, data, attribute, opt)
% CASS_IMAGEPUT cid, data, attribute, opt
   error(nargchk(3, 4, nargin, 'struct'));
   handle = cass_handle();
   if (nargin>3) handle = optmerge(handle, opt); end;
   if iscell(cid), cid = cid{1}; end

   switch (attribute)
     case {'image:raw', 'thumb:raw'}
       handle.ca.putraw(cid, data, handle.cf, strtok(attribute,':'), handle.retry_count);
     case {'image', 'thumb'}
       error('Image encoding to cassandra is not implemented.');
     otherwise
       handle.ca.put(cid, data, handle.cf, attribute, handle.retry_count);
   end
   
end