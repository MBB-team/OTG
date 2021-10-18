% BECHAMEL Master
% Battery of Economic CHoices And Mood/Emotion Links
% Master script for experiment with calibration of delay and mental effort discounting tasks.

%% Set up the experiment
    %Get the experiment settings structure and adjust settings specific to this experiment
        exp_settings = BEC_Settings;
        exp_settings.OTG.ntrials_cal = 25; %Number of choice model calibration trials
        exp_settings.n_example_choices = 10; %Minimum number of example choices per choice type
        exp_settings.max_example_choices = 15; %Maximum number of example choices per choice type
    %Make new dataset if needed (after exp_settings is loaded)
        %Create data structure and get experiment settings structure
            AllData = struct;
            AllData.ID = input('Enter patient ID: ','s');
            AllData.exp_settings = exp_settings; 
            AllData.bookmark = 0; %Indicate progress during the experiment
        %Get the settings and directories
            savename = [AllData.ID '_' datestr(clock,30)]; %Directory name where the dataset will be saved
            AllData.savedir = [exp_settings.datadir filesep savename]; %Path of the directory where the data will be saved      
            mkdir(exp_settings.datadir,savename); %Create the directory where the data will be stored
            disp('Dataset and directory created.')
    %Add all experiment scripts and functions to the path
        addpath(genpath(exp_settings.expdir)) 
    %Plugins: Tactile screen
        AllData.plugins.touchscreen = input('Experiment on a tactile screen device? (flag 1:yes / 0:no): ');
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
        
%% Instructions and examples of DELAY
    if AllData.bookmark == 1
        %Show instructions about choices in general, and about delay
            instruction_numbers = [4 5];
            [exitflag,timings] = BEC_InstructionScreens(window,AllData,instruction_numbers);
            if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
            AllData.EventReel = [AllData.EventReel timings]; %Store the recorded timing structure in a list of all events
        %Delay examples
            i_ex = AllData.ExampleChoices;
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
            AllData.bookmark = 2; %Move on to next section
            AllData.ExampleChoices = 1; %Prepare for what comes next
            save([AllData.savedir filesep 'AllData'],'AllData'); 
    end %if bookmark
    
%% Test battery: DELAY
    if AllData.bookmark == 2
        %Show instructions about calibration choice battery
%             [exitflag,timings] = BEC_InstructionScreens(window,AllData,'effort_instructions');
%             if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
        %Run calibration
            [AllData,exitflag] = BEC_Calibration(AllData,1,window,1);
            AllData.bookmark = 3; %Move on to next section
    end
    
%% Instructions and examples of MENTAL EFFORT
    if AllData.bookmark == 3
        %Show instructions about choices in general, and about effort
            [exitflag,timings] = BEC_InstructionScreens(window,AllData,'effort_instructions');
            if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
            AllData.EventReel = [AllData.EventReel timings]; %Store the recorded timing structure in a list of all events
        %Effort examples
            i_ex = AllData.ExampleChoices;
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
            AllData.bookmark = 4; %Move on to next section
            save([AllData.savedir filesep 'AllData'],'AllData'); 
    end %if bookmark
    
%% Test battery: MENTAL EFFORT
    if AllData.bookmark == 4
        %Show instructions about calibration choice battery
%             [exitflag,timings] = BEC_InstructionScreens(window,AllData,'effort_instructions');
%             if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
        %Run calibration
            [AllData,exitflag] = BEC_Calibration(AllData,4,window,1);
            AllData.bookmark = 5; %Move on to next section
    end

%% End of experiment
if AllData.bookmark == 5        
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