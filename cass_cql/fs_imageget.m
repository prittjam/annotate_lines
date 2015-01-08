function result = fs_imageget(cid, attribute, opt)

   handle = fs_handle();
   if iscell(cid), cid = cid{1}; end

   fname = cid2filename(cid, '');
   % type of features not distinguished
   default_type = 'feats';
   if (nargin<2)
      attribute = 'image';
   end;

   [tok rem] = strtok(attribute,':');
   switch (tok)
     case 'image'
       [type rem] = strtok(rem,':');
       switch (type)
         case 'raw'
           result = fileread(fullfile(handle.images.root, fname), [1 inf], '*uint8');
         otherwise
           result = imread(fullfile(handle.images.root, fname));
       end;
     case 'thumb'
       result = imread(fullfile(handle.thumbs.root, fname));
     case 'sifts'
       % check requested detector
       [detector rem] = strtok(rem,':');
       [type rem] = strtok(rem,':'); if (isempty(type)) type = default_type; end;
       switch (detector)
         case 'haff-na' % legacy stuff, linear files
           % get range od linear file if available
           [first last] = fs_id2linidx(cid);
           % open and seek
           fid = fopen(handle.linfiles.sifts_fname, 'r');
           fseek(fid, first*128, 'bof');
           result = fread(fid, [128 last-first+1], '*uint8');
           fclose(fid);
         otherwise
           % assume "detector" is a hash of configuration
           result = fileread(fullfile(handle.data.root, sprintf('%s-%s-%s-sifts', fname, detector, type)), [128 inf], '*uint8');
       end;
     case 'geom'
       % check requested detector
       [detector rem] = strtok(rem,':');
       [type rem] = strtok(rem,':'); if (isempty(type)) type = default_type; end;
       switch (detector)
         case 'haff-na' % legacy stuff, linear files
           % get range od linear file if available
           [first last] = fs_id2linidx(cid);

           % open and seek
           fid = fopen(handle.linfiles.geom_fname, 'r');
           fseek(fid, first*20, 'bof');
           result = fread(fid, [5 last-first+1], '*single');
           fclose(fid);
         otherwise
           % assume "detector" is a hash of configuration
           result = fileread(fullfile(handle.data.root, sprintf('%s-%s-%s-geom', fname, detector, type)), [5 inf], '*single');
       end;
     case 'labels'
       % check requested detector
       [detector rem] = strtok(rem,':');
       switch (detector)
         case 'haff-na' % legacy stuff, linear files
           % separate out the name of the vocabulary
           [dict rem] = strtok(rem, ':');
           % get range od linear file if available
           [first last] = fs_id2linidx(cid);

           % open and seek
           fid = fopen(sprintf(handle.linfiles.labels_fname, dict), 'r');
           fseek(fid, first*4, 'bof');
           result = fread(fid, [1 last-first+1], '*uint32');
           fclose(fid);
         otherwise
           % assume "detector" is a hash of configuration (that contains dictionary)
           [type rem] = strtok(rem,':'); if (isempty(type)) type = default_type; end;
           result = fileread(fullfile(handle.data.root, sprintf('%s-%s-%s-labels', fname, detector, type)), inf, '*uint32');
       end;
     case 'qv'
       % check requested detector
       [detector rem] = strtok(rem,':');
       % assume "detector" is a hash of configuration (that contains dictionary)
       [type rem] = strtok(rem,':'); if (isempty(type)) type = default_type; end;
       result = fileread(fullfile(handle.data.root, sprintf('%s-%s-%s-qv', fname, detector, type)), [24 inf], '*single');
     otherwise
       error('Unsupported image attribute');
   end;