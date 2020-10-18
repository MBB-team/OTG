function BEC_ShowFeedback(window,AllData,feedback)
% Give quiz question feedback: correct/incorrect/too late response

    %Settings
        exp_settings = AllData.exp_settings;
        if ~isfield(AllData,'triallist'); is_example = 1; %this is an example trial
        else; is_example = 0; %this is a trial from the main experiment
        end
    %Prepare screen
        Screen('TextSize',window,exp_settings.font.FeedbackFontSize);  
        Screen('TextFont',window,exp_settings.font.FontType);
        Screen('FillRect',window,exp_settings.backgrounds.mood);
        [Xsize, Ysize] = Screen('WindowSize', window);
    %Prepare feedback
        switch feedback
            case 1 %Correct response (green)
                text = 'Bonne réponse ! ! !';
                soundfile = 'success.wav';
                color = exp_settings.colors.green;
            case 0 %Incorrect response (red)
                text = 'Mauvaise réponse ! ! !';
                soundfile = 'fail.wav';
                color = exp_settings.colors.red;
            case -1 %Too late (red)
                text = 'Trop tard, répondez plus vite !';
                soundfile = 'fail.wav';
                color = exp_settings.colors.red;
        end
    %Write text
        DrawFormattedText(window,text,'center',exp_settings.Moodstimuli.feedback_y(1)*Ysize,color);
        DrawFormattedText(window,text,'center',exp_settings.Moodstimuli.feedback_y(2)*Ysize,color);
    %Draw emoji
        radius1 = Ysize/6;  %Default: emoji size is 1/3 of Ysize
        pensize = 20;       %Default: emjoi line thickness is 20 pt
        radius2 = radius1/10; %Eyes
        radius3 = radius1/2;  %Mouth
        %Face contour
            emojirect = [Xsize/2-radius1 Ysize/2-radius1 Xsize/2+radius1 Ysize/2+radius1];  
            Screen('FrameOval', window, color, emojirect, pensize, pensize);
        %Eyes
            eyesrect = [Xsize/2 - radius1/3 - radius2, Xsize/2 + radius1/3 - radius2;
                        Ysize/2 - radius1/3 - radius2, Ysize/2 - radius1/3 - radius2; 
                        Xsize/2 - radius1/3 + radius2, Xsize/2 + radius1/3 + radius2; 
                        Ysize/2 - radius1/3 + radius2, Ysize/2 - radius1/3 + radius2]; 
            Screen('FillOval', window, color, eyesrect);
        %Mouth
            if feedback == 1 %Positive
                smilerect = [Xsize/2-radius3 Ysize/2-2/3*radius3 Xsize/2+radius3 Ysize/2+4/3*radius3];  
                Screen('FrameArc',window,color,smilerect,90,180,pensize);
            else
                poutrect = [Xsize/2-radius3 Ysize/2 Xsize/2+radius3 Ysize/2+2*radius3];  
                Screen('FrameArc',window,color,poutrect,270,180,pensize);
            end          
    %Draw on screen
        Screen('Flip',window);
    %Pupil mark -- TO DO
%         if AllData.pupil && ~is_example
%             S10_Exp_PhysiologyMark(AllData,'quiz_feedback')
%         end
    %Play sound
        [audio, FS] = audioread([exp_settings.stimdir filesep soundfile]); %Read sound file
        player = audioplayer(audio, FS); %,16,ID); %nBits = 16 by default, volume = 1 by default.
        play(player); %Play the player object once        
    %Wait and exit
        WaitSecs(exp_settings.timings.show_feedback);
        Screen('Close');
end