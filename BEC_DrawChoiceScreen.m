function [timings] = BEC_DrawChoiceScreen(exp_settings,drawchoice,window)
% Auxiliary function to BEC_ShowChoice.
% Draws the choice screen, as defined in the structure "drawchoice", in Psychtoolbox. "window" is the open PTB window,
% exp_settings is the experimental settings structure. This function returns the exact onset time of the choice on
% screen. 
% This function draws all the parts of the choice screen that are common to all choice types. 
% The individual cost visualizations of the 4 cost types have their own subfunctions.

    %Setup
        tactile_screen = isfield(drawchoice,'plugins') & isfield(drawchoice.plugins,'touchscreen') & drawchoice.plugins.touchscreen == 1; %Logical: tactile screen or not
        [Xsize, Ysize] = Screen('WindowSize', window); screensize = [Xsize Ysize Xsize Ysize];
        Screen('TextFont',window,exp_settings.font.FontType);
        if drawchoice.example == 1
            text_cost_left = exp_settings.choicescreen.costbox_left_example; text_cost_left([2,4]) = exp_settings.choicescreen.cost_y;
            text_cost_right = exp_settings.choicescreen.costbox_right_example; text_cost_right([2,4]) = exp_settings.choicescreen.cost_y;
            text_reward_left = exp_settings.choicescreen.costbox_left_example; text_reward_left([2,4]) = exp_settings.choicescreen.reward_y_example;
            text_reward_right = exp_settings.choicescreen.costbox_right_example; text_reward_right([2,4]) = exp_settings.choicescreen.reward_y_example;
            confirm_left = [text_reward_left; text_cost_left]; confirm_left(:,[1,3]) = confirm_left(:,[1 3]) + [-diff(confirm_left(:,[1 3]),[],2) diff(confirm_left(:,[1 3]),[],2)]/2;
            confirm_right = [text_reward_right; text_cost_right]; confirm_right(:,[1,3]) = confirm_right(:,[1 3]) + [-diff(confirm_right(:,[1 3]),[],2) diff(confirm_right(:,[1 3]),[],2)]/2;
        else
            text_cost_left = exp_settings.choicescreen.costbox_left; text_cost_left([2,4]) = exp_settings.choicescreen.cost_y;
            text_cost_right = exp_settings.choicescreen.costbox_right; text_cost_right([2,4]) = exp_settings.choicescreen.cost_y;
            text_reward_left = exp_settings.choicescreen.costbox_left; text_reward_left([2,4]) = exp_settings.choicescreen.reward_y;
            text_reward_right = exp_settings.choicescreen.costbox_right; text_reward_right([2,4]) = exp_settings.choicescreen.reward_y;
            confirm_left = text_reward_left.*screensize;
            confirm_right = text_reward_right.*screensize;
        end       
    %Background
        Screen('FillRect',window,exp_settings.backgrounds.choice);
    %Title
        if isempty(drawchoice.confirmation) && drawchoice.example == 1
            Screen('TextSize',window,exp_settings.font.TitleFontSize); 
            DrawFormattedText(window, drawchoice.titletext, 'center', exp_settings.choicescreen.title_y*Ysize, exp_settings.colors.white);
        end
    %Draw cost and reward text
        Screen('TextSize',window,exp_settings.font.RewardFontSize); %Same as CostFontSize
        %Reward
            if strcmp(drawchoice.choicetype,'risk') %In the case of risk: add loss
                losscolor = [num2str(exp_settings.font.LossFontColor(1)/255) ',' num2str(exp_settings.font.LossFontColor(2)/255) ',' num2str(exp_settings.font.LossFontColor(3)/255)];
                RewardText_left = [drawchoice.rewardlefttext '\n<color=' losscolor '>' drawchoice.losslefttext];
                RewardText_right = [drawchoice.rewardrighttext '\n<color=' losscolor '>' drawchoice.lossrighttext];
            else
                RewardText_left = drawchoice.rewardlefttext; 
                RewardText_right = drawchoice.rewardrighttext;
            end
            DrawFormattedText2(RewardText_left,'win',window,'sx',mean(text_reward_left([1,3])).*Xsize,'xalign','center','xlayout','center','sy',mean(text_reward_left([2,4])).*Ysize,'yalign','center','baseColor',exp_settings.font.ChoiceFontColor);
            DrawFormattedText2(RewardText_right,'win',window,'sx',mean(text_reward_right([1,3])).*Xsize,'xalign','center','xlayout','center','sy',mean(text_reward_right([2,4])).*Ysize,'yalign','center','baseColor',exp_settings.font.ChoiceFontColor);
        %Cost (example only)
            if drawchoice.example == 1
                DrawFormattedText(window, drawchoice.costlefttext, 'center', 'center', exp_settings.font.ChoiceFontColor, [], [], [], [], [], text_cost_left.*screensize);
                DrawFormattedText(window, drawchoice.costrighttext, 'center', 'center', exp_settings.font.ChoiceFontColor, [], [], [], [], [], text_cost_right.*screensize);
            end
    %In example trials: draw arrow keys (but not on a tactile screen)
        if drawchoice.example && ~tactile_screen
            leftkeyrect = [mean(text_cost_left([1,3]))*Xsize-drawchoice.size_leftkey(1)/4 exp_settings.choicescreen.arrowbuttons_y*Ysize-drawchoice.size_leftkey(2)/4 ...
                mean(text_cost_left([1,3]))*Xsize+drawchoice.size_leftkey(1)/4 exp_settings.choicescreen.arrowbuttons_y*Ysize+drawchoice.size_leftkey(2)/4];
                Screen('DrawTexture', window, drawchoice.tex_leftkey, [], leftkeyrect);
            rightkeyrect = [mean(text_cost_right([1,3]))*Xsize-drawchoice.size_rightkey(1)/4 exp_settings.choicescreen.arrowbuttons_y*Ysize-drawchoice.size_rightkey(2)/4 ...
                mean(text_cost_right([1,3]))*Xsize+drawchoice.size_rightkey(1)/4 exp_settings.choicescreen.arrowbuttons_y*Ysize+drawchoice.size_rightkey(2)/4];
                Screen('DrawTexture', window, drawchoice.tex_rightkey, [], rightkeyrect);
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
        Screen('TextSize',window,exp_settings.font.FixationFontSize); 
        if drawchoice.example == 1
            DrawFormattedText(window, 'ou', 'center', 'center', exp_settings.colors.white);
        else
            if isempty(drawchoice.confirmation) %Before confirming, write "+" until minimum response time, and "?" once the choice may be entered.
                DrawFormattedText(window, drawchoice.centerscreen, 'center', 'center', exp_settings.colors.white);
            else
                DrawFormattedText(window, '+', 'center', 'center', exp_settings.colors.white);
            end
        end
    %On tactile screens: add escape cross
        if tactile_screen && isfield(exp_settings,'tactile')
            escapeCrossSize = exp_settings.tactile.escapeCross_ySize*Ysize;
            escapeCrossRect = [Xsize-1.5*escapeCrossSize 0.5*escapeCrossSize Xsize-0.5*escapeCrossSize 1.5*escapeCrossSize];
            Screen('FillRect',window,exp_settings.colors.red,escapeCrossRect);
            Screen('TextSize',window,exp_settings.tactile.escapeCrossFontSize); %Careful to set the text size back to what it was before
            DrawFormattedText(window, 'X', 'center', 'center', AllData.exp_settings.colors.white,[],[],[],[],[],escapeCrossRect);
        end
    %Cost visualizations            
        switch drawchoice.choicetype
            case 'delay'        
                timings = BEC_DrawDelayCost(window,exp_settings,drawchoice);
            case 'risk'
                drawchoice.rects.text_cost_left = text_cost_left;
                drawchoice.rects.text_cost_right = text_cost_right;
                drawchoice.rects.text_reward_left = text_reward_left;
                drawchoice.rects.text_reward_right = text_reward_right;
                drawchoice.rects.confirm_left = confirm_left;
                drawchoice.rects.confirm_right = confirm_right;
                timings = BEC_DrawRiskCost(window,exp_settings,drawchoice);
            case 'physical_effort'
                timings = BEC_DrawPhysicalEffortCost(window,exp_settings,drawchoice);
            case 'mental_effort'
                timings = BEC_DrawMentalEffortCost(window,exp_settings,drawchoice);
        end %switch choicetype
end %function
