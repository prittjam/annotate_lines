function check = check_image_data(image_id, cfg, what, opt, check)
% read data about IMAGE_ID using universal access CFG
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
      check.image = cfg.storage.check(image_id, 'image', opt);
   end;
   for i = 1:numel(cfg.subtype.tbl)
      t = cfg.subtype.tbl{i};
      key = cfg.dhash;
      vkey = cfg.vhash{i};
      if (~ismember(t, {'haff'}))
         % if not a detector with compound features, disambiguate subtypes into key
         key = [t ':' key];
         vkey = [t ':' key];
      end;
      if (do_sifts) check.(t).sifts = cfg.storage.check(image_id, ['sifts:', key], opt); end; 
      if (do_geom)  check.(t).geom = cfg.storage.check(image_id, ['geom:', key], opt); end; 
      if (do_qv)    check.(t).qv = cfg.storage.check(image_id, ['qv:', key], opt); end;
      if (do_labels) check.(t).labels = cfg.storage.check(image_id, ['labels:', key], opt); end;
      if (do_selresponse) check.(t).selresponse = cfg.storage.check(image_id, ['selresponse:', vkey], opt); end;
   end;
