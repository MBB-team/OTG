function [trialinfo,exitflag] = BEC_ShowChoice(window,exp_settings,trialinfo)
% Battery of Economic Choices - show the choice screen
% Inputs:
%     window                %The Psychtoolbox session window
%     exp_settings          %The experiment settings structure
%     trialinfo.trial       %Trial number (only required for the pupil marker)
%     trialinfo.choicetype  %Set number (1:delay/2:risk/3:physical effort/4:mental effort)
%     trialinfo.SSReward    %Reward for the uncostly (SS) option (between 0 and 1)
%     trialinfo.Cost        %Cost level or the costly (LL) option (between 0 and 1)
%     trialinfo.SideSS      %(optional) set on which side you want the uncostly (SS) option to be (enter string: 'left' or 'right')
%     trialinfo.Example     %(optional, default 0) flag 1 if this is an example trial (with explanation text) 
%     trialinfo.Pupil       %(optional, default 0) flag 1 if you want to record pupil data
%     trialinfo.ITI         %(optional) fixation cross time before choice (default is random value between the set minimum and maximum value from exp_settings)
% Output:
%     trialinfo: updated structure with all the information about the choice trial
%     exitflag: 0 by default; 1 if the experiment was interrupted

%% Prepare
    %Input defaults
        typenames = {'delay','risk','physical_effort','mental_effort'};
        sidenames = {'left','right'};
        if ~isfield(trialinfo,'SideSS') || isempty(trialinfo.SideSS)
            trialinfo.SideSS = sidenames{1+round(rand)};
        end
        if ~isfield(trialinfo,'Example') || isempty(trialinfo.Example)
            trialinfo.Example = 0;
        end
        if ~isfield(trialinfo,'Pupil') || isempty(trialinfo.Pupil)
            trialinfo.Pupil = 0;
        end
        if ~isfield(trialinfo,'ITI') || isempty(trialinfo.ITI)
            trialinfo.ITI = exp_settings.timings.fixation_choice(1) + rand * (exp_settings.timings.fixation_choice(2)-exp_settings.timings.fixation_choice(1));
        end
    %Keyboard
        leftKey = KbName('LeftArrow');
        rightKey = KbName('RightArrow');
        escapeKey = KbName('ESCAPE');
        LRQ = [leftKey rightKey escapeKey];  % join keys 
    %Trial features
        %Reward for uncostly option
            SSReward = round(trialinfo.SSReward*exp_settings.MaxReward,1);
            if SSReward == 1; SSRewardText = sprintf('%.2f euro', round(SSReward, 1));
            else; SSRewardText = sprintf('%.2f euros', round(SSReward, 1));
            end
            if trialinfo.Example; SSRewardText = ['et recevoir ' SSRewardText]; end
        %Reward for costly option
            LLRewardText = sprintf('%.2f euros', exp_settings.MaxReward);
            if strcmp(typenames{trialinfo.choicetype},'risk')
                LLLossText = ['ou -' sprintf('%.2f euros', exp_settings.RiskLoss)];
            else
                LLLossText = [];
            end
            if trialinfo.Example
                if strcmp(typenames{trialinfo.choicetype},'risk')
                    LLRewardText = ['pour gagner ' LLRewardText];
                    LLLossText = ['ou perdre ' sprintf('%.2f euros', exp_settings.RiskLoss)];
                else
                    LLRewardText = ['pour recevoir ' LLRewardText];                    
                end
            end
        %Choicetype-specific features
            switch typenames{trialinfo.choicetype}
                case 'delay'
                    SSCostText = 'ne pas attendre';
                    LLCost = round(trialinfo.Cost*exp_settings.MaxDelay); %Expressed in # of weeks <=== revise this for months!!!
                    [LLCost,LLCostText] = ConvertCost(LLCost,1,exp_settings);
                    LLCostText = ['attendre ce délai' newline newline '(' LLCostText ')'];
                case 'risk'
                    SSCostText = 'ne pas prendre de risque';
                    LLCost = round(trialinfo.Cost*exp_settings.MaxRisk,1);
                    LLCostText = ['prendre ce risque' newline newline '(' num2str(LLCost) '%)'];
                case 'physical_effort'
                    SSCostText = 'ne pas faire d''effort';
                    LLCost = trialinfo.Cost*exp_settings.Max_phys_effort;
                    [~,LLCostText] = ConvertCost(LLCost,3,exp_settings);
                    LLCostText = ['monter ces escaliers' newline newline '(' LLCostText ')'];
                case 'mental_effort'
                    SSCostText = 'ne pas faire d''effort';
                    LLCost = trialinfo.Cost*exp_settings.Max_ment_effort;
                    [~,LLCostText] = ConvertCost(LLCost,4,exp_settings);
                    LLCostText = ['copier ces pages' newline newline '(' LLCostText ')'];
            end       
    %Set drawing parameters
        drawchoice.choicetype = typenames{trialinfo.choicetype};
        drawchoice.example = trialinfo.Example;
        drawchoice.titletext = 'EXEMPLE: Préférez-vous...';
        drawchoice.confirmation = [];
        switch trialinfo.SideSS %Side definition
            case 'left'
                drawchoice.rewardleft = SSReward; 
                drawchoice.rewardlefttext = SSRewardText;
                drawchoice.losslefttext = [];
                drawchoice.costleft = 0; 
                drawchoice.costlefttext = SSCostText;
                drawchoice.rewardright = exp_settings.MaxReward; 
                drawchoice.rewardrighttext = LLRewardText;
                drawchoice.lossrighttext = LLLossText;
                drawchoice.costright  = LLCost; 
                drawchoice.costrighttext = LLCostText;
            case 'right'
                drawchoice.rewardleft = exp_settings.MaxReward; 
                drawchoice.rewardlefttext = LLRewardText;
                drawchoice.losslefttext = LLLossText;
                drawchoice.costleft  = LLCost; 
                drawchoice.costlefttext = LLCostText;
                drawchoice.rewardright = SSReward; 
                drawchoice.rewardrighttext = SSRewardText;
                drawchoice.lossrighttext = [];
                drawchoice.costright = 0; 
                drawchoice.costrighttext = SSCostText;
        end

%% Present screens       
    %Fixation cross on screen for the specified time
        t_fix_on = clock;
        exitflag = BEC_Fixation(window,exp_settings,trialinfo.ITI);
        if exitflag; return; end %Terminate experiment if ESCAPE is pressed at the end of the fixation time
    %Pupil marker
%         if trialinfo.pupil
%             S10_Exp_PhysiologyMark(phys,'choice',trialinfo.trial)
%         end
    %Display choice screen
        KbReleaseWait;  % wait until all keys are released before start with trial again.                        
        t_onset = DrawChoiceScreen(exp_settings,drawchoice,window);
        WaitSecs(exp_settings.timings.min_resp_time);  % minimum response time to avoid constant button presses by the participant without thinking            
    %Monitor for response
        keyCode(LRQ) = 0; exitflag = 0;
        while keyCode(leftKey) == 0 && keyCode(rightKey) == 0 && keyCode(escapeKey) == 0 % as long no button is pressed keep checking the keyboard
            [~, ~, keyCode] = KbCheck(-1);
        end
    %Screenshot
        imageArray=Screen('GetImage', window);
        imwrite(imageArray, 'choiceExample.png');
    %Record response and display confirmation screen
        if keyCode(leftKey)
            resp = leftKey; 
            rt = etime(clock,t_onset); 
            exitflag = 0;
            if ~isempty(window)
                drawchoice.confirmation = 'left';
                DrawChoiceScreen(exp_settings,drawchoice,window);                                    
            end
            WaitSecs(exp_settings.timings.show_response);  % show response before proceeding
        elseif keyCode(rightKey)
            resp = rightKey; 
            rt = etime(clock,t_onset); 
            exitflag = 0;
            if ~isempty(window)
                drawchoice.confirmation = 'right';
                DrawChoiceScreen(exp_settings,drawchoice,window);                                      
            end
            WaitSecs(exp_settings.timings.show_response);  % show response before proceeding
        elseif keyCode(escapeKey) 
            exitflag = 1;
            resp = NaN;
            rt = NaN;
        end
        FlushEvents('keyDown');
        
%% Store all trial information
    %Record decision and RT
        if (strcmp(trialinfo.SideSS,'left') && resp == rightKey) || (strcmp(trialinfo.SideSS,'right') && resp == leftKey) 
            trialinfo.choiceSS = 0;
        else
            trialinfo.choiceSS = 1;
        end
        trialinfo.RT = rt;        
    %Record the full trial info
        trialinfo.LLReward = 1; %Reward for the costly option (default)
        trialinfo.Choicetype = typenames{trialinfo.choicetype}; %name of the choice type
        switch trialinfo.choicetype
            case 1 %Delay
                trialinfo.Delay = trialinfo.Cost;
                trialinfo.Risk = 0; 
                trialinfo.PhysicalEffort = 0;
                trialinfo.MentalEffort = 0;
                trialinfo.Loss = 0;
            case 2 %Risk
                trialinfo.Delay = 0;
                trialinfo.Risk = trialinfo.Cost;
                trialinfo.PhysicalEffort = 0;
                trialinfo.MentalEffort = 0;
                trialinfo.Loss = 0;
            case 3 %Physical effort
                trialinfo.Delay = 0;
                trialinfo.Risk = 0;
                trialinfo.PhysicalEffort = trialinfo.Cost;
                trialinfo.MentalEffort = 0;
                trialinfo.Loss = exp_settings.RiskLoss/exp_settings.MaxReward;
            case 4 %Mental effort
                trialinfo.Delay = 0;
                trialinfo.Risk = 0;
                trialinfo.PhysicalEffort = 0;
                trialinfo.MentalEffort = trialinfo.Cost;
                trialinfo.Loss = 0;
        end
        trialinfo.ITI = etime(t_onset,t_fix_on); %fixation time before choice onset (seconds)
        trialinfo.timestamp = t_onset; %timestamp of choice presentation on screen (format: [y m d h m s])

end
            
%% Draw screen
function [t_onset] = DrawChoiceScreen(exp_settings,drawchoice,window)
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
                t_onset = DrawDelayCost(window,exp_settings,drawchoice);
            case 'risk'
                t_onset = DrawRiskCost(window,exp_settings,drawchoice);
            case 'physical_effort'
                t_onset = DrawPhysicalEffortCost(window,exp_settings,drawchoice);
            case 'mental_effort'
                t_onset = DrawMentalEffortCost(window,exp_settings,drawchoice);
        end %switch choicetype
end %function
    
%% Convert delay cost level to calendar values
function [LLCost,LLCostText] = ConvertCost(LLCost,choicetype,exp_settings)
% input:  LLCost is the cost level expressed as the fraction of the maximal cost

switch choicetype
    case 1 %DELAY
        % output: LLCost: [#months #days_in_last_month], required to fill in the calendar.
        %         LLCostText: in text, the amount of "months,weeks,days" of waiting time
        %Convert in years/months/days
            total_days = LLCost*7;
            cal_days = [31 28 31 30 31 30 31 31 30 31 30 31]; %The days in 12 months
            cum_days = cumsum(cal_days); %The cumulative amount of days up to 1 year
            total_months = find(total_days>cum_days,1,'last');
            if isempty(total_months); total_months = 0; end                    
            if total_months == 0
                n_weeks = floor(total_days/7);
                if n_weeks > 0
                    n_days = rem(total_days,7);
                else
                    n_days = total_days; 
                end
                delta_days = total_days;
            else
                n_weeks = floor((total_days - cum_days(total_months))/7);
                n_days = rem(total_days - cum_days(total_months),7);
                delta_days = total_days - cum_days(total_months);
            end
            LLCostText = [];
            if total_months >= 1
                LLCostText = [LLCostText num2str(total_months) ' mois']; 
                if any([n_weeks n_days]>=1); LLCostText = [LLCostText ', ']; end
            end
            if n_weeks >= 1
                if n_weeks == 1; LLCostText = [LLCostText num2str(n_weeks) ' semaine'];
                elseif n_weeks > 1; LLCostText = [LLCostText num2str(n_weeks) ' semaines'];
                end
                if n_days>=1; LLCostText = [LLCostText ', ']; end
            end
            if n_days >= 1
                if n_days == 1; LLCostText = [LLCostText num2str(n_days) ' jour']; 
                elseif n_days > 1; LLCostText = [LLCostText num2str(n_days) ' jours']; 
                end
            end
            if LLCost == 52
                LLCostText = '1 an';
                total_months = 12; delta_days = 0;
            end
            LLCost = [total_months delta_days]; %Note: this is required for drawing the calendar!
    case 3 %PHYSICAL EFFORT
        nfloors = floor(LLCost);
        nsteps = round((LLCost-floor(LLCost))*exp_settings.choicescreen.flightsteps);
        %Floors
            if nfloors == 1
                LLCostText = '1 étage';
            elseif nfloors > 1
                LLCostText = [num2str(nfloors) ' étages'];
            end
        %Steps
            if nsteps > 0
                if nfloors > 0
                    LLCostText = [LLCostText ' + '];
                end
                if nsteps == 1
                    LLCostText = [LLCostText '1 marche'];
                else
                    LLCostText = [LLCostText num2str(nsteps) ' marches'];
                end
            end
    case 4 %MENTAL EFFORT
        npages = floor(LLCost);
        nlines = round((LLCost-floor(LLCost))*exp_settings.choicescreen.pagelines);
        %Pages
            if npages == 1
                LLCostText = '1 page';
            elseif npages > 1
                LLCostText = [num2str(npages) ' pages'];
            end
        %Lines
            if nlines > 0
                if npages > 0
                    LLCostText = [LLCostText ' + '];
                end
                if nlines == 1
                    LLCostText = [LLCostText '1 ligne'];
                else
                    LLCostText = [LLCostText num2str(nlines) ' lignes'];
                end
            end
end
end

%% Draw Delay cost
function [t_onset] = DrawDelayCost(window,exp_settings,drawchoice)
    
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

%% Draw Risk cost
function [t_onset] = DrawRiskCost(window,exp_settings,drawchoice)

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
                WaitSecs(max(waittime)); 
                t_onset = NaN;
            else
                t_onset = clock;
            end
            anglecount = anglecount+1;
        end %while anglecount
end

%% Draw Physical effort cost
function [t_onset] = DrawPhysicalEffortCost(window,exp_settings,drawchoice)
%Settings for drawing staircases:
    nrows = floor(sqrt(exp_settings.Max_phys_effort));  %Number of rows of pages
    ncols = ceil(sqrt(exp_settings.Max_phys_effort));   %Numbers of columns of pages
    if rem(nrows*ncols,exp_settings.Max_ment_effort)>0
        ncols = ncols+1;
    end
    nsteps = 9; %Number of steps per floor
    gapratio = 1/3; %Width width of the gap between staircases/width of the base of a staircase
    
%Identify the rectangle ("box") inside of which the costs will be drawn
    [Xsize, Ysize] = Screen('WindowSize', window); screensize = [Xsize Ysize Xsize Ysize];
    if drawchoice.example
        rect_leftbox = exp_settings.choicescreen.costbox_left_example .* screensize;
        rect_rightbox = exp_settings.choicescreen.costbox_right_example .* screensize;
    else
        rect_leftbox = exp_settings.choicescreen.costbox_left .* screensize;
        rect_rightbox = exp_settings.choicescreen.costbox_right .* screensize;
    end

%Get the staircase coordinates 
    X = rect_leftbox(3)-rect_leftbox(1);    %Total width of the cost box
    side = X/(ncols + gapratio*(ncols-1));  %Dimension of the sides of a box that contains a staircase
    gap = side*gapratio;                    %Horizontal width between two staircase boxes
    steps = [0:1:nsteps-1;                  %Draw template staircase
             nsteps-1:-1:0;
             nsteps*ones(1,nsteps);
             nsteps:-1:1].*side/nsteps;
    allsteps = NaN(4,exp_settings.Max_phys_effort*nsteps);
    for i = 1:exp_settings.Max_phys_effort
        i_row = ceil(i/ncols);
        i_col = i-(i_row-1)*ncols;
        allsteps(:,(i-1)*nsteps+(1:nsteps)) = (i_col-1)*(side+gap)*[1;0;1;0] + (i_row-1)*(side+gap)*[0;1;0;1] + steps;
    end
    allsteps_left = [rect_leftbox(1) rect_leftbox(2) rect_leftbox(1) rect_leftbox(2)]' + allsteps; %Coordinates of the left cost box steps
    allsteps_right = [rect_rightbox(1) rect_rightbox(2) rect_rightbox(1) rect_rightbox(2)]' + allsteps; %Coordinates of the right cost box steps
    
%Translate cost level into amount of steps:
    costlevel = max([drawchoice.costleft,drawchoice.costright]); %Effort level in terms of flights of stairs
    cost = costlevel/exp_settings.Max_phys_effort; %Effort level of the costly option, expressed as fraction of max effort level
    cost_steps = floor(cost*size(allsteps,2)); %Integer number of steps to fill for the costly option
    last_step = round(((costlevel-floor(costlevel)) - (cost_steps/nsteps - floor(cost_steps/nsteps)))*exp_settings.choicescreen.flightsteps)/exp_settings.choicescreen.flightsteps*nsteps; %Height of the last step (fraction of a full step)         
%Draw the steps
    %Left
        if drawchoice.costleft ~= 0 %Left is the costly side
            %Fill steps above cost level with line color (white)
                if cost_steps ~= length(allsteps)
                    Screen('FillRect',window,exp_settings.choicescreen.linecolor,allsteps_left(:,cost_steps:end));
                end
            %Fill steps until cost level with cost color (red)
                if cost_steps ~= 0
                    if cost_steps == 1 %Write function differently
                        Screen('FillRect',window,exp_settings.choicescreen.fillcolor,allsteps_left(:,1)');
                    else
                        Screen('FillRect',window,exp_settings.choicescreen.fillcolor,allsteps_left(:,1:cost_steps));
                    end
                end
            %Draw the last (fractional) cost step
                if last_step ~= 0
                    last_step = allsteps_left(:,cost_steps+1)' + [0 (1-last_step)*side/nsteps 0 0];
                    Screen('FillRect',window,exp_settings.choicescreen.fillcolor,last_step); %Last costly step (if not whole step)
                end
        else
            Screen('FillRect',window,exp_settings.choicescreen.linecolor,allsteps_left); %No-cost steps
        end
    %Right
        if drawchoice.costright ~= 0 %Right is the costly side
            %Fill steps above cost level with line color (white)
                if cost_steps ~= length(allsteps)
                    Screen('FillRect',window,exp_settings.choicescreen.linecolor,allsteps_right(:,cost_steps:end));
                end
            %Fill steps until cost level with cost color (red)
                if cost_steps ~= 0
                    if cost_steps == 1 %Write function differently
                        Screen('FillRect',window,exp_settings.choicescreen.fillcolor,allsteps_right(:,1)');
                    else
                        Screen('FillRect',window,exp_settings.choicescreen.fillcolor,allsteps_right(:,1:cost_steps));
                    end
                end
            %Draw the last (fractional) cost step
                if last_step ~= 0
                    last_step = allsteps_right(:,cost_steps+1)' + [0 (1-last_step)*side/nsteps 0 0];
                    Screen('FillRect',window,exp_settings.choicescreen.fillcolor,last_step); %Last costly step (if not whole step)
                end
        else
            Screen('FillRect',window,exp_settings.choicescreen.linecolor,allsteps_right); %No-cost steps
        end
    
%Flip
    t_onset = clock;
    Screen('Flip', window);
end

%% Draw Mental effort cost
function [t_onset] = DrawMentalEffortCost(window,exp_settings,drawchoice)
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
        y_gap = (1-density)*Y/(nrows-1);        %vertical space between two pages
        line_gap = h*(1-2*margin)/(nlines-1);   %vertical space between two lines
        w = h * page_AR;                        %width of a page
        x_gap = (X-ncols*w)/(ncols-1);          %horizontal space between two pages
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
    for side = 1:2
        if side == 1 %left
            %Fill the cost pages
                if drawchoice.costleft ~= 0 
                    rects_left_pages = pages(:,1:floor(drawchoice.costleft)) + rect_leftbox([1 2 1 2])';
                    Screen('FillRect',window,exp_settings.choicescreen.fillcolor,rects_left_pages);
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
        else %right
            %Fill the cost pages
                if drawchoice.costright ~= 0 
                    rects_right_pages = pages(:,1:floor(drawchoice.costright)) + rect_rightbox([1 2 1 2])';
                    Screen('FillRect',window,exp_settings.choicescreen.fillcolor,rects_right_pages);
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
        end %if side
    end %for side
    
%Flip
    t_onset = clock;
    Screen('Flip', window); 
end