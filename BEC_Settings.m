function [exp_settings] = BEC_Settings
% Settings structure for the Battery of Economic CHoices And Mood/Emotion Links experiments

% Setup
    rng('shuffle')              %Shuffle the random number generator
    exp_settings = struct;      %Predefine output
    expdir = which('BEC_Settings'); expdir = expdir(1:end-15);  %Get the directory where this function is stored
    cd(expdir);                 %Change directory to the directory where this function is situated
% Keyboard settings
    exp_settings.keys.escapekey = 'escape'; %Do not change this. 'Escape' remains the escape key.
    exp_settings.keys.proceedkey = 'p'; %Key to be pressed by experimenter in order to proceed.
    exp_settings.keys.quiz_A = 'F'; %Mood quiz - answer A
    exp_settings.keys.quiz_B = 'G'; %Mood quiz - answer B
    exp_settings.keys.quiz_C = 'H'; %Mood quiz - answer C
    exp_settings.keys.quiz_D = 'J'; %Mood quiz - answer D    
    
%% Directories    
    %Where are the experiment scrips? (default: present working directory)
        exp_settings.expdir = expdir;
    %Where do you want to save the data? (default: in a directory called 'Experiment data' in the experiment directory)
        exp_settings.datadir = [expdir filesep 'Experiment data'];
        if ~exist(exp_settings.datadir, 'dir')
           mkdir(exp_settings.datadir)  %Make the directory if not already existing
        end
    %Where are the stimuli located? (default: in a directory called 'Stimuli' in the experiment directory)
        exp_settings.stimdir = [expdir filesep 'Stimuli'];
        
%% Graphics defaults
    %Fonts
        exp_settings.font.FixationFontSize = 50;    %Fixation cross
        exp_settings.font.TitleFontSize = 32;       %Screen titles
        exp_settings.font.RewardFontSize = 25;      %Reward amounts in the choice screen
        exp_settings.font.CostFontSize = exp_settings.font.RewardFontSize; %Idem for the cost amounts
        exp_settings.font.EmoFontSize = 22;         %Emotion induction text
        exp_settings.font.QuestionFontSize = 32;    %Quiz question text
        exp_settings.font.AnswerFontSize = 28;      %Quiz answers
        exp_settings.font.FeedbackFontSize = 32;    %Quiz feedback screen
        exp_settings.font.RatingFontSize = 32;      %Quiz rating font size
        exp_settings.font.FontType = 'Arial';       %Font type (universal)
        exp_settings.font.Wrapat = 75;              %Wrapping (for longer texts of induction screens)
        exp_settings.font.vSpacing = 2;             %Vertical spacing
    %Colors 
        %Define colors
            exp_settings.colors.black = [0 0 0];
            exp_settings.colors.white = [255 255 255];
            exp_settings.colors.grey = [128 128 128];
            exp_settings.colors.green = [0.4660, 0.6740, 0.1880].*255; 
            exp_settings.colors.orange = [0.8500, 0.3250, 0.0980].*255; 
            exp_settings.colors.red = [255 49 0];
        %Background colors
            exp_settings.backgrounds.default = exp_settings.colors.black;   %Default background
            exp_settings.backgrounds.fixation = exp_settings.colors.black;  %Fixation screen
            exp_settings.backgrounds.choice = exp_settings.colors.black;    %Choice screen
            exp_settings.backgrounds.emotion = exp_settings.colors.black;   %Emotion induction screen         
            exp_settings.backgrounds.mood = exp_settings.colors.black;      %Mood induction (quiz question screen)
            exp_settings.backgrounds.rating = exp_settings.colors.black;    %Rating screen      
        %Font colors
            exp_settings.font.FixationFontColor = exp_settings.colors.white;%Fixation screen
            exp_settings.font.ChoiceFontColor = exp_settings.colors.white;  %Choice screen
            exp_settings.font.LossFontColor = exp_settings.colors.red;      %Loss amount on choice screen
            exp_settings.font.EmoFontColor = exp_settings.colors.white;     %Emotion induction screen       
            exp_settings.font.RatingFontColor = exp_settings.colors.white;  %Rating screen
            exp_settings.font.QuizFontColor = exp_settings.colors.white;    %All text on the quiz screen
    
%% Choice screen configuration (universal)
    % Cost and reward features
        exp_settings.MaxReward = 30;  % [euros] reward for the costly option
        exp_settings.RiskLoss = 10;   % [euros] possible loss in the lottery
        exp_settings.MaxDelay = 52;   % [weeks] maximum delay
        exp_settings.MaxRisk = 100;   % [percent] maximum risk
        exp_settings.Max_phys_effort = 12; % max # flights of stairs to climb
        exp_settings.Max_ment_effort = 12; % max # pages to copy
    % Choice screen parameters
        exp_settings.choicescreen.title_y = 1/8;                        %Title y position (choice)
        exp_settings.choicescreen.cost_y = [2/8 3/8];                   %Y-coordinates of the cost above the cost box (example trials only)
        exp_settings.choicescreen.reward_y_example = [13/16 15/16];     %Y-coordinates of the reward below the cost box (example trials only)
        exp_settings.choicescreen.reward_y = [9/16 11/16];              %Y-coordinates of the reward below the cost box
        exp_settings.choicescreen.costbox_left_example = [3/16 1/2 5/16 3/4];      %Left cost visualization
        exp_settings.choicescreen.costbox_right_example = [11/16 1/2 13/16 3/4];   %Right cost visualization
        exp_settings.choicescreen.costbox_left = [2/16 1/5 5/16 1/2];   %Left cost visualization
        exp_settings.choicescreen.costbox_right = [11/16 1/5 14/16 1/2];%Right cost visualization
        exp_settings.choicescreen.monthrects = [(0:11)./12; zeros(1,12); (1:12)./12; [31 28 31 30 31 30 31 31 30 31 30 31]./50]; %Delay visualization
        exp_settings.choicescreen.flightsteps = 18; %Physical effort visualization: 1 flight of stairs = 18 steps
        exp_settings.choicescreen.pagelines = 25;   %One page of text is 25 lines
        exp_settings.choicescreen.linewidth = 1;    %Width of the lines of the cost drawings
        exp_settings.choicescreen.linecolor = exp_settings.colors.white;%Color of the lines of the cost drawings
        exp_settings.choicescreen.fillcolor = exp_settings.colors.red;  %Color of the costs
        exp_settings.choicescreen.probabilitycolor = exp_settings.colors.green;     %Color of the risk arc representing probability to win
        exp_settings.choicescreen.confirmcolor = exp_settings.colors.white;         %Color of the confirmation rectangle around the chosen option
    % Timings
        exp_settings.timings.min_resp_time = 0.5; %[s] before ppt can respond
        exp_settings.timings.show_response = 0.25; %[s] visual feedback duration in example choice trials
        exp_settings.timings.fixation_choice = [0.5 0.75]; %[s] minimum and maximum jittered fixation time during experiment
    
%% Choice trial generation settings
    % Choice triallist creation settings       
        exp_settings.trialgen_choice.which_choicetypes = 1:4;     %which choice types to include (1:delay/2:risk/3:physical effort/4:mental effort)
        exp_settings.trialgen_choice.n_choicetypes = 4;           %amount of choice types
        exp_settings.trialgen_choice.typenames = {'delay','risk','physical_effort','mental_effort'};
        exp_settings.trialgen_choice.cost_bins = 5;                 %divide cost spectrum into bins; make sure each bin is represented
        exp_settings.trialgen_choice.cost_crit_min = 1;             %minimum # of trials sampled per bin
        exp_settings.trialgen_choice.cost_crit_max = 27;            %maximum # of trials sampled per bin
        exp_settings.trialgen_choice.ind_bins = [20 10 5 3 2 0 0 0 0 0]; %also divide P_indiff into bins; these are the amounts of trials to be sampled from each bin    
    % Example choice trials 
        exp_settings.exampletrials = [...
            [0 2 3 5 6 8 7.5 9 10 12 13 14.75]./15; %Rewards for the uncostly option
            [0.7 0.5 0.8 0.3 0.6 0.1 0.9 0.4 0.7 0.2 0.5 0.3]]; %Corresponding costs for the costly option
    % Automatic trial generation
        %General
            exp_settings.ATG.grid.nbins = 5;             % # bins
            exp_settings.ATG.grid.bincostlevels = 10;    % # cost levels per bin  
            exp_settings.ATG.grid.binrewardlevels = 60;  % # reward levels (= 2*exp_settings.MaxReward so that the step size is 0.50 euros)
            exp_settings.ATG.grid.costlimits = [0 1];    % [min max] cost (note: bin 1's first value is nonzero)
            exp_settings.ATG.grid.rewardlimits = [0.1/30 29.9/30]; % [min max] reward for uncostly option
        %Choice calibration
            exp_settings.ATG.ntrials = 60;    % # calibration trials per choice type
            exp_settings.ATG.fixed_beta = 5;  % Assume this value for the inverse choice temperature (based on past results) to improve model fit.
            exp_settings.ATG.prior_bias = -3; % Note: this is log(prior)
            exp_settings.ATG.prior_var = 2;   % Note: applies to all parameters
        %Online trial generation during incidental mood/emotion task
            exp_settings.ATG.online_burntrials = 2; % # of trials per bin that must have been sampled before inverting
            exp_settings.ATG.online_priorvar = 1e0*eye(3); % Prior variance for each parameter
            exp_settings.ATG.online_max_iter = 100; % Max. # of iterations, after which we conclude the algorithm does not converge
            exp_settings.ATG.online_maxperbin = 10; % Max. # of trials in a bin - pick the most recent ones.
            exp_settings.ATG.online_min_k = 0.01; % Minimum value for k when updating bins
    
%% Trial Generation Settings (per experiment type)
    % Trial generation settings: emotions experiment
        exp_settings.trialgen_emotions.emotionnames = {'Happy','Sad','Neutral'};
        exp_settings.trialgen_emotions.n_inductions = 60;   %total number of inductions
        exp_settings.trialgen_emotions.i_break = 31;        %break at the beginning of this trial
        exp_settings.trialgen_emotions.n_emotions = 3;      %number of different emotions
        exp_settings.trialgen_emotions.n_music_stim = 5;    %number of different music stimuli
        exp_settings.trialgen_emotions.i_music_emo = 1:2;   %indices of emotions that have music (happiness and sadness)
        exp_settings.trialgen_emotions.i_neutral = 3;       %index of the neutral condition
        exp_settings.trialgen_emotions.inductions_per_emo = 20;     %number of inductions per emotion condition
        exp_settings.trialgen_emotions.choices_per_induction = 6;   %number of choices following each induction
    % Trial generation settings: moods experiment
        exp_settings.trialgen_moods.QuizExamples = 5;       %number of example quiz trials
        exp_settings.trialgen_moods.QuizTrials = 144;       %total number of quiz trials
        exp_settings.trialgen_moods.choices_per_question = 4; %4 choices following each quiz question (1 of each type)
        exp_settings.trialgen_moods.i_break = NaN;          %break from the experiment at these trials
        exp_settings.trialgen_moods.nSessions = 6;          %total number of sessions
        exp_settings.trialgen_moods.SessionConditions = [1,-1];        % 1: positive-mood, 0: neutral-mood, -1: negative-mood
        exp_settings.trialgen_moods.SessionQuizBias.positive = [0.25 0.375 0.5 0.375 0.25];    % pct of the wrong answers that are biased to (incorrectly) display positive feedback (positive condition)
        exp_settings.trialgen_moods.SessionQuizBias.negative = [0.25 0.125 0   0.125 0.25];    % pct of the wrong answers that are biased to (incorrectly) display positive feedback (negative condition)
        exp_settings.trialgen_moods.SessionBiasTrials = [3 6 6 6 3];   % The number of consecutive trials corresponding to the mood biases
        exp_settings.trialgen_moods.Ratingconditions = {'before','after','none'};
        exp_settings.trialgen_moods.Ratingquestion = 'Comment je me sens?';
        exp_settings.trialgen_moods.Rating_label_min = 'de mauvaise humeur';
        exp_settings.trialgen_moods.Rating_label_max = 'de bonne humeur';

%% Participant reward calculation settings
    exp_settings.Pay.Base = 20;     %euros base pay
    exp_settings.Pay.LLRew = 30;    %euros for LL option
    exp_settings.Pay.delaycriterion = 0.50;     %Max. delay of costly option
    exp_settings.Pay.effortcriterion = 0.50;    %Max. effort of costly option
    exp_settings.Pay.riskcriterion = 0.75;  %Max. risk of costly option
    exp_settings.Pay.min_total = 40; %Min. total reward
    exp_settings.Pay.max_total = 65; %Max. total reward
    exp_settings.Pay.SSCriterion = 0.10; %For very low amounts of SS choices: allow maximum to be higher
    
%% Experiment instructions (per experiment type)
% Emotions experiment
%     exp_settings.instructions_emotions.start_emotion_instructions = 1:4;
%     exp_settings.instructions_emotions.end_emotion_instructions = 5;
%     exp_settings.instructions_emotions.instr_effort = 6:9;
%     exp_settings.instructions_emotions.instr_effort_end = 10;
%     exp_settings.instructions_emotions.cal_effort = 11;    
%     exp_settings.instructions_emotions.instr_delay = 12:14;
%     exp_settings.instructions_emotions.instr_delay_end = 15;
%     exp_settings.instructions_emotions.cal_delay = 16;    
%     exp_settings.instructions_emotions.instr_risk = 17:19;
%     exp_settings.instructions_emotions.instr_risk_end = 20;
%     exp_settings.instructions_emotions.cal_risk = 21;    
%     exp_settings.instructions_emotions.phase_2 = 22:23;
%     exp_settings.instructions_emotions.eyetracker = 24;
%     exp_settings.instructions_emotions.start_main_experiment = 25:26;
%     exp_settings.instructions_emotions.break = 27;
%     exp_settings.instructions_emotions.rate_music = 28:29;
%     exp_settings.instructions_emotions.rewardtrial = 30;    

% Moods experiment
    exp_settings.instructions_moods.introduction = 1:2;
    exp_settings.instructions_moods.delay_instructions = 3:5;
    exp_settings.instructions_moods.delay_start_calibration = 6:7;
    exp_settings.instructions_moods.risk_instructions = 8:10;
    exp_settings.instructions_moods.risk_start_calibration = 11:12;
    exp_settings.instructions_moods.mental_effort_instructions = 13:15;
    exp_settings.instructions_moods.mental_effort_start_calibration = 16:17;
    exp_settings.instructions_moods.physical_effort_instructions = 18:20;
    exp_settings.instructions_moods.physical_effort_start_calibration = 21:22;
    exp_settings.instructions_moods.start_phase_2 = 23:26; %Contains: break, Phase 2 screen, instructions for quiz questions and ratings.
    exp_settings.instructions_moods.end_of_instructions = 27;
    exp_settings.instructions_moods.end_of_experiment = 28;
    
%% Mood stimuli
    % Timings
        exp_settings.timings.delay_answers = 0; %[s] delay between question presentation and answers presentation
        exp_settings.timings.min_quiz_time = 1; %[s] delay between presentation of answers 
        exp_settings.timings.quiz_timeout = 15; %[s] maximum response time to a quiz question
        exp_settings.timings.fix_pre_quiz = [0.5 0.75]; %[s] [min max] fixation time
        exp_settings.timings.show_feedback = 2; %[s]
        exp_settings.timings.wait_blank = 1; %[s]%         
        exp_settings.timings.min_rating_time = 4; %[s]
    % Quiz screen layout
        exp_settings.Moodstimuli.quizquestion_y = 1/5;  %Quiz question y position
        exp_settings.Moodstimuli.answers_ymin = 2/5;    %Top of answers boxes
        exp_settings.Moodstimuli.answers_ymax = 4/5;    %Bottom of answers boxes
        exp_settings.Moodstimuli.answers_xmin = 2/5;    %Left margin of answers boxes
        exp_settings.Moodstimuli.feedback_y = [1/6 5/6];%Quiz answer feedback text positions
    % Quiz questions and answers (first answer is the correct one)
        QR = load([exp_settings.stimdir filesep 'QR_fMRI.mat'], 'QR'); 
        exp_settings.QuizQuestions = QR.QR; 
        listTrainingQuizz = load([exp_settings.stimdir filesep 'listTrainingQuizz.mat']); 
        exp_settings.QuizTraining = listTrainingQuizz.listTrainingQuizz;
        questionAccuracy = load([exp_settings.stimdir filesep 'questionAccuracy.mat']); 
        exp_settings.QuizAccuracy = questionAccuracy.questionAccuracy;  % Quiz accuracy

%% Emotion stimuli
    % Timings
        exp_settings.timings.inductiontime = 10;            %[s] duration of the emotion induction screen (vignette)
        exp_settings.timings.fix_pre_induction = [1.5 2];   %[s] min, max time of the jittered fixation before induction
        exp_settings.timings.fix_post_induction = 2;        %[s] fixed fixation time after emotion induction screen
        exp_settings.timings.washout = 8;                   %[s] resting time after rating
    % Indices
        exp_settings.Emostimuli.i_happiness = 1;
        exp_settings.Emostimuli.i_sadness = 2;
        exp_settings.Emostimuli.i_neutral = 3;
    % Examples at the beginning of the experiment (for example vignettes, see below)
        exp_settings.Emostimuli.ExampleEmotions = [1 2 3 1 2 3]; %Cf. indices above
        exp_settings.Emostimuli.ExampleHappyMusic = 'Happy_ex';
        exp_settings.Emostimuli.ExampleSadMusic = 'Sad_ex';
    % Music (1-5)
        exp_settings.Emostimuli.HappyMusic = {'H�ndel - Arrival of the Queen';
            'JS Bach - Brandenburg Concerto 2';
            'Newman - Matilda writes her name';
            'Quantz - Flute Concerto';
            'Mozart - Piano sonata 16'};
        exp_settings.Emostimuli.SadMusic = {'Barber - Adagio for Strings';
            'Chopin - Nocturne no. 20';
            'JS Bach - Erbarme Dich';
            'Rheinberger - Suite';
            'Badelt - Blood Ritual'};
    % Vignettes (1-20)     
        exp_settings.Emostimuli.HappyVignettes_m = {'Tu t''inscris � une comp�tition sans trop y croire, mais tu finis � la premi�re place.';
    'Tu pars en vacances. � ton arriv�e l''endroit semble paradisiaque.�';
    'Tu ach�tes un ticket de loterie et gagnes imm�diatement 100 euros.';
    'C''est ton anniversaire et tes amis t''ont pr�par� une incroyable soir�e surprise.';
    'Tu viens de commencer un nouveau travail, et il s''av�re encore mieux que pr�vu.';
    'Tu passes une journ�e � la montagne, l''air est pur et frais, le ciel est ensoleill�, et tu te baignes dans un lac magnifique.';
    'Tu apprends qu''un ami, qui a �t� malade pendant tr�s longtemps, est maintenant parfaitement gu�ri.';
    '� la fin du semestre tu valides un cours avec la meilleure note.';
    'Ton chef te complimente sur la qualit� de ton travail et te dit que tu as beaucoup de talent.';
    'Tu sors de cours ou du boulot en avance. Le temps est superbe et tu vas prendre une glace avec des amis.';
    'Tu vas au restaurant avec un ami. Le repas, l''ambiance et la conversation sont absolument parfaits.';
    'Tout ton entourage est tr�s admiratif lorsque tu leur montres les r�sultats du projet sur lequel tu as investi beaucoup d''effort.';
    'Tu es en voiture et ta chanson pr�f�r�e passe � la radio.';
    'Tu rends visite � des cousins, et leur tout jeune enfant court vers toi tout excit� tellement il est heureux de te voir.';
    'Tu rencontres par hasard quelqu''un que tu appr�cies. Vous allez prendre un caf� et vous vous entendez tr�s bien. Tu d�couvres que vous pensez de la m�me mani�re et que vous vous int�ressez aux m�mes choses.';
    'Tu essaies une nouvelle recette et le r�sultat est fantastique. L''amie pour qui tu cuisinais est tr�s impressionn�e.';
    'En rentrant � la maison apr�s une longue marche dans le froid, tu te r�gales d''une boisson chaude au coin du feu.';
    'Tu d�couvres sur ton bureau un mot d''une de tes coll�gues te disant combien elle est heureuse de travailler avec toi.';
    'Tu joues � un quizz  avec des amis. Ton �quipe gagne parce que tu as trouv� �norm�ment de bonnes r�ponses.';
    'Tes parents ont achet� un chiot tr�s mignon qui ne se lasse jamais de jouer avec toi.'};
        exp_settings.Emostimuli.HappyVignettes_f = {'Tu t''inscris � une comp�tition sans trop y croire, mais tu finis � la premi�re place.';
    'Tu pars en vacances. � ton arriv�e l''endroit semble paradisiaque.�';
    'Tu ach�tes un ticket de loterie et gagnes imm�diatement 100 euros.';
    'C''est ton anniversaire et tes amis t''ont pr�par� une incroyable soir�e surprise.';
    'Tu viens de commencer un nouveau travail, et il s''av�re encore mieux que pr�vu.';
    'Tu passes une journ�e � la montagne, l''air est pur et frais, le ciel est ensoleill�, et tu te baignes dans un lac magnifique.';
    'Tu apprends qu''un ami, qui a �t� malade pendant tr�s longtemps, est maintenant parfaitement gu�ri.';
    '� la fin du semestre tu valides un cours avec la meilleure note.';
    'Ton chef te complimente sur la qualit� de ton travail et te dit que tu as beaucoup de talent.';
    'Tu sors de cours ou du boulot en avance. Le temps est superbe et tu vas prendre une glace avec des amis.';
    'Tu vas au restaurant avec un ami. Le repas, l''ambiance et la conversation sont absolument parfaits.';
    'Tout ton entourage est tr�s admiratif lorsque tu leur montres les r�sultats du projet sur lequel tu as investi beaucoup d''effort.';
    'Tu es en voiture et ta chanson pr�f�r�e passe � la radio.';
    'Tu rends visite � des cousins, et leur tout jeune enfant court vers toi tout excit� tellement il est heureux de te voir.';
    'Tu rencontres par hasard quelqu''un que tu appr�cies. Vous allez prendre un caf� et vous vous entendez tr�s bien. Tu d�couvres que vous pensez de la m�me mani�re et que vous vous int�ressez aux m�mes choses.';
    'Tu essaies une nouvelle recette et le r�sultat est fantastique. L''amie pour qui tu cuisinais est tr�s impressionn�e.';
    'En rentrant � la maison apr�s une longue marche dans le froid, tu te r�gales d''une boisson chaude au coin du feu.';
    'Tu d�couvres sur ton bureau un mot d''une de tes coll�gues te disant combien elle est heureuse de travailler avec toi.';
    'Tu joues � un quizz  avec des amis. Ton �quipe gagne parce que tu as trouv� �norm�ment de bonnes r�ponses.';
    'Tes parents ont achet� un chiot tr�s mignon qui ne se lasse jamais de jouer avec toi.'};
        exp_settings.Emostimuli.SadVignettes_m = {'Ton animal de compagnie que tu adorais vient de mourir.';
    'Tu apprends qu''un professeur de lyc�e que tu aimais beaucoup est d�sormais d�c�d�. ';
    'Tu rencontres un SDF dans la rue, et tu t''aper�ois que c''est un de tes amis d''enfance que tu avais perdu de vue.';
    'Une jeune personne de ta famille t''annonce qu''elle a un cancer.';
    'Tu viens de regarder un film racontant l''histoire d''un enfant en phase terminale d''une maladie, et qui finit par mourir.';
    'Ta voisine, une vieille dame auparavant tr�s gentille, est d�sormais atteinte de d�mence et n''est plus la personne que tu as connue.';
    'Un parent proche vient de se faire diagnostiquer une tumeur maligne et ne peut plus �tre soign� ni op�r�.';
    'Tu sortais avec quelqu''un et votre relation semblait plut�t prometteuse, quand cette personne t''appelle pour te dire qu''elle ne souhaite plus te voir.';
    'Alors que tu te prom�nes dans un parc, un vieux chien affectueux vient � ta rencontre. Son propri�taire te dit qu''il a une tumeur et souffre beaucoup.';
    'En voyant quelqu''un jouer avec son animal de compagnie, tu repenses � ton vieux compagnon pr�f�r� qui lui ressemblait mais qui est mort il y a quelque temps.';
    'Tu h�sites � appeler un ami dont tu �tais proche, mais tu r�alises que cette amiti� n''est plus vraiment ce qu''elle �tait.';
    'Un ami proche t''avoue qu''il est alcoolique, et la situation semble si d�sesp�r�e qu''il n''y a rien que tu puisses faire pour l''aider.';
    'Tu t''attaches � une personne rencontr�e r�cemment, mais elle d�m�nage � l''�tranger et vous perdez contact.';
    'Tu rends visite � une connaissance dans une maison de retraite. Elle t''apprend que sa famille ne vient jamais la voir.';
    'Ton travail est tr�s monotone, mais tu r�alises que tu n''as pas vraiment les comp�tences n�cessaires pour avoir un m�tier plus int�ressant.';
    'Ton coll�gue pr�f�r� d�cide de quitter ton lieu de travail.';
    'Tu es seul chez toi un vendredi soir par une tr�s belle nuit. Tu te sens abandonn� par tes amis.';
    'En te promenant dans la ville, tu passes devant un monument aux morts. Tu penses � tous ces jeunes hommes et femmes qui ont perdu la vie.';
    'Un membre de ta famille dont tu es tr�s proche t''annonce qu''il part s''installer d�finitivement en Australie.';
    'Aujourd''hui c''�tait ton anniversaire. Personne au travail ou � l''universit� ne l''a remarqu�.'};
        exp_settings.Emostimuli.SadVignettes_f = {'Ton animal de compagnie que tu adorais vient de mourir.';
    'Tu apprends qu''un professeur de lyc�e que tu aimais beaucoup est d�sormais d�c�d�.';
    'Tu rencontres un SDF dans la rue, et tu t''aper�ois que c''est un de tes amis d''enfance que tu avais perdu de vue.';
    'Une jeune personne de ta famille t''annonce qu''elle a un cancer.';
    'Tu viens de regarder un film racontant l''histoire d''un enfant en phase terminale d''une maladie, et qui finit par mourir.';
    'Ta voisine, une vieille dame auparavant tr�s gentille, est d�sormais atteinte de d�mence et n''est plus la personne que tu as connue.';
    'Un parent proche vient de se faire diagnostiquer une tumeur maligne et ne peut plus �tre soign� ni op�r�.';
    'Tu sortais avec quelqu''un et votre relation semblait plut�t prometteuse, quand cette personne t''appelle pour te dire qu''elle ne souhaite plus te voir.';
    'Alors que tu te prom�nes dans un parc, un vieux chien affectueux vient � ta rencontre. Son propri�taire te dit qu''il a une tumeur et souffre beaucoup.';
    'En voyant quelqu''un jouer avec son animal de compagnie, tu repenses � ton vieux compagnon pr�f�r� qui lui ressemblait mais qui est mort il y a quelque temps.';
    'Tu h�sites � appeler un ami dont tu �tais proche, mais tu r�alises que cette amiti� n''est plus vraiment ce qu''elle �tait.';
    'Un ami proche t''avoue qu''il est alcoolique, et la situation semble si d�sesp�r�e qu''il n''y a rien que tu puisses faire pour l''aider.';
    'Tu t''attaches � une personne rencontr�e r�cemment, mais elle d�m�nage � l''�tranger et vous perdez contact.';
    'Tu rends visite � une connaissance dans une maison de retraite. Elle t''apprend que sa famille ne vient jamais la voir.';
    'Ton travail est tr�s monotone, mais tu r�alises que tu n''as pas vraiment les comp�tences n�cessaires pour avoir un m�tier plus int�ressant.';
    'Ton coll�gue pr�f�r� d�cide de quitter ton lieu de travail.';
    'Tu es seule chez toi un vendredi soir par une tr�s belle nuit. Tu te sens abandonn�e par tes amis.';
    'En te promenant dans la ville, tu passes devant un monument aux morts. Tu penses � tous ces jeunes hommes et femmes qui ont perdu la vie.';
    'Un membre de ta famille dont tu es tr�s proche t''annonce qu''il part s''installer d�finitivement en Australie.';
    'Aujourd''hui c''�tait ton anniversaire. Personne au travail ou � l''universit� ne l''a remarqu�.'};
        exp_settings.Emostimuli.NeutralVignettes = {'Les bouleaux font partie de la famille des b�tulac�es et du genre Betula.';
    'Le roman est un genre litt�raire, caract�ris� essentiellement par une narration fictionnelle.';
    'Le nom de Bernicie semble d�river du gallois Brynaich ou Bryneich. Il est possible qu''avant l''arriv�e des Anglo-Saxons, un royaume breton portant ce nom ait occup� la r�gion.';
    'Les argiles d�signent de tr�s fines particules de mati�re arrach�es aux roches par l''�rosion ainsi que les min�raux argileux ou phyllosilicates.';
    'Une classe marchande se d�veloppe dans la premi�re moiti� du VIIe si�cle av. J.-C. comme le d�montrent l''apparition de monnaies grecques vers -680.';
    'Le taux de natalit� est le rapport entre le nombre annuel de naissances et la population totale moyenne sur cette ann�e.';
    'Gilles Deleuze se r�clame de Stirner lorsqu''il critique l''alternative traditionnelle entre le th�ocentrisme et l''anthropocentrisme.';
    'Il existe quatre niveaux d''administration dans l''�glise de J�sus-Christ des Saints des Derniers Jours.';
    'L''�criture chinoise est une transcription de la langue chinoise, et des mots qui la composent, mais elle n''est pas pour autant phon�tique.';
    'Les sportifs ouzbeks sont tr�s pr�sents dans les sports de combats comme le judo, la boxe, l''unifight ou encore la lutte gr�co-romaine.';
    'L''�thique t�l�ologique met l''accent sur les buts et les finalit�s d''une d�cision.';
    'La Communaut� �conomique des �tats de l''Afrique de l''Ouest (C�D�AO) est une organisation intergouvernementale ouest-africaine cr��e le 28 mai 1975. ';
    'En 1900 l''invention de Linn� est red�couverte. Au XXe si�cle, les Japonais d�veloppent alors la culture perli�re et en am�liorent les techniques.';
    'La facult� de m�decine d''Harvard est la troisi�me plus ancienne aux �tats-Unis, fond�e le 19 septembre 1782 par John Warren, Benjamin Waterhouse, et Aaron Dexter.';
    'Les seuls faits authentiquement connus sur H�siode sont les �v�nements consign�s dans ses po�mes.';
    'Les cr�atifs s''interrogent sur le comportement des consommateurs, la modification de leurs styles de vie.';
    'Max Havelaar est inscrit comme repr�sentant d''int�r�ts aupr�s de l''Assembl�e nationale.';
    'Au-del� du go�t prononc� de Roald Dahl pour les histoires touchant de pr�s ou de loin � la fornication pr�sente dans tous ses �crits pour adultes, Mon oncle Oswald brille surtout par son humour ravageur et le charisme de son personnage';
    'Le tao�sme est une qu�te individuelle de la Panac�e, la recette qui rendra immortel.';
    'Le fixisme est une hypoth�se selon laquelle il n''y a ni transformation ni d�rive des esp�ces v�g�tales ou animales, mais aussi aucune modification profonde de l''Univers.'};
        exp_settings.Emostimuli.ExampleVignettes_m = {'Apr�s plusieurs jours froids et pluvieux, tu d�couvres au r�veil un magnifique ciel bleu et ensoleill� pour commencer le weekend.';
    'Ton meilleur ami vient de se marier et t''annonce qu''il va d�m�nager � l''�tranger.';
    'Peu apr�s le championnat de Tripoli, la FIDE lance un appel d''offres pour l''organisation du match entre Kasparov et Qosimjonov, mais aucun sponsor n''y r�pond. En mars 2005, Kasparov annonce qu''il abandonne la comp�tition de haut niveau.';
    'Au bistrot le serveur est emball� de te reconnaitre et t''offre un caf� gratuit.';
    'Une coll�gue ou une camarade dit qu''elle ne veut pas travailler avec toi dans un travail de groupe parce qu''elle te trouve �go�ste et arrogant.';
    'D�s les ann�es 1950, l''US Navy a mis en oeuvre les premiers avions de type AWACS �quip�s d''un puissant radar install� sur le dos de l''appareil.'};
        exp_settings.Emostimuli.ExampleVignettes_f = {'Apr�s plusieurs jours froids et pluvieux, tu d�couvres au r�veil un magnifique ciel bleu et ensoleill� pour commencer le weekend.';
    'Ton meilleur ami vient de se marier et t''annonce qu''il va d�m�nager � l''�tranger.';
    'Peu apr�s le championnat de Tripoli, la FIDE lance un appel d''offres pour l''organisation du match entre Kasparov et Qosimjonov, mais aucun sponsor n''y r�pond. En mars 2005, Kasparov annonce qu''il abandonne la comp�tition de haut niveau.';
    'Au bistrot le serveur est emball� de te reconnaitre et t''offre un caf� gratuit.';
    'Une coll�gue ou une camarade dit qu''elle ne veut pas travailler avec toi dans un travail de groupe parce qu''elle te trouve �go�ste et arrogante.';
    'D�s les ann�es 1950, l''US Navy a mis en oeuvre les premiers avions de type AWACS �quip�s d''un puissant radar install� sur le dos de l''appareil.'};        

