function [AllData] = BEC_RewardTrialSelection(window,AllData)
% Select a trial to be rewarded.
% Visualze the selection process.

%Settings
    n_reward_trials = 1; %How many trials will be selected in total
    whichparts = [1 2]; %Part 1: selection / part 2: display of total reward
    winRect = zeros(1,4);
    [winRect(3), winRect(4)] = Screen('WindowSize', window);
    trialinfo = struct2table(AllData.trialinfo);
    trialinfo = trialinfo(ismember(trialinfo.choicetype,[2 3 4]),:);
    nTrials = size(trialinfo,1);  %total number of trials
    showtrials = round(nTrials/6);     %selection of them to show
%Update the settings
    exp_settings = AllData.exp_settings;
    exp_settings.Pay.Base = 20;     %euros base pay
    exp_settings.Pay.LLRew = 30;    %euros for LL option
    exp_settings.Pay.delaycriterion = 0.50;     %Max. delay of costly option
    exp_settings.Pay.effortcriterion = 5/12;    %Max. effort of costly option
    exp_settings.Pay.riskcriterion = 0.75;  %Max. risk of costly option
    exp_settings.Pay.min_total = 20; %Min. total reward
    exp_settings.Pay.max_total = 35; %Max. total reward
    exp_settings.Pay.SSCriterion = 0.10; %For very low amounts of SS choices: allow maximum to be higher
%Select the rewarded trial
    RewardTrials = GetRewardTrials(trialinfo,exp_settings,n_reward_trials); % Select the rewarded trial
%Colors
    white = [255 255 255];
    black = [0 0 0];
    grey = [128 128 128];
    red = [200 50 100];
    
%% Visualise the reward trial selection
%Loop through parts and types to show
for showparts = whichparts
    Screen('FillRect',window,black);  %black background
    
    flips = 1;
    showselect = 0;    %After the trial has been selected, show its features (on the right)
%     if showparts == 1
        showtypes = [0 1];
%     else
%         showtypes = [RewardTrials(:).choicetype]';
%     end
    for showtype = showtypes
        %Which trials to show during looping on screen
            if showparts == 1
                showlooptrials = [];
                for trl = 1:n_reward_trials
                    showlooptrials = [showlooptrials; randperm(nTrials,showtrials)];
                end
                if showtype; showlooptrials = [showlooptrials [RewardTrials(:).trial]']; end
            else
                showlooptrials = [RewardTrials(:).trial]';
            end
        %Loop through sampled trials on screen
            while flips <= length(showlooptrials) %For visualization of selected trials
            %Title and subtext
                Screen('TextSize',window,30); 
                Screen('TextFont',window,'Arial');
                titletext = 'Sélection aléatoire des décisions rémunérées';
                DrawFormattedText(window,titletext,'center',winRect(4)*1.5/14,white); 
                if showparts == 1 && showtype == 0
                    subtext = 'Appuyez sur la barre espace pour lancer la sélection aléatoire.';
                    DrawFormattedText(window,subtext,'center',winRect(4)*13/14,white); 
                    Screen('Flip',window);
                    break %out of while loop            
                end            
            %Fill in left rectangles
                if showtype ~= 0
                    for trl = 1:n_reward_trials
                        i = RewardTrials(trl).choicetype-1;
                        rectsleft = [winRect(3)/12 winRect(4)*i*3/14 winRect(3)*5/12 winRect(4)*(i*3+2)/14];
                        Screen('FillRect',window,grey,rectsleft);
                        Screen('TextSize',window,24); 
                            boxtexts1 = {'Décisions avec risque';'Décisions avec effort physique';'Décisions avec effort de concentration'};
                            boxtext1a = boxtexts1{i};
                        DrawFormattedText(window,boxtext1a,2/12*winRect(3),(i*3+0.5)/14*winRect(4),white);
                            if showparts == 1; boxtext1b = 'Choix sélectionné :'; else; boxtext1b = 'Votre récompense :'; end
                        DrawFormattedText(window,boxtext1b,2/12*winRect(3),(i*3+1.5)/14*winRect(4),white);
                    end
                end
                %Show trial selected/selection
                    for trl = 1:n_reward_trials
                        i = RewardTrials(trl).choicetype-1;
                        if showparts == 1 %Select trial
                            boxtext1c = ['# ' num2str(showlooptrials(trl,flips))];
                            DrawFormattedText(window,boxtext1c,4/12*winRect(3),(i*3+1.5)/14*winRect(4),red);
                            if flips == length(showlooptrials)
                                subtext = 'Appuyez sur la barre espace.';
                                DrawFormattedText(window,subtext,'center',winRect(4)*13/14,white);
                            end
                        else %Show total reward
                            boxtext1c = [num2str(round(RewardTrials(trl).reward,1)) ' euros'];
                            DrawFormattedText(window,boxtext1c,4/12*winRect(3),(i*3+1.5)/14*winRect(4),red);
                            display_reward = sum([RewardTrials(:).reward]) + exp_settings.Pay.Base;
                            subtext = ['Votre dédommagement total : ' num2str(round(display_reward,1)) ' euros.'];
                            DrawFormattedText(window,subtext,'center',winRect(4)*13/14,white); 
                        end
                    end
            %Fill in right rectangles
                if showtype ~= 0
                    if flips == length(showlooptrials); showselect = 1; end
                    if showselect == 1 %Draw trial features of previous or just now selected choice types
                        for trl = 1:n_reward_trials
                            i = RewardTrials(trl).choicetype-1;
                            %Rectangle and fixation cross
                                rectsright = [winRect(3)*7/12 winRect(4)*(i)*3/14 winRect(3)*11/12 winRect(4)*((i)*3+2)/14];     
                                Screen('FillRect',window,grey,rectsright);
                                Screen('TextSize',window,18); 
                                DrawFormattedText(window, '+', 'center', 'center', black, [], [], [], [], [], rectsright); 
                            %Left side (a) of right rectangle (2): SS
                                rectsright_a = rectsright; rectsright_a(3) = winRect(3)*9/12;
                                rewardleft = RewardTrials(trl).SSReward * exp_settings.MaxReward;
                                if RewardTrials(trl).choice == 1; choicecolor = red; else; choicecolor = white; end
                                switch i
                                    case 1; costleft = 'sans risque';
                                    case 2; costleft = 'sans effort physique';
                                    case 3; costleft = 'sans effort de concentration';
                                end
                                boxtext2a  = sprintf('%.2f euros\n\n\n%s', round(rewardleft, 1), costleft);  % dispaly amounts as X.XX Euros                            
                                DrawFormattedText(window, boxtext2a, 'center', 'center', choicecolor, [], [], [], [], [], rectsright_a);
                            %Right side (b) of right rectangle (2): LL
                                rectsright_b = rectsright; rectsright_b(1) = winRect(3)*9/12;
                                rewardright = exp_settings.Pay.LLRew; %Only for text
                                if RewardTrials(trl).choice == 0; choicecolor = red; else; choicecolor = white; end
                                switch i
                                    case 1 %risk
                                        costright = ['ou -10 euros (' num2str(round(100*RewardTrials(trl).LLCost,1)) ' % risque)'];                         
                                    case 2 %phys effort
%                                         EffortAmount = RewardTrials(trl).LLCost * exp_settings.MaxEffort;
%                                         costright = [num2str(round(EffortAmount)) ' Watt'];
                                        EffortAmount = trialinfo.Cost*exp_settings.Max_phys_effort;
                                        nfloors = floor(EffortAmount);
                                        nsteps = round((EffortAmount-floor(EffortAmount))*exp_settings.choicescreen.flightsteps);
                                        costright = 'ou monter ';
                                        %Floors
                                            if nfloors == 1
                                                costright = '1 étage';
                                            elseif nfloors > 1
                                                costright = [num2str(nfloors) ' étages'];
                                            end
                                        %Steps
                                            if nsteps > 0
                                                if nfloors > 0
                                                    costright = [costright ' + '];
                                                end
                                                if nsteps == 1
                                                    costright = [costright '1 marche'];
                                                else
                                                    costright = [costright num2str(nsteps) ' marches'];
                                                end
                                            end
                                    case 3 %mental effort
                                        LLCost = trialinfo.Cost*exp_settings.Max_ment_effort;
                                        npages = floor(LLCost);
                                        nlines = round((LLCost-floor(LLCost))*exp_settings.choicescreen.pagelines);
                                        costright = 'ou copier ';
                                        %Pages
                                            if npages == 1
                                                costright = '1 page';
                                            elseif npages > 1
                                                costright = [num2str(npages) ' pages'];
                                            end
                                        %Lines
                                            if nlines > 0
                                                if npages > 0
                                                    costright = [costright ' + '];
                                                end
                                                if nlines == 1
                                                    costright = [costright '1 ligne'];
                                                else
                                                    costright = [costright num2str(nlines) ' lignes'];
                                                end
                                            end
                                end
                                boxtext2b = sprintf('%.2f euros\n\n\n%s', round(rewardright, 1), costright);  % dispaly amounts as X.XX Euros
                                DrawFormattedText(window, boxtext2b, 'center', 'center', choicecolor, [], [], [], [], [], rectsright_b);
                        end %for trl
                    end %if showselect(i) == 1
                end %for i == showtype
                Screen('Flip',window);
                WaitSecs(0.05);
                flips = flips + 1;
            end %while flips < maxflips
            flips = 1;
            if showparts == 1
                RH_WaitForKeyPress({'space'}); %Wait for keypress to continue
                KbReleaseWait;
                if any([RewardTrials(:).choicetype] == 2) && showtype == 1
                    trl = find([RewardTrials(:).choicetype] == 2);
                    if RewardTrials(trl).choice == 0
                        risk = RewardTrials(trl).LLCost;
                        if RewardTrials(trl).reward < 0
                            win = 0;
                        else
                            win = 1;
                        end
                    else
                        risk = 0; win = 1;
                    end
                    certainreward = RewardTrials(trl).SSReward * exp_settings.MaxReward;
                    WheelOfFortune(window,winRect,risk,win,certainreward);
                end
            end %if showparts
    end %for showtype 
end %for showparts

%Store
    AllData.RewardTrials = RewardTrials;

end %function

function WheelOfFortune(window,winRect,risk,win,certainreward)
% Entirely copied from S5_WheelOfFortune -- sole purpose is to display it
% on the risk trial implementation.

%% Settings
%Visualizations
    riskcolor = [0.6350, 0.0780, 0.1840].*255;       %Red
    probacolor = [0.4660, 0.6740, 0.1880].*255;      %Green
    pointercolor = [0.8500, 0.3250, 0.0980].*255;    %Orange
%Randomizers
    riskangle = risk*360;
    if win %pin on probability
        min_a = 3;                  %minimum start angle
        max_a = 360-riskangle-3;    %maximum start angle
        finalangle = round((max_a - min_a) * rand + min_a);    %randomly between min and max start angle
    else %loss: pin on risk
        min_a = 360-riskangle+3;    %minimum start angle
        max_a = 360-3;              %maximum start angle
        finalangle = round((max_a - min_a) * rand + min_a);    %randomly between min and max start angle
    end
    angle_level = ceil(finalangle/360*10); %Which of the 10 jumps in a circle is it
    spins = ceil(4*rand+3); %no. of spins, between 3 and 7
    jumpsize = (spins*360+finalangle)/(spins*20+angle_level);
    loopangles = 0:jumpsize:(spins*360+finalangle);

%% Display the chosen option screen
Screen('FillRect',window,[0 0 0]);
anglecount = 1;   
while anglecount <= length(loopangles)
    angle = loopangles(anglecount);
    wheelradius = winRect(4)/4;
    wheelrect = [winRect(3)/2-wheelradius winRect(4)/2-wheelradius winRect(3)/2+wheelradius winRect(4)/2+wheelradius];
    %Draw risk arc
        startAngle_risk = angle;
        arcAngle_risk = riskangle;
        Screen('FillArc',window,riskcolor,wheelrect,startAngle_risk,arcAngle_risk)
    %Draw probability arc
        startAngle_proba = angle+arcAngle_risk;
        arcAngle_proba = 360-arcAngle_risk;
        Screen('FillArc',window,probacolor,wheelrect,startAngle_proba,arcAngle_proba)
    %Title or pointer
        if angle == 0
            text1 = 'Roue de fortune';
            Screen('TextSize',window,30); 
            Screen('TextFont',window,'Arial');
            DrawFormattedText(window,text1,'center',winRect(4)/8,pointercolor); 
        else
            points = [winRect(3)/2 winRect(4)/4;    %pointer tip
                      winRect(3)/2-wheelradius/9 winRect(4)/4-wheelradius/3;
                      winRect(3)/2+wheelradius/9 winRect(4)/4-wheelradius/3];
            Screen('FillPoly', window, pointercolor, points);
        end
    %Probabilities
        Screen('TextSize',window,24); 
        if risk == 0
            text2 = ['100% chance de ganger ' num2str(round(certainreward,2)) ' euros'];
                rightrect = [winRect(3)/2+wheelradius*6/5 winRect(4)/4 winRect(3) winRect(4)/2]; 
                DrawFormattedText(window,text2,rightrect(1),rightrect(2),probacolor,40, [],[],[],[],rightrect);     
        else
            text2 = [num2str(100*round(risk,3)) '% risque de perdre 10 euros'];
                rightrect = [winRect(3)/2+wheelradius*6/5 winRect(4)/4 winRect(3) winRect(4)/2]; 
                DrawFormattedText(window,text2,rightrect(1),rightrect(2),riskcolor,40, [],[],[],[],rightrect);     
            text3 = [num2str(100*round(1-risk,3)) '% chance de gagner 30 euros'];
                leftrect = [0 winRect(4)/4 winRect(3)/2-wheelradius*6/5 winRect(4)/2];
                DrawFormattedText(window,text3,'right',leftrect(2),probacolor,40,[],[],[],[],leftrect);                 
        end    
    %Announce spin or outcome
        if angle == loopangles(end) && win == 1 && risk ~= 0
            text4 = 'Vous avez gagné la loterie. Vous recevrez 30 euros.';
        elseif angle == loopangles(end) && win == 0 && risk ~= 0
            text4 = 'Vous avez perdu la loterie. Vous perdez 10 euros.';
        elseif angle == 0 && risk ~= 0
            text4 = 'Appuyez sur la barre espace pour faire tourner la roue.';
        elseif risk == 0
            text4 = ['Vous avez choisi l''option certaine. Vous recevrez ' num2str(round(certainreward,2)) ' euros.'];
            anglecount = length(loopangles); angle = loopangles(anglecount);
        else
            text4 = [];
        end
        if ~isempty(text4)
            DrawFormattedText(window,text4,'center',10/12.*winRect(4),[255 255 255]); 
        end
        if anglecount == length(loopangles)
            text5 = 'Appuyez sur la barre espace pour continuer.';
            DrawFormattedText(window,text5,'center',11/12.*winRect(4),[255 255 255]); 
        end
    %Hold
        Screen('Flip',window);
        switch anglecount
            case 1
                RH_WaitForKeyPress({'space'})
                anglecount = anglecount + 1;
            case length(loopangles)
                RH_WaitForKeyPress({'space'}); break
            otherwise
                WaitSecs(0.03);
                anglecount = anglecount + 1;
        end
end %while anglecount <= length(loopangles)

end %subfunction

function [LLCostText] = ConvertDelay(delay,exp_settings)

    LLCost = round(delay*exp_settings.MaxDelay); %Expressed in # of weeks
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
%             if n_days>=1; LLCostText = [LLCostText ', ']; end
        end
        %Don't show the amount of days...
%         if n_days >= 1
%             if n_days == 1; LLCostText = [LLCostText num2str(n_days) ' jour']; 
%             elseif n_days > 1; LLCostText = [LLCostText num2str(n_days) ' jours']; 
%             end
%         end
        if LLCost == 52
            LLCostText = '1 an';
        end
end

function [RewardTrials] = GetRewardTrials(trialinfo,exp_settings,n_rew_trials)
% Select two trials to be rewarded

%Settings
    trialno = (1:size(trialinfo,1))'; 
    accept_reward = 0;    
%Sample possible options
    while ~accept_reward
        %Select two trials
            selected_trials = NaN(1,n_rew_trials);
            selected_rewards = NaN(1,n_rew_trials);
            selected_types = NaN(1,n_rew_trials);
            for trl = 1:n_rew_trials
                %Apply criteria to choice trials
                    select =  trialinfo.Risk <= exp_settings.Pay.riskcriterion & ...
                              trialinfo.MentalEffort <= exp_settings.Pay.effortcriterion & ...
                              trialinfo.PhysicalEffort <= exp_settings.Pay.effortcriterion & ...
                              ~ismember(trialno, selected_trials(1:n_rew_trials-1)) & ...
                              ~ismember(trialinfo.choicetype, selected_types(1:n_rew_trials-1));
                    if sum(select) == 0 %In case no trial meets the criteria
                        select = trialno ~= selected_trials(1);
                    end
                    allowed_trials = find(select);
                %Sample one trial
                    i_selected = randperm(length(allowed_trials),1);
                    selected_trials(trl) = allowed_trials(i_selected);
                    selected_types(trl) = trialinfo.choicetype(selected_trials(trl));
                %Calculate reward
                    selected_rewards(trl) = trialinfo.choiceSS(selected_trials(trl)) * trialinfo.SSReward(selected_trials(trl)) + ~trialinfo.choiceSS(selected_trials(trl));
                    if trialinfo.choicetype(selected_trials(trl))==2 && ~trialinfo.choiceSS(selected_trials(trl))
                        win_lottery = rand > trialinfo.Risk(selected_rewards(trl));
                        if ~win_lottery
                            selected_rewards(trl) = -exp_settings.RiskLoss/exp_settings.MaxReward;
                        end
                    end
            end %for trl
        %Verify if the criteria are met
            total_reward = exp_settings.Pay.Base + sum(selected_rewards.*exp_settings.Pay.LLRew);
            if total_reward >= exp_settings.Pay.min_total
                if mean(trialinfo.choiceSS) > exp_settings.Pay.SSCriterion
                    if total_reward <= exp_settings.Pay.max_total
                        accept_reward = 1;
                    else
                        accept_reward = 0;
                    end
                else
                    accept_reward = 1;
                end
            end
    end %while
%Generate output
    RewardTrials = struct;
    for trl = 1:n_rew_trials
        RewardTrials(trl).trial = selected_trials(trl);
        RewardTrials(trl).choicetype = trialinfo.choicetype(selected_trials(trl));
        RewardTrials(trl).SSReward = trialinfo.SSReward(selected_trials(trl));
        RewardTrials(trl).LLCost = trialinfo.Delay(selected_trials(trl))+trialinfo.Risk(selected_trials(trl))+trialinfo.Effort(selected_trials(trl));
        RewardTrials(trl).choice = trialinfo.choiceSS(selected_trials(trl));
        RewardTrials(trl).reward = selected_rewards(trl)*exp_settings.Pay.LLRew;        
    end %for trl
end %function