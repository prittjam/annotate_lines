function result = fs_imagecheck(cid, attribute)
   
   handle = fs_handle();
   if iscell(cid), cid = cid{1}; end

   fname = cid2filename(cid, '');
   % type of features not distinguished
   default_type = 'feats';      
   if (nargin<2)
      attribute = 'image'
   end;
   
   [tok rem] = strtok(attribute,':');
   switch (tok)
     case 'image'
       result = exist(fullfile(handle.images.root, fname), 'file');
     case 'thumb'
       result = exist(fullfile(handle.thumbs.root, fname), 'file');
     case 'sifts'
       % check requested detector
       [detector rem] = strtok(rem,':');
       [type rem] = strtok(rem,':'); if (isempty(type)) type = default_type; end;
       switch (detector)
         case 'haff-na' % legacy stuff, linear files
           results = exist(handle.linfiles.sifts_fname, 'file');
         otherwise
           % assume "detector" is a hash of configuration
           result = exist(fullfile(handle.data.root, sprintf('%s-%s-%s-sifts', fname, detector, type)), 'file');
       end;
     case 'geom'
       % check requested detector
       [detector rem] = strtok(rem,':');
       [type rem] = strtok(rem,':'); if (isempty(type)) type = default_type; end;
       switch (detector)
         case 'haff-na' % legacy stuff, linear files
           results = exist(handle.linfiles.geom_fname, 'file');
         otherwise
           % assume "detector" is a hash of configuration
           result = exist(fullfile(handle.data.root, sprintf('%s-%s-%s-geom', fname, detector, type)), 'file');
       end;
     case 'labels'
       % check requested detector
       [detector rem] = strtok(rem,':');
       switch (detector)
         case 'haff-na' % legacy stuff, linear files           
           % separate out the name of the vocabulary
           [dict rem] = strtok(rem, ':');
           % open and seek
           result = exist(sprintf(handle.linfiles.labels_fname, dict), 'file');
         otherwise
           % assume "detector" is a hash of configuration (that contains dictionary)
           [type rem] = strtok(rem,':'); if (isempty(type)) type = default_type; end;
           result = exist(fullfile(handle.data.root, sprintf('%s-%s-%s-labels', fname, detector, type)), 'file');
       end;
     case 'qv'
       [detector rem] = strtok(rem,':');
       % assume "detector" is a hash of configuration (that contains dictionary)
       [type rem] = strtok(rem,':'); if (isempty(type)) type = default_type; end;
       result = exist(fullfile(handle.data.root, sprintf('%s-%s-%s-qv', fname, detector, type)), 'file');
     otherwise
       error('Unsupported image attribute');      
   end;