function [first last] = fs_id2linidx(image_id)

   error('not implemented');
   handle = fs_handle();

   first = double(handle.linfiles.ind(image_id{2}));
   last = double(handle.linfiles.ind(image_id{2}+1))-1;
   