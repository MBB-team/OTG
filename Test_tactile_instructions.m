
exp_settings = BEC_Settings;
AllData = struct;
AllData.plugins.touchscreen = 0;
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
    which_instruction = [101:103];
    completed = false;
    while ~completed
        BEC_InstructionScreens(window,AllData,which_instruction);
        [left_or_right,~] = BEC_Show_Another_Example(window,AllData,'another_example');
        switch left_or_right
            case 'escape'; BEC_ExitExperiment(AllData); return
            case 'left'; completed = false; %do nothing
            case 'right'; completed = true;
        end
    end
    sca
    
%% Test escape cross

%Settings
    exp_settings.tactile.escapeCross_ySize = 1/20; %Size relative to screen height
    exp_settings.font.escapeCrossFontSize = exp_settings.font.RewardFontSize/2; %Size of the "X" to click in order to exit the screen

%Default way of getting screen size
    [Xsize, Ysize] = Screen('WindowSize', window); screensize = [Xsize Ysize Xsize Ysize];

%Draw escape cross
    escapeCrossSize = exp_settings.tactile.escapeCross_ySize*Ysize;
    escapeCrossRect = [Xsize-1.5*escapeCrossSize 0.5*escapeCrossSize Xsize-0.5*escapeCrossSize 1.5*escapeCrossSize];
    Screen('FillRect',window,exp_settings.colors.red,escapeCrossRect);
    Screen('TextSize',window,exp_settings.font.escapeCrossFontSize); %Careful to set the text size back to what it was before
    DrawFormattedText(window, 'X', 'center', 'center', exp_settings.colors.white,[],[],[],[],[],escapeCrossRect);
    
