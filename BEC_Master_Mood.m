% BECHAMEL Master
% Battery of Economic CHoices And Mood/Emotion Links
% Master script for experiment with mood inductions
% NB: set the volume to a level so that the feedback noise is acceptably loud

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
                AllData.ID = input('Enter the ppt ID: ');
            %Get the settings and directories
                savename = [AllData.initials '_' datestr(clock,30)]; %Directory name where the dataset will be saved
                AllData.savedir = [exp_settings.datadir filesep savename]; %Path of the directory where the data will be saved      
                mkdir(exp_settings.datadir,savename); %Create the directory where the data will be stored
                disp('Dataset and directory created.')
                AllData.Instructions.Progress = 0; %Start with the beginning of the instructions
        else %A dataset already exists
            clearvars -except AllData exp_settings %Keep only the data structure
            startpoint = input('Enter start point (1.Choice instructions and calibration/2.Quiz instructions/3.Main Experiment/4.Reward calculation): '); %Pre-start checks
        end
    %Add all experiment scripts and functions to the path
        addpath(genpath(exp_settings.expdir)) 
    %Pupil settings
        AllData.pupil = input('Record pupil? (flag 1:yes / 0:no): ');
        if startpoint == 3 %Main experiment
            Recalibrate = input('(Re)calibrate eyes? (flag 1:yes / 0:no): ');
        end      
    %Open a screen
        Screen('Preference', 'SkipSyncTests', 1); %Skip sync tests: yes
        Screen('Preference', 'VisualDebugLevel', 3); %Visual debug level
        Screen('Preference', 'SuppressAllWarnings', 1);
        KbName('UnifyKeyNames'); %unify across platforms
        [window,winRect] = Screen('OpenWindow',0,exp_settings.backgrounds.default); %0 for Windows Desktop screen
        HideCursor  
    %Make a triallist
        if ~isfield(AllData,'triallist')
            AllData.triallist = BEC_MakeTriallist_Mood(exp_settings); %Triallist for main experiment
            AllData.triallist.calibration_per_type = exp_settings.trialgen_choice.which_choicetypes(randperm(exp_settings.trialgen_choice.n_choicetypes)); %Order in which the different choice types' instructions/examples/calibration will be presented
        end
    %Save
        save([AllData.savedir filesep 'AllData'],'AllData'); 
        disp('Dataset saved. Experiment will start now.')            
            
%% [1] Instructions, examples, and calibration of choice tasks
    if startpoint == 0 || startpoint == 1
        %Introduction (instruction, timing)
            if AllData.Instructions.Progress == 0
                AllData.timings.StartExperiment = clock;
                exitflag = BEC_InstructionScreens(window,exp_settings,exp_settings.instructions_moods.introduction);
                if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
                AllData.Instructions.Progress = 1;
                AllData.timings.ChoiceInstructions = clock;
            end
        %Loop through choice types
            loop_choicetypes = AllData.triallist.calibration_per_type(AllData.Instructions.Progress:end); %This is so that the ppt does not have to redo choicetype that they have already done.
            for i_type = loop_choicetypes
                exampletrial.choicetype = i_type;  %Set number (1:delay/2:risk/3:physical effort/4:mental effort)
                i_examples = randperm(size(exp_settings.exampletrials,2));
                %Instructions per choice type
                    AllData.timings.(['Instructions_' exp_settings.trialgen_choice.typenames{i_type}]) = clock; %Timing
                    exitflag = BEC_InstructionScreens(window,exp_settings,exp_settings.instructions_moods.([exp_settings.trialgen_choice.typenames{i_type} '_instructions']));
                    if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
                %Example trials
                    for trl = 1:length(i_examples)                                    
                        exampletrial.SSReward = exp_settings.exampletrials(1,i_examples(trl));   %Reward for the uncostly (SS) option (between 0 and 1)
                        exampletrial.Cost = exp_settings.exampletrials(2,i_examples(trl));       %Cost level or the costly (LL) option (between 0 and 1)
                        exampletrial.Example = 1;
                        [~,exitflag] = BEC_ShowChoice(window,exp_settings,exampletrial);
                        if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
                    end
                %Calibration instructions
                    exitflag = BEC_InstructionScreens(window,exp_settings,exp_settings.instructions_moods.([exp_settings.trialgen_choice.typenames{i_type} '_start_calibration']));
                    if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
                %Calibration
                    AllData.timings.(['Calibration_' exp_settings.trialgen_choice.typenames{i_type}]) = clock; %Timing
                    [AllData.calibration.(exp_settings.trialgen_choice.typenames{i_type}),exitflag] = BEC_Calibration(exp_settings,i_type,window,AllData.savedir);
                    if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
                    AllData.timings.(['Calibration_duration_' exp_settings.trialgen_choice.typenames{i_type}]) = etime(clock,...
                        AllData.timings.(['Calibration_' exp_settings.trialgen_choice.typenames{i_type}]));
                %Update instruction progress
                    AllData.Instructions.Progress = AllData.Instructions.Progress + 1;
            end %for i_type
    end %if startpoint
    
%% [2] Quiz and Rating Examples
if startpoint == 0 || startpoint == 2
    startpoint = 0;    
    if AllData.Instructions.Progress == 5
        %Break, announce phase 2, show instructions for quiz and rating
            AllData.timings.break = clock;
            exitflag = BEC_InstructionScreens(window,exp_settings,exp_settings.instructions_moods.start_phase_2); %Contains: break, Phase 2 screen, instructions for quiz questions and ratings.
            if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
        %Loop through examples
            AllData.timings.StartQuizInstructions = clock; 
            for trial = 1:sum(exp_settings.trialgen_moods.QuizExamples)
                %Quiz question
                    answerorder = randperm(4);
                    example_question.Question = exp_settings.QuizTraining{trial,1};
                    example_question.ans_A = exp_settings.QuizTraining{trial,1+answerorder(1)};
                    example_question.ans_B = exp_settings.QuizTraining{trial,1+answerorder(2)};
                    example_question.ans_C = exp_settings.QuizTraining{trial,1+answerorder(3)};
                    example_question.ans_D = exp_settings.QuizTraining{trial,1+answerorder(4)};
                    example_question.CorrectAnswer = find(answerorder==1);
                    [ExampleData,exitflag] = BEC_ShowQuizQuestion(window,example_question,AllData);
                    if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
                %Give feedback
                    switch ExampleData.quiztrialinfo.IsCorrect
                        case 1; feedback = 1; %Correct answer
                        case -1; feedback = -1; %Timeout
                        case 0; feedback = 0; %Wrong answer
                    end
                    BEC_ShowFeedback(window,AllData,feedback)
                %Rate mood
                    BEC_RateMood(window,AllData);
            end                     
        %Save
            AllData.Instructions.Progress = 6;
            save([AllData.savedir filesep 'AllData'],'AllData');
    end            
end

%% [3] Main Experiment
if startpoint == 0 || startpoint == 3
    startpoint = 0;
    
    %Make triallist
        if isfield(AllData,'trialinfo') %Resume previously interrupted
            i_question = size(AllData.quiztrialinfo,2);
            if i_question == 0; i_question = 1; end
        else
            i_question = 1;
            AllData.timings.StartMainExperiment = clock;
            AllData.quiztrialinfo = struct;
            AllData.Ratings = NaN(exp_settings.trialgen_moods.QuizTrials,1);    
            if AllData.pupil; AllData.eye_calibration = []; end
        end    
        save([AllData.savedir filesep 'AllData'],'AllData'); 
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
        exitflag = BEC_InstructionScreens(window,exp_settings,exp_settings.instructions_moods.end_of_instructions);
        if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
    %Loop through quiz questions
        for question = i_question:exp_settings.trialgen_moods.QuizTrials
            %Break time
                if ismember(question,exp_settings.trialgen_moods.i_break)
                    i_break = find(question==exp_settings.trialgen_emotions.i_break);   %Break number
                    %Timing
                        AllData.timings.breakstart(i_break,:) = clock;
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
                        AllData.timings.breakend(i_break,:) = clock;
                end
            %Define Eyetracker scene (i.e. quiz trial number)
                if AllData.pupil; Trial_PupilData = []; EyeTribeSetCurrentScene(question); end            
            %Quiz question
                AllData.quiztrialinfo(question).Question = AllData.triallist.quizquestions{question};
                AllData.quiztrialinfo(question).ans_A = AllData.triallist.quizanswers{question,AllData.triallist.answerorder(question,1)};
                AllData.quiztrialinfo(question).ans_B = AllData.triallist.quizanswers{question,AllData.triallist.answerorder(question,2)};
                AllData.quiztrialinfo(question).ans_C = AllData.triallist.quizanswers{question,AllData.triallist.answerorder(question,3)};
                AllData.quiztrialinfo(question).ans_D = AllData.triallist.quizanswers{question,AllData.triallist.answerorder(question,4)};
                AllData.quiztrialinfo(question).CorrectAnswer = AllData.triallist.correctanswer(question);
                [AllData,exitflag] = BEC_ShowQuizQuestion(window,question,AllData);
                if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
            %Give feedback
                switch AllData.quiztrialinfo(question).IsCorrect
                    case 1; feedback = 1; %Correct answer
                    case -1; feedback = -1; %Timeout
                    case 0 %Incorrect answer; determine feedback to be given
                        if rand < AllData.triallist.quizbias(question)
                            feedback = 1; %False positive feedback (positive feedback bias)
                        else
                            feedback = 0;
                        end
                end
                AllData.quiztrialinfo(question).Feedback = feedback;
                BEC_ShowFeedback(window,AllData,feedback)
            %Blank screen
%                 if AllData.pupil; EyeTribeSetCurrentMark(4); end -- TO DO
%                 Screen('Flip',window);
%                 WaitSecs(exp_settings.timings.wait_blank)
            %Rating (if before choices) 
                if strcmp(AllData.triallist.rating(question),'before')
                    AllData.timings.rating_timestamp(question,:) = clock;
                    [AllData.Ratings(question),AllData.timings.rating_duration(question,1)] = BEC_RateMood(window,AllData);
                end
            %Get pupil data from part one of the trial (mood induction)
                if AllData.pupil
%                     [ ~, PupilData ,~] = EyeTribeGetDataSimple;
%                     Trial_PupilData = [Trial_PupilData; PupilData];
                end
            %Online trial generation
                for choicetrial = 1:2
                    [AllData,exitflag] = BEC_OnlineTrialGeneration(AllData,window);
                    if exitflag; BEC_ExitExperiment(AllData); return; end
                end
            %Rating (if after choices) 
                if strcmp(AllData.triallist.rating(question),'after')
                    AllData.timings.rating_timestamp(question,:) = clock;
                    [AllData.Ratings(question),AllData.timings.rating_duration(question,1)] = BEC_RateMood(window,AllData);
                end
            %Save the data at the end of each trial
                save([AllData.savedir filesep 'AllData'],'AllData');
                if AllData.pupil %Save pupil data from this trial
%                     [ ~, PupilData ,~] = EyeTribeGetDataSimple;
%                     Trial_PupilData = [Trial_PupilData; PupilData];
%                     save([AllData.savedir filesep 'Pupil' filesep 'Pupil_' num2str(induction)],'Trial_PupilData');
                end
        end
        %Terminate the physiology recordings at the end of the battery
            if AllData.pupil; EyeTribeUnInit; end
end

%% [4] Reward calculation
    if startpoint == 0 || startpoint == 4
        %Instruction
            exitflag = BEC_InstructionScreens(window,exp_settings,exp_settings.instructions_moods.end_of_experiment); %Contains: break, Phase 2 screen, instructions for quiz questions and ratings.
            if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment            
        %Reward calculation
%             [AllData] = BEC_RewardTrialSelection(window,AllData);
        %Terminate the experiment
            RH_WaitForKeyPress({exp_settings.keys.proceedkey});
            BEC_ExitExperiment(AllData)
    end