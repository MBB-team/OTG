%% BEC_Demo_Calibration
% Demonstration of the choice calibration procedure. Just below, select which type of cost you want to show, how many
% example trials you want to show first, and how many calibration trials you want to perform.
% This script then calls BEC_Calibration, the function that is used to calibrate a participant's individual preferences.
% It does so by trying to approximate the participant's indifference curve using an online trial generation procedure. 
% A figure is produced that visualizes this iterative procedure with every choice you make. The colors in the grid
% present the likelihood of being at indifference: yellow means a high probability of being at indifference, blue values
% are further removed from the indifference curve.

% Setup
    %What do you want to demonstrate?
        choicetype = 4; %1:delay/2:risk/3:physical effort/4:mental effort
        n_example_trials = 3; %example trials (with random costs and rewards) before starting the calibration
        n_calibration_trials = 20; %calibration trials for demo
    %Get the experiment settings
        exp_settings = BEC_Settings;
    %Create data structure and get experiment settings structure
        AllData = struct;
        AllData.exp_settings = exp_settings; 
        AllData.exp_settings.OTG.ntrials_cal = n_calibration_trials;
%Open a screen
    Screen('Preference', 'SkipSyncTests', 1); %Skip sync tests: yes
    Screen('Preference', 'VisualDebugLevel', 3); %Visual debug level
    Screen('Preference', 'SuppressAllWarnings', 1);
    KbName('UnifyKeyNames'); %unify across platforms
    screens=Screen('Screens');
    if max(screens)==2; i_screen = 1;
    else; i_screen = 0;
    end
    [w,h] = Screen('WindowSize',i_screen); 
    demo_rect = [0.4*w 0.2*h w 0.8*h]; %The demo screen will not fill the entire screen        
    [window,winRect] = Screen('OpenWindow',i_screen,exp_settings.backgrounds.default,demo_rect); %0 for Windows Desktop screen, 2 for external monitor
% Example trials before calibration
    for t = 1:n_example_trials
        trialinfo.choicetype = choicetype;   %Set number (1:delay/2:risk/3:physical effort/4:mental effort)
        trialinfo.SSReward = rand;  %Reward for the uncostly (SS) option (between 0 and 1)
        trialinfo.Cost = rand;      %Cost level or the costly (LL) option (between 0 and 1)
        trialinfo.Example = 1;      %Is this an example trial?
        [trialinfo,exitflag] = BEC_ShowChoice(window,exp_settings,trialinfo);
        if exitflag; BEC_ExitExperiment(AllData); end
    end
% Run calibration
    [AllData,exitflag] = BEC_Calibration(AllData,choicetype,window,2);
% Terminate
    sca
