function [] = chessboard()
img = imread(['/home/prittjam/Dropbox/gopro/Hero 4 Session/' ...
              'checkerboard/wide/vlcsnap-error016.png']);
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

corner_list = reshape(corner_list,9,6)';

corners =   [corner_list{1,1} corner_list{1,9}, ...
             corner_list{6,1} corner_list{6,9}, ...
             corner_list{2,2} corner_list{2,5}, ...   
             corner_list{5,2} corner_list{5,5}];

dr = struct('u',mat2cell(corners,3,ones(1,8)));

corresp = [1 3 5 7;
           2 4 6 8];

[h,w,~] = size(img);
cc = [w/2 h/2];
solver = RANSAC.WRAP.pt4x2_to_lusvq(cc);
model_list = solver.fit(dr,corresp,1:4);

imshow(img);
hold on;
plot(corners(1,:),corners(2,:),'bo');
hold off;

keyboard;
uimg = IMG.ru_div(img,model_list{2}.q);
figure;imshow(uimg);
IMG.output_undistortion(img,uimg);




