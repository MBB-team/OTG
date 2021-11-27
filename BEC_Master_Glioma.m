% BEC_Master_Glioma
% Master script for experiment with calibration of delay and mental effort discounting tasks, and follow-up measure.
% BECHAMEL - Battery of Economic CHoices And Mood/Emotion Links
% RH - November 2021

%% Set up the experiment
% Directories
    ID = input('Enter patient ID: ','s');
    expdir = which('BEC_Master_Glioma'); expdir = expdir(1:end-19);  %Get the directory where this function is stored
    datadir = [expdir filesep 'Experiment data']; %This is where the data will be saved (in expdir/Experiment data) -- can be modified
    find_dataset = dir([datadir filesep 'DM' ID '_*']);
% Verify if there is an existing dataset; otherwise, create one.
    if isempty(find_dataset) %First time doing the experiment (session 1)
        %Get the experiment settings structure and adjust settings specific to this experiment
            exp_settings = BEC_Settings;
            exp_settings.OTG.ntrials_cal = 25; %Number of choice model calibration trials
            exp_settings.n_example_choices = 10; %Minimum number of example choices per choice type
            exp_settings.max_example_choices = 15; %Maximum number of example choices per choice type
            exp_settings.OTG.max_n_inv = 25; %Take all choices into account for model updating
            exp_settings.timings.fixation_choice = [0.5 0.75]; %Interval within which a fixation time will be drawn
            exp_settings.expdir = expdir; %Experiment directory
            exp_settings.datadir = datadir; %Data saving directory
        %Adapt the screen appearance to the touchscreen
            exp_settings.font.RatingFontSize = 60; %Larger for the tablet, which has a high PPI
            exp_settings.font.FixationFontSize = 80;
            exp_settings.font.RewardFontSize = 60;
            exp_settings.choicescreen.costbox_left = [2/16 1/6 6.5/16 6/10];   %Left cost visualization
            exp_settings.choicescreen.costbox_right = [9.5/16 1/6 14/16 6/10];%Right cost visualization
        %Make new dataset if needed (after exp_settings is loaded)
            %Create data structure and get experiment settings structure
                AllData = struct;
                AllData.ID = ID;
                AllData.exp_settings = exp_settings; 
                AllData.bookmark = 0; %Indicate progress during the experiment
                AllData.plugins.touchscreen = 1; %Plugins: Tactile screen (default: no)
            %Get the settings and directories
                savename = ['DM' AllData.ID '_' datestr(clock,30)]; %Directory name where the dataset will be saved
                AllData.savedir = [exp_settings.datadir filesep savename]; %Path of the directory where the data will be saved      
                mkdir(exp_settings.datadir,savename); %Create the directory where the data will be stored
            %First launch settings: create timing event reel, complete the setup
                AllData.Timings.StartExperiment = clock;
                AllData.EventReel = BEC_Timekeeping('StartExperiment',AllData.plugins);
                AllData.bookmark = 1;
            %Save
                save([AllData.savedir filesep 'AllData'],'AllData'); 
                disp('Dataset and directory created. Experiment will start now.')   
    else %Either session 2 of the experiment, or resume after bailout
        %Load dataset
            dataset = load([find_dataset.folder filesep find_dataset.name filesep 'AllData']);
            AllData = dataset.AllData;
        %Get the experiment settings structure
            exp_settings = AllData.exp_settings;
    end
    
% Setup
    %Add all experiment scripts and functions to the path
        addpath(genpath(exp_settings.expdir)) 
    %Open a screen if not provided
        Screen('Preference', 'SkipSyncTests', 1); %Skip sync tests: yes
        Screen('Preference', 'VisualDebugLevel', 3); %Visual debug level
        Screen('Preference', 'SuppressAllWarnings', 1);
        KbName('UnifyKeyNames'); %unify across platforms
        window = Screen('OpenWindow',0,exp_settings.backgrounds.default); %0 for Windows Desktop screen
        Screen(window,'BlendFunction',GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); %for the Alpha transparency values to take effect
        HideCursor  
        
%% Instructions and examples of DELAY
    if AllData.bookmark == 1
        %Show welcome message, and instructions about choices in general, and about delay
            instruction_numbers = 201:203;
            [exitflag,timings] = BEC_InstructionScreens(window,AllData,instruction_numbers);
            if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
            AllData.EventReel = [AllData.EventReel timings]; %Store the recorded timing structure in a list of all events
        %Delay examples
            i_ex = 1;
            while i_ex <= exp_settings.max_example_choices
                %Store time and sample example trials
                    if i_ex == 1
                        AllData.Timings.StartInstructions_Delay = clock;
                        AllData.Example_Choices.choices_delay = exp_settings.exampletrials(:,randperm(size(exp_settings.exampletrials,2),exp_settings.n_example_choices));
                        AllData.Example_Choices.trialinfo_delay = struct;
                    end
                %Present choice
                    trialinput.choicetype = 1;   %Define choice type by number (1:delay/2:risk/3:physical effort/4:mental effort)
                    trialinput.Example = 1;      %Is this an example trial? (1:Yes - with extra text / 0:No - minimal text on screen)
                    trialinput.plugins = AllData.plugins;   %Structure containing information about the plugged in devices
                    if i_ex <= exp_settings.n_example_choices
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
                    if i_ex >= exp_settings.n_example_choices && i_ex < exp_settings.max_example_choices
                        [left_or_right,timings] = BEC_Show_Another_Example(window,AllData,'another_example');
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
            AllData.bookmark = 2; %Move on to next section
            AllData.ExampleChoices = 1; %Prepare for what comes next
            save([AllData.savedir filesep 'AllData'],'AllData'); 
    end %if bookmark
    
%% Test battery: DELAY
    if AllData.bookmark == 2
        %Show instructions about calibration choice battery
            instruction_numbers = 204;
            [exitflag,timings] = BEC_InstructionScreens(window,AllData,instruction_numbers);
            if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
            AllData.EventReel = [AllData.EventReel timings]; %Store the recorded timing structure in a list of all events
        %Run calibration
            [AllData,exitflag] = BEC_Calibration(AllData,1,window,0);
            if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
            AllData.bookmark = 3; %Move on to next section
            save([AllData.savedir filesep 'AllData'],'AllData');
    end
    
%% Instructions and examples of MENTAL EFFORT
    if AllData.bookmark == 3
        %Show instructions about mental effort
            instruction_numbers = 205;
            [exitflag,timings] = BEC_InstructionScreens(window,AllData,instruction_numbers);
            if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
            AllData.EventReel = [AllData.EventReel timings]; %Store the recorded timing structure in a list of all events
        %Effort examples
            i_ex = 1;
            while i_ex <= exp_settings.max_example_choices
                %Store time and sample example trials
                    if i_ex == 1
                        AllData.Timings.StartInstructions_Effort = clock;
                        AllData.Example_Choices.choices_effort = exp_settings.exampletrials(:,randperm(size(exp_settings.exampletrials,2),exp_settings.n_example_choices));
                        AllData.Example_Choices.trialinfo_effort = struct;
                    end
                %Present choice
                    trialinput.choicetype = 4;   %Define choice type by number (1:effort/2:effort/3:physical effort/4:mental effort)
                    trialinput.Example = 1;      %Is this an example trial? (1:Yes - with extra text / 0:No - minimal text on screen)
                    trialinput.plugins = AllData.plugins;   %Structure containing information about the plugged in devices
                    if i_ex <= exp_settings.n_example_choices
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
                    if i_ex >= exp_settings.n_example_choices && i_ex < exp_settings.max_example_choices
                        [left_or_right,timings] = BEC_Show_Another_Example(window,AllData,'another_example');
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
            AllData.bookmark = 4; %Move on to next section
            save([AllData.savedir filesep 'AllData'],'AllData'); 
    end %if bookmark
    
%% Test battery: MENTAL EFFORT
    if AllData.bookmark == 4
        %Show instructions about calibration choice battery
            instruction_numbers = 206;
            [exitflag,timings] = BEC_InstructionScreens(window,AllData,instruction_numbers);
            if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
            AllData.EventReel = [AllData.EventReel timings]; %Store the recorded timing structure in a list of all events
        %Run calibration
            [AllData,exitflag] = BEC_Calibration(AllData,4,window,0);
            if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
            AllData.bookmark = 5; %Move on to next section
            save([AllData.savedir filesep 'AllData'],'AllData');
    end

%% End of pre-race calibrations
    if AllData.bookmark == 5        
        %End of the experiment
            instruction_numbers = 207;
            [~,timings] = BEC_InstructionScreens(window,AllData,instruction_numbers);
            AllData.EventReel = [AllData.EventReel timings]; %Store the recorded timing structure in a list of all events
            AllData.Timings.EndOfSession1 = clock;
            AllData.bookmark = 6;
            save([AllData.savedir filesep 'AllData'],'AllData');
        %Close
            BEC_ExitExperiment(AllData);
            clc; disp('End of the first decision-making session. Data saved.')
            clear; return
    end %if bookmark

%% Test battery Session 2: DELAY
    if AllData.bookmark == 6
        AllData.Timings.StartOfSession2 = clock;
        %Show instructions about calibration choice battery
            instruction_numbers = [201 208];
            [exitflag,timings] = BEC_InstructionScreens(window,AllData,instruction_numbers);
            if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
            AllData.EventReel = [AllData.EventReel timings]; %Store the recorded timing structure in a list of all events
        %Run choice battery
            AllData.exp_settings.OTG.choicetypes = 1; %Define choice type (1: delay)
            AllData.OTG_prior.delay.muPhi = AllData.calibration.delay.posterior.muPhi;
            for trial = 1:25
                [AllData,exitflag] = BEC_OnlineTrialGeneration_VBA(AllData,window);
                if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
            end
            AllData.bookmark = 7; %Move on to next section
            save([AllData.savedir filesep 'AllData'],'AllData');
    end
    
%% Test battery Session 2: MENTAL EFFORT
    if AllData.bookmark == 7
        %Show instructions about calibration choice battery
            instruction_numbers = 209;
            [exitflag,timings] = BEC_InstructionScreens(window,AllData,instruction_numbers);
            if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
            AllData.EventReel = [AllData.EventReel timings]; %Store the recorded timing structure in a list of all events
        %Run choice battery
            AllData.exp_settings.OTG.choicetypes = 4; %Define choice type (4: mental effort)
            AllData.OTG_prior.mental_effort.muPhi = AllData.calibration.mental_effort.posterior.muPhi;
            for trial = 1:25
                [AllData,exitflag] = BEC_OnlineTrialGeneration_VBA(AllData,window);
                if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
            end
            AllData.bookmark = 8; %Move on to next section
            save([AllData.savedir filesep 'AllData'],'AllData');
    end
    
%% End of session 2
    if AllData.bookmark == 8   
        %End of the experiment
            instruction_numbers = 207;
            [~,timings] = BEC_InstructionScreens(window,AllData,instruction_numbers);
            AllData.EventReel = [AllData.EventReel timings]; %Store the recorded timing structure in a list of all events
            AllData.Timings.EndOfSession2 = clock;
            save([AllData.savedir filesep 'AllData'],'AllData');
        %Close
            BEC_ExitExperiment(AllData);
            clc; disp('End of second decision-making session. Data saved.')
            clear; return
    end %if bookmark