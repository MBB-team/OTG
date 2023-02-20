% This function is part of the OTG toolbox, used for generating and presenting a battery of economic choices.
% It is a convenience function ot present slides on screen (e.g. instructions).

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
        [Xsize, Ysize]=Screen('WindowSize',window);
        SF = 1;   %Scaling factor w.r.t. full screen
        sliderect = ((1-SF)/2+[0 0 SF SF]).*[Xsize Ysize Xsize Ysize];
    %Navigation arrows (tactile screens)
        if isfield(AllData.exp_settings,'tactile') && isfield(AllData.exp_settings.tactile,'navigationArrows') && AllData.exp_settings.tactile.navigationArrows == true
            tex_leftkey = Screen('MakeTexture',window,AllData.exp_settings.tactile.im_leftkey);
            tex_rightkey = Screen('MakeTexture',window,AllData.exp_settings.tactile.im_rightkey);
            navigationArrowSize = AllData.exp_settings.tactile.navigationArrows_ySize*Ysize;
            navigationArrowRects = [0.5*navigationArrowSize Ysize-1.5*navigationArrowSize 1.5*navigationArrowSize Ysize-0.5*navigationArrowSize; %Left
                                    Xsize-1.5*navigationArrowSize Ysize-1.5*navigationArrowSize Xsize-0.5*navigationArrowSize Ysize-0.5*navigationArrowSize]'; %Right
            navigationArrowTex = [tex_leftkey; tex_rightkey];
        end
            
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
        %Tactile screen features
            if isfield(AllData,'plugins') && isfield(AllData.plugins,'touchscreen') && AllData.plugins.touchscreen == true
                %Draw escape cross
                    if isfield(AllData.exp_settings,'tactile')
                        escapeCrossSize = AllData.exp_settings.tactile.escapeCross_ySize*Ysize;
                        escapeCrossRect = [Xsize-1.5*escapeCrossSize 0.5*escapeCrossSize Xsize-0.5*escapeCrossSize 1.5*escapeCrossSize];
                        Screen('FillRect',window,AllData.exp_settings.colors.red,escapeCrossRect);
                        Screen('TextSize',window,AllData.exp_settings.tactile.escapeCrossFontSize); %Careful to set the text size back to what it was before
                        DrawFormattedText(window, 'X', 'center', 'center', AllData.exp_settings.colors.white,[],[],[],[],[],escapeCrossRect);
                    end
                %Draw navigation arrows    
                    if isfield(AllData.exp_settings,'tactile') && isfield(AllData.exp_settings.tactile,'navigationArrows') && AllData.exp_settings.tactile.navigationArrows == true
                        %Decide which arrow to draw
                            if slide == 1
                                which_arrow = 'right'; %Can only move on                            
                            else %Can go back or forth
                                which_arrow = 'both';
                            end
                        %Draw arrow(s)
                            switch which_arrow
                                case 'right'
                                    arrowrect = navigationArrowRects(:,2);
                                    arrowtex = navigationArrowTex(2);
                                case 'both'
                                    arrowrect = navigationArrowRects;
                                    arrowtex = navigationArrowTex;
                            end
                            Screen('DrawTextures', window, arrowtex, [], arrowrect);
                    end
            end %if touchscreen
        %Flip
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
                        [keyCode] = SelectOptionTouchscreen(window,exp_settings,LRQS);
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
end %main function

%% Subfunction: monitor responses with tactile screen
function [keyCode] = SelectOptionTouchscreen(window,exp_settings,LRQS)
% Detect if the participant presses the left button, right button, or exit cross.
% Alternatively, the participant can swipe the the left or right

%Settings
    %Tactile screen features
        [Xsize, Ysize] = Screen('WindowSize',window); %Get screen size
        %Escape cross
        if isfield(exp_settings,'tactile')
            escapeCrossSize = exp_settings.tactile.escapeCross_ySize*Ysize;
            escapeCrossRect = [Xsize-1.5*escapeCrossSize 0.5*escapeCrossSize Xsize-0.5*escapeCrossSize 1.5*escapeCrossSize];
        %Navigation arrows
        if isfield(exp_settings.tactile,'navigationArrows') && exp_settings.tactile.navigationArrows == true
            navigationArrowSize = exp_settings.tactile.navigationArrows_ySize*Ysize;
            navigationArrowRects = [0.5*navigationArrowSize Ysize-1.5*navigationArrowSize 1.5*navigationArrowSize Ysize-0.5*escapeCrossSize; %Left
                                    Xsize-1.5*navigationArrowSize Ysize-1.5*navigationArrowSize Xsize-0.5*navigationArrowSize Ysize-0.5*escapeCrossSize]'; %Right
        end
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
            if isempty(first_x) && any(pressed)
                first_x = x;
            end
        %Monitor mouse positions
            if isfield(exp_settings,'tactile')
                %Press escape
                    press_escape = x >= escapeCrossRect(1) & x <= escapeCrossRect(3) & y >= escapeCrossRect(2) & y <= escapeCrossRect(4);
                    if press_escape && ~any(pressed)
                        %Verify that the user REALLY wants to quit; otherwise, proceed.
                            escape_experiment = BEC_Tactile_EscapeScreen(exp_settings,window);
                            if escape_experiment
                                keyCode(LRQS(3)) = true;
                                buttonpress = true;
                            else
                                press_escape = false;
                            end
                    end
                %Press navigation buttons
                if isfield(exp_settings.tactile,'navigationArrows') && exp_settings.tactile.navigationArrows == true
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
                    %Determine if either button is pressed
                        if ~press_escape && isfield(exp_settings.tactile,'navigationArrows') && exp_settings.tactile.navigationArrows == true
                            if any(finger_on_option) && ~any(pressed)
                                buttonpress = true;
                                if finger_on_option(1)
                                    keyCode(LRQS(1)) = true;
                                elseif finger_on_option(2)
                                    keyCode(LRQS(2)) = true;
                                end      
                            end
                        end %if isfield exp_settings.tactile.navigationArrows        
                end
            end
        %Check for swipe
            if ~isempty(first_x) && ~any(pressed) %detect release after initial touch
                delta_x = x - first_x;
                if abs(delta_x) > min_dist_pix %valid swipe
                    swiped = true;
                    if delta_x < 0 %right swipe
                        keyCode(LRQS(2)) = true;
                    elseif delta_x > 0 %left swipe
                        keyCode(LRQS(1)) = true;
                    end
                else                                            
                    first_x = [];
                end %if valid swipe / else: buttons
            end %if released after press
    end %while pressed or swiped
end %subfunction
