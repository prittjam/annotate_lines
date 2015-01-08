function result = cass_imageremove(cid, attribute, opt)
   error(nargchk(1, 3, nargin, 'struct'));
   handle = cass_handle();
   if iscell(cid), cid = cid{1}; end

   if (nargin>2) handle = optmerge(handle, opt); end;
   if (nargin == 1 || isempty(attribute))
      makesure(sprintf('Are you sure that you want to delete all attributes including image for cid %s? [y/N]: ', cid));
      handle.ca.removeAll(cid, handle.cf);
   else
      handle.ca.remove(cid, handle.cf, attribute, handle.retry_count);
   end
end
