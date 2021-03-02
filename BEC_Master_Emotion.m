% BECHAMEL Master
% Battery of Economic CHoices And Mood/Emotion Links
% Master script for experiment with emotion inductions, made to be a 30-minute version of the experiment tailored for
% iEEG studies.

%% Set up the experiment
    %Start the experiment from the beginning, or at an arbitrary point. This depends on whether AllData exists.
        if exist('AllData','var')
            if isfield(AllData,'bookmark')
                if AllData.bookmark == 0 %A dataset exists but it has no data in it => start again
                    clear %Clear everything and start again
                elseif AllData.bookmark > 0 
                    clc
                    use_existing = input(['An existing dataset was found. Do you want to use it? (Be sure to select NO if it might be the dataset from a previous participant, and you are now testing a new participant!' newline 'Enter 1 for YES or 0 for NO : ']);
                    if use_existing
                        clearvars -except AllData %A dataset already exists with actual data in it => resume where the experiment was interrupted, delete any other variable
                    else
                        clear
                    end
                end
            else
                clear
            end
        end
    %Get the experiment settings
        exp_settings = BEC_Settings;
    %Make new dataset if needed (after exp_settings is loaded)
        if ~exist('AllData','var')
            %Create data structure and get experiment settings structure
                AllData = struct;
                AllData.exp_settings = exp_settings; 
                AllData.bookmark = 0; %This field will track where we are in the experiment. If interrupted, the experiment can be resumed at exactly the right location.
            %Participant data
                AllData.ID = input('Enter patient ID: ','s');
                AllData.gender = input('Enter gender (m/f): ','s'); %This information is needed for the French emotion vignettes (which are gendered)
            %Get the settings and directories
                savename = [AllData.ID '_' datestr(clock,30)]; %Directory name where the dataset will be saved
                AllData.savedir = [exp_settings.datadir filesep savename]; %Path of the directory where the data will be saved      
                mkdir(exp_settings.datadir,savename); %Create the directory where the data will be stored
                disp('Dataset and directory created.')
        end
    %Add all experiment scripts and functions to the path
        addpath(genpath(exp_settings.expdir)) 
    %Plugins
        %Pupil (device: EyeTribe)
            AllData.plugins.pupil  = 0; %by default: no.
%             AllData.plugins.pupil = input('Record pupil? (flag 1:yes / 0:no): ');
            if AllData.plugins.pupil && AllData.bookmark == 6 %Main experiment
                AllData.plugins.pupil_Recalibrate = input('(Re)calibrate eyes? (flag 1:yes / 0:no): ');
            end
        %iEEG (device: Arduino)
            AllData.hostname = char(getHostName(java.net.InetAddress.getLocalHost));
            AllData.plugins.Arduino = input('Record iEEG and connect with Arduino? (flag 1:yes / 0:no): ');
            if AllData.plugins.Arduino
                switch AllData.hostname
                    case 'MWS1226' %RLH personal
                        addpath('C:\Users\Roeland\Documents\MATLAB\toolbox\ArduinoPort');
                        Arduino_ComID  = ''; %'' for dummy
                    otherwise %On experiment computer "epimicro"
                        Arduino_ComID  = BEC_GetCOMport; % USB port name
                        addpath('C:\MATLAB_toolboxes\ArduinoPort') 
                end
                OpenArduinoPort(Arduino_ComID)
                disp('Connected to Arduino.')
            end
    %Volume setting required?        
        if isfield(AllData,'volume')
            setvolume = input('An audio volume setting was found. Do you want to reset this volume level first? (flag 1:yes / 0:no): ');    
        else
            disp('Audio volume will be set first, then the experiment will start.')
            setvolume = true;
        end
    %Open a screen
        Screen('Preference', 'SkipSyncTests', 1); %Skip sync tests: yes
        Screen('Preference', 'VisualDebugLevel', 3); %Visual debug level
        Screen('Preference', 'SuppressAllWarnings', 1);
        KbName('UnifyKeyNames'); %unify across platforms
        screens=Screen('Screens');
        if max(screens)==2
            [window,winRect] = Screen('OpenWindow',1,exp_settings.backgrounds.default); %1 for main screen, 2 for external monitor
        else 
            [window,winRect] = Screen('OpenWindow',0,exp_settings.backgrounds.default); %0 for Windows Desktop screen
        end
        Screen(window,'BlendFunction',GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); %for the Alpha transparency values to take effect
        HideCursor  
    %Set experiment volume
        if setvolume
            AllData = BEC_SetVolume(window,AllData); 
        end
    %First launch settings: create timing event reel, complete the setup
        if AllData.bookmark == 0
            AllData.Timings.StartExperiment = clock;
            AllData.EventReel = BEC_Timekeeping('StartExperiment',AllData.plugins);
            AllData.bookmark = 1;
        end
    %Save
        save([AllData.savedir filesep 'AllData'],'AllData'); 
        disp('Dataset saved. Experiment will start now.')   
    
%% Baseline mood ratings
    if AllData.bookmark == 1
        %Four mood dimensions in random order
            ratings = {'fatigue','stress','happiness','pain'};
            ratings = ratings(randperm(length(ratings)));
        %Loop through the four dimensions
            for i_mood = 1:length(ratings)
                %Fixation cross
                    exitflag = BEC_Fixation(window,exp_settings,1); %One second fixation
                    if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
                %Present mood rating screen
                    [rated_mood,timings,exitflag] = BEC_RateEmotion(window,AllData,ratings{i_mood});
                    if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment   
                    AllData.MoodRatings.(ratings{i_mood}) = rated_mood; %Store the rated mood
                    AllData.EventReel = [AllData.EventReel timings]; %Store the recorded timing structure in a list of all events
                    AllData.Timings.MoodRatings.(ratings{i_mood}) = timings; %Store the timing structure in a timing overview
            end
        %Update bookmark
            AllData.bookmark = 2;
            AllData.ExampleInductions = 1; %Prepare for what's next
    end
            
%% General introduction and instructions + examples for emotions
    if AllData.bookmark == 2
        %Show instructions for experiment and emotion ratings
            [exitflag,timings] = BEC_InstructionScreens(window,AllData,'emotion_instructions');
            if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
            AllData.EventReel = [AllData.EventReel timings]; %Store the recorded timing structure in a list of all events
        %Show examples: induction + rating
            i_ex = AllData.ExampleInductions;
            while i_ex <= length(exp_settings.Emostimuli.ExampleEmotions)  
                %Store time
                    if i_ex == 1
                        AllData.Timings.StartExampleInductions = clock;
                    end
                %Instruction for neutral stimuli (after H S H S)
                    if i_ex == 5
                        [exitflag,timings] = BEC_InstructionScreens(window,AllData,'neutral_instructions');
                        if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
                        AllData.EventReel = [AllData.EventReel timings]; %Store the recorded timing structure in a list of all events
                    end
                %Get vignette text
                    switch AllData.gender
                        case 'm'; stim.text = exp_settings.Emostimuli.ExampleVignettes_m{i_ex};
                        case 'f'; stim.text = exp_settings.Emostimuli.ExampleVignettes_f{i_ex};
                    end
                %Get music
                    musicnames = {'Happy_0','Sad_0'};
                    which_emotion = exp_settings.Emostimuli.ExampleEmotions(i_ex);
                    if which_emotion ~= 3
                        stim.music = [musicnames{which_emotion} num2str(exp_settings.Emostimuli.ExampleMusic(i_ex))];
                    else
                        stim.music = [];
                    end
                %Show stimulus
                    [player,timings,exitflag] = BEC_EmotionInduction(window,stim,AllData);
                    if exitflag; BEC_ExitExperiment(AllData,player); return; end %Terminate experiment  
                    AllData.EventReel = [AllData.EventReel timings]; %Store the recorded timing structure in a list of all events
                    clear player %turn off sound    
                %Rating
                    [~,timings,exitflag] = BEC_RateEmotion(window,AllData,'emotions');
                    if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment  
                    AllData.EventReel = [AllData.EventReel timings]; %Store the recorded timing structure in a list of all events 
                %Ask if the participant wants to see another example
                    if i_ex >= 6 && i_ex < length(exp_settings.Emostimuli.ExampleEmotions)
                        [left_or_right,timings] = Show_Another_Example(window,AllData,'another_example');
                        AllData.EventReel = [AllData.EventReel timings]; %Store the recorded timing structure in a list of all events
                        switch left_or_right
                            case 'escape'; BEC_ExitExperiment(AllData); return
                            case 'left' %Another example - do nothing
                            case 'right'; break %Break out of while loop
                        end
                    end
                %Update index and save
                    i_ex = i_ex+1;
                    AllData.ExampleInductions = i_ex;
                    save([AllData.savedir filesep 'AllData'],'AllData'); 
            end %while
        %Update bookmark and save
            AllData.Timings.EndExampleInductions = clock;
            AllData.bookmark = 3; %Move on to next section
            AllData.ExampleChoices = 1; %Prepare for what comes next
            save([AllData.savedir filesep 'AllData'],'AllData'); 
    end %if bookmark == 2
        
%% Instructions and examples of choice tasks
    %Settings
        n_example_choices = 8; %Minimum number of example choices per choice type
        max_example_choices = 15; %Maximum number of example choices per choice type
    %Delay
        if AllData.bookmark == 3
            %Show instructions about choices in general, and about delay
                instruction_numbers = [4 5];
                [exitflag,timings] = BEC_InstructionScreens(window,AllData,instruction_numbers);
                if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
                AllData.EventReel = [AllData.EventReel timings]; %Store the recorded timing structure in a list of all events
            %Delay examples
                i_ex = AllData.ExampleChoices;
                while i_ex <= max_example_choices
                    %Store time and sample example trials
                        if i_ex == 1
                            AllData.timings.StartInstructions_Delay = clock;
                            AllData.Example_Choices.choices_delay = exp_settings.exampletrials(:,randperm(size(exp_settings.exampletrials,2),n_example_choices));
                            AllData.Example_Choices.trialinfo_delay = struct;
                        end
                    %Present choice
                        trialinput.choicetype = 1;   %Define choice type by number (1:delay/2:risk/3:physical effort/4:mental effort)
                        trialinput.Example = 1;      %Is this an example trial? (1:Yes - with extra text / 0:No - minimal text on screen)
                        trialinput.plugins = AllData.plugins;   %Structure containing information about the plugged in devices
                        if i_ex <= n_example_choices
                            trialinput.SSReward = AllData.Example_Choices.choices_delay(1,i_ex);  %Reward for the uncostly (SS) option (between 0 and 1)
                            trialinput.Cost = AllData.Example_Choices.choices_delay(2,i_ex);      %Cost level or the costly (LL) option (between 0 and 1)
                        else
                            trialinput.SSReward = rand;
                            trialinput.Cost = rand;
                        end
                        [trialoutput,exitflag] = BEC_ShowChoice(window,exp_settings,trialinput);
                        if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
                        if i_ex == 1
                            AllData.Example_Choices.trialinfo_delay = trialoutput;
                        else
                            AllData.Example_Choices.trialinfo_delay(i_ex) = trialoutput;
                        end
                        AllData.EventReel = [AllData.EventReel AllData.Example_Choices.trialinfo_delay(i_ex).timings]; %Store the recorded timing structure in a list of all events
                    %Ask if the participant wants to see another example
                        if i_ex >= n_example_choices && i_ex < max_example_choices
                            [left_or_right,timings] = Show_Another_Example(window,AllData,'another_example');
                            AllData.EventReel = [AllData.EventReel timings]; %Store the recorded timing structure in a list of all events
                            switch left_or_right
                                case 'escape'; BEC_ExitExperiment(AllData); return
                                case 'left' %Another example - do nothing
                                case 'right'; break %Break out of while loop
                            end
                        end
                    %Update index and save
                        i_ex = i_ex+1;
                        AllData.ExampleChoices = i_ex;
                        save([AllData.savedir filesep 'AllData'],'AllData');
                end %while
            %Update bookmark and save
                AllData.Timings.EndExamples_Delay = clock;
                AllData.bookmark = 4; %Move on to next section
                AllData.ExampleChoices = 1; %Prepare for what comes next
                save([AllData.savedir filesep 'AllData'],'AllData'); 
        end %if bookmark
    %Risk
        if AllData.bookmark == 4
            %Show instructions about choices in general, and about risk
                [exitflag,timings] = BEC_InstructionScreens(window,AllData,'risk_instructions');
                if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
                AllData.EventReel = [AllData.EventReel timings]; %Store the recorded timing structure in a list of all events
            %Risk examples
                i_ex = AllData.ExampleChoices;
                while i_ex <= max_example_choices
                    %Store time and sample example trials
                        if i_ex == 1
                            AllData.timings.StartInstructions_Risk = clock;
                            AllData.Example_Choices.choices_risk = exp_settings.exampletrials(:,randperm(size(exp_settings.exampletrials,2),n_example_choices));
                            AllData.Example_Choices.trialinfo_risk = struct;
                        end
                    %Present choice
                        trialinput.choicetype = 2;   %Define choice type by number (1:risk/2:risk/3:physical effort/4:mental effort)
                        trialinput.Example = 1;      %Is this an example trial? (1:Yes - with extra text / 0:No - minimal text on screen)
                        trialinput.plugins = AllData.plugins;   %Structure containing information about the plugged in devices
                        if i_ex <= n_example_choices
                            trialinput.SSReward = AllData.Example_Choices.choices_risk(1,i_ex);  %Reward for the uncostly (SS) option (between 0 and 1)
                            trialinput.Cost = AllData.Example_Choices.choices_risk(2,i_ex);      %Cost level or the costly (LL) option (between 0 and 1)
                        else
                            trialinput.SSReward = rand;
                            trialinput.Cost = rand;
                        end
                        [trialoutput,exitflag] = BEC_ShowChoice(window,exp_settings,trialinput);
                        if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
                        if i_ex == 1
                            AllData.Example_Choices.trialinfo_risk = trialoutput;
                        else
                            AllData.Example_Choices.trialinfo_risk(i_ex) = trialoutput;
                        end
                        AllData.EventReel = [AllData.EventReel AllData.Example_Choices.trialinfo_risk(i_ex).timings]; %Store the recorded timing structure in a list of all events
                    %Ask if the participant wants to see another example
                        if i_ex >= n_example_choices && i_ex < max_example_choices
                            [left_or_right,timings] = Show_Another_Example(window,AllData,'another_example');
                            AllData.EventReel = [AllData.EventReel timings]; %Store the recorded timing structure in a list of all events
                            switch left_or_right
                                case 'escape'; BEC_ExitExperiment(AllData); return
                                case 'left' %Another example - do nothing
                                case 'right'; break %Break out of while loop
                            end
                        end
                    %Update index and save
                        i_ex = i_ex+1;
                        AllData.ExampleChoices = i_ex;
                        save([AllData.savedir filesep 'AllData'],'AllData');
                end %while
            %Update bookmark and save
                AllData.Timings.EndExamples_Risk = clock;
                AllData.bookmark = 5; %Move on to next section
                AllData.ExampleChoices = 1; %Prepare for what comes next
                save([AllData.savedir filesep 'AllData'],'AllData'); 
        end %if bookmark
    %Effort
        if AllData.bookmark == 5
            %Show instructions about choices in general, and about effort
                [exitflag,timings] = BEC_InstructionScreens(window,AllData,'effort_instructions');
                if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
                AllData.EventReel = [AllData.EventReel timings]; %Store the recorded timing structure in a list of all events
            %Effort examples
                i_ex = AllData.ExampleChoices;
                while i_ex <= max_example_choices
                    %Store time and sample example trials
                        if i_ex == 1
                            AllData.timings.StartInstructions_Effort = clock;
                            AllData.Example_Choices.choices_effort = exp_settings.exampletrials(:,randperm(size(exp_settings.exampletrials,2),n_example_choices));
                            AllData.Example_Choices.trialinfo_effort = struct;
                        end
                    %Present choice
                        trialinput.choicetype = 4;   %Define choice type by number (1:effort/2:effort/3:physical effort/4:mental effort)
                        trialinput.Example = 1;      %Is this an example trial? (1:Yes - with extra text / 0:No - minimal text on screen)
                        trialinput.plugins = AllData.plugins;   %Structure containing information about the plugged in devices
                        if i_ex <= n_example_choices
                            trialinput.SSReward = AllData.Example_Choices.choices_effort(1,i_ex);  %Reward for the uncostly (SS) option (between 0 and 1)
                            trialinput.Cost = AllData.Example_Choices.choices_effort(2,i_ex);      %Cost level or the costly (LL) option (between 0 and 1)
                        else
                            trialinput.SSReward = rand;
                            trialinput.Cost = rand;
                        end
                        [trialoutput,exitflag] = BEC_ShowChoice(window,exp_settings,trialinput);
                        if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
                        if i_ex == 1
                            AllData.Example_Choices.trialinfo_effort = trialoutput;
                        else
                            AllData.Example_Choices.trialinfo_effort(i_ex) = trialoutput;
                        end
                        AllData.EventReel = [AllData.EventReel AllData.Example_Choices.trialinfo_effort(i_ex).timings]; %Store the recorded timing structure in a list of all events
                    %Ask if the participant wants to see another example
                        if i_ex >= n_example_choices && i_ex < max_example_choices
                            [left_or_right,timings] = Show_Another_Example(window,AllData,'another_example');
                            AllData.EventReel = [AllData.EventReel timings]; %Store the recorded timing structure in a list of all events
                            switch left_or_right
                                case 'escape'; BEC_ExitExperiment(AllData); return
                                case 'left' %Another example - do nothing
                                case 'right'; break %Break out of while loop
                            end
                        end
                    %Update index and save
                        i_ex = i_ex+1;
                        AllData.ExampleChoices = i_ex;
                        save([AllData.savedir filesep 'AllData'],'AllData');
                end %while
            %Update bookmark and save
                AllData.Timings.EndExamples_Effort = clock;
                AllData.bookmark = 6; %Move on to next section
                save([AllData.savedir filesep 'AllData'],'AllData'); 
        end %if bookmark

%% Main experiment
if AllData.bookmark == 6        
    %Make triallist
        if isfield(AllData,'Ratings') %Resume previously interrupted
            i_induction = find(isnan(AllData.Ratings),1,'first');
            if isempty(i_induction)
                BEC_ExitExperiment(AllData);
                error('Main experiment completed.')
            end
        else
            %Make trial list
                AllData.triallist = BEC_MakeTriallist_Emotions(AllData,'first_half');
            %Prepare the main experiment battery (make trial list)
                i_induction = 1;
                AllData.Timings.StartMainExperiment = clock; 
                AllData.Ratings = NaN(exp_settings.trialgen_emotions.n_inductions,length(exp_settings.trialgen_emotions.emotionnames));    
                AllData.trialinfo = struct;                
            %Store
                save([AllData.savedir filesep 'AllData'],'AllData'); 
            %Instructions: end of examples
                [exitflag,timings] = BEC_InstructionScreens(window,AllData,'start_main_experiment');
                if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
                AllData.EventReel = [AllData.EventReel timings]; %Store the recorded timing structure in a list of all events
        end  
    %Pupil setup
        %....
    %Instructions
        [exitflag,timings] = BEC_InstructionScreens(window,AllData,'start_main_experiment');
        if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
    %Loop through inductions
        for induction = i_induction:exp_settings.trialgen_emotions.n_inductions
            %Invert the model half-way...
                if induction == exp_settings.trialgen_emotions.n_inductions/2+1
                    AllData.triallist = BEC_MakeTriallist_Emotions(AllData,'second_half',AllData.triallist);
                end
            %Emotion induction
                %Washout
                    timings = BEC_Timekeeping('Washout',AllData.plugins);
                    [exitflag,timestamp] = BEC_Washout(window,AllData);
                    if exitflag; BEC_ExitExperiment(AllData); return; end
                    timings.seconds = timestamp; %The exact onset time, in GetSecs
                    AllData.EventReel = [AllData.EventReel timings]; %Store the recorded timing structure in a list of all events
                %Show stimulus
                    [player,timings,exitflag] = BEC_EmotionInduction(window,induction,AllData);
                    if exitflag; BEC_ExitExperiment(AllData,player); return; end %Terminate experiment   
                    AllData.EventReel = [AllData.EventReel timings]; %Store the recorded timing structure in a list of all events
                    AllData.Timings.EmotionInductions(induction).timings = timings;
            %Choice battery following the induction
                for choicetrial = (induction-1)*exp_settings.trialgen_emotions.choices_per_induction + (1:exp_settings.trialgen_emotions.choices_per_induction)
                    %Set the trial info
                        sidenames = {'left','right'};
                        trialinput.trial = choicetrial; %Trial number (only required for the pupil marker)
                        trialinput.induction = induction; %Emotion induction number
                        trialinput.condition = AllData.triallist.choices.condition(choicetrial); %Emotion condition
                        trialinput.choicetype = AllData.triallist.choices.choicetype(choicetrial); %Set number (1:delay/2:risk/3:physical effort/4:mental effort)
                        trialinput.SSReward = AllData.triallist.choices.SSReward(choicetrial); %Reward for the uncostly (SS) option (between 0 and 1)
                        trialinput.Cost = AllData.triallist.choices.LLCost(choicetrial); %Cost level or the costly (LL) option (between 0 and 1)
                        trialinput.SideSS = sidenames{1+AllData.triallist.choices.sideSS(choicetrial)}; %(optional) set on which side you want the uncostly (SS) option to be (enter string: 'left' or 'right')
                        trialinput.plugins = AllData.plugins; 
                        trialinput.Example = 0;
                    %Present the choice
                        [trialoutput,exitflag] = BEC_ShowChoice(window,exp_settings,trialinput);
                        if exitflag; BEC_ExitExperiment(AllData,player); return; end %Terminate experiment  
                        if choicetrial == 1
                            AllData.trialinfo = trialoutput;
                        else
                            AllData.trialinfo(choicetrial) = trialoutput;
                        end
                end
            %End of a choice battery: Turn off music
                if ~isnan(AllData.triallist.music_num(induction))
                    clear player       
                end
            %Rating
                [Ratings,timings,exitflag] = BEC_RateEmotion(window,AllData,'emotions');
                if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment   
                AllData.Ratings(induction,:) = Ratings;
                AllData.EventReel = [AllData.EventReel timings]; %Store the recorded timing structure in a list of all events
                AllData.Timings.EmotionRatings(induction).timings = timings;
            %Save the data at the end of each trial
                save([AllData.savedir filesep 'AllData'],'AllData');
        end %for induction
    %End of the experiment
        [~,timings] = BEC_InstructionScreens(window,AllData,'end_of_experiment');
        AllData.EventReel = [AllData.EventReel timings]; %Store the recorded timing structure in a list of all events
        AllData.Timings.EndOfExperiment = clock;
        save([AllData.savedir filesep 'AllData'],'AllData');
    %Close
        BEC_ExitExperiment(AllData);
        
end %if bookmark
    
%% Subfunction
function [left_or_right,timings] = Show_Another_Example(window,AllData,which_instruction)
% Subfunction similar to "BEC_InstructionScreens". Puts one slide on screen asking whether the participant wants to see 
% another example (left) or proceed (right).

    %Prepare
        exp_settings = AllData.exp_settings;
        if isa(which_instruction,'char') %When the instruction topic is entered as a string
            slide = exp_settings.instructions_emotions.(which_instruction); %Get slides
        else %When the slide numbers are directly entered
            slide = which_instruction;
        end
        Screen('FillRect',window,exp_settings.backgrounds.default);
    %Valid key names
        leftKey     = KbName('LeftArrow'); %37
        rightKey    = KbName('RightArrow'); %39
        escapeKey   = KbName('ESCAPE'); %27
    %Scaling of the slide
        [width, height]=Screen('WindowSize',window);
        SF = 1;   %Scaling factor w.r.t. full screen
        sliderect = ((1-SF)/2+[0 0 SF SF]).*[width height width height];            
    %Instruction slide on screen
        KbReleaseWait;  % Wait for all keys to be released before drawing
        try
            im_instruction = imread([exp_settings.stimdir filesep 'Diapositive' num2str(slide) '.png']);
        catch
            im_instruction = imread([exp_settings.stimdir filesep 'Slide' num2str(slide) '.png']);
        end
        tex_instruction = Screen('MakeTexture',window,im_instruction);
        Screen('DrawTexture', window, tex_instruction, [], sliderect);
        timestamp = Screen('Flip', window);
        timings = BEC_Timekeeping('InstructionScreen',AllData.plugins,timestamp);
    %Monitor responses
        valid = 0;
        while ~valid
            [keyIsDown, ~, keyCode, ~] = KbCheck(-1); 
            %keyIsDown returns 1 while a key is pressed
            %keyCode is a logical for all keys of the keyboard
            if keyIsDown %Check if key press is valid
                if keyCode(leftKey) %previous slide
                    left_or_right = 'left'; valid = 1;
                elseif keyCode(rightKey) %next slide
                    left_or_right = 'right'; valid = 1;
                elseif keyCode(escapeKey) %Proceed to exit in master
                    left_or_right = 'escape'; valid = 1;
                end
            end
        end %while ~valid
end