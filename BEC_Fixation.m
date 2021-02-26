function [exitflag,timestamp] = BEC_Fixation(window,exp_settings,time)

%Put fixation cross on screen
    Screen('FillRect',window,exp_settings.backgrounds.fixation);
    Screen('TextSize',window,exp_settings.font.FixationFontSize);
    DrawFormattedText(window,'+','center','center',exp_settings.font.FixationFontColor); 
    timestamp = Screen('Flip',window);
    
%Wait until time has expired or Escape is pressed
    exitflag = 0;
    escapeKey = KbName('ESCAPE'); %27
    [~, ~, keyCode, ~] = KbCheck(-1); 
    while keyCode(escapeKey) == 0 && GetSecs-timestamp < time
        [~, ~, keyCode, ~] = KbCheck(-1); 
    end
    if keyCode(escapeKey) %Proceed to exit in master
        exitflag = 1;
    end
    
end
    