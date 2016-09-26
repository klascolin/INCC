function bloques
% MAIN
    format long g;
    % constantes
    USE_FULLSCREEN = 1;
    USE_WINDOWED = 0;

    DELAY_0 = 0;
    DELAY_1 = 0.25;
    DELAY_2 = 0.50;
    DELAY_3 = 0.75;

    IMG_SI = 1;
    IMG_NO = 0;

    SND_SI = 1;
    SND_NO = 0;

    SEGUIR_IMG = 1;
    SEGUIR_SND = 0;

    TRIALS_BLOQUE_PRACTICA = 5;
    TRIALS_BLOQUE_COMUN = 15;
    % /constantes

    global sujeto;
    try
        sujeto = csvread('data/siguientesujeto.csv')
    catch
        sujeto = 1
    end
    csvwrite('data/siguientesujeto.csv', sujeto+1)

    try
        PsychPortAudio('Close') % en caso de que se haya cerrado mal
        InitPTB(USE_WINDOWED)

        practica = [
            [ DELAY_0, IMG_SI, SND_NO, SEGUIR_IMG, TRIALS_BLOQUE_PRACTICA];
            [ DELAY_0, IMG_NO, SND_SI, SEGUIR_SND, TRIALS_BLOQUE_PRACTICA];
            [ DELAY_0, IMG_SI, SND_SI, SEGUIR_IMG, TRIALS_BLOQUE_PRACTICA];
        ]

        que_seguir = SEGUIR_IMG; % elegirlo bien

        posta = [ 
            [ DELAY_0, IMG_SI, SND_NO, SEGUIR_IMG, TRIALS_BLOQUE_COMUN];
            [ DELAY_0, IMG_NO, SND_SI, SEGUIR_SND, TRIALS_BLOQUE_COMUN];
            [ DELAY_0, IMG_SI, SND_SI, SEGUIR_IMG, TRIALS_BLOQUE_COMUN];
            [ DELAY_0, IMG_SI, SND_SI, que_seguir, TRIALS_BLOQUE_COMUN];
            [ DELAY_1, IMG_SI, SND_SI, que_seguir, TRIALS_BLOQUE_COMUN];
            [-DELAY_1, IMG_SI, SND_SI, que_seguir, TRIALS_BLOQUE_COMUN];
            [ DELAY_2, IMG_SI, SND_SI, que_seguir, TRIALS_BLOQUE_COMUN];
            [-DELAY_2, IMG_SI, SND_SI, que_seguir, TRIALS_BLOQUE_COMUN];
            [ DELAY_3, IMG_SI, SND_SI, que_seguir, TRIALS_BLOQUE_COMUN];
            [-DELAY_3, IMG_SI, SND_SI, que_seguir, TRIALS_BLOQUE_COMUN];
        ]
        
        % mezclar `posta` de alguna forma

        correrBloques(practica, 10)

        % pausa() ???
        correrBloques(posta, 2)

        CleanupPTB();

    % This "catch" section executes in case of an error in the "try" section
    % above.  Importantly, it closes the onscreen window if it's open.
    catch
        psychrethrow(psychlasterror);
        CleanupPTB();
    end

end

function correrBloques(ts, tiempo_pausa)
    I_DELAY = 1;
    I_IMG = 2;
    I_SND = 3;
    I_SEGUIR = 4;
    I_TRIALS = 5;
   
    filas = size(ts, 1)
    
    for i = 1:filas
        Tap(ts(i, I_DELAY), ts(i, I_IMG), ts(i, I_SND), ts(i, I_SEGUIR), ts(i, I_TRIALS))
        pausaEpileptica(tiempo_pausa)
    end
end

function InitPTB(fullscreen)
    global oldVisualDebugLevel;
    global oldSupressAllWarnings;
    global windowHandle;
    global audioHandle;

    global imagetex;
    global iRect;
    global iCenter;
    global wavedata;
    global IMG_NUMBER;
    global BLACK;
    global WHITE;

    
    IMG_NUMBER = 4;
    SND_NUMBER = 2;

    FULLSCREEN = fullscreen;

    KbName('UnifyKeyNames');
    AssertOpenGL;

    % Perform basic initialization of the sound driver:
    InitializePsychSound;

    wavedata = cell(1, SND_NUMBER);
    y = cell(1, SND_NUMBER);
    freq = [];
    nrchannels = [];
    for i = 1:SND_NUMBER
      [y{i}, freq] = wavread(['beep' sprintf('%d', i) '.wav']);
      wavedata{i} = y{i}';
      nrchannels = size(wavedata{i}, 1); % Number of rows == number of channels.
    end

    oldVisualDebugLevel = Screen('Preference', 'VisualDebugLevel', 3);
    oldSupressAllWarnings = Screen('Preference', 'SuppressAllWarnings', 1);

    % Color definitions
    screenNumber = max(Screen('Screens'));
    WHITE = WhiteIndex(screenNumber);
    BLACK = BlackIndex(screenNumber);

    % Open a double buffered (maybe fullscreen)
    if FULLSCREEN
        windowSize = [];
    else
        windowSize = [100 100 900 900];
    end

    [windowHandle, wRect] = Screen('OpenWindow',screenNumber, 0, windowSize, 32, 2);
    [wcx, wcy] = RectCenter(wRect);

    % Import image and and convert it, stored in
    % MATLAB matrix, into a Psychtoolbox OpenGL texture using 'MakeTexture';
    imdata = cell(1, IMG_NUMBER);
    imagetex = cell(1, IMG_NUMBER);
    iRect = cell(1, IMG_NUMBER);
    iCenter = cell(1, IMG_NUMBER);
    for i = 1:IMG_NUMBER
        imdata{i} = imread(['col' sprintf('%d', i) '.jpg']);
        imagetex{i} = Screen('MakeTexture', windowHandle, imdata{i});
        iRect{i} = Screen('Rect', imagetex{i});
        [cx, cy] = RectCenter(iRect{i});
        iCenter{i} = [cx, cy];
    end

    % Open the default audio device [], with default mode [] (==Only playback),
    % and a required latencyclass of zero 0 == no low-latency mode, as well as
    % a frequency of freq and nrchannels sound channels.
    % This returns a handle to the audio device:
    try
        % Try with the 'freq'uency we wanted:
        audioHandle = PsychPortAudio('Open', [], [], 0, freq, nrchannels);
    catch
        % Failed. Retry with default frequency as suggested by device:
        fprintf('\nCould not open device at wanted playback frequency of %i Hz. Will retry with device default frequency.\n', freq);
        fprintf('Sound may sound a bit out of tune, ...\n\n');
        psychlasterror('reset');
        audioHandle = PsychPortAudio('Open', [], [], 0, [], nrchannels);
    end

    % Blank sceen
    Screen('FillRect', windowHandle, uint8(BLACK));
    Screen('Flip', windowHandle);

    % Bump priority for speed
    priorityLevel = MaxPriority(windowHandle);
    Priority(priorityLevel);

end

function CleanupPTB

    global oldVisualDebugLevel;
    global oldSupressAllWarnings;
    global audioHandle;

    % Stop playback:
    PsychPortAudio('Stop', audioHandle);

    % Close the audio device:
    PsychPortAudio('Close', audioHandle);

    % The same command which closes onscreen and offscreen windows also
    % closes textures.
    Screen('CloseAll');
    ShowCursor;
    Priority(0);

    % Restore preferences
    Screen('Preference', 'VisualDebugLevel', oldVisualDebugLevel);
    Screen('Preference', 'SuppressAllWarnings', oldSupressAllWarnings);
end
%%
function pausaEpileptica(tiempo)
    global windowHandle;
    global BLACK;
    global WHITE;

    EPILEPSIA_INTERVAL=0.125;
    t = tiempo/(EPILEPSIA_INTERVAL*2);
    for i = 1:t
        Screen('FillRect', windowHandle, BLACK)
        Screen('Flip', windowHandle);
        WaitSecs(EPILEPSIA_INTERVAL);
        Screen('FillRect', windowHandle, WHITE)
        Screen('Flip', windowHandle);
        WaitSecs(EPILEPSIA_INTERVAL);
    end
    KbWait()
end