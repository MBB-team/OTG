function BEC_Washout(window,AllData)

% Settings
    exp_settings = AllData.exp_settings;
    
% Eyetracker marker (TO DO!)
    if AllData.pupil
        S10_Exp_PhysiologyMark(AllData,'washout')
    end

% Washout instruction text on screen
    Screen('FillRect',window,exp_settings.backgrounds.default);
    Screen('TextSize',window,exp_settings.font.EmoFontSize);
    Screen('TextFont',window,exp_settings.font.FontType);
    text = 'Détendez-vous et videz votre esprit en attendant le prochain essai...';
    DrawFormattedText(window,text,'center','center',exp_settings.font.EmoFontColor);
    Screen('Flip',window);
    pause(exp_settings.timings.washout)
    
end
    