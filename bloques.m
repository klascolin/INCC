function bloques
% MAIN

    format long g;

    % constantes
    USE_FULLSCREEN = 1;
    USE_WINDOWED = 0;
    % /constantes

    try
        InitPTB(USE_WINDOWED)

        % bloque 1
        % el sujeto  solamente ve imagen

        %IMAGEN BIENVENIDA BLOQUE UNO MAS INSTRUCCIONES
        %BLOQUE PRACTICA
        %FIJACION
        img = 1
        snd = 0
        delay = 0
        target = 1
        Tap(delay, img, snd, target, 5)
        %FIN BLOQUE UNO

        % bloque 2
        % el sujeto  solamente ve sondio
        img = 0
        snd = 1
        delay = 0
        target = 0
        Tap(delay, img, snd, target, 5)

        % bloque 3
        % el sujeto ve imagen y sonido sincronizado
        img = 1
        snd = 1
        delay = 0
        target = 1 % no importa
        Tap(delay, img, snd, target, 5)

        % bloque 4
        % el sujeto ve imagen y sonido + 0.25, sigue a la imagen
        img = 1
        snd = 1
        delay = 0.25
        target = 1
        Tap(delay, img, snd, target, 5)

        % bloque 5
        % el sujeto ve imagen y sonido + 0.5, sigue a la imagen
        img = 1
        snd = 1
        delay = 0.5
        target = 1
        Tap(delay, img, snd, target, 5)

        % bloque 6
        % el sujeto ve imagen y sonido + 0.75, sigue a la imagen
        img = 1
        snd = 1
        delay = 0.75
        target = 1
        Tap(delay, img, snd, target, 5)

        % bloque 7
        % el sujeto ve imagen y sonido -0.25 , sigue al sonido
        img = 1
        snd = 1
        delay = 0.25
        target = 0
        Tap(delay, img, snd, target, 5)

        % bloque 8
        % el sujeto ve imagen y sonido -0.5 , sigue al sonido
        img = 1
        snd = 1
        delay = 0.5
        target = 0
        Tap(delay, img, snd, target, 5)

        % bloque 9
        % el sujeto ve imagen y sonido -0.75 , sigue al sonido
        img = 1
        snd = 1
        delay = 0.75
        target = 0
        Tap(delay, img, snd, target, 5)


        CleanupPTB();
    % This "catch" section executes in case of an error in the "try" section
    % above.  Importantly, it closes the onscreen window if it's open.
    catch
        psychrethrow(psychlasterror);
        CleanupPTB();
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
    global SND;

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
