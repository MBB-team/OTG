% This function is part of the OTG toolbox, used for generating and presenting a battery of economic choices.
% It is a convenience function  for experiments on a tactile screen: a screen appears and asks for confirmation after the [X] escape cross is pressed 
% during the experiment. The user replies 'yes' (terminate experiment) or 'no' (don't terminate).

function [Escape_experiment] = BEC_Tactile_EscapeScreen(exp_settings,window)

%% "Are you sure you want to quit"-window
% Set the quit text here:
    quit_text = 'Êtes-vous sur.e de vouloir quitter l''expérience?';

% Open window
    [Xsize, Ysize]=Screen('WindowSize',window); %Get current screen size
    newWindowRect = [0.25*Xsize 0.25*Ysize 0.75*Xsize 0.75*Ysize]; %Rect for the new window
    [window2,winRect2] = Screen('OpenWindow',0,exp_settings.colors.grey,newWindowRect); %0 for Windows Desktop screen

% Draw text on new window
    Screen('TextSize',window2,exp_settings.tactile.QuitScreenFontSize); %Careful to set the text size back to what it was before
    DrawFormattedText(window2, quit_text, 'center', 1/3*winRect2(4), exp_settings.colors.white);
    
% Draw buttons
    buttons = [1/8*winRect2(3) 0.75*winRect2(4) 3/8*winRect2(3) 0.9*winRect2(4);
        5/8*winRect2(3) 0.75*winRect2(4) 7/8*winRect2(3) 0.9*winRect2(4)]';
    Screen('FillRect',window2,exp_settings.colors.black,buttons);
    Screen('TextSize',window,round(exp_settings.tactile.QuitScreenFontSize)); %The word "OK" is written slightly smaller
    DrawFormattedText(window2, 'OUI', 'center', 'center', exp_settings.colors.white, [], [], [], [], [], buttons(:,1)');
    DrawFormattedText(window2, 'NON', 'center', 'center', exp_settings.colors.white, [], [], [], [], [], buttons(:,2)');
    
% Flip
    Screen('Flip',window2);
    
% Monitor response
    SetMouse(winRect2(3)/2,winRect2(4)/2);
    answer = [];
    while isempty(answer)
        [x,y,pressed] = GetMouse(window2);
        if ~any(pressed) %detect release after initial touch
            if x >= buttons(1,1) && x <= buttons(3,1) && y >= buttons(2,1) && y <= buttons(4,1) % "OUI" is pressed
                answer = true;
            elseif x >= buttons(1,2) && x <= buttons(3,2) && y >= buttons(2,2) && y <= buttons(4,2) % "NON" is pressed
                answer = false;
            end
        end
    end
    
% Close screen and return answer
    Screen('Close',window2)
    Escape_experiment = answer;
end