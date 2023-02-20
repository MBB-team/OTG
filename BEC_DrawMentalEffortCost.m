function [timings] = BEC_DrawMentalEffortCost(window,exp_settings,drawchoice)
% This function is part of the OTG toolbox, used for generating and presenting a battery of economic choices.
% Draw the pages that visualize the mental effort cost from the BECHAMEL toolbox.
% This function is an auxiliary function to BEC_DrawChoiceScreen, which draws the choice to be visualized in the
% idiosyncracies of Psychtoolbox.

%Settings for drawing the pages
    nrows = floor(sqrt(exp_settings.Max_ment_effort));  %Number of rows of pages
    ncols = ceil(sqrt(exp_settings.Max_ment_effort));   %Numbers of columns of pages
    if rem(nrows*ncols,exp_settings.Max_ment_effort)>0
        ncols = ncols+1;
    end
    density = 3/4;      %Total vertical area of the pages w.r.t. the cost box height
    page_AR = 210/297;  %Aspect ratio of an A4 sheet of paper
    margin = 0.1;       %Width of the text margin w.r.t. the page dimensions
    nlines = 8;         %Lines on the page

%Identify the rectangle ("box") inside of which the costs will be drawn
    [Xsize, Ysize] = Screen('WindowSize', window); screensize = [Xsize Ysize Xsize Ysize];
    if drawchoice.example
        rect_leftbox = exp_settings.choicescreen.costbox_left_example .* screensize;
        rect_rightbox = exp_settings.choicescreen.costbox_right_example .* screensize;
    else
        rect_leftbox = exp_settings.choicescreen.costbox_left .* screensize;
        rect_rightbox = exp_settings.choicescreen.costbox_right .* screensize;
    end

%Get the rectangle coordinates
    %Get the pages coordinates relative to the top left coordinate of the cost box
        Y = rect_leftbox(4)-rect_leftbox(2);    %Total height of the cost box
        X = rect_leftbox(3)-rect_leftbox(1);    %Total width of the cost box
        h = density*Y/nrows;                    %height of a page
        line_gap = h*(1-2*margin)/(nlines-1);   %vertical space between two lines
        w = h * page_AR;                        %width of a page
        x_gap = (X-ncols*w)/(ncols-1);          %horizontal space between two pages
        y_gap = (1-density)*Y/(nrows-1);        %vertical space between two pages
            if y_gap > x_gap; y_gap = x_gap;    %Correct gap sizes
            elseif y_gap < x_gap; x_gap = y_gap;
            end
        pages = NaN(4,exp_settings.Max_ment_effort);
        lines = NaN(4,nlines*exp_settings.Max_ment_effort);
        for i_page = 1:size(pages,2) %Loop through all pages
            %Get the page coordinates
                i_row = ceil(i_page/ncols);
                i_col = rem(i_page,ncols);
                if i_col == 0; i_col = ncols; end
                pages(1,i_page) = (i_col-1)*(w+x_gap);   %x1
                pages(2,i_page) = (i_row-1)*(h+y_gap);   %y1
                pages(3,i_page) = (i_col-1)*(w+x_gap)+w; %x2
                pages(4,i_page) = (i_row-1)*(h+y_gap)+h; %y2
            %Get the coordinates of the lines on the page
                i_lines = (i_page-1)*nlines + (1:nlines);
                lines(1,i_lines) = pages(1,i_page)+margin*w;
                lines(3,i_lines) = pages(3,i_page)-margin*w;
                lines([2 4],i_lines) = repmat((pages(2,i_page)+margin*h) : line_gap : (pages(4,i_page)-margin*h),2,1);
        end        
        lines(4,:) = lines(4,:)+1; %Thickness of the line
        
%Draw two sets of pages
    %Left
        %Fill the cost pages
            if drawchoice.costleft ~= 0 
                rects_left_pages = pages(:,1:floor(drawchoice.costleft)) + rect_leftbox([1 2 1 2])';
                %Draw the full pages
                    if ~isempty(rects_left_pages)
                        Screen('FillRect',window,exp_settings.choicescreen.fillcolor,rects_left_pages);
                    end
                %Draw the additional lines    
                    if drawchoice.costleft ~= floor(drawchoice.costleft) %If the number of pages is not an integer
                        last_page_rect = pages(:,ceil(drawchoice.costleft))' + rect_leftbox([1 2 1 2]);
                        last_page_rect(4) = last_page_rect(2)+h*(drawchoice.costleft-floor(drawchoice.costleft));
                        Screen('FillRect',window,exp_settings.choicescreen.fillcolor,last_page_rect);
                    end
            end
        %Draw the page outlines
            rects_left_pages = pages + rect_leftbox([1 2 1 2])';
            Screen('FrameRect',window,exp_settings.choicescreen.linecolor,rects_left_pages,exp_settings.choicescreen.linewidth);
        %Draw the lines on the pages
            rects_left_lines = lines + rect_leftbox([1 2 1 2])';
            Screen('FrameRect',window,exp_settings.choicescreen.linecolor,rects_left_lines,exp_settings.choicescreen.linewidth);
    %Right
        %Fill the cost pages
            if drawchoice.costright ~= 0 
                rects_right_pages = pages(:,1:floor(drawchoice.costright)) + rect_rightbox([1 2 1 2])';
                %Draw the full pages
                    if ~isempty(rects_right_pages)
                        Screen('FillRect',window,exp_settings.choicescreen.fillcolor,rects_right_pages);
                    end
                %Draw the additional lines
                    if drawchoice.costright ~= floor(drawchoice.costright) %If the number of pages is not an integer
                        last_page_rect = pages(:,ceil(drawchoice.costright))' + rect_rightbox([1 2 1 2]);
                        last_page_rect(4) = last_page_rect(2)+h*(drawchoice.costright-floor(drawchoice.costright));
                        Screen('FillRect',window,exp_settings.choicescreen.fillcolor,last_page_rect);
                    end
            end
        %Draw the page outlines
            rects_right_pages = pages + rect_rightbox([1 2 1 2])';
            Screen('FrameRect',window,exp_settings.choicescreen.linecolor,rects_right_pages,exp_settings.choicescreen.linewidth);
        %Draw the lines on the pages
            rects_right_lines = lines + rect_rightbox([1 2 1 2])';
            Screen('FrameRect',window,exp_settings.choicescreen.linecolor,rects_right_lines,exp_settings.choicescreen.linewidth);
    
%Flip
    timestamp = Screen('Flip', window); 
    timings = BEC_Timekeeping(drawchoice.event,drawchoice.plugins,timestamp);
end