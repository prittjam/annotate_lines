function data = fetch_image_data(cid, cfg, what, opt, data)
% read data about CID using universal access CFG
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
      data.image = readim(cfg.storage.get(cid, 'image:raw', opt));
   end;
   if ismember('ftype', what)
      data.ftype = cfg.storage.get(cid, ['ftype:', cfg.dhash], opt);
   end
   
   for i = 1:numel(cfg.subtype.tbl)
      t = cfg.subtype.tbl{i};
      key = cfg.dhash;
      if (do_labels | do_selresponse)
         if (iscell(cfg.vhash))
            vkey = cfg.vhash{i};
         else
            vkey = cfg.vhash;
         end;
      end;
      if (~ismember(t, {'haff', 'hess', 'feats'}))
         % if not a detector with compound features, disambiguate subtypes into key
         key = [t ':' key];
         if (do_labels | do_selresponse)
            vkey = [t ':' vkey];
         end;
      end;
      if (do_sifts) data.(t).sifts = typecast2(cfg.storage.get(cid, ['sifts:', key], opt), 'uint8'); end; 
      if (do_geom)  data.(t).geom = cfg.storage.get(cid, ['geom:', key], opt); end; 
      if (do_qv)    data.(t).qv = cfg.storage.get(cid, ['qv:', key], opt); end;
      if (do_labels) data.(t).labels = cfg.storage.get(cid, ['labels:', vkey], opt); end;
      if (do_selresponse) data.(t).selresponse = cfg.storage.get(cid, ['selresponse:', vkey], opt); end;
   end;
