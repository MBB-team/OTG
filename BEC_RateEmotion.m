function [RateHappy,RateSad,RateCurious] = BEC_RateEmotion(window,AllData)
%Rate the presented stimuli along the spectrum of three emotions: happiness, sadness, curiosity

%% Prepare the screen
%Settings
    exp_settings = AllData.exp_settings;
    [screenXpixels, screenYpixels] = Screen('WindowSize', window);
    winRect = [0 0 screenXpixels screenYpixels];        
    line        = 3;    %# pixels axis thickness
    axesWidth   = 700;  %# pixels axis length
    whisLength  = 5;    %# length of the whiskers at axis end
    slider      = [0 0 10 30];  %size of the slider rectangle
    slidercolor = exp_settings.colors.orange;
    linecolor   = exp_settings.colors.white;
    RatingLabelSize = 15;
    emotions = {'Joie','Tristesse','Curiosité'}; %Cell array

%Prepare rating axes
    axes = round([...
        [winRect(3)/2-axesWidth/2 winRect(4)*9/16 winRect(3)/2+axesWidth/2 winRect(4)*9/16+1]
        [winRect(3)/2-axesWidth/2 winRect(4)*10/16 winRect(3)/2+axesWidth/2 winRect(4)*10/16+1]
        [winRect(3)/2-axesWidth/2 winRect(4)*11/16 winRect(3)/2+axesWidth/2 winRect(4)*11/16+1]
        ])'; %Matrix with 3 rating axes - each column contains the coordinates of one axis
    whiskers = round([...
        [winRect(3)/2-axesWidth/2-1 winRect(4)*9/16+whisLength winRect(3)/2-axesWidth/2 winRect(4)*9/16-whisLength]
        [winRect(3)/2-axesWidth/2-1 winRect(4)*10/16+whisLength winRect(3)/2-axesWidth/2 winRect(4)*10/16-whisLength]
        [winRect(3)/2-axesWidth/2-1 winRect(4)*11/16+whisLength winRect(3)/2-axesWidth/2 winRect(4)*11/16-whisLength]
        [winRect(3)/2+axesWidth/2 winRect(4)*9/16+whisLength winRect(3)/2+axesWidth/2+1 winRect(4)*9/16-whisLength]
        [winRect(3)/2+axesWidth/2 winRect(4)*10/16+whisLength winRect(3)/2+axesWidth/2+1 winRect(4)*10/16-whisLength]
        [winRect(3)/2+axesWidth/2 winRect(4)*11/16+whisLength winRect(3)/2+axesWidth/2+1 winRect(4)*11/16-whisLength]
        ])';
    
%% Write text and draw axes
        %Background screen
            Screen('FillRect',window,exp_settings.backgrounds.rating); 
        %Draw axes
            Screen('FrameRect', window, linecolor, axes, line); %Axes
            Screen('FrameRect', window, linecolor, whiskers, line-1); %Whiskers
        %Write message:
            text = 'Dans quelle mesure avez-vous ressenti chacune des émotions ci-dessous?';
            Screen('TextFont',window,exp_settings.font.FontType);
            Screen('TextSize',window,exp_settings.font.EmoFontSize); 
            DrawFormattedText(window,text,'center',winRect(4)/3,exp_settings.font.RatingFontColor); %At 1/3 of the screen height
            %Add labels to the axes
                Screen('TextSize',window,18); Screen('TextStyle', window,2); %italics
                DrawFormattedText(window,'Pas du tout',round(winRect(3)/2-axesWidth/2-50),round(winRect(4)*1/2),exp_settings.font.RatingFontColor);
                DrawFormattedText(window,'Au maximum',round(winRect(3)/2+axesWidth/2),round(winRect(4)*1/2),exp_settings.font.RatingFontColor,16);                
                Screen('TextSize',window,exp_settings.font.EmoFontSize); Screen('TextStyle', window,0); %normal
        %Write emotions and numbers:
            for i = 1:3
                DrawFormattedText(window,'0',round(winRect(3)/2-axesWidth/2-25),round(winRect(4)*(i+8)/16+8),255); %Zeros
                DrawFormattedText(window,'10',round(winRect(3)/2+axesWidth/2+10),round(winRect(4)*(i+8)/16+8),255); %Tens                
                DrawFormattedText(window,char(emotions(i)),round((winRect(3)-axesWidth)/4),round(winRect(4)*(i+8)/16+8),255); %Emotions                
            end        
            Screen('Flip',window)    
        %Eyetracker marker (only in the main experiment, not the examples)
            if AllData.pupil && isfield(AllData,'trialinfo') 
                S10_Exp_PhysiologyMark(AllData,'rating')
            end
            
%% Loop through all 3 emotions; track cursor position to set slider

% Prepare
    ShowCursor('Hand')
    SetMouse(round(winRect(3)/2), round(winRect(4)/2), window)
    RateHappy = 0;
    RateSad   = 0;
    RateCurious = 0;
    confirm = 0;

while ~confirm
for j = 1:4 %Loop through all 3 emotions, then confirm/correct
    
    %if already down, wait for release and reset
        [x,y,buttons] = GetMouse; %GetMouse will always return the state of three buttons.
          while any(buttons) 
            [x,y,buttons] = GetMouse;
          end
        buttons = [0 0 0];
        rating = [];
        response = 0;
        
    %Wait for press while tracking mouse position.
        while ~response
         %Check if the cursor location is in the tracking field:
            [x,y,buttons] = GetMouse;         
            location = (x >= (winRect(3)-axesWidth)/2-10) + (x <= (winRect(3)+axesWidth)/2+10);
            if location == 2
                %Draw former graphics
                    %Draw axes
                        Screen('FrameRect', window, linecolor, axes, line); %Axes
                        Screen('FrameRect', window, linecolor, whiskers, line-1); %Whiskers
                    %Write message:
                        text = 'Dans quelle mesure avez-vous ressenti chacune des émotions ci-dessous?';
                        Screen('TextFont',window,exp_settings.font.FontType);
                        Screen('TextSize',window,exp_settings.font.EmoFontSize); 
                        DrawFormattedText(window,text,'center',winRect(4)/3,exp_settings.font.RatingFontColor); %At 1/3 of the screen height
                        %Add labels to the axes
                            Screen('TextSize',window,18); Screen('TextStyle', window,2); %italics
                            DrawFormattedText(window,'Pas du tout',round(winRect(3)/2-axesWidth/2-50),round(winRect(4)*1/2),exp_settings.font.RatingFontColor);
                            DrawFormattedText(window,'Au maximum',round(winRect(3)/2+axesWidth/2),round(winRect(4)*1/2),exp_settings.font.RatingFontColor,16);                
                            Screen('TextSize',window,exp_settings.font.EmoFontSize); Screen('TextStyle', window,0); %normal
                    %Write emotions and numbers:
                        for i = 1:3
                            DrawFormattedText(window,'0',round(winRect(3)/2-axesWidth/2-25),round(winRect(4)*(i+8)/16+8),255); %Zeros
                            DrawFormattedText(window,'10',round(winRect(3)/2+axesWidth/2+10),round(winRect(4)*(i+8)/16+8),255); %Tens                
                            DrawFormattedText(window,char(emotions(i)),round((winRect(3)-axesWidth)/4),round(winRect(4)*(i+8)/16+8),255); %Emotions                
                        end            
                %Draw the sliders at zero points, or wherever they have been set by the participant
                    if j ~= 1
                        Screen('FillRect', window, slidercolor, CenterRectOnPoint(slider,((winRect(3)-axesWidth)/2+1+RateHappy*axesWidth),winRect(4)*9/16))
                    end
                    if j~= 2
                        Screen('FillRect', window, slidercolor, CenterRectOnPoint(slider,((winRect(3)-axesWidth)/2+1+RateSad*axesWidth),winRect(4)*10/16))
                    end
                    if j ~= 3
                        Screen('FillRect', window, slidercolor, CenterRectOnPoint(slider,((winRect(3)-axesWidth)/2+1+RateCurious*axesWidth),winRect(4)*11/16))
                    end
                %Draw slider live
                    if j < 4
                        %Sligth adjustment for the extrema (allow to move out of borders a bit more flexibly):
                            if x < (winRect(3)-axesWidth)/2
                                x = (winRect(3)-axesWidth)/2;
                            elseif x > (winRect(3)+axesWidth)/2
                                x = (winRect(3)+axesWidth)/2;
                            end
                        sliderpos = CenterRectOnPoint(slider,x,winRect(4)*(j+8)/16);
                            Screen('FillRect', window, [255 153 51], sliderpos)
                    end
                %Draw the confirmation and correction boxes (grey background, white text)
                    if j == 4
                        leftrect = [(winRect(3)-axesWidth)/2 (12/16)*winRect(4) (winRect(3)-axesWidth/3)/2 (13/16)*winRect(4)];
                        rightrect = [(winRect(3)+axesWidth/3)/2 (12/16)*winRect(4) (winRect(3)+axesWidth)/2 (13/16)*winRect(4)];
                        Screen('FillRect',window,exp_settings.colors.grey, [leftrect; rightrect]')
                        Screen('TextSize',window,RatingLabelSize);                     
                        DrawFormattedText(window, 'Confirmer', 'center', 'center', ...
                            exp_settings.font.RatingFontColor, [], [], [], [], [], leftrect);
                        DrawFormattedText(window, 'Corriger', 'center', 'center', ...
                            exp_settings.font.RatingFontColor, [], [], [], [], [], rightrect);
                    end
                %Flip
                    Screen('Flip',window);
                %Check for a click in the slider box or buttons
                    if (x >= sliderpos(1) && x <= sliderpos(3) && y >= sliderpos(2) && y <= sliderpos(4))
                        if any(buttons)
                            response = 1;
                            rating = (sliderpos(1)+sliderpos(3))/2;
                        end
                    elseif j==4 && (x >= leftrect(1) && x <= leftrect(3) && y >= leftrect(2) && y <= leftrect(4)) && any(buttons)
                        response = 1;
                        confirm = 1;
                    elseif j==4 && (x >= rightrect(1) && x <= rightrect(3) && y >= rightrect(2) && y <= rightrect(4)) && any(buttons)
                        response = 1;
                        confirm = 0;
                    end                
            end  %if location == 2
        end  %while            
    %Wait for release
         while any(buttons) % wait for release
            [x,y,buttons] = GetMouse;
         end
    %Record answer
        rating = (rating-(winRect(3)-axesWidth)/2)/axesWidth;
        if j == 1
            RateHappy = rating;
        elseif j == 2
            RateSad = rating;
        elseif j == 3
            RateCurious = rating;
        end
end %for j
end %while confirm
        
    %Cleanup
        HideCursor;
        WaitSecs(0.5);
        Screen('Flip',window);
        Screen('Close');
        
end