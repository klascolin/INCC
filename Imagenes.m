function Imagenes

    global oldVisualDebugLevel;
    global oldSupressAllWarnings;
    global audioHandle;

    % Parameters definitions

    TOTAL_TRIALS = 3;
    IMG_NUMBER = 3;
    SND_NUMBER = 2;

    % tiempo (regular) entre estÃ­mulos, en segundos
    INTERVAL = 0.5;

    % diferencia entre img y sonido, en segundos
    %    si = 0 sincronizados
    %    si > 0 sonido despues
    %    si < 0 sonido antes
    DELAY = 0.2;

    % define si el sujeto deberia seguir la imagen o el sonido.
    %   1 == si, seguir la imagen
    %   2 == no, seguir el sonido
    TARGET_IS_IMAGE = 1;

    % usar imagen / sonido
    IMG = 0;
    SND = 1;

    if ~IMG && ~SND
        fprintf('\nERROR: O bien IMG va en 1 o SND va en 1!!\n')
        quit
    end
    if TARGET_IS_IMAGE && ~IMG
        fprintf('\nERROR: IMG vale 0 (no usar imagenes) y el target es IMG (TARGET_IS_IMAGE == 1). AsÃ­ no tendrÃ­a mucho sentido.\n')
        quit
    end
    if ~TARGET_IS_IMAGE && ~SND
        fprintf('\nERROR: SND vale 0 (no usar imagenes) y el target es SND (TARGET_IS_IMAGE == 0). AsÃ­ no tendrÃ­a mucho sentido.\n')
        quit
    end
    if (IMG ~= SND) && (DELAY ~= 0)
        DELAY = 0
        fprintf('\nINFO: El delay entre sonido e imagenes no era 0, pero como no se estan usando ambas se cambia a 0\n')
    end

    FULLSCREEN = 0;
    
    KbName('UnifyKeyNames');

    try
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
        GREY = GrayIndex(screenNumber);

        % Open a double buffered fullscreen window and draw a gray background
        % and front and back buffers.
        if FULLSCREEN
            windowSize = [];
        else
            windowSize = [100 100 900 900];
        end

        [w, wRect] = Screen('OpenWindow',screenNumber, 0, windowSize, 32, 2);
        [wcx, wcy] = RectCenter(wRect);

        % Import image and and convert it, stored in
        % MATLAB matrix, into a Psychtoolbox OpenGL texture using 'MakeTexture';
        imdata = cell(1, IMG_NUMBER);
        imagetex = cell(1, IMG_NUMBER);
        iRect = cell(1, IMG_NUMBER);
        iCenter = cell(1, IMG_NUMBER);
        for i = 1:IMG_NUMBER
            imdata{i} = imread(['col' sprintf('%d', i) '.jpg']);
            imagetex{i} = Screen('MakeTexture', w, imdata{i});
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
        Screen('FillRect', w, uint8(BLACK));
        Screen('Flip', w);

        % Bump priority for speed
        priorityLevel = MaxPriority(w);
        Priority(priorityLevel);

        i = 1;
        quitKeyCode = 10; % escape
        if IsWin
            tapKeyCode = KbName('SPACE'); % barra espaciadora
        else
            tapKeyCode = 66; % anda en los labos y en octave
        end

        time_samples = [];
        remaining_trials = TOTAL_TRIALS;

        img_before_sound = DELAY > 0;
        delay = abs(DELAY);

        KbQueueCreate();
        KbQueueStart();

        % paint it white
        Screen('FillRect', w, WHITE)
        Screen('Flip', w);

        %%% THE TRIALS BEGIN %%%

        while (remaining_trials > 0)
            Screen('FillRect', w, WHITE)
            % Useful info for user about how to quit.
            % Screen('DrawText', w, 'Bienvenido! Para marcar el final usa la barra espaciadora. Esc para salir', 32, 32, BLACK);

            if IMG && img_before_sound
                Screen('DrawTexture', w, imagetex{i}, iRect{i});
                Screen('Flip', w);
                img_time = GetSecs();
                WaitSecs(delay);
            end
            if SND
                PsychPortAudio('FillBuffer', audioHandle, wavedata{1 + (i == IMG_NUMBER)});
                PsychPortAudio('Start', audioHandle, 1, 0, 1);
                snd_time = GetSecs();
            end
            if IMG && ~img_before_sound
                WaitSecs(delay);
                Screen('DrawTexture', w, imagetex{i}, iRect{i});
                Screen('Flip', w);
                img_time = GetSecs();
            end


            WaitSecs(INTERVAL - delay);

            [pressed, firstPressTimes, firstReleaseTimes, lastPressTimes, lastReleaseTimes] = KbQueueCheck();
            index_pressed = find(firstPressTimes);

            if pressed && find(index_pressed) == quitKeyCode % alguna de las teclas apretadas fue la de salir
                CleanupPTB();
                quit;
            end

            if i == IMG_NUMBER
                % Ya se mostro la imagen final.
                if TARGET_IS_IMAGE
                    target_time = img_time;
                else
                    target_time = snd_time;
                end

                if (pressed ... % se apreto algo
                   && index_pressed == tapKeyCode ...% se apreto la barra
                   && length(index_pressed) == 1 ... % se apreto solamente una tecla (la barra)
                   && firsPtressTimes(tapKeyCode) == lastPressTimes(tapKeyCode) ... % se apreto una sola vez (la primera y ultima vez son la misma)
                   ) % Trial valido
                    remaining_trials = remaining_trials - 1;

% Capaz conviene normalizar esto con el intervalo entre estÃ­mulos?
% o sea en vez de poner el delta en segundos... quedaria que si esto vale -1 significa
% que se apreto la teclajusto cuando aparecio el estimulo anterior
                    time_samples(TOTAL_TRIALS - remaining_trials) = firstPressTimes(tapKeyCode) - target_time;
                end

                KbQueueFlush();
            end

            i = mod(i, IMG_NUMBER) + 1;
        end

        % Show results on console
        disp('')
        disp('Showing samples obtained on this run:');
        disp(time_samples)
        disp('Showing mean obtained on this run:');
        run_mean = mean(time_samples)
        disp('Showing var obtained on this run:');
        run_var = var(time_samples)

        CleanupPTB();

    % This "catch" section executes in case of an error in the "try" section
    % above.  Importantly, it closes the onscreen window if it's open.
    catch
        CleanupPTB();
        psychrethrow(psychlasterror);
    end

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
