% BEC_Master_PTSD
% Experimental "master" script for economic decision-making study of PTSD patients.
% RLH - February 2022

%% Start the experiment
    %Get the experiment default settings and add custom settings for the tablet
        exp_settings = BEC_Settings; %Default settings structure
        %Custom settings: Online Trial Generation
            exp_settings.OTG.ntrials_cal = 30; %Calibration battery consists of n trials
            exp_settings.OTG.ntrials_followup = 25; %Follow-up battery consists of n trials
            exp_settings.OTG.max_n_inv = exp_settings.OTG.ntrials_followup; %Model updating: take all trials into account
        %Custom settings: trial count and timing
            exp_settings.n_example_choices = 6; %For now: 6 examples per type
            exp_settings.max_example_choices = 12; %Limit the amount of examples to 12 in order to avoid wasting time
            exp_settings.timings.fixation_choice = [0.5 0.75]; %Short fixation time before each choice
        %Custom settings: visual appearance adapted for tablet use
            exp_settings.tactile.navigationArrows = true; %Show the navigation buttons that can be pressed on screen.
            exp_settings.font.FixationFontSize = 80;
            exp_settings.font.RewardFontSize = 60;
            exp_settings.choicescreen.costbox_left = [2/16 1/6 6.5/16 6/10]; %Left cost visualization
            exp_settings.choicescreen.costbox_right = [9.5/16 1/6 14/16 6/10]; %Right cost visualization
    %Add all experiment scripts and functions to the path
        addpath(genpath(exp_settings.expdir))          
    %Open a screen
        Screen('Preference', 'SkipSyncTests', 1); %Skip sync tests: yes
        Screen('Preference', 'VisualDebugLevel', 3); %Visual debug level
        Screen('Preference', 'SuppressAllWarnings', 1);
        KbName('UnifyKeyNames'); %unify across platforms
        [window,winRect] = Screen('OpenWindow',0,exp_settings.backgrounds.default); %0 for Windows Desktop screen
        Screen(window,'BlendFunction',GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); %for the Alpha transparency values to take effect
        HideCursor 
    %Get participant ID (show screen)
        [ID,exitflag] = BEC_Tactile_PatientID(exp_settings,window); %if exitflag: terminate the whole experiment; don't proceed and save.
        if exitflag
            sca; clear; return
        end
    %Search for existing dataset or create new one
        find_dataset = dir([exp_settings.datadir filesep ID '_*']);
        if isempty(find_dataset) %No existing dataset for entered ID => make new dataset
            %Create data structure and get experiment settings structure
                AllData = struct;
                AllData.exp_settings = exp_settings; 
                AllData.plugins.touchscreen = 1; %Touchscreen experiment
                AllData.ID = ID; %Attribute ID
            %Get the settings and directories
                savename = [AllData.ID '_' datestr(clock,30)]; %Directory name where the dataset will be saved
                AllData.savedir = [exp_settings.datadir filesep savename]; %Path of the directory where the data will be saved      
                mkdir(exp_settings.datadir,savename); %Create the directory where the data will be stored
                disp('Dataset and directory created.')
            %First launch settings: create timing event reel, complete the setup
                AllData.Timings.StartExperiment = clock;
                AllData.EventReel = BEC_Timekeeping('StartExperiment',AllData.plugins);
                AllData.bookmark = 1; %This field will track where we are in the experiment. If interrupted, the experiment can be resumed at exactly the right location.
            %Save
                save([AllData.savedir filesep 'AllData'],'AllData'); 
                disp('Dataset and directory created and saved. Experiment will start now.') 
        elseif length(find_dataset) > 1 %multiple datasets are found with the same name
            sca
            error('Multiple datasets exist with the same name in the "Experiment data" folder ! Please keep only 1 dataset, or remove them all to start over.')
        else %one previous dataset is found: resume experiment based on last "bookmark" position
            %Load dataset
                dataset = load([find_dataset.folder filesep find_dataset.name filesep 'AllData']);
                AllData = dataset.AllData;
            %Get the experiment settings structure
                exp_settings = AllData.exp_settings;
        end
        
%% Introduction
    if AllData.bookmark == 1
        instruction_numbers = [101 102];
        exitflag = BEC_InstructionScreens(window,AllData,instruction_numbers);
        if exitflag; BEC_ExitExperiment(AllData); end %Terminate experiment
        AllData.Timings.End_of_introduction = clock;
        AllData.bookmark = 2;
    end            
        
%% Instructions and examples of DELAY
    if AllData.bookmark == 2
        %Show instructions about choices in general, and about delay
            AllData.Timings.Start_Delay = clock;
            instruction_numbers = 103;
            exitflag = BEC_InstructionScreens(window,AllData,instruction_numbers);
            if exitflag; BEC_ExitExperiment(AllData); end %Terminate experiment
            AllData.Timings.Instructions_delay_done = clock;
        %Delay examples
            i_ex = 1;
            while i_ex <= exp_settings.max_example_choices
                %Store time and sample example trials
                    if i_ex == 1
                        AllData.Timings.StartExamples_Delay = clock;
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
                    if exitflag; BEC_ExitExperiment(AllData); end %Terminate experiment
                    if i_ex == 1
                        AllData.Example_Choices.trialinfo_delay = trialoutput;
                    else
                        AllData.Example_Choices.trialinfo_delay(i_ex) = trialoutput;
                    end
                    AllData.EventReel = [AllData.EventReel AllData.Example_Choices.trialinfo_delay(i_ex).timings]; %Store the recorded timing structure in a list of all events
                %Ask if the participant wants to see another example
                    if i_ex >= exp_settings.n_example_choices && i_ex < exp_settings.max_example_choices
                        [left_or_right,timings] = BEC_Show_Another_Example(window,AllData);
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
            AllData.bookmark = 3; %Move on to next section
            AllData.ExampleChoices = 1; %Prepare for what comes next
            save([AllData.savedir filesep 'AllData'],'AllData'); 
    end %if bookmark
    
%% Test battery: DELAY
    if AllData.bookmark == 3
        %Show instructions about calibration choice battery
            instruction_numbers = 104; % NB, slide says 25 trials
            exitflag = BEC_InstructionScreens(window,AllData,instruction_numbers);
            if exitflag; BEC_ExitExperiment(AllData); end %Terminate experiment
        %Run calibration
            AllData.Timings.Start_Calibration_Delay = clock;
            [AllData,exitflag] = BEC_Calibration(AllData,1,window,0);
            if exitflag; BEC_ExitExperiment(AllData); end %Terminate experiment
            AllData.Timings.End_Calibration_Delay = clock;
            AllData.bookmark = 4; %Move on to next section
        %Compute results: area under the curve
            AllData.AUC.delay = Compute_AUC(AllData.calibration.delay.posterior.muPhi,exp_settings);
        %Save
            save([AllData.savedir filesep 'AllData'],'AllData'); 
    end
      
%% Instructions and examples of RISK
    if AllData.bookmark == 4
        %Show instructions about choices in general, and about risk
            AllData.Timings.Start_Risk = clock;
            instruction_numbers = 105;
            exitflag = BEC_InstructionScreens(window,AllData,instruction_numbers);
            if exitflag; BEC_ExitExperiment(AllData); end %Terminate experiment
            AllData.Timings.Instructions_risk_done = clock;
        %Risk examples
            i_ex = 1;
            while i_ex <= exp_settings.max_example_choices
                %Store time and sample example trials
                    if i_ex == 1
                        AllData.Timings.StartExamples_Risk = clock;
                        AllData.Example_Choices.choices_risk = exp_settings.exampletrials(:,randperm(size(exp_settings.exampletrials,2),exp_settings.n_example_choices));
                        AllData.Example_Choices.trialinfo_risk = struct;
                    end
                %Present choice
                    trialinput.choicetype = 2;   %Define choice type by number (1:delay/2:risk/3:physical effort/4:mental effort)
                    trialinput.Example = 1;      %Is this an example trial? (1:Yes - with extra text / 0:No - minimal text on screen)
                    trialinput.plugins = AllData.plugins;   %Structure containing information about the plugged in devices
                    if i_ex <= exp_settings.n_example_choices
                        trialinput.SSReward = AllData.Example_Choices.choices_risk(1,i_ex);  %Reward for the uncostly (SS) option (between 0 and 1)
                        trialinput.Cost = AllData.Example_Choices.choices_risk(2,i_ex);      %Cost level or the costly (LL) option (between 0 and 1)
                    else
                        trialinput.SSReward = rand;
                        trialinput.Cost = rand;
                    end
                    [trialoutput,exitflag] = BEC_ShowChoice(window,exp_settings,trialinput);
                    if exitflag; BEC_ExitExperiment(AllData); end %Terminate experiment
                    if i_ex == 1
                        AllData.Example_Choices.trialinfo_risk = trialoutput;
                    else
                        AllData.Example_Choices.trialinfo_risk(i_ex) = trialoutput;
                    end
                    AllData.EventReel = [AllData.EventReel AllData.Example_Choices.trialinfo_risk(i_ex).timings]; %Store the recorded timing structure in a list of all events
                %Ask if the participant wants to see another example
                    if i_ex >= exp_settings.n_example_choices && i_ex < exp_settings.max_example_choices
                        [left_or_right,timings] = BEC_Show_Another_Example(window,AllData);
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
    
%% Test battery: RISK
    if AllData.bookmark == 5
        %Show instructions about calibration choice battery
            instruction_numbers = 106;
            exitflag = BEC_InstructionScreens(window,AllData,instruction_numbers);
            if exitflag; BEC_ExitExperiment(AllData); end %Terminate experiment
        %Run calibration
            AllData.Timings.Start_Calibration_Risk = clock;
            [AllData,exitflag] = BEC_Calibration(AllData,2,window,0);
            if exitflag; BEC_ExitExperiment(AllData); end %Terminate experiment
            AllData.Timings.End_Calibration_Risk = clock;
            AllData.bookmark = 6; %Move on to next section
        %Compute results: area under the curve
            AllData.AUC.risk = Compute_AUC(AllData.calibration.risk.posterior.muPhi,exp_settings);
        %Save
            save([AllData.savedir filesep 'AllData'],'AllData'); 
    end

%% Instructions and examples of PHYSICAL EFFORT
    if AllData.bookmark == 6
        %Show instructions about choices in general, and about physical effort
            AllData.Timings.Start_Physical_Effort = clock;
            instruction_numbers = 107;
            exitflag = BEC_InstructionScreens(window,AllData,instruction_numbers);
            if exitflag; BEC_ExitExperiment(AllData); end %Terminate experiment
            AllData.Timings.Instructions_physical_effort_done = clock;
        %Physical effort examples
            i_ex = 1;
            while i_ex <= exp_settings.max_example_choices
                %Store time and sample example trials
                    if i_ex == 1
                        AllData.Timings.StartExamples_Physical_Effort = clock;
                        AllData.Example_Choices.choices_physical_effort = exp_settings.exampletrials(:,randperm(size(exp_settings.exampletrials,2),exp_settings.n_example_choices));
                        AllData.Example_Choices.trialinfo_physical_effort = struct;
                    end
                %Present choice
                    trialinput.choicetype = 3;   %Define choice type by number (1:delay/2:risk/3:physical effort/4:mental effort)
                    trialinput.Example = 1;      %Is this an example trial? (1:Yes - with extra text / 0:No - minimal text on screen)
                    trialinput.plugins = AllData.plugins;   %Structure containing information about the plugged in devices
                    if i_ex <= exp_settings.n_example_choices
                        trialinput.SSReward = AllData.Example_Choices.choices_physical_effort(1,i_ex);  %Reward for the uncostly (SS) option (between 0 and 1)
                        trialinput.Cost = AllData.Example_Choices.choices_physical_effort(2,i_ex);      %Cost level or the costly (LL) option (between 0 and 1)
                    else
                        trialinput.SSReward = rand;
                        trialinput.Cost = rand;
                    end
                    [trialoutput,exitflag] = BEC_ShowChoice(window,exp_settings,trialinput);
                    if exitflag; BEC_ExitExperiment(AllData); end %Terminate experiment
                    if i_ex == 1
                        AllData.Example_Choices.trialinfo_physical_effort = trialoutput;
                    else
                        AllData.Example_Choices.trialinfo_physical_effort(i_ex) = trialoutput;
                    end
                    AllData.EventReel = [AllData.EventReel AllData.Example_Choices.trialinfo_physical_effort(i_ex).timings]; %Store the recorded timing structure in a list of all events
                %Ask if the participant wants to see another example
                    if i_ex >= exp_settings.n_example_choices && i_ex < exp_settings.max_example_choices
                        [left_or_right,timings] = BEC_Show_Another_Example(window,AllData);
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
            AllData.Timings.EndExamples_Physical_Effort = clock;
            AllData.bookmark = 7; %Move on to next section
            AllData.ExampleChoices = 1; %Prepare for what comes next
            save([AllData.savedir filesep 'AllData'],'AllData'); 
    end %if bookmark
    
%% Test battery: PHYSICAL EFFORT
    if AllData.bookmark == 7
        %Show instructions about calibration choice battery
            instruction_numbers = 108;
            exitflag = BEC_InstructionScreens(window,AllData,instruction_numbers);
            if exitflag; BEC_ExitExperiment(AllData); end %Terminate experiment
        %Run calibration
            AllData.Timings.Start_Calibration_Physical_Effort = clock;
            [AllData,exitflag] = BEC_Calibration(AllData,3,window,0);
            if exitflag; BEC_ExitExperiment(AllData); end %Terminate experiment
            AllData.Timings.End_Calibration_Physical_Effort = clock;
            AllData.bookmark = 8; %Move on to next section
        %Compute results: area under the curve
            AllData.AUC.physical_effort = Compute_AUC(AllData.calibration.physical_effort.posterior.muPhi,exp_settings);
        %Save
            save([AllData.savedir filesep 'AllData'],'AllData'); 
    end
    
%% Instructions and examples of MENTAL EFFORT
    if AllData.bookmark == 8
        %Show instructions about choices in general, and about effort
            AllData.Timings.Start_Mental_Effort = clock;
            instruction_numbers = [109 110]; %Note, added a slide with the text visualized
            exitflag = BEC_InstructionScreens(window,AllData,instruction_numbers);
            if exitflag; BEC_ExitExperiment(AllData); end %Terminate experiment
            AllData.Timings.Instructions_mental_effort_done = clock;
        %Effort examples
            i_ex = 1;
            while i_ex <= exp_settings.max_example_choices
                %Store time and sample example trials
                    if i_ex == 1
                        AllData.Timings.StartExamples_Mental_Effort = clock;
                        AllData.Example_Choices.choices_mental_effort = exp_settings.exampletrials(:,randperm(size(exp_settings.exampletrials,2),exp_settings.n_example_choices));
                        AllData.Example_Choices.trialinfo_mental_effort = struct;
                    end
                %Present choice
                    trialinput.choicetype = 4;   %Define choice type by number (1:delay/2:risk/3:physical effort/4:mental effort)
                    trialinput.Example = 1;      %Is this an example trial? (1:Yes - with extra text / 0:No - minimal text on screen)
                    trialinput.plugins = AllData.plugins;   %Structure containing information about the plugged in devices
                    if i_ex <= exp_settings.n_example_choices
                        trialinput.SSReward = AllData.Example_Choices.choices_mental_effort(1,i_ex);  %Reward for the uncostly (SS) option (between 0 and 1)
                        trialinput.Cost = AllData.Example_Choices.choices_mental_effort(2,i_ex);      %Cost level or the costly (LL) option (between 0 and 1)
                    else
                        trialinput.SSReward = rand;
                        trialinput.Cost = rand;
                    end
                    [trialoutput,exitflag] = BEC_ShowChoice(window,exp_settings,trialinput);
                    if exitflag; BEC_ExitExperiment(AllData); end %Terminate experiment
                    if i_ex == 1
                        AllData.Example_Choices.trialinfo_mental_effort = trialoutput;
                    else
                        AllData.Example_Choices.trialinfo_mental_effort(i_ex) = trialoutput;
                    end
                    AllData.EventReel = [AllData.EventReel AllData.Example_Choices.trialinfo_mental_effort(i_ex).timings]; %Store the recorded timing structure in a list of all events
                %Ask if the participant wants to see another example
                    if i_ex >= exp_settings.n_example_choices && i_ex < exp_settings.max_example_choices
                        [left_or_right,timings] = BEC_Show_Another_Example(window,AllData);
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
            AllData.Timings.EndExamples_Mental_Effort = clock;
            AllData.bookmark = 9; %Move on to next section
            save([AllData.savedir filesep 'AllData'],'AllData'); 
    end %if bookmark
    
%% Test battery: MENTAL EFFORT
    if AllData.bookmark == 9
        %Show instructions about calibration choice battery
            instruction_numbers = 111;
            exitflag = BEC_InstructionScreens(window,AllData,instruction_numbers);
            if exitflag; BEC_ExitExperiment(AllData); end %Terminate experiment
        %Run calibration
            AllData.Timings.Start_Calibration_Mental_Effort = clock;
            [AllData,exitflag] = BEC_Calibration(AllData,4,window,0);
            if exitflag; BEC_ExitExperiment(AllData); end %Terminate experiment
            AllData.Timings.End_Calibration_Mental_Effort = clock;
            AllData.bookmark = 10; %Move on to next section
        %Compute results: area under the curve
            AllData.AUC.mental_effort = Compute_AUC(AllData.calibration.mental_effort.posterior.muPhi,exp_settings);
        %Save
            save([AllData.savedir filesep 'AllData'],'AllData'); 
    end

%% End of calibrations
    if AllData.bookmark == 10       
        %End of the experiment
            instruction_numbers = 207;
            [~,timings] = BEC_InstructionScreens(window,AllData,instruction_numbers);
            AllData.EventReel = [AllData.EventReel timings]; %Store the recorded timing structure in a list of all events
            AllData.Timings.EndOfSession1 = clock;
            AllData.bookmark = 11;
            save([AllData.savedir filesep 'AllData'],'AllData');
        %Close
            BEC_ExitExperiment(AllData);
            clc; disp('End of the first decision-making session. Data saved.')
            clear; return
    end %if bookmark
    
%% Test battery Session 2: DELAY
    if AllData.bookmark == 11
        AllData.Timings.StartOfSession2 = clock;
        %Show instructions about calibration choice battery
            instruction_numbers = [201 208];
            [exitflag,timings] = BEC_InstructionScreens(window,AllData,instruction_numbers);
            if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
            AllData.EventReel = [AllData.EventReel timings]; %Store the recorded timing structure in a list of all events
        %Run choice battery
            AllData.exp_settings.OTG.choicetypes = 1; %Define choice type (1: delay)
            AllData.OTG_prior.delay.muPhi = AllData.calibration.delay.posterior.muPhi;
            for trial = 1:exp_settings.OTG.ntrials_followup
                [AllData,exitflag] = BEC_OnlineTrialGeneration_VBA(AllData,window);
                if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
            end
            AllData.bookmark = 12; %Move on to next section
            save([AllData.savedir filesep 'AllData'],'AllData');
    end
    
%% Test battery Session 2: MENTAL EFFORT
    if AllData.bookmark == 12
        %Show instructions about calibration choice battery
            instruction_numbers = 213;
            [exitflag,timings] = BEC_InstructionScreens(window,AllData,instruction_numbers);
            if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
            AllData.EventReel = [AllData.EventReel timings]; %Store the recorded timing structure in a list of all events
        %Run choice battery
            AllData.exp_settings.OTG.choicetypes = 4; %Define choice type (4: mental effort)
            AllData.OTG_prior.mental_effort.muPhi = AllData.calibration.mental_effort.posterior.muPhi;
            for trial = 1:exp_settings.OTG.ntrials_followup
                [AllData,exitflag] = BEC_OnlineTrialGeneration_VBA(AllData,window);
                if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
            end
            AllData.bookmark = 13; %Move on to next section
            save([AllData.savedir filesep 'AllData'],'AllData');
    end
    
%% End of session 3
    if AllData.bookmark == 13
        %End of the experiment
            instruction_numbers = 112;
            [~,timings] = BEC_InstructionScreens(window,AllData,instruction_numbers);
            AllData.EventReel = [AllData.EventReel timings]; %Store the recorded timing structure in a list of all events
            AllData.Timings.EndOfSession2 = clock;
            save([AllData.savedir filesep 'AllData'],'AllData');
        %Close
            BEC_ExitExperiment(AllData);
            clc; disp('End of second decision-making session. Data saved.')
            clear; return
    end %if bookmark

%% Subfunction: calculate area under the curve
function [AUC] = Compute_AUC(muPhi,exp_settings)
% Settings
    nbins = exp_settings.OTG.grid.nbins;
    binlimits = 0:1/nbins:1;
    costlevels_per_bin = exp_settings.OTG.grid.bincostlevels;
    AUC = 0;
% Loop through cost bins
    for bin = 1:nbins %Loop through cost bins        
        %Get parameters
            %Weight on cost for this bin (parameters 2-6 from muPhi)
                k = exp(muPhi(1+bin));
            %Choice bias (first parameter of muPhi)
                if bin == 1
                    b = exp(muPhi(1));
                else
                    b = 1 - k.*C_i - R_i; %C_i and R_i obtained from previous bin, see below
                end
                C_i = binlimits(bin+1); %Cost level of the bin edge
                R_i = 1 - k*C_i - b; %Indifference reward level at cost bin edge 
        %Compute area under the curve (positive range only)
            X = linspace(binlimits(bin),binlimits(bin+1),costlevels_per_bin);
            Y = 1 - b - k.*X;
            AUC = AUC + trapz(Y(Y>0));
    end
end %function