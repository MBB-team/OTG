function [t_onset] = BEC_DrawDelayCost(window,exp_settings,drawchoice)
% Visualize the calendars of the delay cost visualization of the BECHAMEL toolbox.
% This function is an auxiliary function to BEC_DrawChoiceScreen, which draws the choice to be visualized in the
% idiosyncracies of Psychtoolbox.

%Identify the rectangle ("box") inside of which the costs will be drawn
    [Xsize, Ysize] = Screen('WindowSize', window); screensize = [Xsize Ysize Xsize Ysize];
    if drawchoice.example
        rect_leftbox = exp_settings.choicescreen.costbox_left_example .* screensize;
        rect_rightbox = exp_settings.choicescreen.costbox_right_example .* screensize;
    else
        rect_leftbox = exp_settings.choicescreen.costbox_left .* screensize;
        rect_rightbox = exp_settings.choicescreen.costbox_right .* screensize;
    end
    
%Draw two calendars
    for side = 1:2
        if side == 1 %left
            %Fill the rects
                if ~all(drawchoice.costleft==0)
                    %number of months
                        if drawchoice.costleft(1) >= 1
                            if drawchoice.costleft(1) == 1
                                rects_fill_months = exp_settings.choicescreen.monthrects(:,1)' .* ...
                                    repmat([rect_leftbox(3)-rect_leftbox(1) rect_leftbox(4)-rect_leftbox(2)],1,2) + ...
                                    repmat([rect_leftbox(1) rect_leftbox(2)],1,2); 
                            elseif drawchoice.costleft(1) > 1
                                rects_fill_months = exp_settings.choicescreen.monthrects(:,1:drawchoice.costleft(1)) .* ...
                                    repmat([rect_leftbox(3)-rect_leftbox(1); rect_leftbox(4)-rect_leftbox(2)],2,1) + ...
                                    repmat([rect_leftbox(1); rect_leftbox(2)],2,1);
                            end
                            Screen('FillRect',window,exp_settings.choicescreen.fillcolor,rects_fill_months);
                        end
                    %number of days
                        if drawchoice.costleft(2) > 0
                            i_month = drawchoice.costleft(1)+1;
                            y_days = [0 drawchoice.costleft(2)/50];
                            rects_fill_days = [exp_settings.choicescreen.monthrects(1,i_month) y_days(1) exp_settings.choicescreen.monthrects(3,i_month) y_days(2)] .* ...
                                repmat([rect_leftbox(3)-rect_leftbox(1) rect_leftbox(4)-rect_leftbox(2)],1,2) + ...
                                repmat([rect_leftbox(1) rect_leftbox(2)],1,2); 
                            Screen('FillRect',window,exp_settings.choicescreen.fillcolor,rects_fill_days);
                        end
                end
            %Draw the lines
                rects_frame_months = exp_settings.choicescreen.monthrects .* ...
                    repmat([rect_leftbox(3)-rect_leftbox(1); rect_leftbox(4)-rect_leftbox(2)],2,1) + ...
                    repmat([rect_leftbox(1); rect_leftbox(2)],2,1);
                Screen('FrameRect',window,exp_settings.choicescreen.linecolor,rects_frame_months,exp_settings.choicescreen.linewidth);
        else %right
            %Fill the rects
                if ~all(drawchoice.costright==0)
                    %number of months
                        if drawchoice.costright(1) >= 1
                            if drawchoice.costright(1) == 1
                                rects_fill_months = exp_settings.choicescreen.monthrects(:,1)' .* ...
                                    repmat([rect_rightbox(3)-rect_rightbox(1) rect_rightbox(4)-rect_rightbox(2)],1,2) + ...
                                    repmat([rect_rightbox(1) rect_rightbox(2)],1,2); 
                            elseif drawchoice.costright(1) > 1
                                rects_fill_months = exp_settings.choicescreen.monthrects(:,1:drawchoice.costright(1)) .* ...
                                    repmat([rect_rightbox(3)-rect_rightbox(1); rect_rightbox(4)-rect_rightbox(2)],2,1) + ...
                                    repmat([rect_rightbox(1); rect_rightbox(2)],2,1);
                            end
                            Screen('FillRect',window,exp_settings.choicescreen.fillcolor,rects_fill_months);
                        end
                    %number of days
                        if drawchoice.costright(2) > 0
                            i_month = drawchoice.costright(1)+1;
                            y_days = [0 drawchoice.costright(2)/50];
                            rects_fill_days = [exp_settings.choicescreen.monthrects(1,i_month) y_days(1) exp_settings.choicescreen.monthrects(3,i_month) y_days(2)] .* ...
                                repmat([rect_rightbox(3)-rect_rightbox(1) rect_rightbox(4)-rect_rightbox(2)],1,2) + ...
                                repmat([rect_rightbox(1) rect_rightbox(2)],1,2); 
                            Screen('FillRect',window,exp_settings.choicescreen.fillcolor,rects_fill_days);
                        end
                end
            %Draw the lines
                rects_frame_months = exp_settings.choicescreen.monthrects .* ...
                    repmat([rect_rightbox(3)-rect_rightbox(1); rect_rightbox(4)-rect_rightbox(2)],2,1) + ...
                    repmat([rect_rightbox(1); rect_rightbox(2)],2,1);
                Screen('FrameRect',window,exp_settings.choicescreen.linecolor,rects_frame_months,exp_settings.choicescreen.linewidth);
        end %if side
    end %for side
    
%Flip
    t_onset = clock;
    Screen('Flip', window); 

end
