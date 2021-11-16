
exp_settings = BEC_Settings;
AllData = struct;
AllData.plugins.touchscreen = 1;
AllData.exp_settings = exp_settings;


%Open a screen
    Screen('Preference', 'SkipSyncTests', 1); %Skip sync tests: yes
    Screen('Preference', 'VisualDebugLevel', 3); %Visual debug level
    Screen('Preference', 'SuppressAllWarnings', 1);
    KbName('UnifyKeyNames'); %unify across platforms
    [window,winRect] = Screen('OpenWindow',0,exp_settings.backgrounds.default); %0 for Windows Desktop screen
    Screen(window,'BlendFunction',GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); %for the Alpha transparency values to take effect
    HideCursor  
    
%Show instructions
    which_instruction = [101:111];
    [exitflag,timings] = BEC_InstructionScreens(window,AllData,which_instruction);
    BEC_ExitExperiment(AllData)