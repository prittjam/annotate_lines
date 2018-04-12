function [] = chessboard()
% img = imread(['/home/prittjam/Dropbox/gopro/Hero 4 Session/' ...
%               'checkerboard/wide/vlcsnap-error016.png']);
directory = '~/Downloads/Mobile_calib_resized/';
images = dir(directory);

addpath('~/mexopencv4/mexopencv/')
addpath('~/mexopencv4/mexopencv/opencv_contrib/')

% export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6:/usr/lib/x86_64-linux-gnu/libtiff.so.5

for q = 3:numel(images)
    
    % read image using Img class
    cd ../src/cmpfeat/
    image = Img('url', strcat(directory, images(q).name));
    cd ../../annotate_lines/
    
    disp(q)
    img = imread([strcat(directory, images(q).name)]);
    gray_img = uint8(rgb2gray(img));
    pattern_size = [9 6];         % interior number of corners

    [corner_list,is_found] = cv.findChessboardCorners(gray_img, pattern_size);
    if is_found
        corner_list = cv.cornerSubPix(gray_img, corner_list);
        
    end
    for k = 1:numel(corner_list)
        corner_list{k} = [corner_list{k}';1];   
    end
    dr = struct('u',corner_list)
    
%     if numel(dr) ~= 54 
%         disp('bad');
%         disp(images(q).name);
%     end    


    
    dr_new = zeros(2, numel(dr));
%     x = zeros(1, numel(dr));
%     y = zeros(1, numel(dr));
    for k = 1:numel(dr)
        dr_new(1, k) = dr(k).u(1);
        dr_new(2, k) = dr(k).u(2);
%         x(k) = dr(k).u(1);
%         y(k) = dr(k).u(2);
    end
    % save to cache
    cid_cache = CASS.CidCache(image.cid); 
    cid_cache.add_dependency('chessboard', []);
    cid_cache.put('results', 'chessboard', dr_new) 
%      out = cid_cache.get('results', 'chessboard')
%     for z = 1:3
%              figure; imshow(img);
%      hold on;
%          plot(dr_new(1,z),dr_new(2,z), 'r.', 'MarkerSize', 50);
%     end
         %      plot(dr_new(1,1),dr_new(2,1), '+', 'Color', [1 0 0], 'LineWidth', 4);
% 
%     hold off;
%     saveas(gcf, strcat('~/Downloads/res_calib/', images(q).name, '.jpg'));
%     close all;
end    


% corner_list = reshape(corner_list,9,6)';
% 
% corners =   [corner_list{1,1} corner_list{1,9}, ...
%              corner_list{6,1} corner_list{6,9}, ...
%              corner_list{2,2} corner_list{2,5}, ...   
%              corner_list{5,2} corner_list{5,5}];
% 
% dr = struct('u',mat2cell(corners,3,ones(1,8)));
% 
% corresp = [1 3 5 7;
%            2 4 6 8];
% 
% [h,w,~] = size(img);
% cc = [w/2 h/2];
% solver = RANSAC.WRAP.pt4x2_to_lusvq(cc);
% model_list = solver.fit(dr,corresp,1:4);
% 
% imshow(img);
% hold on;
% plot(corners(1,:),corners(2,:),'bo');
% hold off;
% 
% keyboard;
% uimg = IMG.ru_div(img,model_list{2}.q);
% figure;imshow(uimg);
% IMG.output_undistortion(img,uimg);




