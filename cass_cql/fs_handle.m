function handle=fs_handle()
%
% returns singleton object holding initialised FS_STORAGE structure
%
   global FS_STORAGE;
   % holds variables neccessary to access images and their attachments
   global CFG;

   if ~isstruct(FS_STORAGE)
      db_root = CFG.storage.db_root;
      FS_STORAGE.images.root = fullfile(db_root, 'image');
      FS_STORAGE.thumbs.root = fullfile(db_root, 'en4', 'thumb');
      FS_STORAGE.data.root   = fullfile(db_root, 'image');
      lin_files = fullfile(db_root, 'data', '_linfiles');
      % legacy 505 datafiles
      FS_STORAGE.linfiles.sifts_fname = fullfile(lin_files, 'sift.dat');
      FS_STORAGE.linfiles.geom_fname = fullfile(lin_files, 'geom.dat');
      FS_STORAGE.linfiles.labels_fname = fullfile(lin_files, 'labels-%s.dat');
      FS_STORAGE.linfiles.ind = fileread(fullfile(lin_files, 'ind.dat'), inf, '*uint64');
   end;

   handle=FS_STORAGE;
