%%

% Get settings structure:
    exp_settings = BEC_Settings;
    exp_settings.font.RatingFontSize = 36; %On tablet: set to 60
    AllData.pupil = 0;
    AllData.volume = 1;
    AllData.gender = 'm';
    AllData.plugins = [];
    AllData.exp_settings = exp_settings;
% Open screen:
    %PsychDebugWindowConfiguration([],0.75); %DEBUG MODE - to disable, type "clear Screen"
    Screen('Preference', 'SkipSyncTests', 1); %Skip sync tests: yes
    Screen('Preference', 'VisualDebugLevel', 1); %Visual debug level
    Screen('Preference', 'SuppressAllWarnings', 1);
    KbName('UnifyKeyNames'); %unify across platforms
    screens=Screen('Screens');
    if max(screens)==2
        [window,winRect] = Screen('OpenWindow',1,exp_settings.backgrounds.default); %1 for main screen
%         [window,winRect] = Screen('OpenWindow',2,exp_settings.backgrounds.default); %2 for external monitors
    else 
        [window,winRect] = Screen('OpenWindow',0,exp_settings.backgrounds.default); %0 for Windows Desktop screen
    end
    Screen(window,'BlendFunction',GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); %for the Alpha transparency values to take effect
    HideCursor  
    Screen('Flip',window);
    
% Test window
        [Ratings,timings,exitflag] = BEC_RateEmotion(window,AllData,'happiness');
        sca
    
    