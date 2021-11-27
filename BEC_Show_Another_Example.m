%% BEC_Show_Another_Example
function [left_or_right,timings] = BEC_Show_Another_Example(window,AllData,which_instruction)
% Function similar to "BEC_InstructionScreens". Puts one slide on screen asking whether the participant wants to see 
% another example (left) or proceed (right). Also functional with touchscreen!

    %Prepare
        exp_settings = AllData.exp_settings;
        if isa(which_instruction,'char') %When the instruction topic is entered as a string
            slide = exp_settings.instructions_emotions.(which_instruction); %Get slides
        else %When the slide numbers are directly entered
            slide = which_instruction;
        end
        Screen('FillRect',window,exp_settings.backgrounds.default);
    %Valid key names
        leftKey     = KbName('LeftArrow'); %37
        rightKey    = KbName('RightArrow'); %39
        escapeKey   = KbName('ESCAPE'); %27
        LRQ = [leftKey rightKey escapeKey];  % join keys 
    %Scaling of the slide
        [width, height]=Screen('WindowSize',window);
        SF = 1;   %Scaling factor w.r.t. full screen
        sliderect = ((1-SF)/2+[0 0 SF SF]).*[width height width height];            
    %Instruction slide on screen
        KbReleaseWait;  % Wait for all keys to be released before drawing
        try
            im_instruction = imread([exp_settings.stimdir filesep 'Diapositive' num2str(slide) '.png']);
        catch
            im_instruction = imread([exp_settings.stimdir filesep 'Slide' num2str(slide) '.png']);
        end
        tex_instruction = Screen('MakeTexture',window,im_instruction);
        Screen('DrawTexture', window, tex_instruction, [], sliderect);
        timestamp = Screen('Flip', window);
        timings = BEC_Timekeeping('InstructionScreen',AllData.plugins,timestamp);
    %Monitor responses
        valid = 0;
        while ~valid
            %Monitor response
                %Tactile screen AND keyboard
                    if isfield(AllData,'plugins') && isfield(AllData.plugins,'touchscreen') && AllData.plugins.touchscreen == 1 %Record swipes
                        [keyCode] = SwipeTouchscreen(window,LRQ);
                        keyIsDown = true;
                %Keyboard
                    else
                        [keyIsDown, ~, keyCode, ~] = KbCheck(-1); 
                        %keyIsDown returns 1 while a key is pressed
                        %keyCode is a logical for all keys of the keyboard
                    end            
            %Interpret response
                if keyIsDown %Check if key press is valid
                    if keyCode(leftKey) %previous slide
                        left_or_right = 'left'; valid = 1;
                    elseif keyCode(rightKey) %next slide
                        left_or_right = 'right'; valid = 1;
                    elseif keyCode(escapeKey) %Proceed to exit in master
                        left_or_right = 'escape'; valid = 1;
                    end
                end
        end %while ~valid
    %Animate slide transition
        if any(strcmp(left_or_right,{'left','right'}))
            offscreen = 0;
            loop_sliderect = sliderect;
            iter = 0; n_iter = 10;
            while ~offscreen
                switch left_or_right
                    case 'left'
                        loop_sliderect = loop_sliderect + (sliderect(3)-sliderect(1))/n_iter*[1 0 1 0];
                    case 'right'
                        loop_sliderect = loop_sliderect - (sliderect(3)-sliderect(1))/n_iter*[1 0 1 0];
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
end

%% Subfunction: monitor swipes with MS Surface tactile screen
function [keyCode] = SwipeTouchscreen(window,LRQ)
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
            if any(keyCode(LRQ)) %left/right/quit key is pressed
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
                        if delta_x < 0 %left swipe (go to right)
                            keyCode(LRQ(2)) = true;
                        elseif delta_x > 0 %right swipe (go to left)
                            keyCode(LRQ(1)) = true;
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