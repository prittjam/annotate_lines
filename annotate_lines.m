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

% Last Modified by GUIDE v2.5 06-Sep-2017 16:12:48

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
[start_par_count, start_perp_count] = find_unlabeled_lines(uistate);

uistate.par_count = start_par_count; % = 1
uistate.perp_count = start_perp_count; % = 1 
reset_radiobuttons(uistate); % my changes

update_lines(uistate);

guidata(gcf,uistate);

% --- Executes on button press in nextimage.
function nextimage_Callback(hObject, eventdata, handles)
% hObject    handle to nextimage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
uistate = guidata(gcf);

N = numel(uistate.img_urls);
uistate.cur_url_id = uistate.cur_url_id+1;
if mod(uistate.cur_url_id,N) == 0 || uistate.cur_url_id > N % or was added
    uistate.cur_url_id = 1;
end

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

% --- Executes on selection change in linetype.
function linetype_Callback(hObject, eventdata, handles)
% hObject    handle to linetype (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns linetype contents as cell array
%        contents{get(hObject,'Value')} returns selected item from linetype
uistate = guidata(gcf);
%uistate.linetype = eventdata.Source.Value;

update_lines(uistate);

guidata(gcf,uistate);

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

uistate = next_reset_radiobuttons(uistate); % my changes
reset_radiobuttons(uistate);

update_lines(uistate);

guidata(gcf,uistate); 

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

        reset_radiobuttons(uistate); % my changes
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
draw_annotation(uistate);

disp('Number of paralel line');
disp(uistate.par_count);
disp('Number of perpendicular line');
disp(uistate.perp_count);

switch uistate.linetype.Value
  case 1
    draw_line_pair(gca,uistate.contour_list, ...
                   uistate.par_cspond,uistate.par_count, [0 0 0.8]);
  case 2
    draw_line_pair(gca,uistate.contour_list, ...
                   uistate.perp_cspond,uistate.perp_count,[1 165/255 0]);
end    


function [] = draw_line_pair(ax,contour_list,cspond,idx,color)
hold on;
%plot(contour_list(cspond(idx).cspond(1)).C(1,:),...
%     contour_list(cspond(idx).cspond(1)).C(2,:),...
%     'Linewidth',3,'Color','w');
LINE.draw(ax, contour_list(cspond(idx).cspond(1)).l, ...
          'LineWidth',3,'Color',color);
%plot(contour_list(cspond(idx).cspond(2)).C(1,:),...
%     contour_list(cspond(idx).cspond(2)).C(2,:),...
%     'Linewidth',3,'Color','w');
LINE.draw(ax, contour_list(cspond(idx).cspond(2)).l, ...
          'LineWidth',3,'Color',color);
hold off;


function uistate = next_reset_radiobuttons(uistate)
 if uistate.radiobutton_good.Value == 1
     result = 1;
 elseif uistate.radiobutton_bad.Value == 1
     result = 2;
 else
     result = 0;
 end
 
 if uistate.linetype.Value == 1
     uistate.par_cspond(uistate.par_count - 1).label = result;
 elseif uistate.linetype.Value == 2
     uistate.perp_cspond(uistate.perp_count - 1).label = result;
 end    
 
 uistate.cid_cache.put('annotations','parallel_lines', uistate.par_cspond);
 uistate.cid_cache.put('annotations','perpendicular_lines', uistate.perp_cspond);
 
 
 
function reset_radiobuttons(uistate)
if uistate.linetype.Value == 1
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

function draw_annotation(uistate)
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
