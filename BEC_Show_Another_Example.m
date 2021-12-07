%% BEC_Show_Another_Example
function [left_or_right,timings] = BEC_Show_Another_Example(window,AllData,which_instruction)
% Function similar to "BEC_InstructionScreens". Puts one slide on screen asking whether the participant wants to see 
% another example (left) or proceed (right). Also functional with touchscreen!

    %Prepare
        %Settings structure
            exp_settings = AllData.exp_settings;
        %Tactile or not?
            if isfield(AllData.exp_settings,'tactile') && isfield(AllData.exp_settings.tactile,'navigationArrows') && AllData.exp_settings.tactile.navigationArrows == true
                tactile_screen = true;
            else
                tactile_screen = false;
            end
        %Get slide numbers
            if exist('which_instruction','var') %If the slide is specified manually
                if isa(which_instruction,'char') %When the instruction topic is entered as a string
                    slide = exp_settings.instructions_emotions.(which_instruction); %Get slides
                else %When the slide numbers are directly entered
                    slide = which_instruction;
                end
            else
                %Default
                    slide = exp_settings.instructions_emotions.another_example; %Get slides
                %Tactile with arrows
                    if tactile_screen
                        slide = 11;
                    end
            end
        %Valid key names
            leftKey     = KbName('LeftArrow'); %37
            rightKey    = KbName('RightArrow'); %39
            spacebar    = KbName('space'); %32
            escapeKey   = KbName('ESCAPE'); %27
            LRQS = [leftKey rightKey escapeKey spacebar];  % join keys 
        %Scaling of the slide
            [Xsize, Ysize]=Screen('WindowSize',window);
            SF = 1;   %Scaling factor w.r.t. full screen
            sliderect = ((1-SF)/2+[0 0 SF SF]).*[Xsize Ysize Xsize Ysize];       
        %Navigation arrows (tactile screens)
            if tactile_screen && isfield(AllData.exp_settings,'tactile') && isfield(AllData.exp_settings.tactile,'navigationArrows') && AllData.exp_settings.tactile.navigationArrows == true
                tex_leftkey = Screen('MakeTexture',window,AllData.exp_settings.tactile.im_leftkey);
                tex_rightkey = Screen('MakeTexture',window,AllData.exp_settings.tactile.im_rightkey);
                navigationArrowSize = AllData.exp_settings.tactile.navigationArrows_ySize*Ysize;
                navigationArrowRects = [0.5*navigationArrowSize Ysize-1.5*navigationArrowSize 1.5*navigationArrowSize Ysize-0.5*navigationArrowSize; %Left
                                        Xsize-1.5*navigationArrowSize Ysize-1.5*navigationArrowSize Xsize-0.5*navigationArrowSize Ysize-0.5*navigationArrowSize]'; %Right
                navigationArrowTex = [tex_leftkey; tex_rightkey];
            end
    %Instruction slide on screen
        Screen('FillRect',window,exp_settings.backgrounds.default);
        KbReleaseWait;  % Wait for all keys to be released before drawing
        try
            im_instruction = imread([exp_settings.stimdir filesep 'Diapositive' num2str(slide) '.png']);
        catch
            im_instruction = imread([exp_settings.stimdir filesep 'Slide' num2str(slide) '.png']);
        end
        tex_instruction = Screen('MakeTexture',window,im_instruction);
        Screen('DrawTexture', window, tex_instruction, [], sliderect);
    %Draw escape cross (tactile screens)
        if tactile_screen && isfield(AllData.exp_settings,'tactile')
            escapeCrossSize = AllData.exp_settings.tactile.escapeCross_ySize*Ysize;
            escapeCrossRect = [Xsize-1.5*escapeCrossSize 0.5*escapeCrossSize Xsize-0.5*escapeCrossSize 1.5*escapeCrossSize];
            Screen('FillRect',window,AllData.exp_settings.colors.red,escapeCrossRect);
            Screen('TextSize',window,AllData.exp_settings.tactile.escapeCrossFontSize); %Careful to set the text size back to what it was before
            DrawFormattedText(window, 'X', 'center', 'center', AllData.exp_settings.colors.white,[],[],[],[],[],escapeCrossRect);
        end
    %Draw navigation arrows    
        if tactile_screen && isfield(AllData.exp_settings,'tactile') && isfield(AllData.exp_settings.tactile,'navigationArrows') && AllData.exp_settings.tactile.navigationArrows == true
            Screen('DrawTextures', window, navigationArrowTex, [], navigationArrowRects);
        end
    %Flip
        timestamp = Screen('Flip', window);
        timings = BEC_Timekeeping('InstructionScreen',AllData.plugins,timestamp);
    %Monitor responses
        valid = 0;
        while ~valid
            %Monitor response
                %Tactile screen AND keyboard
                    if tactile_screen %Record screen presses or swipes
                        [keyCode] = SelectOptionTouchscreen(window,exp_settings,LRQS);
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

%% Subfunction: monitor responses with tactile screen
function [keyCode] = SelectOptionTouchscreen(window,exp_settings,LRQS)
% Detect if the participant presses the left button, right button, or exit cross.
% Alternatively, the participant can swipe the the left or right

%Settings
    %Escape cross
        [Xsize, Ysize] = Screen('WindowSize',window); %Get screen size
        escapeCrossSize = exp_settings.tactile.escapeCross_ySize*Ysize;
        escapeCrossRect = [Xsize-1.5*escapeCrossSize 0.5*escapeCrossSize Xsize-0.5*escapeCrossSize 1.5*escapeCrossSize];
    %Navigation arrows
        if isfield(exp_settings,'tactile') && isfield(exp_settings.tactile,'navigationArrows') && exp_settings.tactile.navigationArrows == true
            navigationArrowSize = exp_settings.tactile.navigationArrows_ySize*Ysize;
            navigationArrowRects = [0.5*navigationArrowSize Ysize-1.5*navigationArrowSize 1.5*navigationArrowSize Ysize-0.5*escapeCrossSize; %Left
                                    Xsize-1.5*navigationArrowSize Ysize-1.5*navigationArrowSize Xsize-0.5*navigationArrowSize Ysize-0.5*escapeCrossSize]'; %Right
        end
    %Swiping
        min_dist_pct = 0.05; %5pct of the screen
        min_dist_pix = min_dist_pct*Xsize;

%Pre-loop check: finger released from screen
    [~,~,buttons] = GetMouse;
    while any(buttons)
        [~,~,buttons] = GetMouse;
    end
    swiped = false; %Swipe to left or right
    buttonpress = false; %Press left/right button, or exit cross
    first_x = [];
    x = [];
    y = [];
    finger_on_option = false(1,2);
    SetMouse(Xsize/2,Ysize/2);
    
%Loop until either option is pressed
    while ~( buttonpress || swiped )
        %Monitor keypresses, in case keyboard is plugged in
            [~, ~, keyCode] = KbCheck(-1);
            if any(keyCode(LRQS)) %left/right/quit/spacebar key is pressed
                return
            end
        %Check for swipes
            [x,y,pressed] = GetMouse;
            if any(pressed) && isempty(first_x)
                first_x = x;
            end
        %Monitor button presses
            if isfield(exp_settings,'tactile')
                %Check for exit cross press
                    press_escape = x >= escapeCrossRect(1) & x <= escapeCrossRect(3) & y >= escapeCrossRect(2) & y <= escapeCrossRect(4);
                    if press_escape
                        %Verify that the user REALLY wants to quit; otherwise, proceed.
                            escape_experiment = BEC_Tactile_EscapeScreen(exp_settings,window);
                            if escape_experiment
                                keyCode(LRQS(3)) = true;
                                buttonpress = true;
                            else
                                press_escape = false;
                            end
                    end
                %Check for navigation arrow presses
                    if ~press_escape && isfield(exp_settings.tactile,'navigationArrows') && exp_settings.tactile.navigationArrows == true
                        %Check left option
                            finger_on_option(1) = x >= navigationArrowRects(1,1) & x <= navigationArrowRects(3,1) & ...
                                y >= navigationArrowRects(2,1) & y <= navigationArrowRects(4,1);
                        %Check right option
                            finger_on_option(2) = x >= navigationArrowRects(1,2) & x <= navigationArrowRects(3,2) & ...
                                y >= navigationArrowRects(2,2) & y <= navigationArrowRects(4,2);
                        %Rule out possibility of tapping onto both options
                            if all(finger_on_option)
                                finger_on_option = false(1,2);
                            end
                        %Check if valid response is given
                            if any(finger_on_option)
                                buttonpress = true;
                                if finger_on_option(1)
                                    keyCode(LRQS(1)) = true;
                                elseif finger_on_option(2)
                                    keyCode(LRQS(2)) = true;
                                end                                            
                    end %if isfield exp_settings.tactile.navigationArrows                                
            end %if isfield exp_settings.tactile
        %Check for swipes
            if ~isempty(first_x) && ~isempty(x) %detect release after initial touch
                delta_x = x - first_x;
                if abs(delta_x) > min_dist_pix %valid swipe
                    swiped = true;
                    if delta_x < 0 %right swipe
                        keyCode(LRQS(2)) = true;
                    elseif delta_x > 0 %left swipe
                        keyCode(LRQS(1)) = true;
                    end
                else %not a valid swipe                               
                    first_x = [];                                
                end %any finger_on_option
            end %if released after press
        end %isfield
    end %while
end %subfunction