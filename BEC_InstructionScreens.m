function [exitflag,timings] = BEC_InstructionScreens(window,AllData,which_instruction)
% Enter the slides to put on screen. Wait for the space bar or right arrow 
% to be pressed in order to move on to the next slide, or left arrow to return to previous slide.

%Prepare
    exp_settings = AllData.exp_settings;
    if isa(which_instruction,'char') %When the instruction topic is entered as a string
        try
            slides = exp_settings.instructions_emotions.(which_instruction); %Get slides
        catch
            slides = exp_settings.instructions_moods.(which_instruction); %Get slides
        end
    else %When the slide numbers are directly entered
        slides = which_instruction;
    end
    Screen('FillRect',window,exp_settings.backgrounds.default);
    exitflag = 0;
    %Valid key names
        leftKey     = KbName('LeftArrow'); %37
        rightKey    = KbName('RightArrow'); %39
        spacebar    = KbName('space'); %32
        escapeKey   = KbName('ESCAPE'); %27
        LRQS = [leftKey rightKey escapeKey spacebar];  % join keys 
    %Scaling of the slides
        [width, height]=Screen('WindowSize',window);
        SF = 1;   %Scaling factor w.r.t. full screen
        sliderect = ((1-SF)/2+[0 0 SF SF]).*[width height width height];
            
%Loop through slides
    slide = 1; %start slide
    while slide <= length(slides)
        %Instruction slide on screen
            KbReleaseWait;  % Wait for all keys to be released before drawing
            try
                im_instruction = imread([exp_settings.stimdir filesep 'Diapositive' num2str(slides(slide)) '.png']);
            catch
                im_instruction = imread([exp_settings.stimdir filesep 'Slide' num2str(slides(slide)) '.png']);
            end
            tex_instruction = Screen('MakeTexture',window,im_instruction);
            Screen('DrawTexture', window, tex_instruction, [], sliderect);
            timestamp = Screen('Flip', window);
            if slide == 1
                timings = BEC_Timekeeping('InstructionScreen',AllData.plugins,timestamp);
            else
                timings = [timings BEC_Timekeeping('InstructionScreen',AllData.plugins,timestamp)]; %#ok<AGROW>
            end
        %Monitor responses
            valid = 0;
            while ~valid
                %Tactile screen AND keyboard
                    if isfield(AllData,'plugins') && isfield(AllData.plugins,'touchscreen') && AllData.plugins.touchscreen == 1 %Record swipes
                        [keyCode] = SwipeTouchscreen(window,LRQS);
                        keyIsDown = true;
                %Keyboard
                    else
                        [keyIsDown, ~, keyCode, ~] = KbCheck(-1); 
                        %keyIsDown returns 1 while a key is pressed
                        %keyCode is a logical for all keys of the keyboard
                    end
                %Interpret result
                    if keyIsDown %Check if key press is valid
                        if keyCode(leftKey) %previous slide
                            slide = slide-1; valid = 1;
                            if slide < 1; slide = 1; end %Can't go further back than first slide.
                            which_slide = 'previous';
                        elseif keyCode(rightKey) %next slide
                            slide = slide+1; valid = 1;
                            which_slide = 'next';
                        elseif keyCode(spacebar) %next slide
                            slide = slide+1; valid = 1;
                            which_slide = 'next';
                        elseif keyCode(escapeKey) %Proceed to exit in master
                            exitflag = 1; valid = 1; slide = 99;
                            which_slide = 'escape';
                        end
                    end                    
            end %while ~valid
        %Animate slide transition
            if any(strcmp(which_slide,{'next','previous'}))
                offscreen = 0;
                loop_sliderect = sliderect;
                iter = 0; n_iter = 10;
                while ~offscreen
                    switch which_slide
                        case 'next'
                            loop_sliderect = loop_sliderect - (sliderect(3)-sliderect(1))/n_iter*[1 0 1 0];
                        case 'previous'
                            loop_sliderect = loop_sliderect + (sliderect(3)-sliderect(1))/n_iter*[1 0 1 0];
                    end
                    Screen('DrawTexture', window, tex_instruction, [], loop_sliderect);
                    Screen('Flip', window);
                    pause(0.03);
                    iter = iter+1;
                    if iter == n_iter
                        offscreen = 1;
                    end
                end
            end %if strcmp next/previous
    end %while slide
end

%% Subfunction: monitor swipes with MS Surface tactile screen
function [keyCode] = SwipeTouchscreen(window,LRQS)
% Monitor whether a swipe is being made on a tactile screen
% The subfunction outputs a response as if it were a left or right key press.
% To do: - account for key presses if a keyboard is plugged in.
%        - terminate by pressing [X]   

%Setting: minimal swipeable distance
    min_dist_pct = 0.05; %5% of the screen
    [screenX, ~] = Screen('WindowSize',window); %Get screen size
    min_dist_pix = min_dist_pct*screenX;

%Pre-loop check: finger released from screen
    [~,~,buttons] = GetMouse;
    while any(buttons)
        [~,~,buttons] = GetMouse;
    end
%Loop until swipe is detected
    first_x = [];
    last_x = [];
    swiped = false;
    while ~swiped
        %Monitor keypresses, in case keyboard is plugged in
            [~, ~, keyCode] = KbCheck(-1);
            if any(keyCode(LRQS)) %left/right/quit/spacebar key is pressed
                return
            end
        %Check for swipes
            [x,~,pressed] = GetMouse;
            if any(pressed)
                if isempty(first_x)
                    first_x = x;
                end
                last_x = x;
        %Check for release
            else %unpressed
                if ~isempty(first_x) && ~isempty(last_x) %detect release after initial touch
                    delta_x = last_x - first_x;
                    if abs(delta_x) > min_dist_pix %valid swipe
                        swiped = true;
                        if delta_x < 0 %right swipe
                            keyCode(LRQS(2)) = true;
                        elseif delta_x > 0 %left swipe
                            keyCode(LRQS(1)) = true;
                        end
                    else %not a valid swipe => reset
                        swiped = false;
                        first_x = [];
                        last_x = [];
                    end
                end
            end %if pressed
    end %while               
end %function