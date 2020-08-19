function [rating,RT] = BEC_RateMood(window,AllData,dimension)
%Rate the presented stimuli along the spectrum of the presented dimension

%% Prepare the screen
   %Settings
        exp_settings = AllData.exp_settings;
        if ~isfield(AllData,'triallist'); is_example = 1; %this is an example trial
        else; is_example = 0; %this is a trial from the main experiment
        end
        [screenXpixels, screenYpixels] = Screen('WindowSize', window);
        winRect = [0 0 screenXpixels screenYpixels];        
        line        = 3;    %# pixels axis thickness
        axesWidth   = 700;  %# pixels axis length
        whisLength  = 5;    %# length of the whiskers at axis end
        slider      = [0 0 10 30];  %size of the slider rectangle        
    %Determine rating theme color
        switch dimension
            case {'content','contente'}; themecolor = exp_settings.font.color_content;
            case {'calme'}; themecolor = exp_settings.font.color_calme;
            case {'triste'}; themecolor = exp_settings.font.color_triste;
            case {'tendu','tendue'}; themecolor = exp_settings.font.color_tendu;
        end
    
%% Write text and draw axes
    %Background
        Screen('FillRect',window,exp_settings.backgrounds.rating);
    %Draw axis
        axes = round([winRect(3)/2-axesWidth/2 winRect(4)*9/16 winRect(3)/2+axesWidth/2 winRect(4)*9/16+1])'; 
        whiskers = round([...
            [winRect(3)/2-axesWidth/2-1 winRect(4)*9/16+whisLength winRect(3)/2-axesWidth/2 winRect(4)*9/16-whisLength]
            [winRect(3)/2+axesWidth/2 winRect(4)*9/16+whisLength winRect(3)/2+axesWidth/2+1 winRect(4)*9/16-whisLength]])';
        Screen('FrameRect', window, 255, axes, line); %Axes
        Screen('FrameRect', window, 255, whiskers, line-1); %Whiskers
    %Draw slilder in the middle
        rating = 0.5;
        Screen('FillRect', window, themecolor, CenterRectOnPoint(slider,((winRect(3)-axesWidth)/2+1+rating*axesWidth),winRect(4)*9/16))
    %Write question:
        Screen('TextSize',window,exp_settings.font.RatingFontSize);    
        Screen('TextFont',window,exp_settings.font.FontType);
        text = 'A quel point vous sentez-vous ';
        [nx,ny] = DrawFormattedText(window,text,'center',winRect(4)/3,exp_settings.colors.white); %At 1/3 of the screen height
        DrawFormattedText(window,[dimension ' ?'],nx,ny,themecolor);
        Screen('TextSize',window,18); Screen('TextStyle', window, 2); %italics
            DrawFormattedText(window,'Pas du tout',round(winRect(3)/2-axesWidth/2-50),round(winRect(4)*1/2),255);
            DrawFormattedText(window,'Tout à fait',round(winRect(3)/2+axesWidth/2),round(winRect(4)*1/2),255,16);                
    %Flip
        Screen('Flip',window)    
    %Eyetracking marker -- TO DO
        if AllData.pupil && ~is_example
             %...
        end
    %Start timer
        t1 = clock;
            
%% Track response

ShowCursor('Hand')
SetMouse(round(winRect(3)/2), round(winRect(4)/2), window)
    
    %if already down, wait for release and reset
        [~,~,buttons] = GetMouse; %GetMouse will always return the state of three buttons.
          while any(buttons) 
            [~,~,buttons] = GetMouse;
          end
        buttons = [0 0 0];
        rating = 0;
        response = 0;
        confirm = 0;
        leftrecttext = 'Confirmer'; 
        rightrecttext = 'Corriger';

    %Wait for press while tracking mouse position.
        while ~(response && confirm)
         %Check if the cursor location is in the tracking field:
            [x,y,buttons] = GetMouse;         
            location = (x >= (winRect(3)-axesWidth)/2-10) + (x <= (winRect(3)+axesWidth)/2+10);
            if location == 2 % i.e., mouse is above the scale
                %Draw the former graphics
                        Screen('FrameRect', window, 255, axes, line); %Axes
                        Screen('FrameRect', window, 255, whiskers, line-1); %Whiskers
                        Screen('TextSize',window,exp_settings.font.RatingFontSize);    
                        Screen('TextFont',window,exp_settings.font.FontType);
                        Screen('TextStyle', window, 0); %Normal
                        text = 'A quel point vous sentez-vous ';
                        [nx,ny] = DrawFormattedText(window,text,'center',winRect(4)/3,exp_settings.font.RatingFontColor); %At 1/3 of the screen height
                        DrawFormattedText(window,[dimension ' ?'],nx,ny,themecolor);
                        Screen('TextSize',window,18); Screen('TextStyle', window, 2); %italics
                        DrawFormattedText(window,'Pas du tout',round(winRect(3)/2-axesWidth/2-50),round(winRect(4)*1/2),exp_settings.font.RatingFontColor);
                        DrawFormattedText(window,'Tout à fait',round(winRect(3)/2+axesWidth/2),round(winRect(4)*1/2),exp_settings.font.RatingFontColor,16);
                        Screen('TextStyle', window, 0); %Set back to normal
                %Draw slilder at confirmed position
                    if response == 1
                        Screen('FillRect', window, themecolor, CenterRectOnPoint(slider,rating,winRect(4)*9/16))
                    else
                %Draw slider live
                        %Sligth adjustment for the extrema (allow to move out of borders a bit more flexibly):
                            if x < (winRect(3)-axesWidth)/2
                                x = (winRect(3)-axesWidth)/2;
                            elseif x > (winRect(3)+axesWidth)/2
                                x = (winRect(3)+axesWidth)/2;
                            end
                        sliderpos = CenterRectOnPoint(slider,x,winRect(4)*9/16);
                            Screen('FillRect', window, themecolor, sliderpos)
                    end
                %Draw the confirmation and correction boxes
                    if response == 1 && confirm == 0
                        leftrect = [(winRect(3)-axesWidth)/2 (12/16)*winRect(4) (winRect(3)-axesWidth/3)/2 (13/16)*winRect(4)];
                        rightrect = [(winRect(3)+axesWidth/3)/2 (12/16)*winRect(4) (winRect(3)+axesWidth)/2 (13/16)*winRect(4)];
                        Screen('FillRect',window, exp_settings.colors.grey, [leftrect; rightrect]') %Black
                        Screen('TextSize',window,18);                     
                        DrawFormattedText(window, leftrecttext, 'center', 'center', ...
                            exp_settings.font.RatingFontColor, [], [], [], [], [], leftrect);
                        DrawFormattedText(window, rightrecttext, 'center', 'center', ...
                            exp_settings.font.RatingFontColor, [], [], [], [], [], rightrect);
                    end
                %Flip
                    Screen('Flip',window);
                %Check for a click in the slider box or buttons
                    if response == 0 && (x >= sliderpos(1) && x <= sliderpos(3) && y >= sliderpos(2) && y <= sliderpos(4)) && any(buttons)
                        %Click on the slider
                            response = 1;
                            rating = (sliderpos(1)+sliderpos(3))/2;
                    elseif response == 1 && (x >= leftrect(1) && x <= leftrect(3) && y >= leftrect(2) && y <= leftrect(4)) && any(buttons)
                        %Click in the left box: confirm
                            confirm = 1;                        
                    elseif response == 1 && (x >= rightrect(1) && x <= rightrect(3) && y >= rightrect(2) && y <= rightrect(4)) && any(buttons)
                        %Click in the right box: correct
                            response = 0; 
                            confirm = 0;                    
                    end                
            end  %if location == 2
        end  %while            
    %Wait for release
         while any(buttons) % wait for release
            [~,~,buttons] = GetMouse;
         end
         HideCursor;
    %Record answer
        rating = (rating-(winRect(3)-axesWidth)/2)/axesWidth;     
    %Waiting
        RT = etime(clock,t1); %Response time
        if RT < exp_settings.timings.min_rating_time
            WaitSecs(exp_settings.timings.min_rating_time-RT);
        else
            WaitSecs(0.3);
        end
    %Cleanup
        Screen('Flip',window);
        Screen('Close');
        
end