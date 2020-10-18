% Demonstration of choice types.
% Opens a screen and presents one choice, to be set below.

% Set the choice trial settings-----------------------------------------------------------------------------------------
    trialinfo.trial = 1;        %Trial number
    trialinfo.choicetype = 4;   %Set number (1:delay/2:risk/3:physical effort/4:mental effort)
    trialinfo.SSReward = 2/30;  %Reward for the uncostly (SS) option (between 0 and 1)
    trialinfo.Cost = 1/50;      %Cost level or the costly (LL) option (between 0 and 1)
    trialinfo.Example = 0;      %Is this an example trial?
%-----------------------------------------------------------------------------------------------------------------------

% Get settings:
    [exp_settings] = BEC_Settings;
% Open screen:
    %PsychDebugWindowConfiguration([],0.75); %DEBUG MODE - to disable, type "clear Screen"
    Screen('Preference', 'SkipSyncTests', 1); %Skip sync tests: yes
    Screen('Preference', 'VisualDebugLevel', 1); %Visual debug level
    Screen('Preference', 'SuppressAllWarnings', 1);
    KbName('UnifyKeyNames'); %unify across platforms
    screens=Screen('Screens');
    if max(screens)==2; [window,winRect] = Screen('OpenWindow',2,exp_settings.backgrounds.default); %2 for external monitors
    else; [window,winRect] = Screen('OpenWindow',0,exp_settings.backgrounds.default); %0 for Windows Desktop screen
    end
    HideCursor  
% Choice screen
    [trialinfo,exitflag] = BEC_ShowChoice(window,exp_settings,trialinfo);
% Exit
    sca; %Screen: close all
    ShowCursor
    