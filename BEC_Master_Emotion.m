% BECHAMEL Master
% Battery of Economic CHoices And Mood/Emotion Links
% Master script for experiment with emotion inductions

%% Start the experiment
    %Get the experiment settings
        exp_settings = BEC_Settings;
    %Start the experiment from the beginning, or at an arbitrary point. This depends on whether AllData exists.
        if ~exist('AllData','var') %Make new datast
            startpoint = 0;
            %Create data structure and get experiment settings structure
                AllData = struct;
                AllData.exp_settings = exp_settings; 
            %Participant data
                AllData.initials = input('Initials: ','s');
                AllData.gender = input('Gender (m/f): ','s'); %This information is needed for the French emotion vignettes (which are gendered)
            %Get the settings and directories
                savename = [AllData.initials '_' datestr(clock,30)]; %Directory name where the dataset will be saved
                AllData.savedir = [exp_settings.datadir filesep savename]; %Path of the directory where the data will be saved      
                mkdir(exp_settings.datadir,savename); %Create the directory where the data will be stored
                disp('Dataset and directory created.')
        else %A dataset already exists
            clearvars -except AllData %Keep only the data structure
            startpoint = input('Enter start point (1.TO DO/2.TO DO/3.TO DO/4.TO DO/5.TO DO): '); %Pre-start checks
        end
    %Add all experiment scripts and functions to the path
        addpath(genpath(exp_settings.expdir)) 
    %Pupil settings
        AllData.pupil = input('Record pupil? (flag 1:yes / 0:no): ');
        if startpoint == 3 %Main experiment
            Recalibrate = input('(Re)calibrate eyes? (flag 1:yes / 0:no): ');
        end    
    %Volume setting required?        
        if isfield(AllData,'volume'); disp('Volume setting found.')
        else; disp('No volume setting found.')
        end
        setvolume = input('Set or reset volume first? (flag 1:yes / 0:no): ');    
    %Open a screen
        Screen('Preference', 'SkipSyncTests', 1); %Skip sync tests: yes
        Screen('Preference', 'VisualDebugLevel', 3); %Visual debug level
        Screen('Preference', 'SuppressAllWarnings', 1);
        KbName('UnifyKeyNames'); %unify across platforms
        [window,winRect] = Screen('OpenWindow',0,exp_settings.backgrounds.default); %0 for Windows Desktop screen
        HideCursor  
    %Set experiment volume first
        if setvolume; AllData = BEC_SetVolume(window,AllData); end
    %Save
        save([AllData.savedir filesep 'AllData'],'AllData'); 
        disp('Dataset saved. Experiment will start now.')    
        
%% [1] General introduction and instructions + examples for emotions
    startpoint = 0; %always reset to zero
        %Show instructions (Note: first two slides are general introduction slides)
            exitflag = BEC_InstructionScreens(window,exp_settings,'start_emotion_instructions');
            if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
        %Show examples: induction + rating
            for i_ex = 1:length(exp_settings.Emostimuli.ExampleEmotions)
                %Fixation cross
                    exitflag = BEC_Fixation(window,exp_settings,1.5); %Some extra fixation cross first
                    if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
                %Present emotion stimuli
                    %Get vignette text
                        switch AllData.gender
                            case 'm'; stim.text = exp_settings.Emostimuli.ExampleVignettes_m{i_ex};
                            case 'f'; stim.text = exp_settings.Emostimuli.ExampleVignettes_f{i_ex};
                        end
                    %Get music
                        switch exp_settings.Emostimuli.ExampleEmotions(i_ex)
                            case exp_settings.Emostimuli.i_happiness; stim.music = exp_settings.Emostimuli.ExampleHappyMusic;
                            case exp_settings.Emostimuli.i_sadness; stim.music = exp_settings.Emostimuli.ExampleSadMusic;
                            case exp_settings.Emostimuli.i_neutral; stim.music = []; %neutral: text only
                        end
                    %Show stimulus
                        [exitflag,~,player] = BEC_EmotionInduction(window,stim,AllData);                    
                        clear player %turn off sound   
                        if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment   
                    %Rating
                        BEC_RateEmotion(window,AllData);
            end
        %Show instruction
            exitflag = BEC_InstructionScreens(window,exp_settings,'end_emotion_instructions');
            if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
            
%% [2] Instructions, examples, and calibration of choice tasks
    if startpoint == 0 || startpoint == 2
        % TO DO
    end
    
%% [3] Main experiment
    if startpoint == 0 || startpoint == 3
        startpoint = 0; %always reset to zero
        % TO DO
    end
    
% [4] Likeability ratings ?
    if startpoint == 0 || startpoint == 4
%         startpoint = 0; %always reset to zero
%         AllData = S10_Exp_RateLikeability(window,AllData);
    end
    
% [5] Reward calculation ?
    if startpoint == 0 || startpoint == 5
        %Reward calculation
            % TO DO ?
        %Terminate the experiment
            RH_WaitForKeyPress({'UpArrow'});
            BEC_ExitExperiment(AllData)
    end