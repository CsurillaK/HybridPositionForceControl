function varargout = manipulate(varargin)
% MANIPULATE Interactive function call
%   MANIPULATE(@(ARGS)FUNC(ARGS),{LABEL,ARG_MIN,ARG_MAX,[DEFAULT]}...)
%   calls the function func(ARGS) and allows the user to control the
%   values of the arguments via sliders. If DEFAULT is not set, the value
%   is initially set to ARG_MIN.
%
%   MANIPULATE expects one cell input per argument. All arguments must be
%   scalars. Cells can also be of the form {LABEL,VALUES,[DEFAULT]} where
%   VALUES is a 1D array containing allowed values of the argument.
%
%   H = MANIPULATE(...) returns the the slider handles.
%
%   MANIPULATE(...,'UpdateMode',MODE) allows the user to set the frequency
%   with which the function is called.
%     'Low'    Refresh only when slider is released (after drag) or
%              clicked, or when edit field is altered.
%     'High'   Also refresh continuously as slider is dragged. [Default]
%     'Manual' Refresh only when user presses button.
%
%   MANIPULATE(...,'SliderStep',[SMALL BIG]) allows the user to set the
%   step size of incremental slider increases and decreases. See UICONTROL
%   for details.
% 
%   MANIPULATE(fig,...) adds the sliders to the bottom of the specified
%   figure rather to their own, new, figure.
% 
% Examples:
%   x = 1:.001:10;
%   gca, L = plot(1,1,1,1);
%   myfunc = @(i,f,theta)set(L(i),'XData',x,'YData',sin(10*x)+sin(f*x+theta));
%   h=manipulate(@(f,theta)myfunc(1,f,theta),{'frequency1',10,20},{'phase1',0,2*pi});
%   manipulate(h,@(f,theta)myfunc(2,f,theta),{'frequency2',10,20},{'phase2',0,2*pi})
%
%   Plots the interference of two sine waves and allows the user to
%   manipulate the frequency and phase offset of the second wave. Then does
%   the same again, adding the slider controls to the existing slider
%   figure.
%
%   x = linspace(-10,10,1e4);
%   fig = figure('Visible','off');
%   ax = [subplot(2,1,1),subplot(2,1,2)];
%   f1 = @(u,s) plot(ax(1),x,exp(-1/2*((x-u)/s).^2)/sqrt(2*pi)/s,'r');
%   f2 = @(u,s) title(ax(1),sprintf('N(%.2f,%.2f)',u,s^2));
%   f3 = @(u,s) plot(ax(2),x,erf((x-u)/s/sqrt(2))/2+1/2,'r');
%   myfunc = @(u,s) {f1(u,s),f2(u,s),f3(u,s)};
%   manipulate(fig,myfunc,{'Mean',-5,5,0},{'Standard Deviation',.01,5,1})
%   linkaxes(ax,'x'), set(ax,'NextPlot','replacechildren')
%   movegui(fig,'onscreen')
%   set(fig,'Visible','on')
%
%   Plots the normal distribution and its cumuliative distribution on
%   separate subplots and allows the user to manipulate the mean and
%   standard deviation. The mean is initially set to 0 and the standard
%   deviation to 1. The slider controls appear in the same figure as the
%   subplots.
%
% Created by:
%   Robert Perrotta

% Possible revisions:
%   Don't update discreet sliders unless value changes.
%   Improve figure name for multiple functions.
%   Make slider arrows step through discreet inputs.


if isa(varargin{1},'function_handle')
    func = varargin{1};
    varargin = varargin(2:end);
    addToExistingControl = false;
elseif ishghandle(varargin{1}) && ...
        strcmp(get(varargin{1},'Type'),'figure') && ...
        isa(varargin{2},'function_handle')
    g = varargin{1};
    func = varargin{2};
    varargin = varargin(3:end);
    addToExistingControl = true;
else
    
end

defaults = struct('updatemode','high','sliderstep',[0.01,0.1]);
[properties,varargin] = getproperties(defaults,varargin);

numargs = numel(varargin);

% Create new figure
border = 10;
scrn = get(0,'ScreenSize');
w = scrn(3)*0.5;
h = 100; % will be reset later
f = figure('Name',func2str(func),'Menu','none',...
    'Position',[(scrn(3)-w)/2,60,w,h],'Visible','off');
s = uipanel(f);

% Add sliders
slide = zeros(1,numargs);
u     = zeros(1,numargs);
value = zeros(1,numargs);
array = cell(1,numargs);
% [~,maxi] = max(cellfun(@(c)length(c{1}),varargin));
for i=1:numargs
    thisarg = varargin{i};
    if numel(thisarg{2}) > 1 % vector syntax
        temparg = cell(4,1);
        temparg(1) = thisarg(1);
        temparg{2} = min(thisarg{2});
        temparg{3} = max(thisarg{2});
        if numel(thisarg) < 3 % no default is set
            temparg(4) = temparg(2);
        else
            temparg(4) = thisarg(3);
        end
        array(i) = thisarg(2);
        thisarg = temparg;
    elseif numel(thisarg) < 4 % no default is set
        thisarg(4) = thisarg(2);
    end
    u(i)=uicontrol('Parent',s,'Style','edit','String',thisarg{1},...
        'Enable','inactive','Position',[0,0,1e3,1e3]);
    value(i) = uicontrol('Parent',s,'Style','edit',...
        'String',num2str(thisarg{4}),'Position',[0,0,1e3,1e3]);
    slide(i) = uicontrol('Parent',s,'Style','slider',...
        'Min',thisarg{2},'Max',thisarg{3},'Value',thisarg{4},...
        'SliderStep',properties.sliderstep);
end

extu = [0,0,0,0];
extv = [0,0,0,0];
for i=1:numargs
    extu = max(extu,get(u(i),'Extent'));
    extv = max(extv,get(value(i),'Extent'));
end
extu(3) = min(max(extu(3)+border,60),w/3);
extv(3) = min(max(extu(3)+border,60),w/3);
extu(4) = max(extu(4),extv(4));
extv(4) = extu(4);

h = (extu(4)+border)*(numargs)+border;
set(f,'Position',get(f,'Position').*[1,1,1,0]+[0,0,0,h]);

for i=1:numargs
    set(u(i),'Position',[border,h-(border+extu(4))*i,extu(3),extu(4)])
    set(slide(i),'Position',[border*2+extu(3),h-(border+extv(4))*i,w-border*4-extu(3)-extv(3),extu(4)])
    set(value(i),'Position',[w-border-extv(3),h-(border+extv(4))*i,extv(3),extv(4)])
end

set([u,slide,value],'Units','normalized')

for i=1:numargs
    if strcmp(properties.updatemode,'low')
        set(slide(i),'Interruptible','off','Callback',{@slidercall,slide,value,func,array});
        addlistener(slide(i),'Value','PreSet',@(~,~)softslidercall(slide(i),[],slide,value,array));
    elseif strcmp(properties.updatemode,'high')
        addlistener(slide(i),'Value','PreSet',@(~,~)slidercall([],[],slide,value,func,array));
    else % manual
        addlistener(slide(i),'Value','PreSet',@(~,~)softslidercall(slide(i),[],slide,value,array));
    end
    set(value(i),'Interruptible','off','Callback',{@editcall,slide,value,func,strcmp(properties.updatemode,'manual'),array});
end


if strcmp(properties.updatemode,'manual')
    u=uicontrol('Parent',s,'Style','pushbutton','String','Update Plot',...
        'Callback',{@slidercall,slide,value,func,array,ax},...
        'Position',[0,0,1e3,1e3]);
    extu = min(max(get(u,'Extent')+border,60),200);
    set(u,'Position',[w,border,extu(3),h-2*border]);
    set(s,'Position',get(s,'Position')+[-(extu(3)+border)/2,0,extu(3)+border,0])
end

% Add new control uipanel to existing figure
if addToExistingControl
    gunits = get(g,'Units');
    set(s,'Units','pixels')
    spos = get(s,'Position');
    addtl = spos(4); % must be in pixels
    children = get(g,'Children');
    set(children,'Units','pixels')
    arrayfun(@(c)addheight(c,addtl),children)
    set(g,'Position',get(g,'Position')+[0,0,0,addtl])
    set(children,'Units','normalized')
    set(s,'Parent',g,'Units','normalized')
    set(s,'Position',get(s,'Position').^[1,1,0,1])
    set(g,'Units',gunits)
    delete(f)
    f = g;
else
    set(f,'Visible','on')
end

% Initialize plot (unless UpdateMode is manual)
vars = get(slide,'Value');
if iscell(vars)
    func(vars{:});
else
    func(vars);
end

% If no output requested, don't output anything
if nargout==0
    varargout = {};
else
    varargout = {f};
end

end

function addheight(c,addtl)
%cunits = get(c,'Units');
%set(c,'Units','pixels')
set(c,'Position',get(c,'Position')+[0,addtl,0,0])
%set(c,'Units',cunits)
end

function slidercall(~,~,slide,value,func,array)

fixslider(slide,array)
vars = get(slide,'Value');
if iscell(vars)
    arrayfun(@(h,v)set(h,'String',num2str(v)),value,[vars{:}])
    func(vars{:});
else
    set(value,'String',num2str(vars))
    func(vars);
end

end

function softslidercall(caller,~,slide,value,array)

fixslider(slide,array)
vars = get(caller,'Value');
index = caller==slide;
set(value(index),'String',num2str(vars))

end

function editcall(caller,~,slide,value,func,ismanual,array)

fixedit(value,array)
index = caller==value;
val = eval(get(caller,'String'));
smin = get(slide(index),'Min');
smax = get(slide(index),'Max');
set(slide(index),'Value',min(max(val,smin),smax))
if ismanual
    softslidercall(slide(index),[],slide,value,array)
else
    slidercall([],[],slide,value,func,array)
end

end

function fixslider(slide,arrays)

for ii = 1:length(slide)
    thisarray = arrays{ii};
    if ~isempty(thisarray)
        val = get(slide(ii),'Value');
        [~,jj] = min(abs(val-thisarray));
        set(slide(ii),'Value',thisarray(jj))
    end
end

end

function fixedit(value,arrays)

for ii = 1:length(value)
    thisarray = arrays{ii};
    if ~isempty(thisarray)
        val = eval(get(value(ii),'String'));
        [~,jj] = min(abs(val-thisarray));
        set(value(ii),'String',num2str(thisarray(jj)))
        drawnow
    end
end

end

function [properties,argsin] = getproperties(defaults,argsin)

% Look for parameter inputs following variables in cells
index = find(cellfun(@(c)~iscell(c),argsin),1);

largsin = argsin;
largsin(index:end) = cellfun(@(c)lower(c),argsin(index:end),'UniformOutput',false);

fnd = fieldnames(defaults);
fna = largsin(index:2:end-1);

properties = defaults;

thisstack = dbstack;
caller = thisstack(2).name;

unrecognised = cellfun(@(c)~any(strcmp(c,fnd)),fna);
if any(unrecognised)
    error('manipulate:badproperty',...
        'The name ''%s'' is not an accessible property of the ''%s'' function.',...
        argsin{index+find(unrecognised,1)-1},caller)
end

overwritewith = struct(largsin{index:end});

replaceme = cellfun(@(c)find(strcmp(c,fnd)),fna);
for i=1:length(replaceme)
    j=replaceme(i);
    properties.(fnd{j}) = overwritewith.(fna{i});
end

if ~isempty(index)
    argsin = argsin(1:index-1);
end

end






