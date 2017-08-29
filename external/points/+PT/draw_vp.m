function [] = draw_vp(v,varargin)
v = PT.renormI(v);
hold on;
plot(v(1,:),v(2,:),'*', ...
     'Color', 'y', ...y
     'MarkerSize',25, ...
     'LineWidth',3,varargin{:});

plot(v(1,:),v(2,:),'o', ...
     'MarkerSize',25, ...
     'LineWidth',3,varargin{:});

hold off;
