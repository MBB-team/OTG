% Demo of the choice calibration procedure

% Setup
    %Get the experiment settings
        exp_settings = BEC_Settings;
    %Start the experiment from the beginning, or at an arbitrary point. This depends on whether AllData exists.
        %Create data structure and get experiment settings structure
            AllData = struct;
            AllData.exp_settings = exp_settings; 
        %Participant data
            AllData.initials = input('Initials: ','s');
        %Get the settings and directories
            savename = [AllData.initials '_' datestr(clock,30)]; %Directory name where the dataset will be saved
            AllData.savedir = [exp_settings.datadir filesep savename]; %Path of the directory where the data will be saved      
            mkdir(exp_settings.datadir,savename); %Create the directory where the data will be stored
    %Add all experiment scripts and functions to the path
        addpath(genpath(exp_settings.expdir))     
    %Open a screen
        Screen('Preference', 'SkipSyncTests', 1); %Skip sync tests: yes
        Screen('Preference', 'VisualDebugLevel', 3); %Visual debug level
        Screen('Preference', 'SuppressAllWarnings', 1);
        KbName('UnifyKeyNames'); %unify across platforms
        [w,h] = Screen('WindowSize',0); demo_rect = [0.1*w 0.1*h 0.9*w 0.9*h]; %The demo screen will not fill the entire screen
        [window,winRect] = Screen('OpenWindow',0,exp_settings.backgrounds.default,demo_rect); %0 for Windows Desktop screen
% Run calibration
    choicetype = 4; %1:delay/2:risk/3:physical effort/4:mental effort
    exp_settings.calibration.ntrials = 20; 
    [AllData.trialinfo,exitflag] = BEC_Calibration(exp_settings,choicetype,window,AllData.savedir);
    if exitflag; BEC_ExitExperiment(AllData); end
% Save
    save([AllData.savedir filesep 'AllData'],'AllData'); 
% Terminate
    sca
