% BEC_Demo_DEER_Calibration
% Demonstration of the 4 choice tasks: instructions, examples, then calibration.
% RH - October 2021
% -----------------

%% Start the experiment
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
        exp_settings = BEC_Settings; %Default settings structure
        exp_settings.n_example_choices = 6; %For now: 6 examples per type
        exp_settings.max_example_choices = 12; %Limit the amount of examples to 12 in order to avoid wasting time
        exp_settings.OTG.ntrials_cal = 20; %Calibration battery consists of 20 trials (ideally: 25 or more)
    %Make new dataset if needed (after exp_settings is loaded)
        if ~exist('AllData','var')
            %Create data structure and get experiment settings structure
                AllData = struct;
                AllData.exp_settings = exp_settings; 
                AllData.bookmark = 0; %This field will track where we are in the experiment. If interrupted, the experiment can be resumed at exactly the right location.
                AllData.plugins = struct; %Empty structure: no plugged-in devices
            %Participant data
                AllData.ID = input('Enter participant ID: ','s');
            %Get the settings and directories
                savename = [AllData.ID '_' datestr(clock,30)]; %Directory name where the dataset will be saved
                AllData.savedir = [exp_settings.datadir filesep savename]; %Path of the directory where the data will be saved      
                mkdir(exp_settings.datadir,savename); %Create the directory where the data will be stored
                disp('Dataset and directory created.')
        end
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
    %First launch settings: create timing event reel, complete the setup
        if AllData.bookmark == 0
            AllData.Timings.StartExperiment = clock;
            AllData.EventReel = BEC_Timekeeping('StartExperiment',AllData.plugins);
            AllData.bookmark = 1;
        end
    %Save
        save([AllData.savedir filesep 'AllData'],'AllData'); 
        disp('Dataset saved. Experiment will start now.') 
        
%% Introduction
    if AllData.bookmark == 1
        instruction_numbers = [101 102];
        exitflag = BEC_InstructionScreens(window,AllData,instruction_numbers);
        if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
        AllData.Timings.End_of_introduction = clock;
        AllData.bookmark = 2;
    end            
        
%% Instructions and examples of DELAY
    if AllData.bookmark == 2
        %Show instructions about choices in general, and about delay
            instruction_numbers = 103;
            exitflag = BEC_InstructionScreens(window,AllData,instruction_numbers);
            if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
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
            AllData.bookmark = 3; %Move on to next section
            AllData.ExampleChoices = 1; %Prepare for what comes next
            save([AllData.savedir filesep 'AllData'],'AllData'); 
    end %if bookmark
    
%% Test battery: DELAY
    if AllData.bookmark == 3
        %Show instructions about calibration choice battery
            instruction_numbers = 104;
            exitflag = BEC_InstructionScreens(window,AllData,instruction_numbers);
            if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
        %Run calibration
            [AllData,exitflag] = BEC_Calibration(AllData,1,window,1);
            AllData.bookmark = 4; %Move on to next section
    end
      
%% Instructions and examples of RISK
    if AllData.bookmark == 4
        %Show instructions about choices in general, and about risk
            instruction_numbers = 105;
            exitflag = BEC_InstructionScreens(window,AllData,instruction_numbers);
            if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
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
                    if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
                    if i_ex == 1
                        AllData.Example_Choices.trialinfo_risk = trialoutput;
                    else
                        AllData.Example_Choices.trialinfo_risk(i_ex) = trialoutput;
                    end
                    AllData.EventReel = [AllData.EventReel AllData.Example_Choices.trialinfo_risk(i_ex).timings]; %Store the recorded timing structure in a list of all events
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
            if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
        %Run calibration
            [AllData,exitflag] = BEC_Calibration(AllData,2,window,1);
            AllData.bookmark = 6; %Move on to next section
    end

%% Instructions and examples of PHYSICAL EFFORT
    if AllData.bookmark == 6
        %Show instructions about choices in general, and about physical effort
            instruction_numbers = 107;
            exitflag = BEC_InstructionScreens(window,AllData,instruction_numbers);
            if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
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
                    if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
                    if i_ex == 1
                        AllData.Example_Choices.trialinfo_physical_effort = trialoutput;
                    else
                        AllData.Example_Choices.trialinfo_physical_effort(i_ex) = trialoutput;
                    end
                    AllData.EventReel = [AllData.EventReel AllData.Example_Choices.trialinfo_physical_effort(i_ex).timings]; %Store the recorded timing structure in a list of all events
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
            if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
        %Run calibration
            [AllData,exitflag] = BEC_Calibration(AllData,3,window,1);
            AllData.bookmark = 8; %Move on to next section
    end
    
%% Instructions and examples of MENTAL EFFORT
    if AllData.bookmark == 8
        %Show instructions about choices in general, and about effort
            instruction_numbers = 109;
            exitflag = BEC_InstructionScreens(window,AllData,instruction_numbers);
            if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
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
                    if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
                    if i_ex == 1
                        AllData.Example_Choices.trialinfo_mental_effort = trialoutput;
                    else
                        AllData.Example_Choices.trialinfo_mental_effort(i_ex) = trialoutput;
                    end
                    AllData.EventReel = [AllData.EventReel AllData.Example_Choices.trialinfo_mental_effort(i_ex).timings]; %Store the recorded timing structure in a list of all events
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
            AllData.Timings.EndExamples_Mental_Effort = clock;
            AllData.bookmark = 9; %Move on to next section
            save([AllData.savedir filesep 'AllData'],'AllData'); 
    end %if bookmark
    
%% Test battery: MENTAL EFFORT
    if AllData.bookmark == 9
        %Show instructions about calibration choice battery
            instruction_numbers = 110;
            exitflag = BEC_InstructionScreens(window,AllData,instruction_numbers);
            if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
        %Run calibration
            [AllData,exitflag] = BEC_Calibration(AllData,4,window,1);
            AllData.bookmark = 10; %Move on to next section
    end

%% End of experiment
if AllData.bookmark == 10        
    %End of the experiment
        instruction_numbers = 111;
        BEC_InstructionScreens(window,AllData,instruction_numbers);
        AllData.Timings.EndOfExperiment = clock;
        save([AllData.savedir filesep 'AllData'],'AllData');
    %Close
        BEC_ExitExperiment(AllData);
        
end %if bookmark