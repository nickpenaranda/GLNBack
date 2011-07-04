function results = GLNBack(hObject)
    if(~exist('hObject','var'))
        NBackGUI();
        return;
    end
    
    handles = guidata(hObject);
    
    RandStream.setDefaultStream(RandStream('mt19937ar','seed',sum(100*clock)));

    if(get(handles.checkboxTest,'Value'))
        disp('  *** TEST MODE ***');
        oldSync = Screen('Preference','SkipSyncTests',1);
    else
        oldSync = Screen('Preference','SkipSyncTests',0);
    end
    
    oldEnableFlag = Screen('Preference', 'SuppressAllWarnings', 1);
    oldVerbosity = Screen('Preference', 'Verbosity', 0);
    
    
    % ID N Trial Vehicle Heading PosTrial? Response? Correct RT
    % 1  2 3     4       5       6         7         8       9
    
    results = {};
    trialData = cell(1,8);
    
    % Constants and look-up tables
    bAnisoEnabled = true;
    
    GL_TEXTURE_MAX_ANISOTROPY_EXT = hex2dec('84FE');
    GL_MAX_TEXTURE_MAX_ANISOTROPY_EXT = hex2dec('84FF');

    winOffsetX = 32;
    winOffsetY = 32;
    
    if(~get(handles.checkboxTest,'Value'))
        windowSize = []; % Full Screen
    else
        windowSize = [winOffsetX winOffsetY winOffsetX+640 winOffsetY+480]; % Windowed; for debugging.
    end
    
    tPadding = 15;
    
    tileFactor = 32;
    
    luAngles = [0 45 90 135 180 225 270 315]; % 45-degree increments
    % luAngles = [0 30 60 90 120 150 180 210 240 270 300 330]; % 30-degree increments
    luSin = sind(luAngles);
    luCos = cosd(luAngles);
    
    Velocity = 12;
    CamVelocity = 8;
    CamDist = 20;
    CamHeight = 10;
    
    resPath = 'res/';
    modelNames = {'Ambulance','Firetruck','Pickup','Policecar','Redbus','Schoolbus','Sedan','Taxi'};
    scaleTweak =  [1.5        1.4         0.8      0.7         1.4      1.4         0.6     0.6];
    heightTweak = [0.035      0.67        0.495    0.29        0.665    0.51        0.19    0.245];
    globalFloorTweak = 0.015;
    
    bVerbose = get(handles.checkboxVerbose,'Value');
    subID = get(handles.editID,'String');
    numBack = get(handles.editN,'Value');
    pSame = get(handles.editProb,'Value');
    stimRespTime = get(handles.editResponseTime,'Value');
    blankTime = get(handles.editBlankTime,'Value');
    
    AssertOpenGL;
    
    models = cell(length(modelNames),1);

    disp('  Loading models:');
    % Load models
    for i=1:length(modelNames)
        fprintf('    %s...',modelNames{i});
        
        model = LoadOBJFile2([resPath 'mdl' modelNames{i} '.obj']);
        model = model{1};
        model.texcoords = vertcat(1-model.texcoords(2,:),model.texcoords(1,:));
        
        fprintf('...');
        model.texImage = imread([resPath 'tex' modelNames{i} '.jpg']);
        
        models{i} = model;
        fprintf('...\n');
    end
    
    % Main PTB block (in a try/catch)
    try
        disp('  Initializing PsychToolbox screen...');
        screens = Screen('Screens');
        screenNumber = max(screens);
        
        InitializeMatlabOpenGL;

        [expWin,rect]=Screen('OpenWindow',screenNumber,0,windowSize,[],[],[],4);
        %[mx,my] = RectCenter(rect);
        ar=rect(4)/rect(3);
        
        %HideCursor;
        ListenChar(2);
        
        disp('  Creating textures...');
        % Create textures in video memory from vehicle images
        PTBtextures = zeros(length(models),1);
        for i=1:length(models)
            PTBtextures(i) = Screen('MakeTexture', expWin, models{i}.texImage, [], 1);
            models{i} = rmfield(models{i},'texImage');
        end
        
        % Do the same for the floor texture
        floorImg = imread([resPath 'texFloor.jpg']);
        PTBfloorTex = Screen('MakeTexture', expWin, floorImg, [], 1);
        clear floorImg;
        
        Screen('FillRect',expWin,0);
        DrawFormattedText(expWin,'Please wait...','center','center',255);
        Screen('Flip',expWin);
        
        Screen('BeginOpenGL', expWin);
        
        if(strcmp(glGetString(GL.EXTENSIONS),'GL_EXT_texture_filter_anisotropic')==1 && bAnisoEnabled)
            bAnisoFiltering = true;
        else
            bAnisoFiltering = false;
        end
        
        disp('  Defining OpenGL textures...');
        % Create OpenGL textures from PTB video mem textures
        textures = zeros(length(PTBtextures),1);
        for i=1:length(models)
            textures(i) = Screen('GetOpenGLTexture', expWin, PTBtextures(i));
            glBindTexture(GL.TEXTURE_2D, textures(i));            

            glTexParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.REPEAT);
            glTexParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.REPEAT);
            glTexParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR);
            glTexParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR); 
            if(bAnisoFiltering)
                glTexParameteri(GL.TEXTURE_2D, GL_TEXTURE_MAX_ANISOTROPY_EXT, 4.0);
            end
        end
        
        [floorTex floorTarget] = Screen('GetOpenGLTexture', expWin, PTBfloorTex);
        glBindTexture(floorTarget, floorTex);

        glTexParameteri(floorTarget, GL.TEXTURE_WRAP_S, GL.REPEAT);
        glTexParameteri(floorTarget, GL.TEXTURE_WRAP_T, GL.REPEAT);
        glTexParameteri(floorTarget, GL.TEXTURE_MIN_FILTER, GL.LINEAR);
        glTexParameteri(floorTarget, GL.TEXTURE_MAG_FILTER, GL.LINEAR); 
        if(bAnisoFiltering)
            glTexParameteri(GL.TEXTURE_2D, GL_TEXTURE_MAX_ANISOTROPY_EXT, 4.0);
        end
        
        disp('  Initializing OpenGL scene parameters...');
        % Set some OpenGL states
        glTexEnvfv(GL.TEXTURE_ENV,GL.TEXTURE_ENV_MODE,GL.MODULATE);
        glEnable(GL.LIGHTING);
        glEnable(GL.LIGHT0);
        glEnable(GL.DEPTH_TEST);
        glEnable(GL.TEXTURE_2D);
        
        glEnableClientState(GL.VERTEX_ARRAY);
        glEnableClientState(GL.NORMAL_ARRAY);
                        
        % Set the material and un-textured color of all objects
        glMaterialfv(GL.FRONT,GL.AMBIENT, [ 1 1 1 1 ]);
        glMaterialfv(GL.FRONT,GL.DIFFUSE, [ 1 1 1 1 ]);
        glColor3f(1.0, 1.0, 1.0);
         
        % Set up projection matrix
        glMatrixMode(GL.PROJECTION);
        glLoadIdentity;
        gluPerspective(60,1/ar,.01,500);
        
        % Light parameters
        lightPos = [50 100 10 0];
        glLightfv(GL.LIGHT0,GL.POSITION,lightPos);
        glLightfv(GL.LIGHT0,GL.DIFFUSE,[ 1 1 1 1]);
        glLightfv(GL.LIGHT0,GL.SPECULAR,[ 1 1 1 1 ]);
        glLightfv(GL.LIGHT0,GL.AMBIENT, [0 0 0.1 1]);
        glLightModelfv(GL.LIGHT_MODEL_TWO_SIDE,GL.TRUE);
        % Generate rendering lists for each vehicle, for performance
        modelListsStartIndex = glGenLists(length(models));
        modelLists = modelListsStartIndex:modelListsStartIndex+length(models);
        glMatrixMode(GL.MODELVIEW);
        glLoadIdentity();
        
        fprintf('  Creating OpenGL render models...');
        for i=1:length(models)
            glVertexPointer(3,GL.DOUBLE,0,models{i}.vertices);
            glNormalPointer(GL.DOUBLE,0,models{i}.normals);    
            
            glNewList(modelLists(i),GL.COMPILE);
                %glPushMatrix();
                    glScaled(scaleTweak(i),scaleTweak(i),scaleTweak(i));
                    glBegin(GL.TRIANGLES);
                        for j=1:length(models{i}.faces)
                            glTexCoord2dv(models{i}.texcoords(:,models{i}.faces(4,j)+1));
                            glArrayElement(models{i}.faces(1,j));

                            glTexCoord2dv(models{i}.texcoords(:,models{i}.faces(5,j)+1));
                            glArrayElement(models{i}.faces(2,j));

                            glTexCoord2dv(models{i}.texcoords(:,models{i}.faces(6,j)+1));
                            glArrayElement(models{i}.faces(3,j));
                        end
                    glEnd();
                %glPopMatrix();
            glEndList();
            fprintf('.');
        end
        
        floor = LoadOBJFile2([resPath 'mdlWorld2.obj']);
        floor = floor{1};
        glVertexPointer(3,GL.DOUBLE,0,floor.vertices);
        glNormalPointer(GL.DOUBLE,0,floor.normals);    
        
        floorModel = glGenLists(1);
        glNewList(floorModel,GL.COMPILE);
            glBegin(GL.TRIANGLES);
                for j=1:length(floor.faces)
                    glTexCoord2dv(floor.texcoords(:,floor.faces(4,j)+1)*tileFactor);
                    glArrayElement(floor.faces(1,j));

                    glTexCoord2dv(floor.texcoords(:,floor.faces(5,j)+1)*tileFactor);
                    glArrayElement(floor.faces(2,j));

                    glTexCoord2dv(floor.texcoords(:,floor.faces(6,j)+1)*tileFactor);
                    glArrayElement(floor.faces(3,j));
                end
            glEnd();
        glEndList();
        
        shadowOn = glGenLists(1);
        glNewList(shadowOn,GL.COMPILE);
            glEnable(GL.BLEND);
            glBlendFunc(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA);
            glDisable(GL.LIGHTING);
            glDisable(GL.TEXTURE_2D);
            glColor4f(0.0, 0.0, 0.0, 0.5);
        glEndList();
        
        shadowOff = glGenLists(1);
        glNewList(shadowOff,GL.COMPILE);
            glEnable(GL.LIGHTING);
            glEnable(GL.TEXTURE_2D);
            glDisable(GL.STENCIL_TEST);
            glDisable(GL.BLEND);
        glEndList();
        
        
        fprintf('.\n');
        
        disp('  Calculating shadow matrix...');
        floorPlane = [0 1 0 0];
        floorShadow = shadowMatrix(floorPlane, lightPos);

        % Enter model view matrix mode
        glMatrixMode(GL.MODELVIEW);

        % This is a measure of distance from the default viewing center. 
        % The camera trails by a default amount +/- this number units
        CamTargetDist = 0;

        % In degrees, how much to rotate the entire scene (simulating
        % orbiting of the camera)
        viewAngle = 0;

        prevCond = zeros(10,2);
        curCond = [0 0];

        numCorrect = 0;
        numIncorrect = 0;

        oldNumBack = numBack;
        
        Screen('EndOpenGL',expWin);
        
        disp('  Initialization complete. Experiment is ready to run!');
        Screen('FillRect',expWin,0);
        DrawFormattedText(expWin,'Press any key to begin','center','center',255);
        Screen('Flip',expWin);
        KbWait([],3);
        disp('  ** User initiates trial block **');
        if(strcmp(get(handles.netHandle,'Status'),'open'))
            sendPacket(handles.netHandle,'CTRL',3,3,0);
        end
        
        tic;
        
        if(~get(handles.checkboxAdaptive,'Value')) % Training mode, automatically end after Trim Length + tPadding
            blockLength = str2double(get(handles.textTrimLength,'String')) + tPadding;
            tAutoEnd = blockLength;
            disp(['  ** This block will automatically end in ' num2str(blockLength) ' seconds. **']);
        else
            tAutoEnd = 0;
        end
            
        
        Screen('BeginOpenGL',expWin);
        
        k = 1;
        % Infinite loop, broken via ESC key
        while true
            newNumBack = get(handles.editN,'Value');
            if(newNumBack ~= oldNumBack)
                numBack = newNumBack;
                Screen('EndOpenGL',expWin);
                Screen('FillRect',expWin,0);
                DrawFormattedText(expWin,['N has changed to ' num2str(numBack) '!\n' ...
                    'Press any key to continue.'],'center','center',255);
                Screen('Flip',expWin);
                disp(['  ** User prompted with new N (' num2str(numBack) ') **']);
                drawnow;
                KbWait([],3);
                disp('  ** User initiates trial block **');

                % TODO: Save these values before resetting them?
                k = 1;
                numCorrect = 0;
                numIncorrect = 0;
                Screen('BeginOpenGL',expWin);
            end
            oldNumBack = newNumBack;
            
            % Update info in GUI
            set(handles.editTrialNum,'String',num2str(k));
            set(handles.editTrialNum,'Value',k);

            set(handles.editNumCorrect,'String',num2str(numCorrect));
            set(handles.editNumCorrect,'Value',numCorrect);

            set(handles.editNumIncorrect,'String',num2str(numIncorrect));
            set(handles.editNumIncorrect,'Value',numIncorrect);
            
            now = toc;
            set(handles.editDuration,'String',num2str(now,'%.1f'));
            
            if(k > 1)
                set(handles.editPerf,'String',sprintf('%2.2f%%',numCorrect/(k-1)*100));
                set(handles.editPerf,'Value',numCorrect/(k-1));
            end
            
            if(tAutoEnd && now > tAutoEnd)
                disp('  ** Training block automatically ended (criterion time reached) **');
                break;
            end

            drawnow;

            prevCond(2:end,:) = prevCond(1:end-1,:);
            prevCond(1,:) = curCond;

            if(k > numBack && rand() <= pSame)
                bTrialType = true;
                curCond = prevCond(numBack,:);
            else
                bTrialType = false;
                curCond = [randi(length(models)) randi(length(luAngles))];
                while(isequal(curCond,prevCond(numBack,:)))
                    curCond = [randi(length(models)) randi(length(luAngles))];
                end
            end
            
            startCoord = [luCos(curCond(2))*10 ...
                          luSin(curCond(2))*10];
            vehicle = curCond(1);

            [keyIsDown, checkTime, keyCode] = KbCheck();
            StimulusOnsetTime = GetSecs();
            t = 0;
            tOld = GetSecs();
            
            while(checkTime <= StimulusOnsetTime + stimRespTime)
                [keyIsDown, checkTime, keyCode] = KbCheck();
                if(keyIsDown)
                    break
                end
                glClear(GL.DEPTH_BUFFER_BIT);
                glClearColor(.45, .82, 1, 0);
                glClear(GL.COLOR_BUFFER_BIT);
                glLoadIdentity;

                % Camera position, flying forward over time
                gluLookAt(0,CamHeight,(-CamDist*2)+(t*CamVelocity),0,0,(-CamDist)+(t*CamVelocity)+CamTargetDist,0,1,0);

                % Draw world
                glPushMatrix();
                    glRotated(viewAngle,0,1,0);

                    % Draw floor
                    glPushMatrix();
                        glTranslated(0,globalFloorTweak,0);
                        glBindTexture(floorTarget,floorTex);
                        glCallList(floorModel);
                    glPopMatrix();

                    % Draw vehicle
                    glPushMatrix();
                        glTranslated(startCoord(2)-(luSin(curCond(2))*Velocity*t), ...
                                     heightTweak(vehicle), ...
                                     startCoord(1)-(luCos(curCond(2))*Velocity*t));
                        glRotated(luAngles(curCond(2))+180,0,1,0);

                        glBindTexture(GL.TEXTURE_2D,textures(vehicle));
                        glCallList(modelLists(vehicle));
                    glPopMatrix();
                    
%                     glCallList(shadowOn);
%                     
%                     glPushMatrix();
%                         glMultMatrixf(floorShadow)
%                         glPushMatrix();
%                             glTranslated(startCoord(2)-(luSin(curCond(2))*Velocity*t), ...
%                                          heightTweak(vehicle), ...
%                                          startCoord(1)-(luCos(curCond(2))*Velocity*t));
%                             glRotated(luAngles(curCond(2))+180,0,1,0);
%                             glBindTexture(GL.TEXTURE_2D,textures(vehicle));
%                             glCallList(modelLists(vehicle));
%                         glPopMatrix();
%                     glPopMatrix();
% 
%                     glCallList(shadowOff);
                glPopMatrix();
                glFlush;
                Screen('EndOpenGL', expWin);

                tReal = GetSecs();
                t = t + tReal - tOld;
                tOld = tReal;


                % Any PTB drawing code goes here, e.g., text display
%                 if(k > numBack)
%                     if(numBack>1)
%                         trialString = 'screens';
%                     else
%                         trialString = 'screen';
%                     end
%                     tNBackInfo = [ ...
%                         'Press any key if the vehicle is the same\n' ...
%                         'and moving in the same direction as\n' ...
%                         num2str(numBack) ' ' trialString ' ago.'];
%                     DrawFormattedText(expWin,tNBackInfo,'center',0,255);
%                 end
                DrawFormattedText(expWin,['N = ' num2str(numBack)],'center',0,255);
                Screen('Flip', expWin);

                % Re-initialize openGL block for next draw cycle
                Screen('BeginOpenGL',expWin); 
            end
                
            cc = KbName(keyCode);
            
            if(strcmp(cc,'esc')==1)
                disp('  ** User exits trial block **');
                break;
            elseif(~isempty(cc) && bTrialType == false) % Key pressed but this is not a matching trial
                % SEND FALSEALARM
                if(bVerbose)
                    disp('    False alarm!');
                end
                numIncorrect = numIncorrect + 1;
                bResponded = true;
                bCorrect = false;
            elseif(~isempty(cc) && bTrialType == true) % Correct response
                % SEND HIT
                numCorrect = numCorrect + 1;
                bResponded = true;
                bCorrect = true;
            elseif(isempty(cc) && bTrialType == true) % No key pressed but this is a matching trial
                % SEND MISS
                if(bVerbose)
                    disp('    Miss!');
                end
                numIncorrect = numIncorrect + 1;
                bResponded = false;
                bCorrect = false;
            else
                % SEND CORRECT REJECTION
                numCorrect = numCorrect + 1;
                bResponded = false;
                bCorrect = true;
            end
            
            trialData{1} = subID;
            trialData{2} = numBack;
            trialData{3} = k;
            trialData{4} = modelNames{curCond(1)};
            trialData{5} = luAngles(curCond(2));
            trialData{6} = bTrialType;
            trialData{7} = bResponded;
            trialData{8} = bCorrect;
            trialData{9} = checkTime - StimulusOnsetTime;

            results = vertcat(results,trialData);
            glClearColor(0,0,0,0);
            glClear();
            Screen('EndOpenGL',expWin);

            Screen('Flip',expWin);
            
            %WaitSecs('UntilTime',blankFlipTime + blankTime);
            WaitSecs('UntilTime',StimulusOnsetTime + stimRespTime + blankTime);
            
            k = k + 1;
            
            Screen('BeginOpenGL',expWin);

            if(strcmp(get(handles.menuitemKillExperiment,'Checked'),'on'))
                disp('  ** Experimenter exits training block **');
                break;
            end
        end
        
        % Clean up
        glBindTexture(GL.TEXTURE_2D, 0);
        glDeleteTextures(length(textures),textures);
        glDeleteTextures(1,floorTex);
        
        glDeleteLists(length(modelLists),modelLists);
        glDeleteLists(1,floorModel);
        glDeleteLists(1,shadowOn);
        glDeleteLists(1,shadowOff);
        
        Screen('EndOpenGL',expWin);

        ShowCursor;
        Screen('CloseAll');
        ListenChar(0);
        Screen('Preference','Verbosity', oldVerbosity);
        Screen('Preference','SkipSyncTests',oldSync);
        Screen('Preference', 'SuppressAllWarnings', oldEnableFlag);
    catch
        ShowCursor;
        Screen('CloseAll');
        ListenChar(0);
        Screen('Preference','Verbosity', oldVerbosity);
        Screen('Preference','SkipSyncTests',oldSync);
        Screen('Preference', 'SuppressAllWarnings', oldEnableFlag);
        psychrethrow(psychlasterror);
    end
        
function shadowMat = shadowMatrix(groundPlane,lightPos)
  d = dot(groundPlane,lightPos);

  shadowMat = zeros(4,4);
  shadowMat(1,:) = [d - lightPos(1) * groundPlane(1), ...
                    0 - lightPos(1) * groundPlane(2), ...
                    0 - lightPos(1) * groundPlane(3), ...
                    0 - lightPos(1) * groundPlane(4)];

  shadowMat(2,:) = [0 - lightPos(2) * groundPlane(1), ...
                    d - lightPos(2) * groundPlane(2), ...
                    0 - lightPos(2) * groundPlane(3), ...
                    0 - lightPos(2) * groundPlane(4)];

  shadowMat(3,:) = [0 - lightPos(3) * groundPlane(1), ...
                    0 - lightPos(3) * groundPlane(2), ...
                    d - lightPos(3) * groundPlane(3), ...
                    0 - lightPos(3) * groundPlane(4)];

  shadowMat(4,:) = [0 - lightPos(4) * groundPlane(1), ...
                    0 - lightPos(4) * groundPlane(2), ...
                    0 - lightPos(4) * groundPlane(3), ...
                    d - lightPos(4) * groundPlane(4)];

