function pts = segment_contours(E,varargin)
cfg = struct('min_response',1e-3, ...
             'max_kappa', 1e-1, ...
             'min_length', 15, ...
             'kappa_stride', 5, ...
             'theta_stride', 5);

cfg = cmp_argparse(cfg,varargin{:});

[ny nx] = size(E);

E1 = E;

E1(E1 < cfg.min_response) = 0;
E1(E1 ~= 0) = 1;

E2 = bwmorph(E1,'thin',Inf);
E3 = bwmorph(E2,'spur',5);

B = DL.edgelink(E3,cfg.min_length);
Bsz = cellfun(@(x) size(x,1),B);

G = repelem(1:numel(B),Bsz);
x = cat(1,B{:})';
[x(1,:),x(2,:)] = deal(x(2,:),x(1,:));

theta = ...
    msplitapply(@(x) dlines('calc_orientation',x, ...
                            'stride',cfg.theta_stride), ...
                x,G);
kappa = ...
    msplitapply(@(x) dlines('calc_curvature',x, ...
                            'stride',cfg.kappa_stride), ...
                x,G);

pts = struct('x',mat2cell(x,2,ones(1,size(x,2))), ...
             'G',mat2cell(G,1,ones(1,numel(G))), ...
             'theta',mat2cell(theta,1,ones(1,numel(theta))), ...
             'kappa',mat2cell(kappa,1,ones(1,numel(kappa))));

uG = unique(G);
maxGc = 0;
for g = 1:numel(uG)
    iG = find(G==g);
    Gc = break_contour(kappa(iG));
    if ~all(isnan(Gc))
        Gc = findgroups(msplitapply(@(g) rm_short_contours(g,cfg.min_length),Gc,Gc));
        Gc = Gc+maxGc;
        ng = sum(~isnan(unique(Gc)));
        maxGc = maxGc+ng;
    end
    tmp = mat2cell(Gc,1,ones(1,numel(Gc)));    
    [pts(iG).G] = tmp{:};
end

function [G,g] = break_contour(kappa)
ind = find((kappa > 0.1) & ~isnan(kappa)); 
G = nan(size(kappa));
g = 0;
s = 1;
for k = 1:numel(ind)
    if ind(k) > s
        g = g+1;
        G(s:ind(k)-1) = g;
    end
    s = ind(k)+1;
end

function x = rm_short_contours(x,min_length)
if numel(x) < min_length
    x(:) = nan;
end
