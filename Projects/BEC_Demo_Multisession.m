%% Demonstration of a multisession choice experiment.
% The participant undergoes multiple short sessions of economic binary choice batteries. Choices are presented by an
% adaptive online trial generation algorithm that uses posteriors from the previous session as priors for the current
% one. For each session, a data structure "AllData" is created. Model posteriors from the previous session are stored in
% "OTG_posterior.mat", which is updated at the end of each session.

%% Setup
% Don't forget to add VBA to the search path
    mkdir('Experiment data')
% Make a data structure, a new one for each session
    AllData = struct;
    AllData.exp_settings = BEC_Settings; %Get default settings structure
    AllData.session = input('Fill in the current session number: ');
    AllData.savedir = [cd filesep 'Experiment data' filesep 'Data_session_' num2str(AllData.session)]; %Defining the directory where data will be saved is necessary in order to be able to call "BEC_ExitExperiment" if needed.
    AllData.plugins.touchscreen = input('Experiment on a tactile screen device? (flag 1:yes / 0:no): '); %(optional; assumes no plugins by default)
    AllData.plugins.pupil = input('Record pupil data? (flag 1:yes / 0:no): '); %(optional; assumes no plugins by default)
% Adjustments to the default settings: if the experiment is performed on the Windows Surface Pro, this enhances the appearance of choices:
    if AllData.plugins.touchscreen
        AllData.exp_settings.font.RatingFontSize = 60; %Set fonts larger for the Surface, which has a high PPI
        AllData.exp_settings.font.FixationFontSize = 80; %Set fonts larger for the Surface, which has a high PPI
        AllData.exp_settings.font.RewardFontSize = 60; %Set fonts larger for the Surface, which has a high PPI
        AllData.exp_settings.choicescreen.costbox_left = [2/16 1/6 6.5/16 6/10]; %Left cost visualization is drawn in this "box"
        AllData.exp_settings.choicescreen.costbox_right = [9.5/16 1/6 14/16 6/10]; %Right cost visualization is drawn in this "box"
    end
% Adjustments to the default settings: online trial generation and choice presentation
    AllData.exp_settings.timings.min_resp_time = 0.5; %[s] before ppt can respond
    AllData.exp_settings.timings.show_response = 0.25; %[s] visual feedback duration (confirmation rectangle around selected option)
    AllData.exp_settings.timings.fixation_choice = [0.5 0.5]; %[s] minimum and maximum jittered fixation time during experiment
    AllData.exp_settings.OTG.max_n_inv = Inf; %Recency criterion: take only most recent trials into account (not needed - set to Inf)
% Get past session's model posteriors and set them as priors
    if AllData.session ~= 1
        load([cd filesep 'Experiment data' filesep 'OTG_posterior.mat']) %Load the model posteriors from the previous session
        AllData.OTG_prior.delay.muPhi = OTG_posterior.delay.muPhi;
        AllData.OTG_prior.risk.muPhi = OTG_posterior.risk.muPhi;
        AllData.OTG_prior.physical_effort.muPhi = OTG_posterior.physical_effort.muPhi;
        AllData.OTG_prior.mental_effort.muPhi = OTG_posterior.mental_effort.muPhi;
    else %If this is the first session: use population average model as prior
        AllData.OTG_prior.delay.muPhi = [-3.6628;0.2041;-2.2642;-2.8915;-3.2661;-1.8419];
        AllData.OTG_prior.risk.muPhi = [-1.4083;0.8217;-1.1018;-1.1148;-0.6224;0.2078];
        AllData.OTG_prior.physical_effort.muPhi = [-5.4728;-2.9728;-2.4963;-1.8911;-0.3541;-1.7483];
        AllData.OTG_prior.mental_effort.muPhi = [-4.0760;0.2680;-0.5499;-2.0245;-2.6053;-1.9991];
    end
% Open screen
    Screen('Preference', 'SkipSyncTests', 1); %Skip sync tests: yes
    Screen('Preference', 'VisualDebugLevel', 1); %Visual debug level
    Screen('Preference', 'SuppressAllWarnings', 1);
    KbName('UnifyKeyNames'); %unify across platforms
    [window,winRect] = Screen('OpenWindow',0,exp_settings.backgrounds.default); %0 for Windows Desktop screen
    HideCursor  
    
%% Present choices
% The algorithm will now start presenting choices along a distribution that gets updated with every choice trial. The
% priors have been provided above. "AllData" gets updated with every trial: it will contain a the full details of all
% presented trials in the structure AllData.trialinfo, and it will contain the posteriors from the online trial
% generation procedure in AllData.OTG_posterior. The generated trials are of the four different choice types, presented
% in a random order but such that each set of 4 subsequent trials contains one occurrence of each choice type, and no
% two subsequent trials (the last of the previous set of 4 and the first of the next set of 4) are of the same type.
% You can specify your own trial list, though. See on top of the function below how "AllData.triallist" should be
% defined.
% The experiment can be interrupted at any time by pressing ESCAPE, provided that you have defined AllDat.savedir.
    AllData.start_time = clock;
    while etime(clock,AllData.start_time) < 600 %Session time: 10 minutes
        AllData = BEC_OnlineTrialGeneration_VBA(AllData,window);
    end
    
%% Terminate
    mkdir(AllData.savedir)
    save([AllData.savedir filesep 'AllData'],'AllData'); %save AllData - the data from the current session
    OTG_posterior = AllData.OTG_posterior;
    save([cd filesep 'Experiment data' filesep 'OTG_posterior'],'OTG_posterior'); %Save the model posteriors for the next session. Note: save it in the pwd, or wherever you want to load it (see line 32!)
    sca; %close    
    ShowCursor;