
function Tap(delay, img, snd, target, total_trials, practica)

    global audioHandle;
    global windowHandle;
    global SND;
    global BLACK;
    global IMG_NUMBER;

    global imagetex;
    global iRect;
    global iCenter;
    global wavedata;

    global sujeto;

    % Parameters definitions
    TOTAL_TRIALS = total_trials;

    % tiempo (regular) entre estimulos, en segundos
    INTERVAL = 0.50;

    % diferencia entre img y sonido, en segundos
    %    si = 0 sincronizados
    %    si > 0 sonido despues
    %    si < 0 sonido antes
    DELAY = delay;

    % define si el sujeto deberia seguir la imagen o el sonido.
    %   1 == si, seguir la imagen
    %   0 == no, seguir el sonido
    TARGET_IS_IMAGE = target;

    % usar imagen / sonido
    IMG = img;
    SND = snd;

    if ~IMG && ~SND
        error('\nERROR: O bien IMG va en 1 o SND va en 1!!\n')
    end
    if TARGET_IS_IMAGE && ~IMG
        error('\nERROR: IMG vale 0 (no usar imagenes) y el target es IMG (TARGET_IS_IMAGE == 1). Asi no tendria mucho sentido.\n')
    end
    if ~TARGET_IS_IMAGE && ~SND
        error('\nERROR: SND vale 0 (no usar imagenes) y el target es SND (TARGET_IS_IMAGE == 0). Asi no tendria mucho sentido.\n')
    end
    if (IMG ~= SND) && (DELAY ~= 0)
        DELAY = 0
        fprintf('\nINFO: El delay entre sonido e imagenes no era 0, pero como no se estan usando ambas se cambia a 0\n')
    end
    i = 1;
    quitKeyCode = 10; % escape
    if IsWin
        tapKeyCode = KbName('SPACE'); % barra espaciadora
    else
        tapKeyCode = 66; % anda en los labos y en octave
    end

    time_firstPress = [];
    remaining_trials = TOTAL_TRIALS;

    img_before_sound = DELAY > 0;
    delay = abs(DELAY);

    KbQueueCreate();
    KbQueueStart();

    % paint it white
    Screen('FillRect', windowHandle, BLACK)
    Screen('Flip', windowHandle);

    %%% THE TRIALS BEGIN %%%

    while (remaining_trials > 0)

        Screen('FillRect', windowHandle, BLACK)

        if IMG && img_before_sound
            Screen('DrawTexture', windowHandle, imagetex{i}, iRect{i});
            Screen('Flip', windowHandle);
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
            Screen('DrawTexture', windowHandle, imagetex{i}, iRect{i});
            Screen('Flip', windowHandle);
            img_time = GetSecs();
        end


        WaitSecs(INTERVAL - delay);

        if i == IMG_NUMBER
            % Ya se mostro la imagen final.
            remaining_trials = remaining_trials - 1;
            if TARGET_IS_IMAGE
                target_time(TOTAL_TRIALS-remaining_trials) = img_time;
            else
                target_time(TOTAL_TRIALS-remaining_trials) = snd_time;
            end

            [pressed, firstPressTimes, firstReleaseTimes, lastPressTimes, lastReleaseTimes] = KbQueueCheck();
            index_pressed = find(firstPressTimes);

            if pressed && firstPressTimes(quitKeyCode) % alguna de las teclas apretadas fue la de salir
                error('Se apreto ESC, saliendo');
            end

            if (pressed && firstPressTimes(tapKeyCode) ~= 0) % se apreto la barra
                % Trial valido
                first_press = firstPressTimes(tapKeyCode);
                last_press = lastPressTimes(tapKeyCode);
            else 
                % Trial invalido
                first_press = -1;
                last_press = -1;
            end

            time_firstPress(TOTAL_TRIALS - remaining_trials) = first_press;
            time_lastPress(TOTAL_TRIALS - remaining_trials) = last_press;

            KbQueueFlush();
        end

        i = mod(i, IMG_NUMBER) + 1;

    end

    tiempo = GetSecs();

    f = fopen('data/bloques.csv', 'a');

    fprintf(f, '%i,', sujeto);
    
    fprintf(f, '%f,', tiempo);

    fprintf(f, '%i,', practica);
    fprintf(f, '%f,', delay);
    fprintf(f, '%i,', img);
    fprintf(f, '%i,', snd);
    fprintf(f, '%i,', target);
    fprintf(f, '%i,', total_trials);

    fprintf(f, '%f:', target_time);
    fprintf(f, ',');
    fprintf(f, '%f:', time_firstPress);
    fprintf(f, ',');
    fprintf(f, '%f:', time_lastPress);
    fprintf(f, ',');
    fprintf(f, '\n');

    fclose(f);

end
