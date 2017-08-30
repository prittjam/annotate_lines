function [E,o,cfg] = extract_contours(img,cfg)


opts = struct('multiscale',1, ...
              'sharpen',2, ...
              'nTreesEval',4, ...
              'nThreads',4, ...
              'nms',1);

model = get_dollar_model();
cfg = model.opts;
[E,o] = edgesDetect(img,model); 


