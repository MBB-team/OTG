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
        startpoint = 0;        
%     %Make triallist (AFTER choice calibration - TO DO)
%         if isfield(AllData,'Ratings') %Resume previously interrupted
%             i_induction = find(isnan(AllData.Ratings),1,'first');
%             if isempty(i_induction)
%                 BEC_ExitExperiment(AllData);
%                 error('Main experiment completed.')
%             end
%         else
%             %Make trial list
%                 triallist = [];
%                 while isempty(triallist) %"try" is just in case the sampling would go wrong
%                     try triallist = S10_Exp_MakeTrialList(AllData,exp_settings);
%                     catch; triallist = [];
%                     end
%                 end
%             %Prepare the main experiment battery (make trial list)
%                 i_induction = 1;
%                 AllData.timings.StartMainExperiment = clock; 
%                 AllData.triallist = triallist;
%                 AllData.Ratings = NaN(exp_settings.n_inductions,length(exp_settings.emotionnames));    
%                 AllData.trialinfo = struct;
%                 if AllData.pupil; AllData.eye_calibration = []; end
%             %Store
%                 save([AllData.savedir filesep 'AllData'],'AllData'); 
%             %Instructions
%                 exitflag = BEC_InstructionScreens(window,exp_settings,'phase_2');
%                 if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
%                 BEC_WaitForKeyPress({'UpArrow'});
%         end  
    %Pupil setup
        if AllData.pupil
            %Calibration
                calibrate = 1; %By default (re)calibrate, unless:
                if exist('Recalibrate','var') && (isempty(Recalibrate) || Recalibrate == 0)
                    calibrate = 0;
                end
                if calibrate
                    try
                        AllData.eye_calibration(1).results = BEC_SetupEyetracker(window,exp_settings);
                    catch
                        BEC_ExitExperiment(AllData);
                        error('Eye calibration failed.')
                    end
                else %Initialize eyetracker without calibrating
                    EyeTribeInit(60,90); % init EyeTribe at 60Hz and 90 seconds buffer
                end
            %Make pupil directory and store data
                mkdir(AllData.savedir,'Pupil'); %Make directory, if it doesn't exist yet
                EyeTribeGetDataSimple; %Clear the buffer
        end
    %Instructions
        exitflag = BECInstructionScreens(window,exp_settings,'start_main_experiment');
        if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
    %Loop through inductions
        for induction = i_induction:exp_settings.trialgen_emotions.n_inductions
            %Break half way
                if induction == exp_settings.trialgen_emotions.i_break
                    %Timing
                        AllData.timings.breakstart = clock;
                    %Turn off eyetracker
                        if AllData.pupil; EyeTribeUnInit; end
                    %Announcement
                        exitflag = BEC_InstructionScreens(window,exp_settings,'break');
                        if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
                    %Monitor keypress to proceed
                        proceed_Key = KbName(exp_settings.keys.proceedkey); escape_Key = KbName(exp_settings.keys.escapekey);
                        keyCode([proceed_Key escape_Key]) = 0; 
                        while keyCode(proceed_Key) == 0 && keyCode(escape_Key) == 0 % as long no button is pressed keep checking the keyboard
                            [~, ~, keyCode] = KbCheck(-1);
                        end
                    %Relaunch pupil (recalibrate pupil by default) or bail out
                        if keyCode(escape_Key)
                            BEC_ExitExperiment(AllData); return;
                        else
                            if AllData.pupil                                    
                                AllData.eye_calibration(2).results = S10_Exp_SetupEyetracker(window,exp_settings);
                                EyeTribeGetDataSimple; %Clear the buffer
                            end
                        end
                        FlushEvents('keyDown');
                    %Timing
                        AllData.timings.breakend = clock;
                end
            %Emotion induction
                %Define Eyetracker scene (i.e. induction number)
                    Trial_PupilData = [];
                    if AllData.pupil; EyeTribeSetCurrentScene(induction); end
                %Washout
                    BEC_Washout(window,AllData);
                %Emotion induction
                    [exitflag,AllData,player] = BEC_EmotionInduction(window,induction,AllData);
                    if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
                %Get pupil data from part one of the trial (emotion induction)
                    if AllData.pupil
                        [ ~, PupilData ,~] = EyeTribeGetDataSimple;
                        Trial_PupilData = [Trial_PupilData; PupilData];
                    end
            %Choice battery following the induction
                for choicetrial = (induction-1)*exp_settings.trialgen_emotions.choices_per_induction + (1:exp_settings.trialgen_emotions.choices_per_induction)
                    %Set the trial info
                        sidenames = {'left','right'};
                        trialinfo.trial = choicetrial; %Trial number (only required for the pupil marker)
                        trialinfo.induction = induction; %Emotion induction number
                        trialinfo.condition = AllData.triallist.choices.condition(choicetrial); %Emotion condition
                        trialinfo.choicetype = AllData.triallist.choices.choicetype(choicetrial); %Set number (1:delay/2:risk/3:physical effort/4:mental effort)
                        trialinfo.SSReward = AllData.triallist.choices.SSReward(choicetrial); %Reward for the uncostly (SS) option (between 0 and 1)
                        trialinfo.Cost = AllData.triallist.choices.LLCost(choicetrial); %Cost level or the costly (LL) option (between 0 and 1)
                        trialinfo.SideSS = sidenames{1+AllData.triallist.choices.sideSS(choicetrial)}; %(optional) set on which side you want the uncostly (SS) option to be (enter string: 'left' or 'right')
                        trialinfo.Pupil = AllData.pupil; %(optional, default 0) flag 1 if you want to record pupil data
                    %Present the choice
                        [AllData.trialinfo(choicetrial),exitflag] = BEC_ShowChoice(window,exp_settings,trialinfo);
                        if exitflag; BEC_ExitExperiment(AllData); return; end
                end
            %End of a choice battery: Turn off music
                if ~isnan(AllData.triallist.music_num(induction))
                    clear player       
                end
            %Rating
                tic
                AllData.timings.rating_timestamp(induction,:) = clock;
                [RateHappy,RateSad,RateCurious] = BEC_RateEmotion(window,AllData);
                AllData.Ratings(induction,:) = [RateHappy RateSad RateCurious];
                AllData.timings.rating_duration(induction,1) = toc;
            %Save the data at the end of each trial
                save([AllData.savedir filesep 'AllData'],'AllData');
                if AllData.pupil %Save pupil data from this trial
                    [ ~, PupilData ,~] = EyeTribeGetDataSimple;
                    Trial_PupilData = [Trial_PupilData; PupilData];
                    save([AllData.savedir filesep 'Pupil' filesep 'Pupil_' num2str(induction)],'Trial_PupilData');
                end
        end
        %Terminate the physiology recordings at the end of the battery
            if AllData.pupil; EyeTribeUnInit; end
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
            RH_WaitForKeyPress({exp_settings.keys.proceedkey});
            BEC_ExitExperiment(AllData)
    end