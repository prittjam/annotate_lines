function [contour_list,par_cspond,perp_cspond, cid_cache, bounding_boxes] = ...
        get_contour_list(img)
    cid_cache = CASS.CidCache(img.cid);
    pth = pwd;
    model = get_dollar_model();

    cid_cache.add_dependency('contours',model.opts);

    cid_cache.add_dependency('parallel_lines',[], ...
                             'parents','contours'); 
    cid_cache.add_dependency('perpendicular_lines',[], ...
                             'parents','contours'); 
                         
    cid_cache.add_dependency('bounding_boxes', []);   % maksym added                  

    contour_list = cid_cache.get('annotations','contour_list'); 

    bounding_boxes = cid_cache.get('annotations', 'bounding_boxes');  %maksym added
    
    if isempty(contour_list)
        [E,o] = edgesDetect(img.data,model);
        cd(pth);
        pts = DL.segment_contours(E);
        C = cmp_splitapply(@(x) { x },[pts(:).x],[pts(:).G]);
      
        box_id_list = cellfun(@(x) label_box_id(x,bounding_boxes),C);

        num_contours = numel(C);
        l = zeros(3,num_contours);
        for k = 1:numel(C)
            l(:,k) = LINE.fit(C{k});
        end
        contour_list = struct('C', C, ...
                              'l', mat2cell(l,3,ones(1,num_contours)), ...
                              'box_id', mat2cell(box_id_list,1, ...
                                                 ones(1,num_contours)));
        
        cid_cache.put('annotations','contour_list', contour_list);
    end

    cd(pth);

    par_cspond = ...
        cid_cache.get('annotations','parallel_lines');

    keyboard
    perp_cspond = ...
        cid_cache.get('annotations','perpendicular_lines');
    
%     par_cspond = [];
    if isempty(par_cspond)
        Gbox = [contour_list(:).box_id];
        par_cspond = cmp_splitapply(@(c,cind)...
                                    { make_par_cspond(c, cind) }, ...
                                    contour_list, ...
                                    1:num_contours,Gbox);
        par_cspond = par_cspond{:};
        keyboard
        cid_cache.put('annotations','parallel_lines',par_cspond);
        
        perp_cspond = cmp_splitapply(@(c,cind) { make_perp_cspond(c,cind) }, ...
                                     contour_list,1:num_contours, ...
                                     Gbox);
        perp_cspond = perp_cspond{:};
        cid_cache.put('annotations','perpendicular_lines',perp_cspond);
    end
    
    
function box_id = label_box_id(C,bounding_box_list)
    in_box = zeros(1,numel(bounding_box_list));
    for k = 1:numel(bounding_box_list)
        x = [bounding_box_list(k).rect(:,1) ...
             [bounding_box_list(k).rect(1,2); bounding_box_list(k).rect(2,1)] ...
             bounding_box_list(k).rect(:,2) ...
             [bounding_box_list(k).rect(1,1); bounding_box_list(k).rect(2,2)] ];
        convind = convhull(x');
        x = x(:,convind);
        inl = inpolygon(C(1,:), C(2,:), x(1,:), x(2,:));
        in_box(k) = sum(inl)/numel(inl) > 0.5;
    end
    box_id = min(find(in_box));
    if isempty(box_id)
        box_id = nan;
    end

function par_cspond = make_par_cspond(contour_list,contour_ind)    
    sz = arrayfun(@(contour) size(contour.C,2), contour_list);
    
    l = [contour_list(:).l];
    c = abs(l(1:2,:)'*l(1:2,:));
    c(c>1) = 1;
    theta = acos(c)*180/pi;
    ltri = itril([size(l,2) size(l,2)],-1);
    
    par_ind = find(theta(ltri) < 5);
    par_inl_ind = ltri(par_ind);
    [ii,jj] = ind2sub([size(l,2) size(l,2)],par_inl_ind);
    [~,sind] = sort(mean([sz(ii);sz(jj)],1),'descend');
    cspond_par = [contour_ind(ii(sind));contour_ind(jj(sind))];
    max_num_par = min([100 size(cspond_par,2)]);

    par_cspond = ...
        struct('cspond',mat2cell(cspond_par(:,1:max_num_par),2,ones(1,max_num_par)), ...
               'label', mat2cell(zeros(1,max_num_par),1,ones(1,max_num_par)));

function perp_cspond = make_perp_cspond(contour_list,contour_ind)    
    sz = arrayfun(@(contour) size(contour.C,2), contour_list);

    l = [contour_list(:).l];
    c = abs(l(1:2,:)'*l(1:2,:));
    c(c>1) = 1;
    theta = acos(c)*180/pi;
    ltri = itril([size(l,2) size(l,2)],-1);

    perp_ind = theta(ltri) > 85; 
    perp_inl_ind = ltri(find(perp_ind));
    [ii2,jj2] = ind2sub([size(l,2) size(l,2)],perp_inl_ind);
    [~,sind] = sort(mean([sz(ii2);sz(jj2)],1),'descend');
    cspond_perp = [contour_ind(ii2(sind));contour_ind(jj2(sind))];
    max_num_perp = min([100 size(cspond_perp,2)]);
    
    perp_cspond = ...
        struct('cspond',mat2cell(cspond_perp(:,1:max_num_perp),2,ones(1,max_num_perp)), ...
               'label', mat2cell(zeros(1,max_num_perp),1,ones(1, ...
                                                      max_num_perp))); 
