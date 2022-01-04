function [timings] = BEC_DrawDelayCost(window,exp_settings,drawchoice)
% Visualize the calendars of the delay cost visualization of the BECHAMEL toolbox.
% This function is an auxiliary function to BEC_DrawChoiceScreen, which draws the choice to be visualized in the
% idiosyncracies of Psychtoolbox.
% Note: this is the more recent version of the delay cost visualization (created February 2021). For the original
% calendar representation, see "BEC_DrawDelayCost2"

%Settings
    days_per_month = [31 28 31 30 31 30 31 31 30 31 30 31]; %The calendar year. Leave untouched.
    cum_days_per_month = cumsum(days_per_month); %Cumulative amount of days
    nrows = floor(sqrt(exp_settings.MaxDelay)); %Number of rows of months
    ncols = ceil(sqrt(exp_settings.MaxDelay)); %Numbers of columns of months
    if rem(nrows*ncols,exp_settings.MaxDelay)>0
        ncols = ncols+1; %In case the # months does not have a natural root: more columns than rows.
    end
    density = 0.85; %Total area of the calendars w.r.t. the gaps
    
%Identify the rectangle ("box") inside of which the costs will be drawn
    [Xsize, Ysize] = Screen('WindowSize', window); screensize = [Xsize Ysize Xsize Ysize];
    if drawchoice.example
        rect_leftbox = exp_settings.choicescreen.costbox_left_example .* screensize;
        rect_rightbox = exp_settings.choicescreen.costbox_right_example .* screensize;
    else
        rect_leftbox = exp_settings.choicescreen.costbox_left .* screensize;
        rect_rightbox = exp_settings.choicescreen.costbox_right .* screensize;
    end
    Y = rect_leftbox(4)-rect_leftbox(2);    %Total height of the cost box
    X = rect_leftbox(3)-rect_leftbox(1);    %Total width of the cost box
    
%Define rects for drawing
    dayheight = density*Y/(nrows*6); %6 week rows per month (top bar is filled)
    daywidth = density*X/(ncols*7); %7 day columns per month
    daysize = min([dayheight,daywidth]); %The size, in pixels, of 1 day
    y_gap = (Y-nrows*6*daysize)/(nrows-1); %Vertical gap size between months, in pixels
    if y_gap > 2*daysize; y_gap = 2*daysize; end
    x_gap = (X-ncols*7*daysize)/(ncols-1); %Horizontal gap size between months, in pixels
    if x_gap > 2*daysize; x_gap = 2*daysize; end
    %Make 3 month rects
        for ndays = [28,30,31]
            calrect = NaN(4,1+ndays); %Calendar rect of 1 month
            calrect(:,1) = [0; 0; 7; 1]*daysize; %Calendar month top rect
            for i_day = 1:ndays %Loop through days of the month
                calrect(:,1+i_day) = [rem(i_day-1,7), 1+floor((i_day-1)/7), 1+rem(i_day-1,7), 1+ceil(i_day/7)]' * daysize;
            end
            monthrect.(['month_' num2str(ndays)]) = calrect;
        end
    %Make calendar rects
        allmonthrects = cell(1,exp_settings.MaxDelay);
        for i_month = 1:exp_settings.MaxDelay
            i_row = ceil(i_month/ncols);
            i_col = 1+rem(i_month-1,ncols);      
            topleft = [(i_col-1)*(7*daysize+x_gap); (i_row-1)*(6*daysize+y_gap); (i_col-1)*(7*daysize+x_gap); (i_row-1)*(6*daysize+y_gap)];
            allmonthrects{i_month} = topleft + monthrect.(['month_' num2str(days_per_month(1+rem(i_month-1,12)))]);
        end
        allmonthrects = cell2mat(allmonthrects); %The full calendar including all days
        i_toprect = cumsum(1+[0 days_per_month(1:exp_settings.MaxDelay-1)]); %Indices of the horizontal bars at the top of each month
        i_days = setdiff(1:length(allmonthrects),i_toprect); %Indices of the rects that correspond to individual days
        
%Draw two calendars
    for side = 1:2
        if side == 1 %left
            %Fill the top horizontal bars of each month
                rects_fill_bars = [rect_leftbox(1);rect_leftbox(2);rect_leftbox(1);rect_leftbox(2)] + allmonthrects(:,i_toprect);
                Screen('FillRect',window,exp_settings.choicescreen.linecolor,rects_fill_bars);
            %Fill the cost rects
                if ~all(drawchoice.costleft==0)
                    if drawchoice.costleft(1)>0
                        fill_left = i_days([1:cum_days_per_month(drawchoice.costleft(1)), cum_days_per_month(drawchoice.costleft(1))+(1:drawchoice.costleft(2))]); %Indices of the days to be filled on the left
                    else %Less than 1 month
                        fill_left = i_days(1:drawchoice.costleft(2)); %Indices of the days to be filled on the left
                    end
                    rects_fill_days = [rect_leftbox(1);rect_leftbox(2);rect_leftbox(1);rect_leftbox(2)] + allmonthrects(:,fill_left);
                    Screen('FillRect',window,exp_settings.choicescreen.fillcolor,rects_fill_days);
                end
            %Draw the lines
                rects_frame_days = [rect_leftbox(1);rect_leftbox(2);rect_leftbox(1);rect_leftbox(2)] + allmonthrects;
                Screen('FrameRect',window,exp_settings.choicescreen.linecolor,rects_frame_days,exp_settings.choicescreen.linewidth);
        else %right
            %Fill the top horizontal bars of each month
                rects_fill_bars = [rect_rightbox(1);rect_rightbox(2);rect_rightbox(1);rect_rightbox(2)] + allmonthrects(:,i_toprect);
                Screen('FillRect',window,exp_settings.choicescreen.linecolor,rects_fill_bars);
            %Fill the cost rects
                if ~all(drawchoice.costright==0)
                    if drawchoice.costright(1)>0
                        fill_right = i_days([1:cum_days_per_month(drawchoice.costright(1)), cum_days_per_month(drawchoice.costright(1))+(1:drawchoice.costright(2))]); %Indices of the days to be filled on the right
                    else %Less than 1 month
                        fill_right = i_days(1:drawchoice.costright(2)); %Indices of the days to be filled on the right
                    end
                    rects_fill_days = [rect_rightbox(1);rect_rightbox(2);rect_rightbox(1);rect_rightbox(2)] + allmonthrects(:,fill_right);
                    Screen('FillRect',window,exp_settings.choicescreen.fillcolor,rects_fill_days);
                end
            %Draw the lines
                rects_frame_days = [rect_rightbox(1);rect_rightbox(2);rect_rightbox(1);rect_rightbox(2)] + allmonthrects;
                Screen('FrameRect',window,exp_settings.choicescreen.linecolor,rects_frame_days,exp_settings.choicescreen.linewidth);
        end %if side
    end %for side
    
%Flip
    timestamp = Screen('Flip', window); 
    timings = BEC_Timekeeping(drawchoice.event,drawchoice.plugins,timestamp);

end
