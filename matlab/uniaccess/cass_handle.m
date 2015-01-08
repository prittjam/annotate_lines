function handle=cass_handle()
%
% returns singleton object holding initialised CASS_STORAGE structure
%
   global CASS_STORAGE;
   % holds variables neccessary to access images and their attachments
   global CFG;

   if ~isstruct(CASS_STORAGE)
      if ~isfield(CFG, 'cass_read_consistency_level') || ~isfield(CFG, 'cass_write_consistency_level') % posibilities are {'ALL', 'ANY', 'ONE', 'QUORUM'}
         CASS_STORAGE.ca = imagedb.CassandraAccessor(CFG.imagedb_cluster); %should be 'cmpgrid_cassandra'
      else
         CASS_STORAGE.ca = imagedb.CassandraAccessor(CFG.imagedb_cluster, CFG.cass_read_consistency_level, CFG.cass_write_consistency_level); %should be 'cmpgrid_cassandra'
      end
      CASS_STORAGE.cf = 'image';
      CASS_STORAGE.retry_count = 5;
      if (isfield(CFG, 'storage'))
         if (isfield(CFG.storage, 'retry_count'))
            CASS_STORAGE.retry_count = CFG.storage.retry_count;
         end         
         if (isfield(CFG.storage, 'cf'))
            CASS_STORAGE.cf = CFG.storage.cf;
         end
      end      
   end;
   
   handle=CASS_STORAGE;
end
