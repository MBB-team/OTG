function [triallist] = BEC_MakeTriallist_Mood(exp_settings)

%% Quiz trials
    %List trials
        triallist = struct;
        triallist.trialno = (1:exp_settings.trialgen_moods.QuizTrials)';
    %Session allocation       
        nconditions = length(exp_settings.trialgen_moods.SessionConditions); %Conditions: positive and negative mood sessions
        conditions = ShuffleConditions(nconditions,exp_settings.trialgen_moods.nSessions/nconditions);
        triallist.sessionconditions = exp_settings.trialgen_moods.SessionConditions(conditions); 
        triallist.quizsession = kron((1:exp_settings.trialgen_moods.nSessions)',ones(exp_settings.trialgen_moods.QuizTrials/exp_settings.trialgen_moods.nSessions,1));
        triallist.quizcondition = kron((triallist.sessionconditions)',ones(exp_settings.trialgen_moods.QuizTrials/exp_settings.trialgen_moods.nSessions,1));
    %Bias percentage
        %Biases in a positive and negative session
            biases_positive = []; biases_negative = [];
            for i = 1:length(exp_settings.trialgen_moods.SessionBiasTrials)
                biases_positive = [biases_positive ...
                    exp_settings.trialgen_moods.SessionQuizBias.positive(i)*ones(1,exp_settings.trialgen_moods.SessionBiasTrials(i))]; %#ok<*AGROW>
                biases_negative = [biases_negative ...
                    exp_settings.trialgen_moods.SessionQuizBias.negative(i)*ones(1,exp_settings.trialgen_moods.SessionBiasTrials(i))];
            end
        %Across sessions
            triallist.quizbias = [];
            for j = 1:exp_settings.trialgen_moods.nSessions
                if triallist.sessionconditions(j) == 1 %Positive session
                    triallist.quizbias = [triallist.quizbias; biases_positive'];
                elseif triallist.sessionconditions(j) == -1 %Negative session
                    triallist.quizbias = [triallist.quizbias; biases_negative'];
                end
            end
    %Question selection
        %Sort according to accuracy (1-difficulty)
            accuracy = exp_settings.QuizAccuracy +0.0001*rand(length(exp_settings.QuizAccuracy),1); % (inspired by Fabien) Randomization across a given level of difficulty
            [~,i_accuracy] = sort(accuracy); %Sorted from hardest to easiest
        %Make question list
            triallist.quizquestions = cell(exp_settings.trialgen_moods.QuizTrials,5);
            %Randomly sample pos. condition trials from easier questions after median split
                i_easy = i_accuracy(floor(length(i_accuracy)/2)+1:end);
                select_positive = i_easy(randperm(length(i_easy),sum(triallist.quizcondition==1)));
                triallist.quizquestions(triallist.quizcondition==1) = exp_settings.QuizQuestions(select_positive,1);
                triallist.quizanswers(triallist.quizcondition==1,:) = exp_settings.QuizQuestions(select_positive,2:end);
                triallist.quizaccuracy(triallist.quizcondition==1,1) = accuracy(select_positive);
            %Randomly sample neg. condition trials from harder questions after median split
                i_hard = i_accuracy(1:floor(length(i_accuracy)/2));
                select_negative = i_hard(randperm(length(i_hard),sum(triallist.quizcondition==-1)));
                triallist.quizquestions(triallist.quizcondition==-1) = exp_settings.QuizQuestions(select_negative,1);
                triallist.quizanswers(triallist.quizcondition==-1,:) = exp_settings.QuizQuestions(select_negative,2:end);
                triallist.quizaccuracy(triallist.quizcondition==-1,1) = accuracy(select_negative);
            %Question features: answer order, correct answer
                triallist.answerorder = NaN(length(triallist.quizquestions),4); %four possible answers
                triallist.correctanswer = NaN(length(triallist.quizquestions),1);
                for k = 1:length(triallist.answerorder)
                    answers = randperm(4,4);
                    triallist.answerorder(k,:) = answers;
                    triallist.correctanswer(k,:) = find(answers==1);
                end
                
%% Ratings
    %Before choices, after choices, or no mood rating following this question
        triallist.rating = exp_settings.trialgen_moods.Ratingconditions(...
            ShuffleConditions(length(exp_settings.trialgen_moods.Ratingconditions),exp_settings.trialgen_moods.QuizTrials/length(exp_settings.trialgen_moods.Ratingconditions)))';
           
%% Choice trials
    %In the main experiment: 4 choices in random order, following a quiz question
        triallist.choicetypes = ShuffleConditions(exp_settings.trialgen_choice.n_choicetypes,...
            exp_settings.trialgen_moods.QuizTrials*exp_settings.trialgen_moods.choices_per_question/exp_settings.trialgen_choice.n_choicetypes);


end %function

function [conditions] = ShuffleConditions(nConditions,nRepetitions)
% nConditions: how many unique conditions are there?
% nRepetitions: how many instances of each condition should occur?
% conditions: list all repetitions of all conditions, such that:
%   - there is no fixed repeated pattern, and
%   - no two subsequent conditions are the same
        conditions = [];
        for k = 1:nRepetitions
            addconditions = randperm(nConditions)';
            if ~isempty(conditions)
                while addconditions(1) == conditions(end)
                    addconditions = randperm(nConditions)';
                end
            end
            conditions = [conditions; addconditions];
        end 
end