function remove_image_data(cid, cfg, what, opt)
% remove image data CID using universal access CFG
% columns/files are given in WHAT and can be a subset of {'sifts','geom','qv', 'image'} 
   if (~iscell(what))
      what = {what};
   end;
   do_sifts = ismember('sifts', what) || ismember('sift', what);
   do_geom  = ismember('geom', what);
   do_qv    = ismember('qv', what);
   do_labels= ismember('labels', what);
   do_selresponse = ismember('selresponse', what);
   if ismember('image', what) || ismember('im', what)
      cfg.storage.remove(cid, 'image:raw', opt); fprintf('!');
   end;
   if ismember('ftype', what)
      cfg.storage.remove(cid, ['ftype:', cfg.dhash], opt); fprintf('!');
   end
   
   for i = 1:numel(cfg.subtype.tbl)
      t = cfg.subtype.tbl{i};
      key = cfg.dhash;
     
      if (do_labels | do_selresponse)
         vkey = cfg.vhash{i};
      end;
      if (~ismember(t, {'haff'}))
         % if not a detector with compound features, disambiguate subtypes into key
         key = [t ':' key];
         if (do_labels | do_selresponse)
            vkey = [t ':' key];
         end;
      end;
      if (do_sifts)       cfg.storage.remove(cid, ['sifts:', key], opt); fprintf('!'); end; 
      if (do_geom)        cfg.storage.remove(cid, ['geom:', key], opt); fprintf('!'); end; 
      if (do_qv)          cfg.storage.remove(cid, ['qv:', key], opt); fprintf('!'); end;
      if (do_labels)      cfg.storage.remove(cid, ['labels:', vkey], opt); fprintf('!'); end;
      if (do_selresponse) cfg.storage.remove(cid, ['selresponse:', vkey], opt); fprintf('!'); end;
   end;
