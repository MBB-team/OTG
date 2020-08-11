% Testing MASTER

% Get settings:
    [exp_settings] = BEC_Settings;
    
% Open screen:
    %PsychDebugWindowConfiguration([],0.75); %DEBUG MODE - to disable, type "clear Screen"
    Screen('Preference', 'SkipSyncTests', 1); %Skip sync tests: yes
    Screen('Preference', 'VisualDebugLevel', 1); %Visual debug level
    Screen('Preference', 'SuppressAllWarnings', 1);
    KbName('UnifyKeyNames'); %unify across platforms
    [window,winRect] = Screen('OpenWindow',0,exp_settings.backgrounds.default); %0 for Windows Desktop screen
    HideCursor  
    
% Choice screen
    trialinfo = struct;
    trialinfo.trial = 1;        %Trial number
    trialinfo.choicetype = 1;   %Set number (1:delay/2:risk/3:physical effort/4:mental effort)
    trialinfo.SSReward = rand;  %Reward for the uncostly (SS) option (between 0 and 1)
    trialinfo.Cost = rand;      %Cost level or the costly (LL) option (between 0 and 1)
    trialinfo.Example = 1;
    [trialinfo,exitflag] = BEC_ShowChoice(window,exp_settings,trialinfo);

% Exit
    sca; %Screen: close all
    
return
%% Set outside choice function:
%Emotion-related (optional)
    emo_condition = AllData.triallist.choices.condition(choicetrial);
    trialinfo.induction = trial; %induction number
    trialinfo.ind_trialno = choicetrial-(trial-1)*exp_settings.choices_per_induction; %number of the choice following the induction
    trialinfo.condition = emo_condition; %emotion condition
    trialinfo.is_neutral = emo_condition==5; %is this a neutral trial (logical)
%Save
    AllData.trialinfo(choicetrial) = trialinfo;

