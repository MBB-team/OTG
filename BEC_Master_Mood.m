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
            
%% [1] Instructions, examples, and calibration of choice tasks
    if startpoint == 0 || startpoint == 1
        % TO DO
    end
    
%% [2] Quiz and Rating Examples
if startpoint == 0 || startpoint == 2
    startpoint = 0;
    
    %Instructions and examples: Quiz
        if AllData.Instructions.Progress == 4 %TO DO: update instruction progress number w.r.t. preceding choice instructions
            AllData.timings.StartQuizInstructions = clock; 
            %Make examples triallist
                ex_quiztrialinfo = struct;
                ex_triallist.quizcondition = [ones(exp_settings.QuizExamples(1),1); zeros(exp_settings.QuizExamples(2),1)];
                ex_triallist.quizquestions = exp_settings.QuizTraining(:,1);
                ex_triallist.quizanswers = exp_settings.QuizTraining(:,2:end);
            %Show instructions
%                 exitflag = S8_Exp_InstructionScreens(window,exp_settings,slides);
                if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
            %Loop through examples
                for trial = 1:sum(exp_settings.QuizExamples)
                    %Instruction: neutral condition
                        if trial == exp_settings.QuizExamples(1)+1
%                             exitflag = S8_Exp_InstructionScreens(window,exp_settings,slides);
                            if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
                        end
                    %Quiz question
                        answerorder = randperm(4);
                        ex_quiztrialinfo(trial).IsNeutral = ex_triallist(trial).quizcondition == 0;
                        ex_quiztrialinfo(trial).Question = ex_triallist.quizquestions{trial};
                        ex_quiztrialinfo(trial).ans_A = ex_triallist.quizanswers{trial,answerorder(1)};
                        ex_quiztrialinfo(trial).ans_B = ex_triallist.quizanswers{trial,answerorder(2)};
                        ex_quiztrialinfo(trial).ans_C = ex_triallist.quizanswers{trial,answerorder(3)};
                        ex_quiztrialinfo(trial).ans_D = ex_triallist.quizanswers{trial,answerorder(4)};
                        ex_quiztrialinfo(trial).CorrectAnswer = find(answerorder==1);
                        [ExampleData,exitflag] = BEC_ShowQuizQuestion(window,question,AllData);
                        if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
                    %Give feedback
                        if ex_triallist.quizcondition(trial) ~= 0
                            switch ExampleData.quiztrialinfo.IsCorrect
                                case 1; feedback = 1; %Correct answer
                                case -1; feedback = -1; %Timeout
                                case 0; feedback = 0; %Wrong answer
                            end
                            BEC_ShowFeedback(window,AllData,feedback)
                        else %Blank screen for the same amount of time as feedback
                            Screen('Flip',window);
                            WaitSecs(exp_settings.timings.show_feedback);
                        end
                end            
            %Save
                AllData.Instructions.Progress = 5; %TO DO: update instruction progress number w.r.t. preceding choice instructions
                save([AllData.savedir filesep 'AllData'],'AllData');
        end        
    %Instructions and examples: rating        
        if AllData.Instructions.Progress == 5 %TO DO: update instruction progress number w.r.t. preceding choice instructions
            AllData.timings.StartRatingInstructions = clock; 
            %Show instructions
%                 exitflag = S8_Exp_InstructionScreens(window,exp_settings,slides);
                if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
            %Examples: rating
                for rate = 1:4
                    switch AllData.gender
                        case 'm'; dimension = exp_settings.RatingDimensions_male{rate};
                        case 'f'; dimension = exp_settings.RatingDimensions_female{rate};
                    end
                    BEC_RateMood(window,AllData,dimension);
                end
            %Save
                AllData.Instructions.Progress = 6; %TO DO: update instruction progress number w.r.t. preceding choice instructions
                save([AllData.savedir filesep 'AllData'],'AllData');
        end
    %End of examples 
        %Show instructions
%             exitflag = S8_Exp_InstructionScreens(window,exp_settings,slides);
            if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
end

%% [3] Main Experiment
if startpoint == 0 || startpoint == 3
    startpoint = 0;
    
%     %Make triallist
%         if isfield(AllData,'triallist') %Resume previously interrupted
%             i_question = size(AllData.quiztrialinfo,2);
%             if i_question == 0; i_question = 1; end
%         else
AllData.trialinfo = struct;
AllData.OTG_prior = struct;
AllData.OTG_posterior = struct;
%             AllData.timings.StartMainExperiment = clock; 
%             AllData.triallist = S8_Exp_MakeTriallist(exp_settings,AllData);
%             AllData.Ratings = NaN(exp_settings.QuizTrials,length(exp_settings.RatingDimensions_male));    
%             AllData.quiztrialinfo = struct;
%             AllData.trialinfo = struct;
%             if AllData.pupil; AllData.eye_calibration = []; end
%             i_question = 1;
%         end    
%         save([AllData.savedir filesep 'AllData'],'AllData'); 
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
        exitflag = BEC_InstructionScreens(window,exp_settings,'start_main_experiment');
        if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
    %Loop through quiz questions
        for question = i_question:exp_settings.trialgen_moods.QuizTrials
            %Break time after sessions 3 and 6
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
                AllData.quiztrialinfo(question).IsNeutral = AllData.triallist(question).quizcondition == 0;
                AllData.quiztrialinfo(question).Question = AllData.triallist.quizquestions{question};
                AllData.quiztrialinfo(question).ans_A = AllData.triallist.quizanswers{question,AllData.triallist.answerorder(question,1)};
                AllData.quiztrialinfo(question).ans_B = AllData.triallist.quizanswers{question,AllData.triallist.answerorder(question,2)};
                AllData.quiztrialinfo(question).ans_C = AllData.triallist.quizanswers{question,AllData.triallist.answerorder(question,3)};
                AllData.quiztrialinfo(question).ans_D = AllData.triallist.quizanswers{question,AllData.triallist.answerorder(question,4)};
                AllData.quiztrialinfo(question).CorrectAnswer = AllData.triallist.correctanswer(question);
                [AllData,exitflag] = BEC_ShowQuizQuestion(window,question,AllData);
                if exitflag; BEC_ExitExperiment(AllData); return; end %Terminate experiment
            %Give feedback
                if AllData.triallist.quizcondition(question) ~= 0
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
                else %Blank screen for the same amount of time as feedback
                    Screen('Flip',window);
                    if AllData.pupil %-- TO DO
%                         S10_Exp_PhysiologyMark(AllData,'quiz_feedback')
                    end
                    WaitSecs(exp_settings.timings.show_feedback);
                end
            %Blank screen
%                 if AllData.pupil; EyeTribeSetCurrentMark(4); end -- TO DO
                Screen('Flip',window);
                WaitSecs(exp_settings.timings.wait_blank)
            %Rating    
                AllData.timings.rating_timestamp(question,:) = clock;
%                 switch AllData.gender
%                     case 'm'; dimension = exp_settings.RatingDimensions_male{rate};
%                     case 'f'; dimension = exp_settings.RatingDimensions_female{rate};
%                 end
                [rating,RT] = BEC_RateMood(window,AllData,dimension);
                AllData.Ratings(question,AllData.triallist.ratings_num(question)) = rating;
                AllData.timings.rating_duration(question,1) = RT;
            %Get pupil data from part one of the trial (mood induction)
                if AllData.pupil
                    [ ~, PupilData ,~] = EyeTribeGetDataSimple;
                    Trial_PupilData = [Trial_PupilData; PupilData];
                end
            %Choice battery
                for choicetrial = (question-1)*exp_settings.trialgen_moods.choices_per_question + (1:exp_settings.trialgen_moods.choices_per_question)
                    %Set the trial info
                        sidenames = {'left','right'};
                        trialinfo.trial = choicetrial; %Trial number (only required for the pupil marker)
                        trialinfo.question = question; %Quiz question number
                        trialinfo.condition = AllData.triallist(question).quizcondition; %Quiz condition
                        trialinfo.choicetype = AllData.triallist.choices.choicetype(choicetrial); %Set number (1:delay/2:risk/3:physical effort/4:mental effort)
                        trialinfo.SSReward = AllData.triallist.choices.SSReward(choicetrial); %Reward for the uncostly (SS) option (between 0 and 1)
                        trialinfo.Cost = AllData.triallist.choices.LLCost(choicetrial); %Cost level or the costly (LL) option (between 0 and 1)
                        trialinfo.SideSS = sidenames{1+AllData.triallist.choices.sideSS(choicetrial)}; %(optional) set on which side you want the uncostly (SS) option to be (enter string: 'left' or 'right')
                        trialinfo.Pupil = AllData.pupil; %(optional, default 0) flag 1 if you want to record pupil data
                    %Present the choice
                        [AllData.trialinfo(choicetrial),exitflag] = BEC_ShowChoice(window,exp_settings,trialinfo);
                        if exitflag; BEC_ExitExperiment(AllData); return; end
                end
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

%% [4] Reward calculation ?
    if startpoint == 0 || startpoint == 4
        %Reward calculation
            % TO DO ?
        %Terminate the experiment
            RH_WaitForKeyPress({exp_settings.keys.proceedkey});
            BEC_ExitExperiment(AllData)
    end