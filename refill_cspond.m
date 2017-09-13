% function refill_cspond
% directory = '~/Downloads/gtrepeat_dataset/multiplane/';
% images = dir(directory);
% model = get_dollar_model();
% cd ../..
% for k = 43:numel(images)
%     cd ../src/cmpfeat/
%     img = Img('url', strcat(directory, images(k).name));
%     disp(images(k).name);
%     disp(k);
%     cd ../../annotate_lines/
%     
%     if k == 7 || k == 14 || k ==28 || k == 32 || k ==37 || k == 38 || k == 43 || k == 51
%         continue
%     end    
%     
%     cid_cache = CASS.CidCache(img.cid);
% 
%     cid_cache.add_dependency('contour_list',model.opts);
% 
%     cid_cache.add_dependency('parallel_lines',[], ...
%                              'parents','contour_list'); 
%     cid_cache.add_dependency('perpendicular_lines',[], ...
%                              'parents','contour_list');
%                          
%     cid_cache.put('annotations','contour_list', []); 
%     cid_cache.put('annotations','parallel_lines', []);
%     cid_cache.put('annotations','perpendicular_lines', []);      
%     get_contour_list(img);
% end
