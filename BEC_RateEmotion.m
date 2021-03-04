function [Ratings,timings,exitflag] = BEC_RateEmotion(window,AllData,which_rating)
% Presents the rating screen for evaluating one's moods or emotions on an analog scale using a slider.
% Inputs:
%           window: the Psychtoolbox window
%           AllData: the experiment data structure
%           which_rating: a string, can be either 'emotions', 'mood', 'fatigue', 'stress', 'happiness', 'pain'
% Output:   Ratings: the rating, outputted as a variable of type double and size [1 x dimensions]
%           timings: a structure containing the precise timings of the main events
%           exitflag: a logical that equals 1 when ESCAPE is pressed

%% Setup
    %Settings
        %General
            exp_settings = AllData.exp_settings;  
            try
                Ratingdimensions = exp_settings.ratings.(which_rating).Ratingdimensions; 
            catch
                Ratingdimensions = {''};
            end
            switch AllData.gender
                case 'm'; i_gender = 1;
                case 'f'; i_gender = 2;
            end 
            escapeKey = KbName('ESCAPE'); %27
            exitflag = 0;
        %Screen setup
            Screen(window,'BlendFunction',GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); %for the Alpha transparency values to take effect - in case this has not yet been set when opening the window
            Screen('TextFont',window,exp_settings.font.FontType);
            [screenX, screenY] = Screen('WindowSize', window); %Screen width, height
            winrect = [0 0 screenX screenY]; % Screen dimensions in Psychtoolbox rect format
            ShowCursor('Hand');
        %Dimensions (custom)
            ratingYrange = [4/12 10/12]; % [Min Max] Y-position, relative to screen height, of the rating axes
            unitsize = 1/12; % This "unit" relative to the screen height is used to vertically space the axes and the various texual elements
            axeswidth = 0.45 * screenX; % # pixels axis width (X)
            margin = 0.1 * axeswidth; % # pixels gap between items to the left and right of the axes
            linethickness = 3; % # pixels axis thickness    
            whiskerslength = 0.015 * screenY; % # pixels length of the whiskers at axis end
            sliderradius = 0.01*screenY; % # pixels diameter of the round slider
            sliderhalo = 0.5; % magnification factor for the halo around the active slider
            buttonsize = [0.06*screenX 0.03*screenY]; % # pixels width x height of the OK buttons
            fontsizefactors = [0.75 1 1.25]; % Font dimensions relative to exp_settings.font.RatingFontSize: [smaller base larger]
        %Graphics colors (custom)
            alpha = 0.75; % transparency of the halo
            ratingcolor = [0 114 189 alpha*255]; % The theme color for the active rating dimension (4th element is transparency alpha) (BORDEAUX RED: [162  20  47  alpha*255])
            linecolor   = exp_settings.colors.white; % The various lines on screen
            slidercolor = exp_settings.colors.grey; % The round slider is filled with "slidercolor", and has an outline color "linecolor"
    %Prepare rating axes
        %Relative y-positions
            ndims = length(Ratingdimensions);
            if diff(ratingYrange) >= (ndims-1)*unitsize
                yrelpos = linspace(-(ndims-1)/2,(ndims-1)/2,ndims) .* unitsize + mean(ratingYrange);
            else %More than 7 rating dimensions: stack them closer together
                yrelpos = linspace(-(ndims-1)/2,(ndims-1)/2,ndims) .* diff(ratingYrange)/(ndims-1) + mean(ratingYrange);
            end
        %Cordinates of axes, whiskers, and OK-buttons (each column is a rect)
            axes = [(screenX-axeswidth)/2*ones(1,ndims);
                    yrelpos.*screenY;
                    (screenX+axeswidth)/2*ones(1,ndims);
                    yrelpos.*screenY+1];
            whiskers = [(axes(1)-linethickness)*ones(1,ndims) (axes(3))*ones(1,ndims);
                        repmat(axes(2,:)-whiskerslength/2,1,2);
                        (axes(1))*ones(1,ndims) (axes(3)+linethickness)*ones(1,ndims);
                        repmat(axes(4,:)+whiskerslength/2,1,2)];
            OKbuttons = [(axes(3)+margin)*ones(1,ndims);
                        axes(2,:)-buttonsize(2)/2;
                       (axes(3)+margin+buttonsize(1))*ones(1,ndims);
                        axes(2,:)+buttonsize(2)/2];
            
%% Loop
    %Pre-loop check: no buttons clicked
        [~,~,buttons] = GetMouse; %GetMouse will always return the state of three buttons.
        while any(buttons) 
            [~,~,buttons] = GetMouse;
        end
    %Prepare
        Ratings = NaN(1,ndims); %Output: completed ratings
        timings = struct; %Output: precise onset and confirmation times
        completed = false; %logical for looping
        rating = NaN; %the value of the current active dimension's rating
        released = false; %logical, signals if currently active dimension has a confirmed rating
    %Loop until all ratings are confirmed
        while ~completed
            %Draw screen defaults
                DrawScreenDefaults(exp_settings, window, winrect, unitsize, axes, whiskers, linethickness, which_rating, linecolor, OKbuttons, fontsizefactors, i_gender);
            %Draw the slider positions of the already confirmed ratings
                if any(~isnan(Ratings))
                    sliderrects = [axes(1)+Ratings*axeswidth-sliderradius; mean([axes(2,:);axes(4,:)])-sliderradius; axes(1)+Ratings*axeswidth+sliderradius; mean([axes(2,:);axes(4,:)])+sliderradius]; %Completed ratings
                    Screen('FillOval',window,slidercolor,sliderrects);
                    Screen('FrameOval',window,linecolor,sliderrects,linethickness);                    
                end
            %Draw the slider position of the rating that is about to be confirmed
                if ~isnan(rating) && released %This is the case when a slider has been positioned and the mouse button is released, but before "OK" is clicked
                    currentslider = [axes(1)+rating*axeswidth-sliderradius mean([axes(2,i_dim);axes(4,i_dim)])-sliderradius axes(1)+rating*axeswidth+sliderradius mean([axes(2,i_dim);axes(4,i_dim)])+sliderradius]; %Currently active rating (if confirmed but not completed with "OK"
                    Screen('FillOval',window,slidercolor,currentslider);
                    Screen('FrameOval',window,linecolor,currentslider,linethickness);
                end
            %Determine current active axis    
                %Track the mouse
                    [x,y,buttons] = GetMouse;
                %A priori: the next unconfirmed rating is the current active axis
                    i_dim = find(isnan(Ratings),1,'first'); %(index; will be empty if all ratings are confirmed)
                %But: this can be overridden if a formerly confirmed rating is made active again by clicking that slider
                    if any(~isnan(Ratings))
                        mouse_on_slider = all([x >= sliderrects(1,:); y >= sliderrects(2,:); x <= sliderrects(3,:); y<= sliderrects(4,:)]);
                        if any(mouse_on_slider) && any(buttons)
                            mouse_dim = find(mouse_on_slider);
                            if mouse_dim ~= i_dim %Switch to the axis that is being selected with the mouse
                                i_dim = mouse_dim;
                                rating = NaN;
                                Ratings(i_dim) = NaN;
                            end
                        end
                    end
            %Write the dimension label of the active axis in the theme color, and the others in the default color
                Screen('TextSize',window,exp_settings.font.RatingFontSize);
                for i_label = 1:ndims
                    if ~isempty(Ratingdimensions{i_label})
                        if ~isempty(i_dim) && i_label == i_dim
                            labelcolor = round(ratingcolor(1:3));
                        else
                            labelcolor = round(exp_settings.font.RatingFontColor);
                        end
                        DrawFormattedText2(Ratingdimensions{i_label},'win',window,'sx',axes(1)-margin,'sy',mean(axes([2 4],i_label)),'xalign','right','yalign','center','baseColor',labelcolor);
                    end
                end
            %Collect rating from active axis
                if ~isempty(i_dim)
                    %Determine whether the slider should follow the cursor                        
                        %Check for a confirmation (a rating has been given and the button has been released)
                            if ~isnan(rating) && ~any(buttons)
                                released = 1;
                            else
                                released = 0;
                            end
                        %Check if the cursor location is within the tracking field (i.e. within the width of the axes)
                            infield = x >= axes(1)-10 & x <= axes(3)+10; %Logical
                    %Track the cursor with the slider if within the width range and no rating has been confirmed
                        if infield && ~released
                            %Get slider rect
                                if x < axes(1); x = axes(1);
                                elseif x > axes(3); x = axes(3);
                                end
                                sliderrect = [x-sliderradius mean(axes([2 4],i_dim))-sliderradius x+sliderradius mean(axes([2 4],i_dim))+sliderradius];
                            %Draw halo: either pulsating or static
                                if ~isempty(fieldnames(timings)) && ~any(buttons) %Pulsating halo until click (don't draw on first iteration)
                                    halosize = sliderhalo * sliderradius * (1 + sin(pi*etime(clock,timings(1).time)+1));
                                else %Static halo while button is pressed
                                    halosize = sliderhalo*sliderradius;
                                end
                                halorect = sliderrect + [-halosize -halosize halosize halosize];
                                Screen('FillOval',window,ratingcolor,halorect);
                            %Draw slider live (overlay on axis and halo)
                                Screen('FillOval',window,slidercolor,sliderrect);
                                Screen('FrameOval',window,linecolor,sliderrect,linethickness);
                            %If slider is clicked: get current rating level
                                if any(buttons)
                                    rating = (x-axes(1))/axeswidth;
                                end
                        end %followcursor                        
                    %Record response if a rating is confirmed
                        %Make "OK" button active
                            if released
                                Screen('TextSize',window,round(exp_settings.font.RatingFontSize*fontsizefactors(1))); %The word "OK" is written slightly smaller
                                Screen('FillRect',window,ratingcolor,OKbuttons(:,i_dim)'); %The button is filled in the rating theme color
                                DrawFormattedText2('OK','win',window,'sx',mean(OKbuttons([1 3],i_dim)),'sy',mean(OKbuttons([2 4],i_dim)),'xalign','center','yalign','center','baseColor',exp_settings.colors.black); %The word "OK" is written in black instead of grey
                                Screen('LineStipple',window,1,2); % Set the next lines to be drawn to be stippled; then draw an inner frame in the button:
                                    Screen('DrawLine', window, [0 0 0], OKbuttons(1,i_dim)+0.05*buttonsize(1), OKbuttons(2,i_dim)+0.1*buttonsize(2), OKbuttons(3,i_dim)-0.05*buttonsize(1), OKbuttons(2,i_dim)+0.1*buttonsize(2), linethickness/2);
                                    Screen('DrawLine', window, [0 0 0], OKbuttons(3,i_dim)-0.05*buttonsize(1), OKbuttons(2,i_dim)+0.1*buttonsize(2), OKbuttons(3,i_dim)-0.05*buttonsize(1), OKbuttons(4,i_dim)-0.1*buttonsize(2), linethickness/2);
                                    Screen('DrawLine', window, [0 0 0], OKbuttons(1,i_dim)+0.05*buttonsize(1), OKbuttons(4,i_dim)-0.1*buttonsize(2), OKbuttons(3,i_dim)-0.05*buttonsize(1), OKbuttons(4,i_dim)-0.1*buttonsize(2), linethickness/2);
                                    Screen('DrawLine', window, [0 0 0], OKbuttons(1,i_dim)+0.05*buttonsize(1), OKbuttons(2,i_dim)+0.1*buttonsize(2), OKbuttons(1,i_dim)+0.05*buttonsize(1), OKbuttons(4,i_dim)-0.1*buttonsize(2), linethickness/2);
                                Screen('LineStipple',window,0); %Disable line stipple
                            end
                        %Record click in the button and store the confirmed rating
                            %Note: this is different on tablet vs. with an actual mouse
                            mouse_on_OKbutton = x >= OKbuttons(1,i_dim) && x <= OKbuttons(3,i_dim) && y >= OKbuttons(2,i_dim) && y<= OKbuttons(4,i_dim); %Logical
                            if isfield(AllData,'plugins') && isfield(AllData.plugins,'touchscreen') && AllData.plugins.touchscreen == 1
                                if ~isnan(rating) && mouse_on_OKbutton
                                    Ratings(i_dim) = rating; %Fill in the rating level
                                    rating = NaN; %Reset current rating estimate, will be filled in once a new button is clicked. "released" remains = 1.                                
                                    timings(1+i_dim) = BEC_Timekeeping('RatingConfirmation',AllData.plugins);
                                end
                            else
                                if ~isnan(rating) && mouse_on_OKbutton && any(buttons)
                                    Ratings(i_dim) = rating; %Fill in the rating level
                                    rating = NaN; %Reset current rating estimate, will be filled in once a new button is clicked. "released" remains = 1.                                
                                    timings(1+i_dim) = BEC_Timekeeping('RatingConfirmation',AllData.plugins);
                                end
                            end
                else %All ratings have been confirmed
                    completed = true; %Bail out of the loop
                end %i_dim
            %Flip
                timestamp = Screen('Flip',window); %"t1" is the GetSecs time
            %Collect timing and set trigger upon first iteration
                if isempty(fieldnames(timings))
                    timings = BEC_Timekeeping('RatingScreenOnset',AllData.plugins,timestamp);
                    timings.event = ['RatingScreenOnset_' which_rating];
                end
            %Check for manual termination if escape key is pressed
                [keyIsDown, ~, keyCode, ~] = KbCheck(-1); 
                if keyIsDown && keyCode(escapeKey)
                    exitflag = 1;
                    FlushEvents('keyDown');
                    return %Terminate the rating session
                end
        end %while ~completed
    %Cleanup
        pause(0.1);
        HideCursor;
        Screen('Flip',window);
        Screen('Close');
        t_complete = BEC_Timekeeping('RatingCompleted',AllData.plugins);
        timings = [timings t_complete];
        
end

%% Draw screen defaults
function DrawScreenDefaults(exp_settings, window, winrect, unitsize, axes, whiskers, linethickness, which_rating, linecolor, OKbuttons, fontsizefactors, i_gender)
    %Get dimensions
        ndims = size(OKbuttons,2);
    %Get texts
        Ratingquestion = exp_settings.ratings.(which_rating).Ratingquestion; 
        Rating_label_min = ['<i>' exp_settings.ratings.(which_rating).Rating_label_min{i_gender}]; 
        Rating_label_max = ['<i>' exp_settings.ratings.(which_rating).Rating_label_max{i_gender}]; 
        try
            Rating_quantity_min = exp_settings.ratings.(which_rating).Rating_quantity_min;
            Rating_quantity_max = exp_settings.ratings.(which_rating).Rating_quantity_max;
        catch
            Rating_quantity_min = '';
            Rating_quantity_max = '';
        end
    %Window background
        Screen('FillRect',window,exp_settings.backgrounds.rating); 
    %Draw axes
        Screen('FrameRect', window, linecolor, axes, linethickness); %Axes
        Screen('FrameRect', window, linecolor, whiskers, linethickness); %Whiskers
    %Write question (slightly larger)
        Screen('TextSize',window,round(exp_settings.font.RatingFontSize*fontsizefactors(3)));
        DrawFormattedText(window,Ratingquestion,'center',axes(2,1)-2*unitsize*winrect(4),exp_settings.font.RatingFontColor);
    %Add labels to the axes (slightly smaller)
        Screen('TextSize',window,round(exp_settings.font.RatingFontSize*fontsizefactors(1)));         
        DrawFormattedText2(Rating_label_min,'win',window,'sx',axes(1)-15,'sy',axes(2)-unitsize*winrect(4),'xalign','center','baseColor',exp_settings.font.RatingFontColor);
        DrawFormattedText2(Rating_label_max,'win',window,'sx',axes(3)+15,'sy',axes(2)-unitsize*winrect(4),'xalign','center','baseColor',exp_settings.font.RatingFontColor);
    %Write dimension label and numbers at the axis extrema
        for i_dim = 1:ndims
            if ~isempty(Rating_quantity_min)
                DrawFormattedText2(Rating_quantity_min,'win',window,'sx',axes(1)-25,'sy',mean(axes([2 4],i_dim)),'yalign','center','baseColor',exp_settings.font.RatingFontColor); %Zero
            end
            if ~isempty(Rating_quantity_max)
                DrawFormattedText2(Rating_quantity_max,'win',window,'sx',axes(3)+10,'sy',mean(axes([2 4],i_dim)),'yalign','center','baseColor',exp_settings.font.RatingFontColor); %Zero
            end
        end        
    %Draw "OK" buttons
        Screen('FillRect',window,exp_settings.colors.grey,OKbuttons);
        darkgrey = mean([exp_settings.colors.black;exp_settings.colors.grey]);
        for i_dim = 1:ndims
            DrawFormattedText2('OK','win',window,'sx',mean(OKbuttons([1 3],i_dim)),'sy',mean(OKbuttons([2 4],i_dim)),'xalign','center','yalign','center','baseColor',darkgrey); 
        end
end    