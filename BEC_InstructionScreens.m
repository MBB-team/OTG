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
                [keyIsDown, ~, keyCode, ~] = KbCheck(-1); 
                %keyIsDown returns 1 while a key is pressed
                %keyCode is a logical for all keys of the keyboard
                if keyIsDown %Check if key press is valid
                    if keyCode(leftKey) %previous slide
                        slide = slide-1; valid = 1;
                        if slide < 1; slide = 1; end %Can't go further back than first slide.
                    elseif keyCode(rightKey) %next slide
                        slide = slide+1; valid = 1;
                    elseif keyCode(spacebar) %next slide
                        slide = slide+1; valid = 1;
                    elseif keyCode(escapeKey) %Proceed to exit in master
                        exitflag = 1; valid = 1; slide = 99;
                    end
                end
            end %while ~valid
    end %while slide
end