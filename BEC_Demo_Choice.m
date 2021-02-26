% Demonstration of choice types.
% Opens a screen and presents one choice, to be set below.

% Get settings structure:
    exp_settings = BEC_Settings;
% Open screen:
    Screen('Preference', 'SkipSyncTests', 1); %Skip sync tests: yes
    Screen('Preference', 'VisualDebugLevel', 1); %Visual debug level
    Screen('Preference', 'SuppressAllWarnings', 1);
    KbName('UnifyKeyNames'); %unify across platforms
    screens=Screen('Screens');
    if max(screens)==2
        [window,winRect] = Screen('OpenWindow',1,exp_settings.backgrounds.default); %2 for external monitors
    else
        [window,winRect] = Screen('OpenWindow',0,exp_settings.backgrounds.default); %0 for Windows Desktop screen
    end
    HideCursor  
    
% Choice screen
    for trial = 1:10
        %Set the choice trial settings-----------------------------------------------------------------------------------------
            trialinput.choicetype = randperm(4,1);   %Define choice type by number (1:delay/2:risk/3:physical effort/4:mental effort)
            trialinput.SSReward = rand;  %Reward for the uncostly (SS) option (between 0 and 1)
            trialinput.Cost = rand;      %Cost level or the costly (LL) option (between 0 and 1)
            trialinput.Example = 0;      %Is this an example trial? (1:Yes - with extra text / 0:No - minimal text on screen)
        %-----------------------------------------------------------------------------------------------------------------------
        [trialoutput,exitflag] = BEC_ShowChoice(window,exp_settings,trialinput);
    end
% Exit
    sca; %Screen: close all
    ShowCursor
    