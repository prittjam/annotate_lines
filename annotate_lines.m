function varargout = annotate_lines(varargin)
% ANNOTATE_LINES MATLAB code for annotate_lines.fig
%      ANNOTATE_LINES, by itself, creates a new ANNOTATE_LINES or raises the existing
%      singleton*.
%
%      H = ANNOTATE_LINES returns the handle to a new ANNOTATE_LINES or the handle to
%      the existing singleton*.
%
%      ANNOTATE_LINES('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ANNOTATE_LINES.M with the given input arguments.
%
%      ANNOTATE_LINES('Property','Value',...) creates a new ANNOTATE_LINES or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before annotate_lines_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to annotate_lines_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help annotate_lines

% Last Modified by GUIDE v2.5 16-Sep-2017 13:58:57

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @annotate_lines_OpeningFcn, ...
                   'gui_OutputFcn',  @annotate_lines_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before annotate_lines is made visible.
function annotate_lines_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to annotate_lines (see VARARGIN)

% Choose default command line output for annotate_lines
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

addpath(genpath('external'));
addpath(genpath('~/opt/mex'));
addpath(genpath('~/opt/bgl'));

cache_params = { 'read_cache', true, ...
                 'write_cache', true };
init_dbs(cache_params{:});

uistate = guidata(gcf);

uistate.main_axes = gca;

uistate.par_count = 1;
uistate.perp_count = 1;

set(gcf, 'units','normalized','outerposition',[0 0 1 1]);  

uistate.uibuttongroup.SelectionChangedFcn = @(bg,uistate) radiobuttons_control(bg,uistate);

guidata(gcf,uistate);

% UIWAIT makes annotate_lines wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = annotate_lines_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in previmage.
function previmage_Callback(hObject, eventdata, handles)
% hObject    handle to previmage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
uistate = guidata(gcf);

N = numel(uistate.img_urls);
uistate.cur_url_id = uistate.cur_url_id-1;
if mod(uistate.cur_url_id,N) == 0 || uistate.cur_url_id < 1 % or was added
    uistate.cur_url_id = N;
end

uistate.img = Img('url',uistate.img_urls{uistate.cur_url_id});       
uistate.handles.img = imshow(uistate.img.data,'Parent',gca);    
[uistate.contour_list,uistate.par_cspond,uistate.perp_cspond, uistate.cid_cache, uistate.bounding_boxes] = ...
    get_contour_list(uistate.img);   

disp(numel(uistate.par_cspond));
disp(numel(uistate.perp_cspond));

[start_par_count, start_perp_count] = find_unlabeled_lines(uistate);

uistate.par_count = start_par_count; % = 1
uistate.perp_count = start_perp_count; % = 1 

reset_radiobuttons(uistate); % my changes

update_lines(uistate);

guidata(gcf,uistate);
[Npar, Nperp] = count_cspond_pairs()
see_status;

% --- Executes on button press in nextimage.
function nextimage_Callback(hObject, eventdata, handles)
% hObject    handle to nextimage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
uistate = guidata(gcf);

N = numel(uistate.img_urls);
% uistate.cur_url_id = uistate.cur_url_id+1;
% if mod(uistate.cur_url_id,N) == 0 || uistate.cur_url_id > N % or was added
%     uistate.cur_url_id = 1;
% end

uistate.cur_url_id = mod(uistate.cur_url_id, N)+1; % maksym added

disp(uistate.cur_url_id);

uistate.img = Img('url',uistate.img_urls{uistate.cur_url_id});  
uistate.handles.img = imshow(uistate.img.data,'Parent',gca);    
[uistate.contour_list,uistate.par_cspond,uistate.perp_cspond, uistate.cid_cache, uistate.bounding_boxes] = ...
    get_contour_list(uistate.img);   

[start_par_count, start_perp_count] = find_unlabeled_lines(uistate);

uistate.par_count = start_par_count; % = 1
uistate.perp_count = start_perp_count; % = 1

reset_radiobuttons(uistate); % my changes

update_lines(uistate);

guidata(gcf,uistate);

[Npar, Nperp] = count_cspond_pairs()

see_status;

% --- Executes on selection change in linetype.
function linetype_Callback(hObject, eventdata, handles)
% hObject    handle to linetype (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns linetype contents as cell array
%        contents{get(hObject,'Value')} returns selected item from linetype
uistate = guidata(gcf);

reset_radiobuttons(uistate);
%uistate.linetype = eventdata.Source.Value;

update_lines(uistate);

guidata(gcf,uistate);
see_status;

% --- Executes during object creation, after setting all properties.
function linetype_CreateFcn(hObject, eventdata, handles)
% hObject    handle to linetype (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in prevlines.
function prevlines_Callback(hObject, eventdata, handles)
% hObject    handle to prevlines (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
uistate = guidata(gcf);

imshow(uistate.img.data,'Parent',uistate.main_axes);   
switch uistate.linetype.Value
  case 1
    N = numel(uistate.par_cspond);
    uistate.par_count = uistate.par_count-1;
    %%% my changes %%%
    if uistate.par_count < 1
        uistate.par_count = N;
    end    
    %%% end %%%
  case 2
    N = numel(uistate.perp_cspond);
    uistate.perp_count = uistate.perp_count-1;
    %%% my changes %%%
    if uistate.perp_count < 1
        uistate.perp_count = N;
    end    
    %%% end %%%
end
reset_radiobuttons(uistate); % my changes

update_lines(uistate);

guidata(gcf,uistate);
see_status;




% --- Executes on button press in nextlines.
function nextlines_Callback(hObject, eventdata, handles)
% hObject    handle to nextlines (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
uistate = guidata(gcf);

switch uistate.linetype.Value
  case 1
    N = numel(uistate.par_cspond);
%     uistate.par_count = uistate.par_count+1;
     uistate.par_count = mod(uistate.par_count, N) + 1;   
  case 2
    N = numel(uistate.perp_cspond);
%     uistate.perp_count = uistate.perp_count+1;
     uistate.perp_count = mod(uistate.perp_count, N) + 1;
end
% keyboard
reset_radiobuttons(uistate);

update_lines(uistate);

guidata(gcf,uistate); 
see_status;

% --------------------------------------------------------------------
function openfile_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to openfile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

uistate = guidata(gcf);
[file_name,path] = uigetfile({'*.png;*.jpg;*.gif;*.JPG','Pictures (*.png,*.jpg,*.gif)';'*.mat', 'Repeats (*.mat)'});

if ~isequal(file_name, 0)
    [cur_url,uistate.file_name_base,file_name_end] = fileparts(file_name);
    if ~isequal(file_name_end, '.mat') 
        uistate.img_urls = get_img_urls(path); 
        [~,uistate.cur_url_id] = ismember([path file_name], uistate.img_urls);
        uistate.img = Img('url',uistate.img_urls{uistate.cur_url_id}); 
        [uistate.contour_list,uistate.par_cspond,uistate.perp_cspond, uistate.cid_cache, uistate.bounding_boxes] = ...
            get_contour_list(uistate.img);

        [start_par_count, start_perp_count] = find_unlabeled_lines(uistate);
        uistate.par_count = start_par_count;
        uistate.perp_count = start_perp_count;
                
        update_lines(uistate);

        guidata(gcf,uistate); 
        
        [Npar, Nperp] = count_cspond_pairs()

        reset_radiobuttons(uistate); % my changes

        see_status;
    end
end

function img_urls = get_img_urls(base_path)
img_urls = dir(fullfile(base_path,'*.jpg'));

img_urls = cat(1,img_urls,dir(fullfile(base_path,'*.JPG')));
img_urls = cat(1,img_urls,dir(fullfile(base_path,'*.png')));
img_urls = cat(1,img_urls,dir(fullfile(base_path,'*.PNG')));
img_urls = cat(1,img_urls,dir(fullfile(base_path,'*.gif')));
img_urls = cat(1,img_urls,dir(fullfile(base_path,'*.GIF')));

img_urls = rmfield(img_urls,{'date','bytes','isdir','datenum'});
img_urls = arrayfun(@(x)[x.folder '/' x.name], ...
                    img_urls,'UniformOutput',false);

function [] = update_lines(uistate)
imshow(uistate.img.data,'Parent',uistate.main_axes);   
draw_annotations(uistate);

switch uistate.linetype.Value
  case 1     
    draw_line_pair(gca,uistate.contour_list, ...
       uistate.par_cspond,uistate.par_count, [0 0 0.8]);
    plot_C(uistate.contour_list, ...
       uistate.par_cspond,uistate.par_count);
  case 2      
    draw_line_pair(gca,uistate.contour_list, ...
                   uistate.perp_cspond,uistate.perp_count,[1 165/255 0]);
    plot_C(uistate.contour_list, ...
                   uistate.perp_cspond,uistate.perp_count);          
end

function draw_line_pair(ax,contour_list,cspond,idx,color)
hold on;
% plot(contour_list(cspond(idx).cspond(1)).C(1,:),...
%     contour_list(cspond(idx).cspond(1)).C(2,:),...
%     'Linewidth',3,'Color','w');

LINE.draw(ax, contour_list(cspond(idx).cspond(1)).l, ...
          'LineWidth',3,'Color',color);       

% plot(contour_list(cspond(idx).cspond(2)).C(1,:),...
%     contour_list(cspond(idx).cspond(2)).C(2,:),...
%     'Linewidth',3,'Color','w');

LINE.draw(ax, contour_list(cspond(idx).cspond(2)).l, ...
          'LineWidth',3,'Color',color);   
hold off;

function plot_C(contour_list,cspond,idx)
hold on
plot(contour_list(cspond(idx).cspond(1)).C(1,:),...
    contour_list(cspond(idx).cspond(1)).C(2,:),...
    'Linewidth',4,'Color','green');

plot(contour_list(cspond(idx).cspond(2)).C(1,:),...
    contour_list(cspond(idx).cspond(2)).C(2,:),...
    'Linewidth',4,'Color','green');

hold off
 
function reset_radiobuttons(uistate)
if uistate.linetype.Value == 1
    if numel(uistate.par_cspond) == 0
        disp('No paralel pairs');
        return
    end 
    switch  uistate.par_cspond(uistate.par_count).label
        case 0
            uistate.radiobutton_good.Value = 0;
            uistate.radiobutton_bad.Value = 0;
            uistate.radiobutton_unlabeled.Value = 1;
        case 1
            uistate.radiobutton_good.Value = 1;
            uistate.radiobutton_bad.Value = 0;
            uistate.radiobutton_unlabeled.Value = 0;
        case 2
            uistate.radiobutton_good.Value = 0;
            uistate.radiobutton_bad.Value = 1;
            uistate.radiobutton_unlabeled.Value = 0;
    end        
else
    if numel(uistate.perp_cspond) == 0
        disp('No perpendicular pairs');
        return
    end    
    switch  uistate.perp_cspond(uistate.perp_count).label
        case 0
            uistate.radiobutton_good.Value = 0;
            uistate.radiobutton_bad.Value = 0;
            uistate.radiobutton_unlabeled.Value = 1;
        case 1
            uistate.radiobutton_good.Value = 1;
            uistate.radiobutton_bad.Value = 0;
            uistate.radiobutton_unlabeled.Value = 0;
        case 2
            uistate.radiobutton_good.Value = 0;
            uistate.radiobutton_bad.Value = 1;
            uistate.radiobutton_unlabeled.Value = 0;
    end      
end  

function draw_annotations(uistate)
imshow(uistate.img.data,'Parent',uistate.main_axes); 

if isempty(uistate.bounding_boxes)
    return
end    
hold on  

for j = 1:numel(uistate.bounding_boxes)
    width = uistate.bounding_boxes(j).rect(1,2) - uistate.bounding_boxes(j).rect(1,1);
    height = uistate.bounding_boxes(j).rect(2,2) - uistate.bounding_boxes(j).rect(2,1);        
    rectangle('Position',[uistate.bounding_boxes(j).rect(1) uistate.bounding_boxes(j).rect(2) width height],...
            'LineWidth', 3, 'EdgeColor' ,[1 0 0])
end  
hold off                   
   
function [start_par_count, start_perp_count] = find_unlabeled_lines(uistate)
start_par_count = 1;
start_perp_count = 1;
for i = 1:numel(uistate.par_cspond)
    if uistate.par_cspond(i).label == 0
       start_par_count = i;
       break;
    end
end
for i = 1:numel(uistate.perp_cspond)
    if uistate.perp_cspond(i).label == 0
       start_perp_count = i;
       break;
    end
end

function radiobuttons_control(bg,~)
uistate = guidata(gcf);
 if strcmp(bg.Children(3).String, 'Good') == 1 && bg.Children(3).Value == 1
     result = 1;
 elseif strcmp(bg.Children(2).String, 'Bad') == 1 && bg.Children(2).Value == 1
     result = 2;
 else
     result = 0;
 end
if uistate.linetype.Value == 1
     uistate.par_cspond(uistate.par_count).label = result; 
elseif uistate.linetype.Value == 2
     uistate.perp_cspond(uistate.perp_count).label = result;
end    
 
uistate.cid_cache.put('annotations','parallel_lines', uistate.par_cspond);
uistate.cid_cache.put('annotations','perpendicular_lines', uistate.perp_cspond);
 
guidata(gcf,uistate); 
see_status;
nextlines_Callback([],[],[]);

function see_status
uistate = guidata(gcf);

uistate.text1.String = sprintf('Idx par: %d', uistate.par_count);
uistate.text2.String = sprintf('Idx perp: %d', uistate.perp_count);     

Nplanes = numel(uistate.bounding_boxes);    
[count_good_par, count_good_perp] = find_good_pairs;
% keyboard
final_str_par = ''; final_str_perp = '';

for k = 1:Nplanes
    if count_good_par(k) >= 20 
        final_str_par = sprintf('%sD ',final_str_par);
    else 
        final_str_par = sprintf('%s%d ',final_str_par, count_good_par(k));
    end
    
    if count_good_perp(k) >= 20 
        final_str_perp = sprintf('%sD ',final_str_perp);
    else  
        final_str_perp = sprintf('%s%d ',final_str_perp, count_good_perp(k));
    end
end
uistate.text3.String = sprintf('Good par: %s', final_str_par);
uistate.text4.String = sprintf('Good perp: %s', final_str_perp);
guidata(gcf,uistate); 
  
function [Npar, Nperp] = count_cspond_pairs()

uistate = guidata(gcf);
bounding_box_list = uistate.bounding_boxes;
Npar = zeros(1,numel(bounding_box_list));
Nperp = zeros(1,numel(bounding_box_list));
for k = 1:numel(bounding_box_list)
    x = [bounding_box_list(k).rect(:,1) ...
        [bounding_box_list(k).rect(1,2); bounding_box_list(k).rect(2,1)] ...
        bounding_box_list(k).rect(:,2) ...
        [bounding_box_list(k).rect(1,1); bounding_box_list(k).rect(2,2)] ];
    convind = convhull(x');
    x = x(:,convind);

    for q = 1:numel(uistate.par_cspond)
        C1 = uistate.contour_list(uistate.par_cspond(q).cspond(1)).C;
        inl1 = inpolygon(C1(1,:), C1(2,:), x(1,:), x(2,:));
        C2 = uistate.contour_list(uistate.par_cspond(q).cspond(2)).C;
        inl2 = inpolygon(C2(1,:), C2(2,:), x(1,:), x(2,:));
        t = (sum(inl1)/numel(inl1) > 0.5) && (sum(inl2)/numel(inl2) > 0.5);
        Npar(k) = Npar(k) + double(t);
    end
    
    for q = 1:numel(uistate.perp_cspond)
        C1 = uistate.contour_list(uistate.perp_cspond(q).cspond(1)).C;
        inl1 = inpolygon(C1(1,:), C1(2,:), x(1,:), x(2,:));
        C2 = uistate.contour_list(uistate.perp_cspond(q).cspond(2)).C;
        inl2 = inpolygon(C2(1,:), C2(2,:), x(1,:), x(2,:));
        t = (sum(inl1)/numel(inl1) > 0.5) && (sum(inl2)/numel(inl2) > 0.5);
        Nperp(k) = Nperp(k) + double(t);
    end
end    
uistate.Npar = Npar;
uistate.Nperp = Nperp;
% keyboard
guidata(gcf, uistate);

function [count_good_par, count_good_perp] = find_good_pairs
uistate = guidata(gcf);
%  [Npar, Nperp] = count_cspond_pairs;
Npar = uistate.Npar;
Nperp = uistate.Nperp;
% keyboard
Npar_temp = zeros(1, numel(Npar));
Nperp_temp = zeros(1, numel(Nperp));
Npar_temp(1) = Npar(1);
Nperp_temp(1) = Nperp(1);
for k = 2:numel(uistate.bounding_boxes)
    Npar_temp(k) = Npar(k) + Npar_temp(k-1);
    Nperp_temp(k) = Nperp(k) + Nperp_temp(k-1);
end
count_good_par = zeros(1, numel(uistate.bounding_boxes));
count_good_perp = zeros(1, numel(uistate.bounding_boxes));

f = 1; ff = 1;
for k = 1:numel(uistate.bounding_boxes)
    for kk = f:Npar_temp(k)
        if uistate.par_cspond(kk).label == 1
            count_good_par(k) = count_good_par(k) + 1;
        end
    end
    for kk = ff:Nperp_temp(k)
        if uistate.perp_cspond(kk).label == 1
            count_good_perp(k) = count_good_perp(k) + 1;
        end
    end
    f = Npar_temp(k) + 1;
    ff = Nperp_temp(k) + 1;
end

function next_plane_Callback(hObject, eventdata, handles)
uistate = guidata(gcf);
[Npar, Nperp] = count_cspond_pairs;
linetype = uistate.linetype.Value;
curr_par = uistate.par_count;
curr_perp = uistate.perp_count;
Npar_temp = zeros(1, numel(Npar));
Nperp_temp = zeros(1, numel(Nperp));
Npar_temp(1) = Npar(1);
Nperp_temp(1) = Nperp(1);
for k = 2:numel(uistate.bounding_boxes)
    Npar_temp(k) = Npar(k) + Npar_temp(k-1);
    Nperp_temp(k) = Nperp(k) + Nperp_temp(k-1);
end
go_to = 1;
if linetype == 1
    for q = 1:numel(Npar)
        if Npar_temp(q) - curr_par >= 0
           go_to = mod(q, numel(Npar)) + 1;
           break;
        end
    end   
    uistate.par_count = Npar_temp(go_to) - Npar(go_to);
else
    for q = 1:numel(Nperp)
        if Nperp_temp(q) - curr_perp >= 0
           go_to = mod(q, numel(Nperp)) + 1;
           break;
        end
    end     
    uistate.perp_count = Nperp_temp(go_to)- Nperp(go_to);
end    

guidata(gcf, uistate);
see_status;
nextlines_Callback([],[],[]);
