function varargout = NBackGUI(varargin)
% NBACKGUI M-file for NBackGUI.fig
%      NBACKGUI, by itself, creates a new NBACKGUI or raises the existing
%      singleton*.
%
%      H = NBACKGUI returns the handle to a new NBACKGUI or the handle to
%      the existing singleton*.
%
%      NBACKGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in NBACKGUI.M with the given input arguments.
%
%      NBACKGUI('Property','Value',...) creates a new NBACKGUI or raises
%      the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before NBackGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to NBackGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help NBackGUI

% Last Modified by GUIDE v2.5 09-Sep-2010 20:52:27

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @NBackGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @NBackGUI_OutputFcn, ...
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


% --- Executes just before NBackGUI is made visible.
function NBackGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to NBackGUI (see VARARGIN)

% Choose default command line output for NBackGUI
handles.output = hObject;

clc;
diary 'Runlog.txt'

disp([datestr(now) ': ********** 3D Vehicle N-Back GUI starting **********']);

% Experiment settings initialization
defConfigFilename = 'Default.config.mat';
if(exist(defConfigFilename,'file'))
    guidata(hObject,handles);
    doLoadConfig(hObject,handles,defConfigFilename);
    handles = guidata(hObject);
else
    set(handles.editID,'String','TEST');
    set(handles.editID,'Value',0);
    set(handles.editN,'String','2');
    set(handles.editN,'Value',2);
    set(handles.editProb,'String','0.5');
    set(handles.editProb,'Value',0.5);
    set(handles.editResponseTime,'String','2');
    set(handles.editResponseTime,'Value',2);
    set(handles.editBlankTime,'String','0.5');
    set(handles.editBlankTime,'Value',0.5);

    % Physio measures initialization
    set(handles.editFreq,'String','[0.01 3;4 7;8 12;13 30;31 42]');
    set(handles.editChan,'String','[4 5 6 7 8 9 12 13 14 15]');
    set(handles.textTrimLength,'String',sprintf('%.0f',get(handles.sliderTrimLength,'Value')));
    set(handles.textWinOverlap,'String',sprintf('%.2f',get(handles.sliderWinOverlap,'Value')));
    set(handles.textWinLength,'String',sprintf('%.0f',get(handles.sliderWinLength,'Value')));

    % Performance buckets init
    set(handles.editUnderload,'String','0.95');
    set(handles.editUnderload,'Value',.95);
    set(handles.editOverload,'String','0.70');
    set(handles.editOverload,'Value',.70);

    set(handles.editServer,'String','localhost');
    set(handles.editPort,'String','4500');
    set(handles.editPort,'Value',4500);

    set(handles.checkboxTest,'Value',1);

    set(handles.editWorkloadThreshold,'String','5');
    set(handles.editWorkloadThreshold,'Value',5);

    set(handles.editWorkloadDecay,'String','0.5');
    set(handles.editWorkloadDecay,'Value',0.5);

end

set(handles.editID,'String','TEST');
set(handles.editTrialNum,'String','N/A');
set(handles.editNumCorrect,'String','N/A');
set(handles.editNumIncorrect,'String','N/A');
set(handles.editDuration,'String','N/A');
set(handles.editPerf,'String','N/A');
set(handles.editWorkloadCurrent,'String','0');
set(handles.editWorkloadCurrent,'Value',0);
set(handles.txtServerStatus,'String','Disconnected from server.');
set(handles.btnConnection,'String','Connect to server');

handles.netHandle = tcpip(get(handles.editServer,'String'), ...
    get(handles.editPort,'Value'));

bufferSize = 23400;

set(handles.netHandle,'BytesAvailableFcn',{@dataRecCallback,hObject});
set(handles.netHandle,'BytesAvailableFcnMode','byte');
set(handles.netHandle,'BytesAvailableFcnCount',bufferSize);
set(handles.netHandle,'InputBufferSize',bufferSize*8);

%fopen(handles.netHandle);
%sendPacket(handles.netHandle,'CTRL',3,5,0);

handles.eegData = [];
handles.exUnderload = [];
handles.exOK = [];
handles.exOverload = [];

handles.ann = [];
handles.workloadIndex = 0;

set(handles.menuitemKillExperiment,'Checked','off');

% Update handles structure
guidata(hObject, handles);


% UIWAIT makes NBackGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = NBackGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

function editID_Callback(hObject, eventdata, handles)

function editID_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function editN_Callback(hObject, eventdata, handles)
nVal = round(str2double(get(hObject,'String')));
if(nVal < 1 || nVal > 9)
    msgbox('N must be 0 < x < 10','Error','error');
    set(hObject,'String',get(hObject,'Value'));
    return;
else
    set(hObject,'Value',nVal);
end
guidata(hObject, handles);

function editN_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function editProb_Callback(hObject, eventdata, handles)
nVal = str2double(get(hObject,'String'));
if(nVal <= 0 || nVal >= 1)
    msgbox('p(Same as N-Back) must be 0 < p < 1','Error','error');
    set(hObject,'String',get(hObject,'Value'));
    return;
else
    set(hObject,'Value',nVal);
end
guidata(hObject, handles);

function editProb_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function editResponseTime_Callback(hObject, eventdata, handles)
nVal = str2double(get(hObject,'String'));
if(nVal <= 0)
    msgbox('Response time must be > 0','Error','error');
    set(hObject,'String',2);
    return;
else
    set(hObject,'Value',nVal);
end
guidata(hObject, handles);

function editResponseTime_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function editFeedbackTime_Callback(hObject, eventdata, handles)
nVal = str2double(get(hObject,'String'));
if(nVal <= 0)
    msgbox('Feedback time must be > 0','Error','error');
    set(hObject,'String',0.5);
    return;
else
    set(hObject,'Value',nVal);
end
guidata(hObject, handles);

function editFeedbackTime_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function editBlankTime_Callback(hObject, eventdata, handles)
nVal = str2double(get(hObject,'String'));
if(nVal <= 0)
    msgbox('Time between trials must be > 0','Error','error');
    set(hObject,'String',0.5);
    return;
else
    set(hObject,'Value',nVal);
end
guidata(hObject, handles);

function editBlankTime_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function editTrialNum_Callback(hObject, eventdata, handles)

function editTrialNum_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function editNumCorrect_Callback(hObject, eventdata, handles)

function editNumCorrect_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function editNumIncorrect_Callback(hObject, eventdata, handles)

function editNumIncorrect_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function editDuration_Callback(hObject, eventdata, handles)

function editDuration_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function btnRun_Callback(hObject, eventdata, handles)
if(~isConnected(handles.netHandle))
    msg = ['EEG connection does not appear to be active. ' ...
           'The program will not be able to generate exemplars from ' ...
           'this block. To enable exemplar generation, please ' ...
           'connect to an EEG server first. Continue running this block?'];
       
    resp = questdlg(msg,'No EEG detected!','Yes','No','Connect and run','No');
    if(strcmp(resp,'Connect and run'))
        if(~doConnect(handles.netHandle))
            disp([datestr(now) ': ** Failed to connect. Run block aborted **']);
            return;
        end
    elseif(~strcmp(resp,'Yes'))
        disp([datestr(now) ': ** Run block aborted **']);
        return;
    end
    pause(0.5); % Allow time for network response
end

set(handles.editID,'Enable','off');
set(handles.editN,'Enable','off');
set(handles.editProb,'Enable','off');
set(handles.editResponseTime,'Enable','off');
set(handles.editBlankTime,'Enable','off');

drawnow;

if(isConnected(handles.netHandle))
    handles.eegData.output = [];
%   sendPacket(handles.netHandle,'CTRL',3,3,0);
%   This is now called when the user begins trial block
end 

if(get(handles.checkboxVerbose,'Value'))
    disp([datestr(now) ': Calling GLNBack...']);
end

set(handles.menuitemKillExperiment,'Checked','off');
%guidata(hObject,handles);

results = GLNBack(hObject);

if(get(handles.checkboxVerbose,'Value'))
    disp([datestr(now) ': GLNBack finishes.']);
end

if(isConnected(handles.netHandle))
    sendPacket(handles.netHandle,'CTRL',3,4,0);
    dataRecCallback(handles.netHandle,[],gcbo); % Make sure we eat up all data
end

if(~isdir('data'))
    mkdir('data');
end

i = 1;
fName = ['data\' '3DNBack-Sub' get(handles.editID,'String') '-' num2str(i,'%03d') '.xls'];

while(exist(fName,'file'))
    i = i + 1;
    fName = ['data\' '3DNBack-Sub' get(handles.editID,'String') '-' num2str(i,'%03d') '.xls'];
end

if(get(handles.checkboxVerbose,'Value'))
    disp([datestr(now) ': Writing performance data file "' fName '"']);
end

headerRow = {'Subject ID' 'N' 'Trial #' 'Vehicle' 'Heading' 'Response Trial?' 'Responded?' 'Correct?' 'Response Time'}; 
results = vertcat(headerRow,results);
xlswrite(fName,results);

handles = guidata(hObject);

if(~get(handles.checkboxAdaptive,'Value'))
    if(get(handles.checkboxVerbose,'Value'))
        disp([datestr(now) ': Classifying block performance']);
    end
    
    blockExemplars = [];
    try 
        blockExemplars = genExemplars(hObject,handles.eegData.output);
    catch e
        disp(['  * Error generating exemplars: ' e.message]);
        disp('    (Was the EEG server set up properly?)');
    end
    
    if(~isempty(blockExemplars))
        % Auto bucket placement
        if(~get(handles.checkboxManual,'Value')) 
            blockPerf = get(handles.editPerf,'Value');
            if(blockPerf > get(handles.editUnderload,'Value'))
                if(get(handles.checkboxVerbose,'Value'))
                    disp('  * This block belongs in underload');
                end
                handles.exUnderload = vertcat(handles.exUnderload,blockExemplars); 
            elseif(blockPerf > get(handles.editOverload,'Value'))
                if(get(handles.checkboxVerbose,'Value'))
                    disp('  * This block belongs in OK');
                end
                handles.exOK = vertcat(handles.exOK,blockExemplars);
            else
                if(get(handles.checkboxVerbose,'Value'))
                    disp('  * This block belongs in overload');
                end
                handles.exOverload = vertcat(handles.exOverload,blockExemplars);
            end
        else
            bucketSel = questdlg('Please manually choose a workload bucket', ...
                'Manual bucket assignment','Underload','OK','Overload','OK');
            switch bucketSel,
                case 'Underload'
                    disp('  * Manually assigned this block to Underload');
                    handles.exUnderload = vertcat(handles.exUnderload,blockExemplars);
                case 'OK'
                    disp('  * Manually assigned this block to OK');
                    handles.exOK = vertcat(handles.exOK,blockExemplars);
                case 'Overload'
                    disp('  * Manually assigned this block to Overload');
                    handles.exOverload = vertcat(handles.exOverload,blockExemplars);
            end
        end
    end
else
    disp('  * Exemplars were not generated because of adaptive mode');
end

set(handles.editID,'Enable','on');
set(handles.editN,'Enable','on');
set(handles.editProb,'Enable','on');
set(handles.editResponseTime,'Enable','on');
set(handles.editBlankTime,'Enable','on');

guidata(hObject,handles);

UpdateBucketStatus(hObject);
if(get(handles.checkboxVerbose,'Value'))
    disp([datestr(now) ': Clean exit from block run']);
end
figure(gcbf);

function btnDebug_Callback(hObject, eventdata, handles)
    if(get(handles.checkboxVerbose,'Value'))
        disp([datestr(now) ': Entering debug mode. Type "return" to exit.']);
    end
    keyboard;
    resp = questdlg('Commit changes to handles structure? This may be unsafe if EEG data is currently streaming.','Commit changes','Yes');
    if(strcmp(resp,'Yes'))
        guidata(hObject,handles);
        disp([datestr(now) ': Handles saved.']);
        %disp(handles);
    end
    figure(gcbf);
    
function dataRecCallback(obj,event,hObject)
    handles = guidata(hObject);
    eegData = handles.eegData;
    
    if(get(obj,'BytesAvailable') == 0)
        return;
    end
    
    while(get(obj,'BytesAvailable') >= 12)
        header = uint8(fread(obj,12));

        id = char(header(1:4));
        code = swapbytes(typecast(header(5:6),'uint16'));
        req = swapbytes(typecast(header(7:8),'uint16'));
        bodysize = swapbytes(typecast(header(9:12),'uint32'));

%         fprintf('\n*** HEADER RECEIVED ***\n')
%         fprintf('Type:      %s\n', event.Type);
%         fprintf('Timestamp: %d/%d/%d, %d:%d:%d\n', event.Data.AbsTime);
%         disp(' ');
%         fprintf('ID:        %s\n', id);
%         fprintf('Code:      %d\n', code);
%         fprintf('Request:   %d\n', req);
%         fprintf('Size:      %d\n\n', bodysize);
%         fprintf('Raw:       ');
%         disp(header');
        if(strcmp(id','CTRL') || strcmp(id','DATA')) % Otherwise, this is a corrupt/misaligned packet
            if(bodysize > 0)
                %disp(['Attempting to read ' num2str(bodysize) ' bytes (' id' ')']);
                %fprintf('Packet size = %d\n',double(bodysize)+12);
                %fprintf('Data:      ');
                dataIn = fread(obj,double(bodysize),'uint8');
                data = uint8(dataIn);
                %disp(data');
            end

            if(strcmp(id','DATA') && code == 1) % Basic Info
                %disp('** INFO Data Block **');
                eegData.basicInfo.infoSize = typecast(data(1:4),'int32');
                eegData.basicInfo.numChans = typecast(data(5:8),'int32');
                eegData.basicInfo.numEventChans = typecast(data(9:12),'int32');
                eegData.basicInfo.numSamples = typecast(data(13:16),'int32');
                eegData.basicInfo.sRate = typecast(data(17:20),'int32');
                eegData.basicInfo.dataSize = typecast(data(21:24),'int32');
                eegData.basicInfo.resolution = typecast(data(25:28),'single');
                %fprintf('BasicInfo Data:\n');
                %disp(eegData.basicInfo);

                eegData.output = [];
            elseif(strcmp(id','DATA') && code == 2) % EEG Data
                %disp('** EEG Data Block **');
                %disp(eegData.basicInfo);
                if(eegData.basicInfo.dataSize == 2)
                    eegData.output = vertcat(eegData.output,zeros(eegData.basicInfo.numSamples,eegData.basicInfo.numChans + eegData.basicInfo.numEventChans,'int16'));
                    data = typecast(data,'int16');
                    for i=1:eegData.basicInfo.numSamples
                        eegData.output(end-(eegData.basicInfo.numSamples-i),:) = data((i-1)*(eegData.basicInfo.numChans + eegData.basicInfo.numEventChans)+1 : ...
                            i*(eegData.basicInfo.numChans + eegData.basicInfo.numEventChans))';
                    end
                elseif(eegData.basicInfo.dataSize == 4)
                    eegData.output = vertcat(eegData.output,zeros(eegData.basicInfo.numSamples,eegData.basicInfo.numChans + eegData.basicInfo.numEventChans,'int32'));
                    data = typecast(data,'int32');
                    for i=1:eegData.basicInfo.numSamples
                        eegData.output(end-(eegData.basicInfo.numSamples-i),:) = data((i-1)*(eegData.basicInfo.numChans + eegData.basicInfo.numEventChans)+1 : ...
                            i*(eegData.basicInfo.numChans + eegData.basicInfo.numEventChans))';
                    end
                end
                
                windowSize = round(eegData.basicInfo.sRate * ...
                    str2double(get(handles.textWinLength,'String')));
                
                if(get(handles.checkboxAdaptive,'Value'))
                    if(size(eegData.output,1) >= windowSize)
                        ex = reduceFrame(hObject,eegData.output(end-windowSize+1:end,:));
%                        disp(['** Adaptive mode **']);
%                        disp(['  Sending ' num2str(ex)]);
                        output = classify(hObject,ex);
                        [z, classOut] = max(output);
                        if(get(handles.checkboxVerbose,'Value'))
                            if(classOut == 1) 
                                classStr = 'Underload';
                            elseif(classOut == 2) 
                                classStr = 'OK';
                            else
                                classStr = 'Overload';
                            end
                            
                            disp([datestr(now) ': *** Adaptive mode: classify() returned ' num2str(output') ' (' classStr ') ***']);
                            %disp(['*** Adaptive mode: Classified as ' classStr ' ***']);
                        end
                        workloadIndex = feedbackDriver(hObject,output);
                        handles.workloadIndex = workloadIndex;
                        eegData.output = [];
                    end
                end
            end
        else
            if(get(handles.checkboxVerbose,'Value'))
                disp([datestr(now) ': *** Corrupted EEG signal received. Clearing output and resetting ***']);
            end
            eegData.output = [];
        end
    end
    handles.eegData = eegData;
    guidata(hObject,handles);
    
function btnConnection_Callback(hObject, eventdata, handles)
    if(strcmp(get(handles.netHandle,'Status'),'open'))
        sendPacket(handles.netHandle,'CTRL',1,2,0); % "Closing Up Conn"
        fclose(handles.netHandle);
    else
        doConnect(handles.netHandle);
    end
    updateServerStatus(hObject,handles);

function bSuccess = doConnect(netHandle)
    bSuccess = false;
    try
        fprintf('%s Attempting to connect to %s:%d...', datestr(now), ...
            get(netHandle,'RemoteHost'), ...
            get(netHandle,'RemotePort'));
        fopen(netHandle);
        sendPacket(netHandle,'CTRL',3,5,0);
        disp('Success!');
        bSuccess = true;
    catch err
        disp(['Error: ' err.message]);
    end

function figure1_CloseRequestFcn(hObject, eventdata, handles)
    if(strcmp(get(handles.netHandle,'Status'),'open'))
        sendPacket(handles.netHandle,'CTRL',1,2,0);
    end
    
    fclose(handles.netHandle);
    
    disp([datestr(now) ': ********** 3D Vehicle N-Back GUI closing **********']);
    diary off;
    
    delete(hObject);

function editServer_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function editPort_Callback(hObject, eventdata, handles)
nVal = str2double(get(hObject,'String'));
if(nVal <= 0)
    msgbox('Port # must be > 0','Error','error');
    set(hObject,'String',4500);
    return;
else
    set(hObject,'Value',nVal);
end
if(strcmp(get(handles.netHandle,'Status'),'open'))
    sendPacket(handles.netHandle,'CTRL',1,2,0); % "Closing Up Conn"
    fclose(handles.netHandle);
end
set(handles.netHandle,'RemotePort',get(handles.editPort,'Value'));
guidata(hObject, handles);
updateServerStatus(hObject,handles);

function editPort_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editServer_Callback(hObject, eventdata, handles)
if(strcmp(get(handles.netHandle,'Status'),'open'))
    sendPacket(handles.netHandle,'CTRL',1,2,0); % "Closing Up Conn"
    fclose(handles.netHandle);
end
set(handles.netHandle,'RemoteHost',get(handles.editServer,'String'));
guidata(hObject, handles);
updateServerStatus(hObject,handles);

function updateServerStatus(hObject,handles)
if(strcmp(get(handles.netHandle,'Status'),'open'))
    set(handles.txtServerStatus,'String','Connected to server.');
    set(handles.btnConnection,'String','Disconnect');
else
    set(handles.txtServerStatus,'String','Disconnected from server.');
    set(handles.btnConnection,'String','Connect');
end
    
function doIncreaseN(hObject)
    handles = guidata(hObject);
    numBack = get(handles.editN,'Value');
    if(numBack < 10)
        set(handles.editN,'Value',numBack + 1);
        set(handles.editN,'String',num2str(numBack + 1));
        guidata(hObject,handles);
        drawnow;
    end
    
function doDecreaseN(hObject)
    handles = guidata(hObject);
    numBack = get(handles.editN,'Value');
    if(numBack > 1)
        set(handles.editN,'Value',numBack - 1);
        set(handles.editN,'String',num2str(numBack - 1));
        guidata(hObject,handles);
        drawnow;
    end
    
function editPerf_Callback(hObject, eventdata, handles)
% hObject    handle to editPerf (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editPerf as text
%        str2double(get(hObject,'String')) returns contents of editPerf as a double


% --- Executes during object creation, after setting all properties.
function editPerf_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editPerf (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function editFreq_Callback(hObject, eventdata, handles)
% hObject    handle to editFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editFreq as text
%        str2double(get(hObject,'String')) returns contents of editFreq as a double


% --- Executes during object creation, after setting all properties.
function editFreq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editChan_Callback(hObject, eventdata, handles)
% hObject    handle to editChan (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editChan as text
%        str2double(get(hObject,'String')) returns contents of editChan as a double


% --- Executes during object creation, after setting all properties.
function editChan_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editChan (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function sliderTrimLength_Callback(hObject, eventdata, handles)
pos = get(hObject,'Value');
set(handles.textTrimLength,'String',sprintf('%.0f',pos));
guidata(hObject,handles);
% hObject    handle to sliderTrimLength (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function sliderTrimLength_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderTrimLength (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function sliderWinOverlap_Callback(hObject, eventdata, handles)
pos = get(hObject,'Value');
set(handles.textWinOverlap,'String',sprintf('%.2f',pos));
guidata(hObject,handles);
% hObject    handle to sliderWinOverlap (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function sliderWinOverlap_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderWinOverlap (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

% --- Executes on slider movement.
function sliderWinLength_Callback(hObject, eventdata, handles)
pos = get(hObject,'Value');
set(handles.textWinLength,'String',sprintf('%.0f',pos));
guidata(hObject,handles);
% hObject    handle to sliderWinLength (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function sliderWinLength_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderWinLength (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function exemplars = genExemplars(hObject,rawData)
    handles = guidata(hObject);
    sRate = double(handles.eegData.basicInfo.sRate);
    %sRate = 500;
    trimLength = str2double(get(handles.textTrimLength,'String'));
    winLength = str2double(get(handles.textWinLength,'String'));
    winOverlap = str2double(get(handles.textWinOverlap,'String'));
    
    framesInRange = trimLength * sRate;
    windowLengthFrames = winLength * sRate;

    chans = eval(get(handles.editChan,'String'));
    numChans = length(chans);
    
    freqs = eval(get(handles.editFreq,'String'));
    numFreqs = length(freqs);
    
    numFeatures = numChans * numFreqs;
    
    if(winOverlap > 0)
        numExemplars = (framesInRange / windowLengthFrames / winOverlap) - 1;
    else
%        numExemplars = (framesInRange / windowLengthFrames) - 1;
        numExemplars = (framesInRange / windowLengthFrames);
    end
    
    numExemplars = floor(numExemplars);
    
    if(get(handles.checkboxVerbose,'Value'))
        disp(['  Trim Length    : ' num2str(trimLength) ' seconds']);
        disp(['  Window Length  : ' num2str(winLength) ' seconds']);
        disp(['  Window Overlap : ' num2str(winOverlap*100) '%']);
        disp(['  # of Exemplars : ' num2str(numExemplars)]);
        disp(['  # of Features  : ' num2str(numFeatures)]);
    end
    
    mData = zeros(numChans,framesInRange);
    %data = rawData(chans,:); EEGLAB format
    data = rawData(:,chans)';
    if length(data) < framesInRange
        errMsg = 'Raw data has insufficient length.';
        uiwait(msgbox(errMsg,'Error','error'));
        return;
    end
    
    center = length(data)/2;
    data = data(:,center-framesInRange/2+1:center+framesInRange/2);
    mData = data;
    
    nlFreqs = 2*freqs(:,:)/sRate;

    mBands = zeros(numChans,numFreqs,framesInRange);
    
    if(get(handles.checkboxVerbose,'Value'))
        disp('  * Splitting frequency ranges');
    end
    
    % For each frequency band in freqs table
    for i=1:numFreqs
        % Create a 8th order elliptical filter, stopband atten. 20db,
        % passband ripple 1db (Russell & Wilson, 2001, p. 6).
        wBarMsg = sprintf('Filtering %dhz -> %dhz',freqs(i,1),freqs(i,2));
        [z,p,k] = ellip(4,1,20,[nlFreqs(i,1),nlFreqs(i,2)]);
        [sos,g] = zp2sos(z,p,k);
        Hd = dfilt.df2tsos(sos,g);
        
        % For each channel in *Data
        wBar = waitbar(0,wBarMsg); 
        for j=1:numChans
            % Filter and assign into separate bandpass filtered channels
            % for both low and high workload data.
            waitbar(j/numChans,wBar);
            mBands(j,i,:) = filter(Hd,mData(j,:));
        end
        close(wBar);
    end
    
    clear mData;
    
    % Preallocate our exemplar sets for speed
    mExemplars = zeros(numExemplars,numFeatures);
    
    % Window function?
    wFunc = hamming(windowLengthFrames);
    
    %useHamming = get(handles.cbHamming,'Value');
    useHamming = true;
    
    if(get(handles.checkboxVerbose,'Value'))
        disp('  * Creating overlapped exemplar sets and collapsing to RMS power');
    end
    
    wBar = waitbar(0,'Creating overlapped exemplar sets');
    for i=1:numExemplars
        frameWindow = [1 + ((i-1) * windowLengthFrames * (1-winOverlap)), ...
            windowLengthFrames + ((i-1) * windowLengthFrames * (1-winOverlap))];
        % fprintf('  %d: %d -> %d\n', i, frameWindow(1), frameWindow(2));
        for j=1:numChans
            offset = (j-1)*numFreqs;
            for k=1:numFreqs
                if(useHamming)
                    rawWindow = squeeze(mBands(j,k,frameWindow(1):frameWindow(2)));
                    window = rawWindow .* wFunc;
                    winPower = 10 * log(sum(window.^2));
                    mExemplars(i,offset+k) = winPower;
                else
                    mExemplars(i,offset+k) = 10 * log(sum(mBands(j,k,frameWindow(1):frameWindow(2)).^2));
                end
            end
        end
        waitbar(i/numExemplars,wBar);
    end
    close(wBar);
    
    clear mBands;

    exemplars = mExemplars(:,:);
    
    % Safe to clear the low/high split exemplar matrices at this point...
    clear mExemplars;
    
    % Exemplars cannot be normalized until all conditions are known

% For test purposes ONLY!!!!
function rawData = selFiles()
    dTitle = 'Select .cnt file';
    [file, path] = uigetfile('*.cnt',dTitle);
    if(isequal(file,0) || isequal(path,0)) % User cancelled
        return;
    end
    fName = [path file];
    mCNT = loadcnt(fName,'dataformat','int32');
    rawData = mCNT.data;



function editUnderload_Callback(hObject, eventdata, handles)
% hObject    handle to editUnderload (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editUnderload as text
%        str2double(get(hObject,'String')) returns contents of editUnderload as a double
nVal = str2double(get(hObject,'String'));
overT = get(handles.editOverload,'Value');
if(nVal <= overT || nVal > 1)
    msgbox('Underload threshold must be Overload_threshold < x <= 1','Error','error');
    set(hObject,'String',num2str(get(hObject,'Value')));
    return;
else
    set(hObject,'Value',nVal);
end
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function editUnderload_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editUnderload (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editOverload_Callback(hObject, eventdata, handles)
% hObject    handle to editOverload (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editOverload as text
%        str2double(get(hObject,'String')) returns contents of editOverload as a double
nVal = str2double(get(hObject,'String'));
underT = get(handles.editUnderload,'Value');
if(nVal >= underT || nVal < 0)
    msgbox('Overload threshold must be 0 <= x < Underload_threshold','Error','error');
    set(hObject,'String',num2str(get(hObject,'Value')));
    return;
else
    set(hObject,'Value',nVal);
end
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function editOverload_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editOverload (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxUnder.
function checkboxUnder_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxUnder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxUnder


% --- Executes on button press in checkboxOK.
function checkboxOK_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxOK (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxOK


% --- Executes on button press in checkboxOver.
function checkboxOver_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxOver (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxOver


% --- Executes on button press in checkboxTest.
function checkboxTest_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxTest (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxTest

function result = isConnected(netHandle)
    if(strcmp(get(netHandle,'Status'),'open'))
        result = true;
    else
        result = false;
    end

function UpdateBucketStatus(hObject)
    handles = guidata(hObject);
    if(~isempty(handles.exUnderload))
        set(handles.checkboxUnder,'Value',1);
    else
        set(handles.checkboxUnder,'Value',0);
    end
    
    if(~isempty(handles.exOK))
        set(handles.checkboxOK,'Value',1);
    else
        set(handles.checkboxOK,'Value',0);
    end

        if(~isempty(handles.exOverload))
        set(handles.checkboxOver,'Value',1);
    else
        set(handles.checkboxOver,'Value',0);
        end

function [ex,ps] = getExemplars(hObject)
    handles = guidata(hObject);
    rawEx = vertcat(handles.exUnderload,handles.exOK,handles.exOverload)';
    if(get(handles.checkboxNormalize,'Value'))
        [ex, handles.normParams] = mapminmax(rawEx,0,1);
        ex = ex';
    else
        ex = rawEx';
        handles.normParams = [];
    end
    ps = handles.normParams;
    guidata(hObject,handles);
    
function types = getExTypes(hObject)
    handles = guidata(hObject);
    types = vertcat(repmat(1,size(handles.exUnderload,1),1),repmat(2,size(handles.exOK,1),1),repmat(3,size(handles.exOverload,1),1));

function targets = getTargets(hObject)
    handles = guidata(hObject);
    targets = vertcat(repmat([1 0 0],size(handles.exUnderload,1),1),repmat([0 1 0],size(handles.exOK,1),1),repmat([0 0 1],size(handles.exOverload,1),1));

    function btnPlotExemplars_Callback(hObject, eventdata, handles)
    exemplars = getExemplars(hObject);
    
    matExTypes = vertcat(repmat(1,size(handles.exUnderload,1),1),repmat(2,size(handles.exOK,1),1),repmat(3,size(handles.exOverload,1),1));
    
    if(~isempty(exemplars))
        plotFig = figure();
        hold on;
        
        x = 1:size(exemplars,2);
        if(~isempty(handles.exUnderload))
            plot(x,exemplars(matExTypes==1,:),'gv');
        end
        if(~isempty(handles.exOK))
            plot(x,exemplars(matExTypes==2,:),'ys');
        end
        if(~isempty(handles.exOverload))
            plot(x,exemplars(matExTypes==3,:),'r^');
        end
        uiwait(plotFig);
    else
        uiwait(msgbox('No exemplars to plot!','Error','error'));
    end

function checkboxNormalize_Callback(hObject, eventdata, handles)

function ex = reduceFrame(hObject,rawData)
    handles = guidata(hObject);
    sRate = double(handles.eegData.basicInfo.sRate);

    winLength = str2double(get(handles.textWinLength,'String'));
    
    windowLengthFrames = winLength * sRate;

    chans = eval(get(handles.editChan,'String'));
    numChans = length(chans);
    
    freqs = eval(get(handles.editFreq,'String'));
    numFreqs = length(freqs);
    
    numFeatures = numChans * numFreqs;
        
    %data = rawData(chans,:); EEGLAB format
    data = rawData(:,chans)';
    if length(data) < windowLengthFrames
        errMsg = 'Raw data has insufficient length.';
        uiwait(msgbox(errMsg,'Error','error'));
        return;
    end
    
    mData = data;
    
    nlFreqs = 2*freqs(:,:)/sRate;

    mBands = zeros(numChans,numFreqs,windowLengthFrames);
    
    % For each frequency band in freqs table
    for i=1:numFreqs
        % Create a 8th order elliptical filter, stopband atten. 20db,
        % passband ripple 1db (Russell & Wilson, 2001, p. 6).
        [z,p,k] = ellip(4,1,20,[nlFreqs(i,1),nlFreqs(i,2)]);
        [sos,g] = zp2sos(z,p,k);
        Hd = dfilt.df2tsos(sos,g);
        
        % For each channel in *Data
        for j=1:numChans
            % Filter and assign into separate bandpass filtered channels
            % for both low and high workload data.
            mBands(j,i,:) = filter(Hd,mData(j,:));
        end
    end
    
    clear mData;
    
    % Preallocate our exemplar sets for speed
    mExemplar = zeros(1,numFeatures);
    
    % Window function?
    wFunc = hamming(windowLengthFrames);
    
    %useHamming = get(handles.cbHamming,'Value');
    useHamming = true;
    
    for j=1:numChans
        offset = (j-1)*numFreqs;
        for k=1:numFreqs
            if(useHamming)
                rawWindow = squeeze(mBands(j,k,:));
                window = rawWindow .* wFunc;
                winPower = 10 * log(sum(window.^2));
                mExemplar(offset+k) = winPower;
            else
                mExemplar(offset+k) = 10 * log(sum(mBands(j,k,:).^2));
            end
        end
    end
    
    clear mBands;

    ex = mExemplar;
    
    % Safe to clear the low/high split exemplar matrices at this point...
    clear mExemplar;
    
function createNet(hObject)
    handles = guidata(hObject);
    [ex,ps] = getExemplars(hObject);
    ex = ex';
    tar = getTargets(hObject)';
    
    if(isempty(ex) || isempty(tar))
        uiwait(msgbox('Cannot create ANN without full buckets!','Error','error'));
        return;
    end
    handles.ann = newpr(ex,tar,size(ex,2));
    handles.ann.divideFcn = 'divideint';
    handles.ann.divideparam.trainRatio = .6;
    handles.ann.divideparam.valRatio = .2;
    handles.ann.divideparam.testRatio = .2;
    
    handles.ann = train(handles.ann,ex,tar);
    handles.normParams = ps;
    guidata(hObject,handles);
    
function output = classify(hObject,ex)
    handles = guidata(hObject);
    ann = handles.ann;
    if(get(handles.checkboxNormalize,'Value'))
        ex = mapminmax('apply',ex',handles.normParams);
        ex = ex';
    end
    netOut = sim(ann,ex');
    output = netOut;
    %[output,index] = max(netOut);
    
function loadTestData(hObject)
    handles = guidata(hObject);
    ex = load('exUnderload');
    handles.exUnderload = ex.ex;
    
    ex = load('exOK');
    handles.exOK = ex.ex;
    
    ex = load('exOverload');
    handles.exOverload = ex.ex;
    
    guidata(hObject,handles);
    
function checkboxAdaptive_Callback(hObject, eventdata, handles)
    if(get(hObject,'Value') && isempty(handles.ann))
        uiwait(msgbox('Adaptive mode cannot be activated until ANN is created and trained!','Error','error'));
        set(hObject,'Value',0);
    end
    
function workloadIndex = feedbackDriver(hObject,input)
    handles = guidata(hObject);
    workloadIndex = handles.workloadIndex;
    workloadThreshold = get(handles.editWorkloadThreshold,'Value');
    workloadDecay = get(handles.editWorkloadDecay,'Value');
    
    [z,inIndex] = max(input);
    if(inIndex == 1) % Underload
        workloadIndex = workloadIndex - 1;
    elseif(inIndex == 2) % OK -- gravitate towards 0 at decay rate
        if(workloadIndex < 0)
            workloadIndex = workloadIndex + workloadDecay;
        elseif(workloadIndex > 0)
            workloadIndex = workloadIndex - workloadDecay;
        end
    else % Overload
        workloadIndex = workloadIndex + 1;
    end
    
    %disp(['  Workload index is now ' num2str(workloadIndex)]);
    
    if(workloadIndex <= -workloadThreshold)
        if(get(handles.checkboxVerbose,'Value'))
            disp([datestr(now) ': *** (FEEDBACK DRIVER) Increasing N! ***']);
        end
        doIncreaseN(hObject);
        workloadIndex = 0;
    elseif(workloadIndex >= workloadThreshold)
        if(get(handles.checkboxVerbose,'Value'))
            disp([datestr(now) ': *** (FEEDBACK DRIVER) Decreasing N! ***']);
        end
        doDecreaseN(hObject);
        workloadIndex = 0;
    end
    
    set(handles.editWorkloadCurrent,'Value',workloadIndex);
    set(handles.editWorkloadCurrent,'String',num2str(workloadIndex));
    drawnow;
    
    %guidata(hObject,handles);
            


function btnCreateNet_Callback(hObject, eventdata, handles)
    createNet(hObject);

function btnShowTrain_Callback(hObject, eventdata, handles)
    if(~isempty(handles.ann))
        nntraintool;
    else
        uiwait(msgbox('ANN has not been created!','Error','error'));
    end
    
function btnClear_Callback(hObject, eventdata, handles)
    resp = questdlg(['Are you sure you want to clear exemplars? ' ...
        'This will clear all exemplar buckets and all training exemplar ' ...
        'data will be lost if they have not been saved'],'Confirm','Yes','No','Save and Continue','No');
    if(strcmp(resp,'Save and Continue'))
        if(~doSave(handles))
            return
        end
    elseif(~strcmp(resp,'Yes'))
        return
    end
    
    handles.exUnderload = [];
    handles.exOK = [];
    handles.exOverload = [];
    handles.normParams = [];
    handles.ann = [];
    
    disp([datestr(now) ': *** All training data have been cleared ***']);
    guidata(hObject,handles);
    UpdateBucketStatus(hObject);
    


function menuFile_Callback(hObject, eventdata, handles)


function menuitemSave_Callback(hObject, eventdata, handles)
    doSave(handles);
    
function bSuccess = doSave(handles)
    bSuccess = false;
    
    subID = get(handles.editID,'String');
    i = 1;
    
    try
        if(~exist('save','dir'))
            mkdir('save');
        end

        fNameDefault = ['save\' '3DNBack-' subID '-' num2str(i,'%03d') '.train.mat'];
        while(exist(fNameDefault,'file'))
            i = i + 1;
            fNameDefault = ['save\' '3DNBack-' subID '-' num2str(i,'%03d') '.train.mat'];
        end

        % Save exemplars and ANN
        [fName, path] = uiputfile('*.train.mat','Save exemplar and ANN data as...',fNameDefault);
        if(~fName)
            return;
        end

        fName = [path fName];

        fprintf('%s: Saving ANN and exemplar data to "%s"...', datestr(now), fName);

        saveStruct.exOverload = handles.exOverload;
        saveStruct.exOK = handles.exOK;
        saveStruct.exUnderload = handles.exUnderload;
        saveStruct.ann = handles.ann;

        save(fName,'saveStruct');
        disp('Done.');
        bSuccess = true;
    catch err
        disp(['Error: ' err.message]);
    end
    
function menuitemLoad_Callback(hObject, eventdata, handles)
    [fName, path] = uigetfile('*.train.mat','Select a state save file...');
    if(~fName)
        return;
    end
    fName = [path fName];
    fprintf('%s: Loading ANN and exemplar data from "%s"...', datestr(now),fName);
    try
        l = load(fName);
        saveStruct = l.saveStruct;
        
        handles.exOverload = saveStruct.exOverload;
        handles.exOK = saveStruct.exOK;
        handles.exUnderload = saveStruct.exUnderload;
        handles.ann = saveStruct.ann;
        
        disp('Done.');
        guidata(hObject,handles);
        UpdateBucketStatus(hObject);
    catch err
        disp(['ERROR: ' err.message]);
    end
    
function menuitemSaveConfig_Callback(hObject, eventdata, handles)
    doSaveConfig(handles);

function doSaveConfig(handles,fName)
    if(~exist('fName','file'))
        [fName,path] = uiputfile('*.config.mat','Save configuration file as...','Untitled.config.mat');
        if(~fName)
            return;
        end
        fName = [path fName];
    end

    fprintf('Saving configuration data to "%s"...', fName);
    
    saveConfigStruct = struct();
    
    saveConfigStruct.editN = get(handles.editN,'Value');
    saveConfigStruct.editProb = get(handles.editProb,'Value');
    saveConfigStruct.editResponseTime = get(handles.editResponseTime,'Value');
    saveConfigStruct.editBlankTime = get(handles.editBlankTime,'Value');
    saveConfigStruct.editUnderload = get(handles.editUnderload,'Value');
    saveConfigStruct.editOverload = get(handles.editOverload,'Value');
    saveConfigStruct.editPort = get(handles.editPort,'Value');
    
    saveConfigStruct.sliderTrimLength = get(handles.sliderTrimLength,'Value');
    saveConfigStruct.sliderWinLength = get(handles.sliderWinLength,'Value');
    saveConfigStruct.sliderWinOverlap = get(handles.sliderWinOverlap,'Value');

    saveConfigStruct.editFreq = get(handles.editFreq,'String');
    saveConfigStruct.editChan = get(handles.editChan,'String');
    saveConfigStruct.editServer = get(handles.editServer,'String');

    saveConfigStruct.editWorkloadThreshold = get(handles.editWorkloadThreshold,'Value');
    saveConfigStruct.editWorkloadDecay = get(handles.editWorkloadDecay,'Value');
    
    saveConfigStruct.checkboxNormalize = get(handles.checkboxNormalize,'Value');
    saveConfigStruct.checkboxTest = get(handles.checkboxTest,'Value');
    saveConfigStruct.checkboxVerbose = get(handles.checkboxVerbose,'Value');
    
    saveConfigStruct.checkboxManual = get(handles.checkboxManual,'Value');
    
    save(fName,'saveConfigStruct');
    disp('Done.');
    
function menuitemLoadConfig_Callback(hObject, eventdata, handles)
    doLoadConfig(hObject,handles);

function doLoadConfig(hObject,handles,fName)
    if(~exist('fName','var'))
        [fName,path] = uigetfile('*.config.mat','Select a configuration file to load...');
        if(~fName)
            return;
        end
        fName = [path fName];
    end
    fprintf('%s: Loading configuration data from "%s"...',datestr(now),fName);
    try
        l = load(fName);
        saveConfigStruct = l.saveConfigStruct;
        
        if(isfield(handles,'netHandle') && strcmp(get(handles.netHandle,'Status'),'Open'))
            sendPacket(handles.netHandle,'CTRL',3,4,0);
            sendPacket(handles.netHandle,'CTRL',1,2,0);
            fclose(handles.netHandle);
            bNetHandle = true;
        else
            bNetHandle = false;
        end
        
        set(handles.editN,'String',num2str(saveConfigStruct.editN));
        set(handles.editN,'Value',saveConfigStruct.editN);
        
        set(handles.editProb,'String',num2str(saveConfigStruct.editProb));
        set(handles.editProb,'Value',saveConfigStruct.editProb);
        
        set(handles.editResponseTime,'String',num2str(saveConfigStruct.editResponseTime));
        set(handles.editResponseTime,'Value',saveConfigStruct.editResponseTime);
        
        set(handles.editBlankTime,'String',num2str(saveConfigStruct.editBlankTime));
        set(handles.editBlankTime,'Value',saveConfigStruct.editBlankTime);
        
        set(handles.editUnderload,'String',num2str(saveConfigStruct.editUnderload));
        set(handles.editUnderload,'Value',saveConfigStruct.editUnderload);

        set(handles.editOverload,'String',num2str(saveConfigStruct.editOverload));
        set(handles.editOverload,'Value',saveConfigStruct.editOverload);


        set(handles.textTrimLength,'String',sprintf('%.0f',saveConfigStruct.sliderTrimLength));
        set(handles.sliderTrimLength,'Value',saveConfigStruct.sliderTrimLength);

        set(handles.textWinLength,'String',sprintf('%.0f',saveConfigStruct.sliderWinLength));
        set(handles.sliderWinLength,'Value',saveConfigStruct.sliderWinLength);

        set(handles.textWinOverlap,'String',sprintf('%.2f',saveConfigStruct.sliderWinOverlap));
        set(handles.sliderWinOverlap,'Value',saveConfigStruct.sliderWinOverlap);
        
        set(handles.editFreq,'String',saveConfigStruct.editFreq);
        set(handles.editChan,'String',saveConfigStruct.editChan);
        
        set(handles.editServer,'String',saveConfigStruct.editServer);
        set(handles.editPort,'String',num2str(saveConfigStruct.editPort));
        set(handles.editPort,'Value',saveConfigStruct.editPort);
        
        if(bNetHandle)
            set(handles.netHandle,'RemotePort',saveConfigStruct.editPort);
            set(handles.netHandle,'RemoteHost',saveConfigStruct.editServer);
        end
        
        set(handles.checkboxNormalize,'Value',saveConfigStruct.checkboxNormalize);
        set(handles.checkboxTest,'Value',saveConfigStruct.checkboxTest);
        set(handles.checkboxVerbose,'Value',saveConfigStruct.checkboxVerbose);
        
        set(handles.editWorkloadThreshold,'String',num2str(saveConfigStruct.editWorkloadThreshold));
        set(handles.editWorkloadThreshold,'Value',saveConfigStruct.editWorkloadThreshold);

        set(handles.editWorkloadDecay,'String',num2str(saveConfigStruct.editWorkloadDecay));
        set(handles.editWorkloadDecay,'Value',saveConfigStruct.editWorkloadDecay);
        
        set(handles.checkboxManual,'Value',saveConfigStruct.checkboxManual);
        setManual(hObject);
        
        disp('Done.');
        %guidata(hObject,handles);
    catch err
        %disp(['ERROR: ' err.message]);
        rethrow(err);
    end


function editWorkloadThreshold_Callback(hObject, eventdata, handles)
nVal = str2double(get(hObject,'String'));
if(nVal < 1)
    uiwait(msgbox('Workload threshold must be greater than 1!','Error','error'));
    set(hObject,'String',num2str(get(hObject,'Value')));
else
    set(hObject,'Value',nVal);
end

function editWorkloadThreshold_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function editWorkloadCurrent_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function checkboxVerbose_Callback(hObject, eventdata, handles)

function btnResetIndex_Callback(hObject, eventdata, handles)
    handles.workloadIndex = 0;
    set(handles.editWorkloadCurrent,'String','0');
    guidata(hObject,handles);

function checkboxManual_Callback(hObject, eventdata, handles)
    setManual(hObject);
    
function setManual(hObject,value)
    handles = guidata(hObject);
    if(exist('value','var'))
        if(isequal(value,'toggle'))
            if(get(handles.checkboxManual,'Value') == 1)
                set(handles.checkboxManual,'Value',0);
            else
                set(handles.checkboxManual,'Value',1);
            end
        elseif(isequal(value,false))
            set(handles.checkboxManual,'Value',0);
        elseif(isequal(value,true))
            set(handles.checkboxManual,'Value',1);
        end
    end
    if(get(handles.checkboxManual,'Value')) % ON, disable threshold boxes
        state = 'off';
    else
        state = 'on';
    end
    
    set(handles.editOverload,'Enable',state);
    set(handles.editUnderload,'Enable',state);

function menuControl_Callback(hObject, eventdata, handles)

function menuitemIncreaseN_Callback(hObject, eventdata, handles)
    disp([datestr(now) ': *** (EXPERIMENTER) Increasing N! ***']);
    doIncreaseN(hObject);

function menuitemDecreaseN_Callback(hObject, eventdata, handles)
    disp([datestr(now) ': *** (EXPERIMENTER) Decreasing N! ***']);
    doDecreaseN(hObject);

function editWorkloadDecay_Callback(hObject, eventdata, handles)
nVal = round(str2double(get(hObject,'String')));
if(nVal <= 0)
    msgbox('Threshold decay must be > 0','Error','error');
    set(hObject,'String',get(hObject,'Value'));
    return;
else
    set(hObject,'Value',nVal);
end
guidata(hObject, handles);

function editWorkloadDecay_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function menuitemIncreaseThreshold_Callback(hObject, eventdata, handles)
n = get(handles.editWorkloadThreshold,'Value');
set(handles.editWorkloadThreshold,'Value',n+1);
set(handles.editWorkloadThreshold,'String',num2str(n+1,'%.0f'));
drawnow();

function menuitemDecreaseThreshold_Callback(hObject, eventdata, handles)
n = get(handles.editWorkloadThreshold,'Value');
if(n > 1)
    set(handles.editWorkloadThreshold,'Value',n-1);
    set(handles.editWorkloadThreshold,'String',num2str(n-1,'%.0f'));
end
drawnow();

function menuitemKillExperiment_Callback(hObject, eventdata, handles)
    set(handles.menuitemKillExperiment,'Checked','on');
    guidata(hObject,handles);
    drawnow();
    
