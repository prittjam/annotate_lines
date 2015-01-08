function store_image_data(cid, data, cfg, what, opt)
% write data about CID using universal access CFG
% columns/files are given in WHAT and can be a subset of {'sifts','geom','qv', 'image'}
   if (~iscell(what))
      what = {what};
   end;
   do_sifts = ismember('sifts', what);
   do_geom  = ismember('geom', what);
   do_qv    = ismember('qv', what);
   do_labels= ismember('labels', what);
   do_selresponse = ismember('selresponse', what);
   if ismember('image', what) || ismember('im', what)
      % TODO: a check if image is raw, 2d or 3d matrix..., fast encoder yet to be done
      error('Writing image is not supported yet.');
   end;
   if ismember('ftype', what)
      cfg.storage.put(cid, data.ftype, ['ftype:', cfg.dhash], opt);
   end

   for i = 1:numel(cfg.subtype.tbl)
      % separately for each detector type
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
      if (do_sifts) cfg.storage.put(cid, data.(t).sifts, ['sifts:', key], opt); end;
      if (do_geom)  cfg.storage.put(cid, data.(t).geom, ['geom:', key], opt); end;
      if (do_qv)    cfg.storage.put(cid, data.(t).qv, ['qv:', key], opt); end;
      if (do_labels) cfg.storage.put(cid, data.(t).labels, ['labels:', vkey], opt); end;
      if (do_selresponse) cfg.storage.put(cid, data.(t).selresponse , ['selresponse:', vkey], opt); end;
   end;