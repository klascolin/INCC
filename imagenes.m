function imagenes

% Parameters definitions

TOTAL_TRIALS = 3
IMG_NUMBER = 3
ZAPALLOFRAME = 8
INTERVAL = 0.5
TIMEOUT = 0.5

KbName('UnifyKeyNames');

try
  AssertOpenGL;
  oldVisualDebugLevel = Screen('Preference', 'VisualDebugLevel', 3);
  oldSupressAllWarnings = Screen('Preference', 'SuppressAllWarnings', 1);

  % Color definitions
  screenNumber = max(Screen('Screens'));
  WHITE = WhiteIndex(screenNumber);
  BLACK = BlackIndex(screenNumber);
  GREY = GrayIndex(screenNumber);

  % Open a double buffered fullscreen window and draw a gray background
  % and front and back buffers.
  [w, wRect] = Screen('OpenWindow',screenNumber, 0, [], 32, 2);
  [wcx, wcy] = RectCenter(wRect);

  % Import image and and convert it, stored in
  % MATLAB matrix, into a Psychtoolbox OpenGL texture using 'MakeTexture';
  imdata = cell(1, IMG_NUMBER);
  imagetex = cell(1, IMG_NUMBER);
  iRect = cell(1, IMG_NUMBER);
  iCenter = cell(1, IMG_NUMBER);

  for i = 1:IMG_NUMBER
    imdata{i} = imread([ 'col' sprintf('%d', i) '.jpg']);
    imagetex{i} = Screen('MakeTexture', w, imdata{i});
    iRect{i} = Screen('Rect', imagetex{i});
    [cx, cy] = RectCenter(iRect{i});
    iCenter{i} = [cx, cy];
  end

  % Blank sceen
  Screen('FillRect', w, uint8(BLACK));
  Screen('Flip', w);

  % Bump priority for speed
  priorityLevel = MaxPriority(w);
  Priority(priorityLevel);

  i = 1;
  escapeKey = KbName('ESCAPE');
  enterKey = KbName('SPACE');
  time_samples = []
  remaining_trials = TOTAL_TRIALS

  KbQueueCreate()
  KbQueueStart()

  %%% THE TRIALS BEGIN %%%

  while (remaining_trials > 0)

    Screen('FillRect', w, WHITE)

    % We only redraw if mouse has been moved:
    [mousex, mousey, buttons]=GetMouse(screenNumber);

    % Draw image for current frame:

    Screen('DrawTexture', w, imagetex{i}, iRect{i});%, oRect)

    % Useful info for user about how to quit.
    Screen('DrawText', w, 'Bienvenido! Para marcar el final usa la barra espaciadora. Esc para salir', 32, 32, BLACK);
    % Show result on screen:
    Screen('Flip', w);

    if i == IMG_NUMBER
      remaining_trials = remaining_trials - 1
      t_start = GetSecs()
      WaitSecs(INTERVAL)
      KbQueueStop()
      [ pressed, firstPress]=KbQueueCheck();
      %Asumo que solo se apreto una tecla en el trial y que es
      %enterkey
      if pressed
        time_samples(TOTAL_TRIALS - remaining_trials) = firstPress(find(firstPress)) - t_start
      end
      KbQueueFlush()
      KbQueueStart()
    else
      WaitSecs(INTERVAL)
    end

    i = mod(i,IMG_NUMBER)+1;

    % Break out of loop on mouse key or Scape key
    if find(buttons)
      break;
    end
  end

  % Show results on console
  disp(time_samples)
  mean(time_samples)
  var(time_samples)

  % The same command which closes onscreen and offscreen windows also
  % closes textures.
  Screen('CloseAll');
  ShowCursor;
  Priority(0);
  KbQueueRelease()

  % Restore preferences
  Screen('Preference', 'VisualDebugLevel', oldVisualDebugLevel);
  Screen('Preference', 'SuppressAllWarnings', oldSupressAllWarnings);

% This "catch" section executes in case of an error in the "try" section
% above.  Importantly, it closes the onscreen window if it's open.
catch

  Screen('CloseAll');
  ShowCursor;
  Priority(0);

  % Restore preferences
  Screen('Preference', 'VisualDebugLevel', oldVisualDebugLevel);
  Screen('Preference', 'SuppressAllWarnings', oldSupressAllWarnings);

  psychrethrow(psychlasterror);
end
