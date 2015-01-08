function result = cass_imagecheck(cid, attribute, opt)
   error(nargchk(2, 3, nargin, 'struct'))
   handle = cass_handle();
   if (nargin>2) handle = optmerge(handle, opt); end;
   if iscell(cid), cid = cid{1}; end

   result = handle.ca.isPresent(cid, handle.cf, attribute, handle.retry_count);
end