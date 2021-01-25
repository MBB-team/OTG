function [t_onset] = BEC_DrawChoiceScreen(exp_settings,drawchoice,window)
% Auxiliary function to BEC_ShowChoice.
% Draws the choice screen, as defined in the structure "drawchoice", in Psychtoolbox. "window" is the open PTB window,
% exp_settings is the experimental settings structure. This function returns the exact onset time of the choice on
% screen. 
% This function draws all the parts of the choice screen that are common to all choice types. 
% The individual cost visualizations of the 4 cost types have their own subfunctions.

    %Setup
        [Xsize, Ysize] = Screen('WindowSize', window); screensize = [Xsize Ysize Xsize Ysize];
        Screen('TextFont',window,'Arial');
        if drawchoice.example == 1
            text_cost_left = exp_settings.choicescreen.costbox_left_example; text_cost_left([2,4]) = exp_settings.choicescreen.cost_y;
            text_cost_right = exp_settings.choicescreen.costbox_right_example; text_cost_right([2,4]) = exp_settings.choicescreen.cost_y;
            text_reward_left = exp_settings.choicescreen.costbox_left_example; text_reward_left([2,4]) = exp_settings.choicescreen.reward_y_example;
            text_reward_right = exp_settings.choicescreen.costbox_right_example; text_reward_right([2,4]) = exp_settings.choicescreen.reward_y_example;
            confirm_left = [text_reward_left; text_cost_left]; confirm_left(:,[1,3]) = confirm_left(:,[1 3]) + [-diff(confirm_left(:,[1 3]),[],2) diff(confirm_left(:,[1 3]),[],2)];
            confirm_right = [text_reward_right; text_cost_right]; confirm_right(:,[1,3]) = confirm_right(:,[1 3]) + [-diff(confirm_right(:,[1 3]),[],2) diff(confirm_right(:,[1 3]),[],2)];
        else
            text_cost_left = exp_settings.choicescreen.costbox_left; text_cost_left([2,4]) = exp_settings.choicescreen.cost_y;
            text_cost_right = exp_settings.choicescreen.costbox_right; text_cost_right([2,4]) = exp_settings.choicescreen.cost_y;
            text_reward_left = exp_settings.choicescreen.costbox_left; text_reward_left([2,4]) = exp_settings.choicescreen.reward_y;
            text_reward_right = exp_settings.choicescreen.costbox_right; text_reward_right([2,4]) = exp_settings.choicescreen.reward_y;
            confirm_left = text_reward_left.*screensize;
            confirm_right = text_reward_right.*screensize;
        end       
    %Adjustment of the confirmation box for risk
        if strcmp(drawchoice.choicetype,'risk')
            if ~isempty(drawchoice.losslefttext)
                confirm_left(1,:) = confirm_left(1,:) + diff(confirm_left(1,[2 4]),[],2)/4 * [0 1 0 1];
            else
                confirm_right(1,:) = confirm_right(1,:) + diff(confirm_right(1,[2 4]),[],2)/4 * [0 1 0 1];
            end
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
            DrawFormattedText(window, drawchoice.rewardlefttext, 'center', 'center', exp_settings.font.ChoiceFontColor, [], [], [], [], [], text_reward_left.*screensize); %Left
            [~,~,textbounds] = DrawFormattedText(window, drawchoice.rewardrighttext, 'center', 'center', exp_settings.font.ChoiceFontColor, [], [], [], [], [], text_reward_right.*screensize); %Right
        %Loss (risk only)
            if strcmp(drawchoice.choicetype,'risk')
                DrawFormattedText(window, drawchoice.losslefttext, 'center', 'center', exp_settings.font.LossFontColor, [], [], [], [], [], text_reward_left.*screensize + [0 1 0 1] * diff(textbounds([2 4])) * 2); %Left
                DrawFormattedText(window, drawchoice.lossrighttext, 'center', 'center', exp_settings.font.LossFontColor, [], [], [], [], [], text_reward_right.*screensize + [0 1 0 1] * diff(textbounds([2 4])) * 2); %Right
            end
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
            DrawFormattedText(window, 'ou', 'center', 'center', exp_settings.colors.white);
        else
            if isempty(drawchoice.confirmation)
                DrawFormattedText(window, '?', 'center', 'center', exp_settings.colors.white);
            else
                DrawFormattedText(window, '+', 'center', 'center', exp_settings.colors.white);
            end
        end
    %Cost visualizations            
        switch drawchoice.choicetype
            case 'delay'        
                t_onset = BEC_DrawDelayCost(window,exp_settings,drawchoice);
            case 'risk'
                t_onset = BEC_DrawRiskCost(window,exp_settings,drawchoice);
            case 'physical_effort'
                t_onset = BEC_DrawPhysicalEffortCost(window,exp_settings,drawchoice);
            case 'mental_effort'
                t_onset = BEC_DrawMentalEffortCost(window,exp_settings,drawchoice);
        end %switch choicetype
end %function
