function [contour_list,par_pair,perp_pair] = ...
        get_contour_list(img)
cid_cache = CASS.CidCache(img.cid);

model = get_dollar_model();

cid_cache.add_dependency('contours',model.opts);
cid_cache.add_dependency('parallel_lines',[], ...
                         'parents','contours'); 
cid_cache.add_dependency('perpendicular_lines',[], ...
                         'parents','contours'); 

contour_list = cid_cache.get('dr','contours'); 

if isempty(contour_list)
    [E,o] = edgesDetect(img.data,model);
    cd(pth);
    pts = DL.segment_contours(E);
    C = cmp_splitapply(@(x) { x },[pts(:).x],[pts(:).G]);
    sz = cmp_splitapply(@(x)  numel(x) ,[pts(:).x],[pts(:).G]);
    ind = sz > 20;
    num_ind = sum(ind);
    sC = C(ind);
    cid_cache.put('dr','contours',sC);
    l = zeros(3,num_ind);
    for k = 1:numel(sC)
        l(:,k) = LINE.fit(sC{k});
    end
    contour_list = struct('C', C, ...
                          'l', mat2cell(3,size(l,2)));
end

par_pair = ...
    cid_cache.get('annotations','parallel_lines');

perp_pair = ...
    cid_cache.get('annotations','perpendicular_lines');

if isempty(par_pair)
    c = abs(l(1:2,:)'*l(1:2,:));
    c(c>1) = 1;
    theta = acos(c)*180/pi;
    ltri = itril([size(l,2) size(l,2)],-1);
    par_ind = theta(ltri) < 5; 
    inl_ind = ltri(find(par_ind));
    [ii,jj] = ind2sub([size(l,2) size(l,2)],inl_ind);
    sind = sort(mean([sz(ii);sz(jj)],1),'descend');
    par_pair = [ii(sind) jj(sind)]';
    
    perp_ind = theta(ltri) > 85; 
    inl_ind = ltri(find(perp_ind));
    [ii2,jj2] = ind2sub([size(l,2) size(l,2)],inl_ind);
    sind = sort(mean([sz(ii2);sz(jj2)],1),'descend');
    perp_pair = [ii2(sind) jj2(sind)]';

    cid_cache.put('annotations','parallel_lines', ...
                  par_pair);
    cid_cache.put('annotations','perpendicular_lines', ...
                  perp_pair);
    
end
par_pair = par_pair;
perp_pair = perp_pair;

%        itril()

%        set(uistate.handles.img,'HitTest','on');
%        set(uistate.handles.img,'ButtonDownFcn',@image_click_callback);
%        uistate.file_name = file_name;
%        uistate.path = path;
%        uistate.outlier = struct('h',[],'select',false);
%        uistate.ignore = struct('h',[],'select',false);
%        uistate.plane_list = cell(1,0);
