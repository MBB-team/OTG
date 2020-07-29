function [exitflag] = BEC_Fixation(window,exp_settings,time)

    Screen('FillRect',window,exp_settings.backgrounds.fixation);
    Screen('TextSize',window,exp_settings.font.FixationFontSize);
    DrawFormattedText(window,'+','center','center',exp_settings.font.FixationFontColor); 
    Screen('Flip',window);
    pause(time)
    
    %For bailout: press excape key until the end of the required fixation time
        exitflag = 0;
        escapeKey   = KbName('ESCAPE'); %27
        [keyIsDown, ~, keyCode, ~] = KbCheck(-1); 
        if keyIsDown %Check if key press is valid
            if keyCode(escapeKey) %Proceed to exit in master
                exitflag = 1;
            end
        end
end
    