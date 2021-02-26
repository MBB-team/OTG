function [exitflag,timestamp] = BEC_Washout(window,AllData)

% Settings
    exp_settings = AllData.exp_settings;   

% Washout instruction text on screen
    Screen('FillRect',window,exp_settings.backgrounds.default);
    Screen('TextSize',window,exp_settings.font.EmoFontSize);
    text = 'Détendez-vous et videz votre esprit en attendant le prochain essai...';
    DrawFormattedText(window,text,'center','center',exp_settings.font.EmoFontColor);
    timestamp = Screen('Flip',window);
    
%Wait until time has expired or Escape is pressed
    exitflag = 0;
    escapeKey = KbName('ESCAPE'); %27
    [~, ~, keyCode, ~] = KbCheck(-1); 
    while keyCode(escapeKey) == 0 && GetSecs-timestamp < exp_settings.timings.washout
        [~, ~, keyCode, ~] = KbCheck(-1); 
    end
    if keyCode(escapeKey) %Proceed to exit in master
        exitflag = 1;
    end
    
end
    