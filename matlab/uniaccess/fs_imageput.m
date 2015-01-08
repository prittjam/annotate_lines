function result = fs_imageput(cid, data, attribute, opt)

	handle = fs_handle();
	if iscell(cid)
		cid = cid{1};
	end

	fname = cid2filename(cid, handle.data.root);
	default_type = 'feats';

	% require attribute explicitly... (to not overwrite image file)
	[tok rem] = strtok(attribute,':');
	switch (tok)
	case 'image'
		fname = cid2filename(cid, handle.images);
		error('Images are read-only for safety reasons.');
	case 'thumb'
		try
			fname = cid2filename(cid, handle.thumbs.root);
			[res1 res2] = unix(['umask ugo=rwx; mkdir -pm 777 ', fileparts(fname)]);
			imwrite(data, fname, 'jpg', 'Quality', 50);
			[res1 res2] = unix(['chmod 666 ', fname]);

			result = true;
		catch
			result = false;
		end
	case 'sifts'
		% separate out a configuration hash
		[cfghash rem] = strtok(rem,':');
		[type rem] = strtok(rem,':'); if (isempty(type)) type = default_type; end;
		result = filewrite(sprintf('%s-%s-%s-sifts', fname, cfghash, type), data, '*uint8');
	case 'geom'
		% separate out a configuration hash
		[cfghash rem] = strtok(rem,':');
		[type rem] = strtok(rem,':'); if (isempty(type)) type = default_type; end;
		result = filewrite(sprintf('%s-%s-%s-geom', fname, cfghash, type), data, '*single');
	case 'labels'
		% separate out a configuration hash
		[cfghash rem] = strtok(rem,':');
		[type rem] = strtok(rem,':'); if (isempty(type)) type = default_type; end;
		result = filewrite(sprintf('%s-%s-%s-labels', fname, cfghash, type), data, '*uint32');
	case 'qv'
		% separate out a configuration hash
		[cfghash rem] = strtok(rem,':');
		[type rem] = strtok(rem,':'); if (isempty(type)) type = default_type; end;
		result = filewrite(sprintf('%s-%s-%s-qv', fname, cfghash, type), data, '*single');
	otherwise
		error('Unsupported image attribute');
end;