function [contour_list,par_cspond,perp_cspond] = ...
        get_contour_list(img)
    cid_cache = CASS.CidCache(img.cid);
    pth = pwd;
    
    model = get_dollar_model();

    cid_cache.add_dependency('contours',model.opts);

    cid_cache.add_dependency('parallel_lines',[], ...
                             'parents','contours'); 
    cid_cache.add_dependency('perpendicular_lines',[], ...
                             'parents','contours'); 

    contour_list = cid_cache.get('annotations','contour_list'); 

    if isempty(contour_list)
        [E,o] = edgesDetect(img.data,model);
        cd(pth);
        pts = DL.segment_contours(E);
        C = cmp_splitapply(@(x) { x },[pts(:).x],[pts(:).G]);
        sz = cmp_splitapply(@(x) numel(x),[pts(:).x],[pts(:).G]);
        num_ind = numel(sz);
        l = zeros(3,num_ind);
        for k = 1:numel(C)
            l(:,k) = LINE.fit(C{k});
        end
        contour_list = struct('C', C, ...
                              'l', mat2cell(l,3,ones(1,size(l,2))));
        cid_cache.put('annotations','contour_list', contour_list);
    end

    cd(pth);

    par_cspond = ...
        cid_cache.get('annotations','parallel_lines');

    perp_cpsond = ...
        cid_cache.get('annotations','perpendicular_lines');


    par_cspond = [];
    perp_cpsond = [];

    if isempty(par_cspond)
        l = [contour_list(:).l];
        c = abs(l(1:2,:)'*l(1:2,:));
        c(c>1) = 1;
        theta = acos(c)*180/pi;
        ltri = itril([size(l,2) size(l,2)],-1);
    
        par_ind = find(theta(ltri) < 5);
        par_inl_ind = ltri(par_ind);
        [ii,jj] = ind2sub([size(l,2) size(l,2)],par_inl_ind);
        [~,sind] = sort(mean([sz(ii);sz(jj)],1),'descend');
        cspond_par = [ii(sind) jj(sind)]';
        num_par = size(cspond_par,2);
        
        perp_ind = theta(ltri) > 85; 
        perp_inl_ind = ltri(find(perp_ind));
        [ii2,jj2] = ind2sub([size(l,2) size(l,2)],perp_inl_ind);
        [~,sind] = sort(mean([sz(ii2);sz(jj2)],1),'descend');
        cspond_perp = [ii2(sind) jj2(sind)]';
        num_perp = size(cspond_perp,2);
        
        par_cspond = ...
            struct('cspond',mat2cell(cspond_par,2,ones(1,num_par)), ...
                   'label', mat2cell(zeros(1,num_par),1,ones(1,num_par)));
        perp_cspond = ...
            struct('cspond',mat2cell(cspond_perp,2,ones(1,num_perp)), ...
                   'label', mat2cell(zeros(1,num_perp),1,ones(1,num_perp)));          

        cid_cache.put('annotations','parallel_lines',par_cspond);
        cid_cache.put('annotations','perpendicular_lines',perp_cspond);
    end
