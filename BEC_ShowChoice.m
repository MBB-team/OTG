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
        escapeKey = KbName('ESCAPE'); % (deliberately set to invariable)
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
        t_onset = BEC_DrawChoiceScreen(exp_settings,drawchoice,window);
        pause(exp_settings.timings.min_resp_time);  % minimum response time to avoid constant button presses by the participant without thinking            
    %Monitor for response...
        keyCode(LRQ) = 0; exitflag = 0;
        while (keyCode(leftKey) == 0 && keyCode(rightKey) == 0 && keyCode(escapeKey) == 0) && ... % as long no button is pressed, AND...
                etime(clock,t_onset) <= exp_settings.timings.max_resp_time % ... as long as the timeout limit is not reached
            [~, ~, keyCode] = KbCheck(-1);
        end
%     %Screenshot
%         imageArray=Screen('GetImage', window);
%         imwrite(imageArray, 'choiceExample.png');
    %Record response and display confirmation screen
        if keyCode(leftKey)
            resp = leftKey; 
            rt = etime(clock,t_onset); 
            exitflag = 0;
            if ~isempty(window)
                drawchoice.confirmation = 'left';
                BEC_DrawChoiceScreen(exp_settings,drawchoice,window);                                    
            end
            WaitSecs(exp_settings.timings.show_response);  % show response before proceeding
        elseif keyCode(rightKey)
            resp = rightKey; 
            rt = etime(clock,t_onset); 
            exitflag = 0;
            if ~isempty(window)
                drawchoice.confirmation = 'right';
                BEC_DrawChoiceScreen(exp_settings,drawchoice,window);                                      
            end
            WaitSecs(exp_settings.timings.show_response);  % show response before proceeding
        elseif keyCode(escapeKey) 
            exitflag = 1;
            resp = NaN;
            rt = NaN;
        else % time out: participant took too long to respond
            resp = NaN;
            rt = NaN;
        end
        FlushEvents('keyDown');
        
%% Store all trial information
    %Record decision and RT
        if isnan(resp) % time out
            trialinfo.choiceSS = NaN;
        elseif (strcmp(trialinfo.SideSS,'left') && resp == rightKey) || (strcmp(trialinfo.SideSS,'right') && resp == leftKey) % costly option chosen
            trialinfo.choiceSS = 0;
        else % uncostly option chosen
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
                trialinfo.Loss = exp_settings.RiskLoss/exp_settings.MaxReward;
            case 3 %Physical effort
                trialinfo.Delay = 0;
                trialinfo.Risk = 0;
                trialinfo.PhysicalEffort = trialinfo.Cost;
                trialinfo.MentalEffort = 0;
                trialinfo.Loss = 0;
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
            
%% Convert cost levels ([0-1]) to analog values
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
        LLCostText = [];
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
        LLCostText = [];
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
end %switch choicetype
end %function