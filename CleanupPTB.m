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
