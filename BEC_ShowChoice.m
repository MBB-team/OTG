function [trialoutput,exitflag] = BEC_ShowChoice(window,exp_settings,trialinput)
% Battery of Economic Choices - show the choice screen
% Inputs:
%     window                %The Psychtoolbox session window
%     exp_settings          %The experiment settings structure
%     trialinput.choicetype  %Set number (1:delay/2:risk/3:physical effort/4:mental effort)
%     trialinput.SSReward    %Reward for the uncostly (SS) option (between 0 and 1)
%     trialinput.Cost        %Cost level or the costly (LL) option (between 0 and 1)
%     trialinput.SideSS      %(optional) set on which side you want the uncostly (SS) option to be (enter string: 'left' or 'right')
%     trialinput.Example     %(optional, default 0) flag 1 if this is an example trial (with explanation text) 
%     trialinput.ITI         %(optional) fixation cross time before choice (default is random value between the set minimum and maximum value from exp_settings)
%     trialinput.plugins     %(optional) indicate any interacting devices, e.g. touchscreen or eyetracker
% Output:
%     trialoutput: updated structure with all the information about the choice trial
%     exitflag: 0 by default; 1 if the experiment was interrupted

%% Prepare
    %Set output (in case the user exits before choice is presented)
        trialoutput = struct;
    %Input defaults
        typenames = {'delay','risk','physical_effort','mental_effort'};
        sidenames = {'left','right'};
        if ~isfield(trialinput,'SideSS') || isempty(trialinput.SideSS)
            trialinput.SideSS = sidenames{1+round(rand)};
        end
        if ~isfield(trialinput,'Example') || isempty(trialinput.Example)
            trialinput.Example = 0;
        end
        if ~isfield(trialinput,'ITI') || isempty(trialinput.ITI)
            trialinput.ITI = exp_settings.timings.fixation_choice(1) + rand * (exp_settings.timings.fixation_choice(2)-exp_settings.timings.fixation_choice(1));
        end
        if ~isfield(trialinput,'plugins')
            trialinput.plugins = [];
        end
    %Keyboard
        leftKey = KbName('LeftArrow');
        rightKey = KbName('RightArrow');
        escapeKey = KbName('ESCAPE'); % (deliberately set to invariable)
        LRQ = [leftKey rightKey escapeKey];  % join keys 
    %Trial features
        %Reward for uncostly option
            SSReward = round(trialinput.SSReward*exp_settings.MaxReward,1);
            if SSReward == 1; SSRewardText = sprintf('%.2f euro', round(SSReward, 1));
            else; SSRewardText = sprintf('%.2f euros', round(SSReward, 1));
            end
            if trialinput.Example; SSRewardText = ['et recevoir ' SSRewardText]; end
        %Reward for costly option
            LLRewardText = sprintf('%.2f euros', exp_settings.MaxReward);
            if strcmp(typenames{trialinput.choicetype},'risk')
                LLLossText = ['ou -' sprintf('%.2f euros', exp_settings.RiskLoss)];
            else
                LLLossText = [];
            end
            if trialinput.Example
                if strcmp(typenames{trialinput.choicetype},'risk')
                    LLRewardText = ['pour gagner ' LLRewardText];
                    LLLossText = ['ou perdre ' sprintf('%.2f euros', exp_settings.RiskLoss)];
                else
                    LLRewardText = ['pour recevoir ' LLRewardText];                    
                end
            end
        %Choicetype-specific features
            switch typenames{trialinput.choicetype}
                case 'delay'
                    SSCostText = 'ne pas attendre';
                    LLCost = trialinput.Cost*exp_settings.MaxDelay; %Expressed in # of weeks <=== revise this for months!!!
                    [LLCost,LLCostText] = ConvertCost(LLCost,1,exp_settings);
                    LLCostText = ['attendre ce délai' newline newline '(' LLCostText ')'];
                case 'risk'
                    SSCostText = 'ne pas prendre de risque';
                    LLCost = round(trialinput.Cost*exp_settings.MaxRisk,1);
                    LLCostText = ['prendre ce risque' newline newline '(' num2str(LLCost) '%)'];
                case 'physical_effort'
                    SSCostText = 'ne pas faire d''effort';
                    LLCost = trialinput.Cost*exp_settings.Max_phys_effort;
                    [~,LLCostText] = ConvertCost(LLCost,3,exp_settings);
                    LLCostText = ['monter ces escaliers' newline newline '(' LLCostText ')'];
                case 'mental_effort'
                    SSCostText = 'ne pas faire d''effort';
                    LLCost = trialinput.Cost*exp_settings.Max_ment_effort;
                    [~,LLCostText] = ConvertCost(LLCost,4,exp_settings);
                    LLCostText = ['copier ces pages' newline newline '(' LLCostText ')'];
            end      
    %Set drawing parameters
        drawchoice.plugins = trialinput.plugins;
        drawchoice.choicetype = typenames{trialinput.choicetype};
        drawchoice.example = trialinput.Example;
        drawchoice.titletext = 'EXEMPLE: Préférez-vous...';
        drawchoice.confirmation = [];
        drawchoice.centerscreen = '+';
        switch trialinput.SideSS %Side definition
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
    %In example trials: load arrow key images (takes <0.01s)
        if trialinput.Example
            im_leftkey = imread([exp_settings.stimdir filesep 'leftkey.png']);
            im_rightkey = imread([exp_settings.stimdir filesep 'rightkey.png']);
            drawchoice.tex_leftkey = Screen('MakeTexture',window,im_leftkey);
            drawchoice.size_leftkey = size(im_leftkey);
            drawchoice.tex_rightkey = Screen('MakeTexture',window,im_rightkey);
            drawchoice.size_rightkey = size(im_rightkey);
        end
        
%% Present screens       
    %1.Fixation cross
        timings = BEC_Timekeeping('Choice_fixation',trialinput.plugins); %Get timings
        [exitflag,timestamp] = BEC_Fixation(window,exp_settings,trialinput.ITI);
        if exitflag; return; end
        timings.seconds = timestamp; %The exact onset time, in GetSecs
    %2.Display choice screen, wait for minimum response time
        KbReleaseWait;  % wait until all keys are released before start with trial again.   
        drawchoice.event = 'Choice_screenonset';
        timings = [timings BEC_DrawChoiceScreen(exp_settings,drawchoice,window)];
        pause(exp_settings.timings.min_resp_time);  % minimum response time to avoid constant button presses by the participant without thinking
    %3.Display choice screen and monitor for response
        drawchoice.centerscreen = '?';
        drawchoice.event = 'Choice_decisiononset';
        timings = [timings BEC_DrawChoiceScreen(exp_settings,drawchoice,window)];
    %4.Monitor for response...
        keyCode(LRQ) = 0; exitflag = 0;
        while ~any(keyCode(LRQ)) && ... % as long no button is pressed, AND...
            (GetSecs-timings(2).seconds) <= exp_settings.timings.max_resp_time % ... as long as the timeout limit is not reached
            [~, ~, keyCode] = KbCheck(-1);
            %Special case: tactile screen
                if isfield(trialinput.plugins,'touchscreen') && trialinput.plugins.touchscreen == 1 %Record finger press on selected option
                    keyCode = SelectOptionTouchscreen(window,trialinput,exp_settings,LRQ);           
                end
        end %while: monitor response
        timings = [timings BEC_Timekeeping('Choice_decisiontime',trialinput.plugins,GetSecs)]; 
        rt = timings(4).seconds-timings(2).seconds; %Response time
    %Screenshot
%         imageArray=Screen('GetImage', window);
%         imwrite(imageArray, 'choiceExample.png');
    %5.Record response and display confirmation screen
        if keyCode(leftKey)
            resp = leftKey;  
            exitflag = 0;
            if ~isempty(window)
                drawchoice.confirmation = 'left';
                drawchoice.event = 'Choice_confirmation';
                timings = [timings BEC_DrawChoiceScreen(exp_settings,drawchoice,window)];                                
            end
            WaitSecs(exp_settings.timings.show_response);  % show response before proceeding
        elseif keyCode(rightKey)
            resp = rightKey; 
            exitflag = 0;
            if ~isempty(window)
                drawchoice.confirmation = 'right';
                drawchoice.event = 'Choice_confirmation';
                timings = [timings BEC_DrawChoiceScreen(exp_settings,drawchoice,window)];                                     
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
    %Make the output structure
        trialoutput = trialinput;
    %Record decision and RT
        if isnan(resp) % time out
            trialoutput.choiceSS = NaN;
        elseif (strcmp(trialoutput.SideSS,'left') && resp == rightKey) || (strcmp(trialoutput.SideSS,'right') && resp == leftKey) % costly option chosen
            trialoutput.choiceSS = 0;
        else % uncostly option chosen
            trialoutput.choiceSS = 1;
        end
        trialoutput.RT = rt;        
    %Record the full trial info
        trialoutput.LLReward = 1; %Reward for the costly option (default)
        trialoutput.Choicetype = typenames{trialoutput.choicetype}; %name of the choice type
        switch trialoutput.choicetype
            case 1 %Delay
                trialoutput.Delay = trialoutput.Cost;
                trialoutput.Risk = 0; 
                trialoutput.PhysicalEffort = 0;
                trialoutput.MentalEffort = 0;
                trialoutput.Loss = 0;
            case 2 %Risk
                trialoutput.Delay = 0;
                trialoutput.Risk = trialoutput.Cost;
                trialoutput.PhysicalEffort = 0;
                trialoutput.MentalEffort = 0;
                trialoutput.Loss = exp_settings.RiskLoss/exp_settings.MaxReward;
            case 3 %Physical effort
                trialoutput.Delay = 0;
                trialoutput.Risk = 0;
                trialoutput.PhysicalEffort = trialoutput.Cost;
                trialoutput.MentalEffort = 0;
                trialoutput.Loss = 0;
            case 4 %Mental effort
                trialoutput.Delay = 0;
                trialoutput.Risk = 0;
                trialoutput.PhysicalEffort = 0;
                trialoutput.MentalEffort = trialoutput.Cost;
                trialoutput.Loss = 0;
        end
        trialoutput.ITI = timings(2).seconds-timings(1).seconds; %fixation time before choice onset (seconds)
        trialoutput.timings = timings; %timestamp of choice presentation on screen (format: [y m d h m s])

end
            
%% Convert cost levels ([0-1]) to analog values
function [LLCost,LLCostText] = ConvertCost(LLCost,choicetype,exp_settings)
% input:  LLCost is the cost level expressed as the fraction of the maximal cost

switch choicetype
    case 1 %DELAY
        % output: LLCost: [#months #days_in_last_month], required to fill in the calendar.
        %         LLCostText: in text, the amount of "months,weeks,days" of waiting time
        % Recode LLCost for drawing calendar
             total_months = floor(LLCost); %Amount of full months
             total_years = floor(LLCost/12); %Amount of full years
             monthly_days = repmat([31 28 31 30 31 30 31 31 30 31 30 31],1,total_years+1); %The #days of all months
             total_days = floor((LLCost-total_months)*(monthly_days(total_months+1))); %The #days of the last month
             LLCost = [total_months total_days]; %Note: this is required for drawing the calendar!
        % Generate textual delay
             n_weeks = floor(total_days/7); % #full weeks in the last month
             n_days = total_days-n_weeks*7; % #days in the last week of the month
             LLCostText = [];
             if rem(LLCost,12) == 0 %Special case: cost is the exact multiple of a number of years
                 if total_years >= 1
                    if total_years == 1; LLCostText = '1 an';
                    elseif total_years > 1; LLCostText = [num2str(total_years) 'ans'];
                    end
                 end
             else %Generate number of months/weeks/days
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
             end
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

%% Subfunction: monitor responses with MS Surface tactile screen
function [keyCode] = SelectOptionTouchscreen(window,trialinput,exp_settings,LRQ)
% Monitor whether a choice option is selected by a finger press or swipe on a touchscreen, such as the Windows Surface or the PRISME tactile screens.
% A correct response is: one finger taps or swipes over either option, within the x-margins of the costbox, along the
% full height of the screen. The finger must then be released again.
% The subfunction outputs a response as if it were a left or right key press. ESCAPE presses with finger do not exist.

%Pre-loop check: finger released from screen
    [~,~,buttons] = GetMouse;
    while any(buttons)
        [~,~,buttons] = GetMouse;
    end
%Loop until either option is pressed
    finger_on_option = false(1,2);
    confirm_release = false;
    [screenX, screenY] = Screen('WindowSize',window); %Get screen size
    SetMouse(screenX/2,screenY/2);
    while ~(any(finger_on_option) && confirm_release)
        %Monitor keypresses
            [~, ~, keyCode] = KbCheck(-1);
            if any(keyCode(LRQ)) %left/right/quit key is pressed
                return
            end
            [x,~,pressed] = GetMouse;
        %Check if an option is selected (sensitive area is within the x-limits of the cost box, over the full height of the screen)
            if trialinput.Example
                %Check left option
                    finger_on_option(1) = x >= exp_settings.choicescreen.costbox_left_example(1)*screenX & x <= exp_settings.choicescreen.costbox_left_example(3)*screenX;
                %Check right option
                    finger_on_option(2) = x >= exp_settings.choicescreen.costbox_right_example(1)*screenX & x <= exp_settings.choicescreen.costbox_right_example(3)*screenX;
            else
                %Check left option
                    finger_on_option(1) = x >= exp_settings.choicescreen.costbox_left(1)*screenX & x <= exp_settings.choicescreen.costbox_left(3)*screenX;
                %Check right option
                    finger_on_option(2) = x >= exp_settings.choicescreen.costbox_right(1)*screenX & x <= exp_settings.choicescreen.costbox_right(3)*screenX;
            end
        %Rule out possibility of tapping onto both options
            if all(finger_on_option)
                finger_on_option = false(1,2);
            end
        %Check if the screen is subsequently released (for confirmation)
            if any(finger_on_option) && ~any(pressed)
                confirm_release = true;
            end
    end %while
%Code response as if it was a keypress
    if finger_on_option(1) %left is selected
        keyCode(LRQ(1)) = true;
    elseif finger_on_option(2) %right is selected
        keyCode(LRQ(2)) = true;
    end
end