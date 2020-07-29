%% Additions to exp_settings:

%put colors in the beginning

exp_settings.Max_phys_effort = 12; % max # flights of stairs to climb
exp_settings.Max_ment_effort = 12; % max # pages to copy

%background colors
    exp_settings.backgrounds.fixation = exp_settings.colors.black;
    exp_settings.backgrounds.choice = exp_settings.colors.black;

%font colors
    exp_settings.font.FixationFontColor = exp_settings.colors.white;
    exp_settings.font.ChoiceFontColor = exp_settings.colors.white;
    
%choice screen parameters
    exp_settings.choicescreen.title_y = 1/8;                        %Title y position (choice)
    exp_settings.choicescreen.cost_left = [1/8 2/8 3/8 3/8];        %Left cost text
    exp_settings.choicescreen.cost_right = [5/8 2/8 7/8 3/8];       %Right costtext
    exp_settings.choicescreen.reward_left = [1/8 13/16 3/8 15/16];  %Left reward text
    exp_settings.choicescreen.reward_right = [5/8 13/16 7/8 15/16]; %Right reward text
    exp_settings.choicescreen.reward_shift = -[0 3/16 0 3/16];      %During actual choice trials, show rewards closer to the center of the screen
    exp_settings.choicescreen.costbox_left_example = [3/16 1/2 5/16 3/4];      %Left cost visualization
    exp_settings.choicescreen.costbox_right_example = [11/16 1/2 13/16 3/4];   %Right cost visualization
    exp_settings.choicescreen.costbox_left = [3/16 1/4 5/16 1/2];   %Left cost visualization
    exp_settings.choicescreen.costbox_right = [11/16 1/4 13/16 1/2];%Right cost visualization
    exp_settings.choicescreen.monthrects = [(0:11)./12; zeros(1,12); (1:12)./12; [31 28 31 30 31 30 31 31 30 31 30 31]./50]; %Delay visualization
    exp_settings.choicescreen.linewidth = 1;    %Width of the lines of the cost drawings
    exp_settings.choicescreen.linecolor = exp_settings.colors.white;%Color of the lines of the cost drawings
    exp_settings.choicescreen.fillcolor = exp_settings.colors.red;  %Color of the costs
    exp_settings.choicescreen.confirmcolor = exp_settings.colors.white;         %Color of the confirmation rectangle around the chosen option
    
%% Set outside choice function:
%Emotion-related (optional)
    emo_condition = AllData.triallist.choices.condition(choicetrial);
    trialinfo.induction = trial; %induction number
    trialinfo.ind_trialno = choicetrial-(trial-1)*exp_settings.choices_per_induction; %number of the choice following the induction
    trialinfo.condition = emo_condition; %emotion condition
    trialinfo.is_neutral = emo_condition==5; %is this a neutral trial (logical)
%Save
    AllData.trialinfo(choicetrial) = trialinfo;

