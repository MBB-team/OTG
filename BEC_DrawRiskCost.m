function [t_onset] = BEC_DrawRiskCost(window,exp_settings,drawchoice)
% Visualize the wheel-of-fortune, the visualization of the risk cost from the BECHAMEL toolbox.

%Identify the rectangle ("box") inside of which the costs will be drawn
    [Xsize, Ysize] = Screen('WindowSize', window); screensize = [Xsize Ysize Xsize Ysize];
    if drawchoice.example
        rect_leftbox = exp_settings.choicescreen.costbox_left_example .* screensize;
        rect_rightbox = exp_settings.choicescreen.costbox_right_example .* screensize;
        text_cost_left = exp_settings.choicescreen.costbox_left_example; text_cost_left([2,4]) = exp_settings.choicescreen.cost_y;
        text_cost_right = exp_settings.choicescreen.costbox_right_example; text_cost_right([2,4]) = exp_settings.choicescreen.cost_y;
        text_reward_left = exp_settings.choicescreen.costbox_left_example; text_reward_left([2,4]) = exp_settings.choicescreen.reward_y_example;
        text_reward_right = exp_settings.choicescreen.costbox_right_example; text_reward_right([2,4]) = exp_settings.choicescreen.reward_y_example;
        confirm_left = [text_reward_left; text_cost_left]; confirm_left(:,[1,3]) = confirm_left(:,[1 3]) + [-diff(confirm_left(:,[1 3]),[],2) diff(confirm_left(:,[1 3]),[],2)];
        confirm_right = [text_reward_right; text_cost_right]; confirm_right(:,[1,3]) = confirm_right(:,[1 3]) + [-diff(confirm_right(:,[1 3]),[],2) diff(confirm_right(:,[1 3]),[],2)];
    else
        rect_leftbox = exp_settings.choicescreen.costbox_left .* screensize;
        rect_rightbox = exp_settings.choicescreen.costbox_right .* screensize;
        text_cost_left = exp_settings.choicescreen.costbox_left; text_cost_left([2,4]) = exp_settings.choicescreen.cost_y;
        text_cost_right = exp_settings.choicescreen.costbox_right; text_cost_right([2,4]) = exp_settings.choicescreen.cost_y;
        text_reward_left = exp_settings.choicescreen.costbox_left; text_reward_left([2,4]) = exp_settings.choicescreen.reward_y;
        text_reward_right = exp_settings.choicescreen.costbox_right; text_reward_right([2,4]) = exp_settings.choicescreen.reward_y;
        confirm_left = text_reward_left.*screensize;
        confirm_right = text_reward_right.*screensize;
    end
%Adjustment of the confirmation box for risk
    if ~isempty(drawchoice.losslefttext)
        confirm_left(1,:) = confirm_left(1,:) + diff(confirm_left(1,[2 4]),[],2)/4 * [0 1 0 1];
    else
        confirm_right(1,:) = confirm_right(1,:) + diff(confirm_right(1,[2 4]),[],2)/4 * [0 1 0 1];
    end
%Draw two wheels of fortune
    %Prepare to animate the lottery (in example trials)
        if ~isempty(drawchoice.confirmation) && drawchoice.example == 1 
            animation = 1; 
            if (strcmp(drawchoice.confirmation,'left') && drawchoice.costleft ~= 0) || ...
                (strcmp(drawchoice.confirmation,'right') && drawchoice.costright ~= 0)
                %Lottery
                    riskangle = max([drawchoice.costleft drawchoice.costright]./100) * 360;
                    if rand > max([drawchoice.costleft drawchoice.costright]./100) % Win: pin lands on probability arc
                        win = 1;
                        min_a = 3;                  %minimum start angle
                        max_a = 360-riskangle-3;    %maximum start angle
                        finalangle = round((max_a - min_a) * rand + min_a);    %randomly between min and max start angle
                    else; win = 0; %loss: pin on risk
                        min_a = 360-riskangle+3;    %minimum start angle
                        max_a = 360-3;              %maximum start angle
                        finalangle = round((max_a - min_a) * rand + min_a);    %randomly between min and max start angle
                    end
                    angle_level = ceil(finalangle/360*10); %Which of the 10 jumps in a circle is it
                    spins = ceil(2*rand+3); %no. of spins, between 3 and 5
                    jumpsize = (spins*360+finalangle)/(spins*20+angle_level);
                    loopangles = 0:jumpsize:(spins*360+finalangle);
            else
                loopangles = 0;
            end
            color_proba_arc = exp_settings.choicescreen.probabilitycolor;
        else; animation = 0; %Before the wheel is on screen
            loopangles = 0;
            color_proba_arc = exp_settings.choicescreen.probabilitycolor;
        end
    %Loop through the angles of the wheel (for animation; otherwise: fixed)
        anglecount = 1; 
        if animation && length(loopangles) > 1; waittime = [0.03 0.03]; end
        while anglecount <= length(loopangles)
            angle = loopangles(anglecount);
            for side = 1:2
                if side == 1 %Left wheel dimensions
                    wheelradius = diff(rect_leftbox([1 3]))/2; %The radius is determined by the width of the cost box
                    wheelrect = [mean(rect_leftbox([1 3]))-wheelradius mean(rect_leftbox([2 4]))-wheelradius mean(rect_leftbox([1 3]))+wheelradius mean(rect_leftbox([2 4]))+wheelradius];
                    riskangle = drawchoice.costleft/100*360;
                else %Right wheel dimensions
                    wheelradius = diff(rect_rightbox([1 3]))/2; %The radius is determined by the width of the cost box
                    wheelrect = [mean(rect_rightbox([1 3]))-wheelradius mean(rect_rightbox([2 4]))-wheelradius mean(rect_rightbox([1 3]))+wheelradius mean(rect_rightbox([2 4]))+wheelradius];
                    riskangle = drawchoice.costright/100*360;
                end
                %Fill risk arc
                    if riskangle ~= 0
                        startAngle_risk = angle;
                        arcAngle_risk = riskangle;
                        Screen('FillArc',window,exp_settings.choicescreen.fillcolor,wheelrect,startAngle_risk,arcAngle_risk);
                    end
                %Fill probability arcs
                    startAngle_proba = angle+riskangle;
                    arcAngle_proba = 360-riskangle;
                    Screen('FillArc',window,color_proba_arc,wheelrect,startAngle_proba,arcAngle_proba);
                %Draw wheel
                    Screen('FrameArc',window,exp_settings.choicescreen.linecolor,wheelrect,0,360,exp_settings.choicescreen.linewidth);
                %Draw pointer 
                    if animation && riskangle ~= 0
                        points = [mean(wheelrect([1 3])) wheelrect(2);    %pointer tip
                            mean(wheelrect([1 3]))-1/6*wheelradius wheelrect(2)-1/3*wheelradius;
                            mean(wheelrect([1 3]))+1/6*wheelradius wheelrect(2)-1/3*wheelradius];
                        Screen('FillPoly', window, exp_settings.colors.orange, points);
                    end
                %Text trial features
                    %Title
                        if isempty(drawchoice.confirmation) && drawchoice.example == 1
                            Screen('TextSize',window,exp_settings.font.TitleFontSize); 
                            DrawFormattedText(window, drawchoice.titletext, 'center', exp_settings.choicescreen.title_y*Ysize, exp_settings.colors.white);
                        end
                    %Draw cost and reward text
                        Screen('TextSize',window,exp_settings.font.RewardFontSize); %Same as CostFontSize
                        %Reward
                            DrawFormattedText(window, drawchoice.rewardlefttext, 'center', 'center', exp_settings.font.ChoiceFontColor, [], [], [], [], [], text_reward_left.*screensize); %Left
                            [~,~,textbounds] = DrawFormattedText(window, drawchoice.rewardrighttext, 'center', 'center', exp_settings.font.ChoiceFontColor, [], [], [], [], [], text_reward_right.*screensize); %Right
                        %Loss (risk only)
                            DrawFormattedText(window, drawchoice.losslefttext, 'center', 'center', exp_settings.font.LossFontColor, [], [], [], [], [], text_reward_left.*screensize + [0 1 0 1] * diff(textbounds([2 4])) * 2); %Left
                            DrawFormattedText(window, drawchoice.lossrighttext, 'center', 'center', exp_settings.font.LossFontColor, [], [], [], [], [], text_reward_right.*screensize + [0 1 0 1] * diff(textbounds([2 4])) * 2); %Right
                        %Cost (example only)
                            if drawchoice.example == 1
                                DrawFormattedText(window, drawchoice.costlefttext, 'center', 'center', exp_settings.font.ChoiceFontColor, [], [], [], [], [], text_cost_left.*screensize);
                                DrawFormattedText(window, drawchoice.costrighttext, 'center', 'center', exp_settings.font.ChoiceFontColor, [], [], [], [], [], text_cost_right.*screensize);
                            end
                    %Confirmation rectangle
                        if ~isempty(drawchoice.confirmation)
                            if strcmp(drawchoice.confirmation,'left'); confirm_rect = confirm_left;
                            elseif strcmp(drawchoice.confirmation,'right'); confirm_rect = confirm_right;
                            end
                            if drawchoice.example; confirm_rect = (confirm_rect.*screensize)'; end
                            Screen('FrameRect',window,exp_settings.colors.white,confirm_rect,3); %Note, confirm_rect has already been converted to pixels!
                        end
                    %Center question mark or fixation cross    
                        Screen('TextSize',window,exp_settings.font.RewardFontSize); 
                        if drawchoice.example == 1
                            DrawFormattedText(window, 'ou', 'center', 'center', exp_settings.font.ChoiceFontColor);
                        else
                            if isempty(drawchoice.confirmation)
                                DrawFormattedText(window, '?', 'center', 'center', exp_settings.font.ChoiceFontColor);
                            else
                                DrawFormattedText(window, '+', 'center', 'center', exp_settings.font.ChoiceFontColor);
                            end
                        end
                %Text outcome
                    sidenames = {'left','right'};
                    if animation && length(loopangles) == 1; waittime = [3 3]; 
                    end
                    if animation && strcmp(sidenames{side},drawchoice.confirmation)
                        if angle == loopangles(end) && riskangle ~= 0 && win == 1 
                            conf_text = ['Vous avez gagné la loterie. Vous recevrez ' num2str(exp_settings.MaxReward) ' euros.'];
                            outcome_color = exp_settings.colors.green;
                            waittime(side) = 3;
                        elseif angle == loopangles(end) && riskangle ~= 0 && win == 0 
                            conf_text = ['Vous avez perdu la loterie. Vous perdez ' num2str(exp_settings.RiskLoss) ' euros.'];
                            outcome_color = exp_settings.colors.red;
                            waittime(side) = 3;
                        elseif riskangle == 0
                            SSReward = min([drawchoice.rewardleft drawchoice.rewardright]);
                            if SSReward == 1; SSRewardText = sprintf('%.2f euro', round(SSReward, 1));
                            else; SSRewardText = sprintf('%.2f euros', round(SSReward, 1));
                            end
                            conf_text = ['Vous avez choisi l''option certaine. Vous recevrez ' SSRewardText ' .'];
                            outcome_color = exp_settings.colors.white;
                            waittime(side) = 3;
                        else
                            conf_text = [];
                        end
                        if ~isempty(conf_text)
                            Screen('TextSize',window,exp_settings.font.TitleFontSize); 
                            DrawFormattedText(window,conf_text,'center',exp_settings.choicescreen.title_y*Ysize,outcome_color); 
                        end
                    end
            end %for side
        %Flip
            Screen('Flip',window);
            if animation
                pause(max(waittime)); 
                t_onset = NaN;
            else
                t_onset = clock;
            end
            anglecount = anglecount+1;
        end %while anglecount
end
