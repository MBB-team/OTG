function [exp_settings] = BEC_Settings
% Settings structure for the Battery of Economic CHoices And Mood/Emotion Links experiments
% The settings that can be altered here are mostly general-purpose settings that have no impact on performance when
% altered. For more detailed settings of certain functions (e.g. BEC_RateEmotion), see these functions directly.
% The notable exception to this is that all settings related to decision-making (the appearance of the choice screen,
% the features of the choice trials being generated, and the settings of the online trial generation procedure, are set
% here.

%% Setup
    rng('shuffle')              %Shuffle the random number generator
    exp_settings = struct;      %Predefine output
    expdir = fileparts(mfilename('fullpath'));  %Get the directory where this function is stored
    cd(expdir);                 %Change directory to the directory where this function is situated
% Keyboard settings
    %General:
        % ESCAPE is the key to terminate the experiment. This key can be used at various points throughout the
        % experiment and cannot be changed here. Same is the case for the keys used in decision-making: left and right
        % arrow keys by default. For browsing trough instuction slides, the arrow keys are used as well, or the space
        % bar.
    %Mood quiz answer keys:
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
        exp_settings.font.FixationFontSize = 40;    %Fixation cross between trials is written as a "+" (note: this is not the fixation cross in a choice trial)
        exp_settings.font.TitleFontSize = 32;       %Screen titles
        exp_settings.font.RewardFontSize = 35;      %Reward amounts in the choice screen
        exp_settings.font.CostFontSize = exp_settings.font.RewardFontSize; %Idem for the cost amounts
        exp_settings.font.EmoFontSize = 36;         %Emotion induction text
        exp_settings.font.QuestionFontSize = 18;    %Quiz question text
        exp_settings.font.AnswerFontSize = 18;      %Quiz answers
        exp_settings.font.FeedbackFontSize = 32;    %Quiz feedback screen
        exp_settings.font.RatingFontSize = 36;      %Rating screen font size (note: this is the base font size, two other font sizes are used in this function => see settings there)
        exp_settings.font.FontType = 'Arial';       %Font type (universal)
        exp_settings.font.Wrapat = 75;              %Wrapping (for longer texts of induction screens)
        exp_settings.font.vSpacing = 2;             %Vertical spacing (universal)
    %Colors 
        %Define colors
            exp_settings.colors.black = [0 0 0];
            exp_settings.colors.white = [255 255 255];
            exp_settings.colors.grey = [128 128 128];
            exp_settings.colors.green = [59 199 118]; %update 2022
            exp_settings.colors.orange = [0.8500, 0.3250, 0.0980].*255; 
            exp_settings.colors.red = [218 37 37]; %update 2022
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
    %Tactile screen
        exp_settings.tactile.escapeCross_ySize = 1/20; %Size relative to screen height
        exp_settings.tactile.escapeCrossFontSize = 25; %Size of the "X" to click in order to exit the screen
        exp_settings.tactile.navigationArrows = false; %Flag if you want to display the navigation arrows and make them active for navigation (default: false)
        exp_settings.tactile.navigationArrows_ySize = 1/10; %Size relative to screen height    
        exp_settings.tactile.im_leftkey = imread([exp_settings.stimdir filesep 'leftkey.png']); %Left key image loaded
        exp_settings.tactile.im_rightkey = imread([exp_settings.stimdir filesep 'rightkey.png']); %Right key image loaded
        exp_settings.tactile.QuitScreenFontSize = 32;
        exp_settings.tactile.PatientIDFontSize = 40;            
            
%% Choice screen configuration
    % Cost and reward features
        exp_settings.MaxReward = 30;  % [euros] reward for the costly option
        exp_settings.RiskLoss = 10;   % [euros] possible loss in the lottery
        exp_settings.MaxDelay = 12;   % [months] maximum delay
        exp_settings.MaxRisk = 100;   % [percent] maximum risk
        exp_settings.Max_phys_effort = 12; % max # flights of stairs to climb
        exp_settings.Max_ment_effort = 12; % max # pages to copy
    % Timings
        exp_settings.timings.min_resp_time = 1; %[s] before ppt can respond
        exp_settings.timings.max_resp_time = Inf; %[s] timeout time, set Inf if there is no timeout. When timeout is reached, the choice and RT will be set to NaN.
        exp_settings.timings.show_response = 0.25; %[s] visual feedback duration in example choice trials
        exp_settings.timings.fixation_choice = [0.75 1.25]; %[s] minimum and maximum jittered fixation time during experiment
    % Choice screen visual parameters
        exp_settings.choicescreen.title_y = 1/8;                        %Title y position (choice)
        exp_settings.choicescreen.cost_y = [2/8 3/8];                   %Y-coordinates of the cost above the cost box (example trials only)
        exp_settings.choicescreen.reward_y_example = [12/16 14/16];     %Y-coordinates of the reward below the cost box (example trials only)
        exp_settings.choicescreen.reward_y = [10/16 12/16];              %Y-coordinates of the reward below the cost box
        exp_settings.choicescreen.costbox_left_example = [3/16 2/5 6/16 3/4];      %Left cost visualization
        exp_settings.choicescreen.costbox_right_example = [10/16 2/5 13/16 3/4];   %Right cost visualization
        exp_settings.choicescreen.costbox_left = [3/16 1/5 6.5/16 6/10];   %Left cost visualization
        exp_settings.choicescreen.costbox_right = [9.5/16 1/5 13/16 6/10];%Right cost visualization
        exp_settings.choicescreen.arrowbuttons_y = 15/16; %Vertical position of the arrow key images in the example choice screen
        exp_settings.choicescreen.flightsteps = 18; %Physical effort visualization: 1 flight of stairs = 18 steps
        exp_settings.choicescreen.pagelines = 25;   %Mental effort visualization: one page of text is contains 25 lines
        exp_settings.choicescreen.linewidth = 1;    %Width of the lines of the cost drawings
        exp_settings.choicescreen.linecolor = exp_settings.colors.white;%Color of the lines of the cost drawings
        exp_settings.choicescreen.fillcolor = exp_settings.colors.red;  %Color of the costs
        exp_settings.choicescreen.probabilitycolor = exp_settings.colors.green;     %Color of the risk arc representing probability to win
        exp_settings.choicescreen.confirmcolor = exp_settings.colors.white;         %Color of the confirmation rectangle around the chosen option
    
%% Choice trial generation settings
    % Choice triallist creation settings       
        exp_settings.trialgen_choice.which_choicetypes = 1:4;     %which choice types to include (1:delay/2:risk/3:physical effort/4:mental effort)
        exp_settings.trialgen_choice.n_choicetypes = length(exp_settings.trialgen_choice.which_choicetypes); %amount of choice types
        exp_settings.trialgen_choice.typenames = {'delay','risk','physical_effort','mental_effort'};
    % Example choice trials 
        exp_settings.exampletrials = [...
            [0 2 3 5 6 8 7.5 9 10 12 13 14.75]./15; %Rewards for the uncostly option
            [0.7 0.5 0.8 0.3 0.6 0.1 0.9 0.4 0.7 0.2 0.5 0.3]]; %Corresponding costs for the costly option 
    % Online trial generation
        %Choice types
            exp_settings.OTG.choicetypes = exp_settings.trialgen_choice.which_choicetypes;
            exp_settings.OTG.typenames = exp_settings.trialgen_choice.typenames;
        %Sampling grid
            exp_settings.OTG.grid.nbins = 5;             % # bins (current default is 5 -- please do not change)
            exp_settings.OTG.grid.bincostlevels = 10;    % # cost levels per bin  
            exp_settings.OTG.grid.binrewardlevels = 50;  % # reward levels (= 2*exp_settings.MaxReward so that the step size is 0.50 euros)
            exp_settings.OTG.grid.costlimits = [0 1];    % [min max] cost (note: bin 1's first value is nonzero)
            exp_settings.OTG.grid.rewardlimits = [0.1/30 29.9/30]; % [min max] reward for uncostly option
            exp_settings.OTG.grid.binlimits = exp_settings.OTG.grid.costlimits(1) + ([0:exp_settings.OTG.grid.nbins-1;1:exp_settings.OTG.grid.nbins])'  * (exp_settings.OTG.grid.costlimits(2)-exp_settings.OTG.grid.costlimits(1))/exp_settings.OTG.grid.nbins; % Upper limit and lower limit of each cost bin
            exp_settings.OTG.grid.gridY = exp_settings.OTG.grid.rewardlimits(1):(exp_settings.OTG.grid.rewardlimits(2)-exp_settings.OTG.grid.rewardlimits(1))/(exp_settings.OTG.grid.binrewardlevels-1):exp_settings.OTG.grid.rewardlimits(2);  % Uncostly option rewards for the indifference grid
            exp_settings.OTG.grid.gridX = exp_settings.OTG.grid.costlimits(1):(exp_settings.OTG.grid.costlimits(2)-exp_settings.OTG.grid.costlimits(1))/(exp_settings.OTG.grid.bincostlevels*exp_settings.OTG.grid.nbins):exp_settings.OTG.grid.costlimits(2);   % Cost amounts for sampling grid
        %Parameter settings
            exp_settings.OTG.fixed_beta = 5;       % Assume this fixed value for the inverse choice temperature (based on past results) to improve model fit.
            exp_settings.OTG.priorvar = 2*eye(exp_settings.OTG.grid.nbins+1);   % Prior variance for each parameter
        %Calibration settings
            exp_settings.OTG.prior_bias_cal = -3;   % Note: this is log(prior) [used in calibration only]
            exp_settings.OTG.prior_var_cal = 2;     % Note: applies to all parameters [used in calibration only]
            exp_settings.OTG.ntrials_cal = 60;      %Number of trials per choice type in the calibration
            exp_settings.OTG.burntrials_cal = [59/60  0     55/60  2/30;  %Present these "burn trials" at the beginning of the calibration, for the participant (and the algorithm) to start with some 'easy' choices that are rather extreme.
                                               46/50  5/50  1      1/50]; %(Note that presenting these burn trials is optional)
        %Algorithm settings
            exp_settings.OTG.max_n_inv = 20;        % Max. # of trials entered in model inversion algorithm
            exp_settings.OTG.max_iter = 200;        % [G-N] Max. # of iterations, after which we conclude the algorithm does not converge
            exp_settings.OTG.conv_crit = 1e-2;      % [G-N] Max. # of iterations for the model inversion algorithm, after which it is forced to stop
            exp_settings.OTG.burntrials = 3;        % [G-N] # of trials that must have been sampled before inverting the model
            exp_settings.OTG.adjust_rew_nonconverge = [0.2 0.4 0.6 0.8 1]; % [G-N] Adjustment to the indifference reward: helps the algorithm get out when it is stuck on a wrong indifference estimate
        %VBA: Dimensions
            exp_settings.OTG.dim.n_theta = 0;   % Number of evolution parameters
            exp_settings.OTG.dim.n = 0;         % Number of hidden states
            exp_settings.OTG.dim.p = 1;         % Output data dimension (# of observations per time sample)
            exp_settings.OTG.dim.n_phi = 6;     % Number of observation parameters: 1 intercept (bias) and a slope for each bin
        %VBA: Options
            exp_settings.OTG.options.sources.type = 1;  % Type 1 for binomial distribution
            exp_settings.OTG.options.verbose = 0;       % Flag 1 to show VBA's inversion process text updates
            exp_settings.OTG.options.DisplayWin = 0;    % Flag 1 to show VBA's inversion process visualized    
            exp_settings.OTG.options.inG.ind.bias = 1;  % Choice bias, or the intercept of the indifference curve in the first bin (parameter #1)
            exp_settings.OTG.options.inG.ind.k1 = 2;    % Slope of bin 1 (parameter #2)
            exp_settings.OTG.options.inG.ind.k2 = 3;    % Slope of bin 2 (parameter #3)
            exp_settings.OTG.options.inG.ind.k3 = 4;    % Slope of bin 3 (parameter #4)    
            exp_settings.OTG.options.inG.ind.k4 = 5;    % Slope of bin 4 (parameter #5)
            exp_settings.OTG.options.inG.ind.k5 = 6;    % Slope of bin 5 (parameter #6)
            exp_settings.OTG.options.inG.beta = exp_settings.OTG.fixed_beta; %Inv. choice temp. for observation function (takes an assumed fixed value)
            exp_settings.OTG.options.inG.grid = exp_settings.OTG.grid; %Grid is entered in observation function too
    
%% Trial generation settings for emotions or moods studies
    % Trial generation settings: emotions experiment
        exp_settings.trialgen_emotions.emotionnames = {'Happy','Sad','Neutral'};
        exp_settings.trialgen_emotions.n_inductions = 30;   %total number of inductions
        exp_settings.trialgen_emotions.i_break = 31;        %break at the beginning of this trial
        exp_settings.trialgen_emotions.n_emotions = 3;      %number of different emotions
        exp_settings.trialgen_emotions.n_music_stim = 6;    %number of different music stimuli
        exp_settings.trialgen_emotions.i_music_emo = 1:2;   %indices of emotions that have music (happiness and sadness)
        exp_settings.trialgen_emotions.i_neutral = 3;       %index of the neutral condition
        exp_settings.trialgen_emotions.inductions_per_emo = 15; %number of inductions per emotion condition
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
        
%% Rating screen settings
% Note: the rating labels are entered twice, with m/f declinations if applicable
    %Emotions
        exp_settings.ratings.emotions.Ratingquestion = 'Dans quelle mesure avez-vous ressenti chacune des émotions ci-dessous?';
        exp_settings.ratings.emotions.Rating_label_min = {'Pas du tout','Pas du tout'};
        exp_settings.ratings.emotions.Rating_label_max = {'Au maximum','Au maximum'};
        exp_settings.ratings.emotions.Ratingdimensions = {'Joie','Tristesse','Curiosité'};
        exp_settings.ratings.emotions.Rating_quantity_min = '0';
        exp_settings.ratings.emotions.Rating_quantity_max = '10';
    %Mood - generic
        exp_settings.ratings.mood.Ratingquestion = 'Comment je me sens?';
        exp_settings.ratings.mood.Rating_label_min = {'de mauvaise humeur','de mauvaise humeur'};
        exp_settings.ratings.mood.Rating_label_max = {'de bonne humeur','de bonne humeur'};
    %Fatigue
        exp_settings.ratings.fatigue.Ratingquestion = 'Comment vous sentez-vous?';
        exp_settings.ratings.fatigue.Rating_label_min = {'très fatigué','très fatiguée'};
        exp_settings.ratings.fatigue.Rating_label_max = {'plein d''énergie','pleine d''énergie'};
    %Stess
        exp_settings.ratings.stress.Ratingquestion = 'Comment vous sentez-vous?';
        exp_settings.ratings.stress.Rating_label_min = {'stressé','stressée'};
        exp_settings.ratings.stress.Rating_label_max = {'détendu','détendue'};
    %Happiness
        exp_settings.ratings.happiness.Ratingquestion = 'Comment vous sentez-vous?';
        exp_settings.ratings.happiness.Rating_label_min = {'triste','triste'};
        exp_settings.ratings.happiness.Rating_label_max = {'heureux','heureuse'};
    %Pain
        exp_settings.ratings.pain.Ratingquestion = 'Comment vous sentez-vous?';
        exp_settings.ratings.pain.Rating_label_min = {'douleur maximale','douleur maximale'};
        exp_settings.ratings.pain.Rating_label_max = {'aucune douleur','aucune douleur'};
    
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
        try
            QR = load([exp_settings.stimdir filesep 'QR_fMRI.mat'], 'QR'); 
            exp_settings.QuizQuestions = QR.QR; 
            listTrainingQuizz = load([exp_settings.stimdir filesep 'listTrainingQuizz.mat']); 
            exp_settings.QuizTraining = listTrainingQuizz.listTrainingQuizz;
            questionAccuracy = load([exp_settings.stimdir filesep 'questionAccuracy.mat']); 
            exp_settings.QuizAccuracy = questionAccuracy.questionAccuracy;  % Quiz accuracy
        catch
            %The quiz stimuli are not present in the Stimuli directory - probably because you don't need it
        end
    % Instruction slides
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

%% Emotion stimuli
    % Timings
        exp_settings.timings.inductiontime = 10;            %[s] duration of the emotion induction screen (vignette)
        exp_settings.timings.fix_pre_induction = [1 1];   %[s] min, max time of the jittered fixation before induction
        exp_settings.timings.fix_post_induction = 1;        %[s] fixed fixation time after emotion induction screen
        exp_settings.timings.washout = 7;                   %[s] resting time after rating
    % Indices
        exp_settings.Emostimuli.i_happiness = 1;
        exp_settings.Emostimuli.i_sadness = 2;
        exp_settings.Emostimuli.i_neutral = 3;
    % Examples at the beginning of the experiment (for example vignettes, see below)
        exp_settings.Emostimuli.ExampleEmotions = [1 2 1 2 3 3 1 2 3 1 2 3 1 2]; %Cf. indices above
        exp_settings.Emostimuli.ExampleMusic = [7 7 8 8 NaN NaN 7 7 NaN 8 8 NaN 7 7]; %Music piece number, i.e. 'Happy_07/8' e.g.
    % Music (1-6)
        exp_settings.Emostimuli.HappyMusic = {'Händel - Arrival of the Queen';
            'JS Bach - Brandenburg Concerto 2';
            'Newman - Matilda writes her name';
            'Quantz - Flute Concerto';
            'Mozart - Piano sonata 16';
            'Hooper - Dumbledore''s Army'};
        exp_settings.Emostimuli.SadMusic = {'Barber - Adagio for Strings';
            'Chopin - Nocturne no. 20';
            'JS Bach - Erbarme Dich';
            'Rheinberger - Suite';
            'Badelt - Blood Ritual';
            'Hilmarsson - The Black Dog and the Scottish Play'};
    % Instruction slides (example)
        exp_settings.instructions_emotions.emotion_instructions = 1;
        exp_settings.instructions_emotions.neutral_instructions = 2;
        exp_settings.instructions_emotions.another_example = 3;
        exp_settings.instructions_emotions.choice_instructions = 4;
        exp_settings.instructions_emotions.delay_instructions = 5;
        exp_settings.instructions_emotions.risk_instructions = 6;
        exp_settings.instructions_emotions.effort_instructions = 7;
        exp_settings.instructions_emotions.start_main_experiment = 8;
        exp_settings.instructions_emotions.end_of_experiment = 9;
    % Vignettes (1-12)     
        exp_settings.Emostimuli.HappyVignettes_m = {'Tu t''inscris à une compétition sans trop y croire, mais tu finis à la première place.';
    'Tu pars en vacances. À ton arrivée l''endroit semble paradisiaque. ';
    'Tu achètes un ticket de loterie et gagnes immédiatement 100 euros.';
    'C''est ton anniversaire et tes amis t''ont préparé une incroyable soirée surprise.';
    'Tu viens de commencer un nouveau travail, et il s''avère encore mieux que prévu.';
    'Tu apprends qu''un ami, qui a été malade pendant très longtemps, est maintenant parfaitement guéri.';
    'Tu vas au restaurant avec un ami. Le repas, l''ambiance et la conversation sont absolument parfaits.';
    'Tout ton entourage est très admiratif lorsque tu leur montres les résultats du projet sur lequel tu as investi beaucoup d''effort.';
    'Tu es en voiture et ta chanson préférée passe à la radio.';
    'Tu rends visite à des cousins, et leur tout jeune enfant court vers toi tout excité tellement il est heureux de te voir.';
    'Tu essaies une nouvelle recette et le résultat est fantastique. Les proches pour qui tu cuisinais sont très impressionnés.';
    'En rentrant à la maison après une longue marche dans le froid, tu te régales d''une boisson chaude au coin du feu.'};
        exp_settings.Emostimuli.HappyVignettes_f = {'Tu t''inscris à une compétition sans trop y croire, mais tu finis à la première place.';
    'Tu pars en vacances. À ton arrivée l''endroit semble paradisiaque. ';
    'Tu achètes un ticket de loterie et gagnes immédiatement 100 euros.';
    'C''est ton anniversaire et tes amis t''ont préparé une incroyable soirée surprise.';
    'Tu viens de commencer un nouveau travail, et il s''avère encore mieux que prévu.';
    'Tu apprends qu''un ami, qui a été malade pendant très longtemps, est maintenant parfaitement guéri.';
    'Tu vas au restaurant avec un ami. Le repas, l''ambiance et la conversation sont absolument parfaits.';
    'Tout ton entourage est très admiratif lorsque tu leur montres les résultats du projet sur lequel tu as investi beaucoup d''effort.';
    'Tu es en voiture et ta chanson préférée passe à la radio.';
    'Tu rends visite à des cousins, et leur tout jeune enfant court vers toi tout excité tellement il est heureux de te voir.';
    'Tu essaies une nouvelle recette et le résultat est fantastique. Les proches pour qui tu cuisinais sont très impressionnés.';
    'En rentrant à la maison après une longue marche dans le froid, tu te régales d''une boisson chaude au coin du feu.'};
        exp_settings.Emostimuli.SadVignettes_m = {'Ton animal de compagnie que tu adorais vient de mourir.';
    'Tu as prévu de partir en vacances mais tous les transports sont bloqués et tu dois rester chez toi.';
    'Tu rencontres un SDF dans la rue, et tu t''aperçois que c''est un de tes amis d''enfance que tu avais perdu de vue.';
    'Tu sortais avec quelqu''un et votre relation semblait plutôt prometteuse, quand cette personne t''appelle pour te dire qu''elle ne souhaite plus te voir.';
    'Tu hésites à appeler un ami dont tu étais proche, mais tu réalises que cette amitié n''est plus vraiment ce qu''elle était.';
    'Tu t''attaches à une personne rencontrée récemment, mais elle déménage à l''étranger et vous perdez contact.';
    'Tu rends visite à une connaissance dans une maison de retraite. Elle t''apprend que sa famille ne vient jamais la voir.';
    'Ton travail est très monotone, mais tu réalises que tu n''as pas vraiment les compétences nécessaires pour avoir un métier plus intéressant.';
    'Tu es seul chez toi un vendredi soir par une très belle nuit. Tu te sens abandonné par tes amis.';
    'En te promenant dans la ville, tu passes devant un monument aux morts. Tu penses à tous ces jeunes hommes et femmes qui ont perdu la vie.';
    'Le temps a été mauvais toute la semaine et il n''y a aucun signe d''amélioration.';
    'Un enfant que tu aimes t''avoue se faire maltraiter par les autres à l''école.'};
        exp_settings.Emostimuli.SadVignettes_f = {'Ton animal de compagnie que tu adorais vient de mourir.';
    'Tu as prévu de partir en vacances mais tous les transports sont bloqués et tu dois rester chez toi.';
    'Tu rencontres un SDF dans la rue, et tu t''aperçois que c''est un de tes amis d''enfance que tu avais perdu de vue.';
    'Tu sortais avec quelqu''un et votre relation semblait plutôt prometteuse, quand cette personne t''appelle pour te dire qu''elle ne souhaite plus te voir.';
    'Tu hésites à appeler un ami dont tu étais proche, mais tu réalises que cette amitié n''est plus vraiment ce qu''elle était.';
    'Tu t''attaches à une personne rencontrée récemment, mais elle déménage à l''étranger et vous perdez contact.';
    'Tu rends visite à une connaissance dans une maison de retraite. Elle t''apprend que sa famille ne vient jamais la voir.';
    'Ton travail est très monotone, mais tu réalises que tu n''as pas vraiment les compétences nécessaires pour avoir un métier plus intéressant.';
    'Tu es seule chez toi un vendredi soir par une très belle nuit. Tu te sens abandonnée par tes amis.';
    'En te promenant dans la ville, tu passes devant un monument aux morts. Tu penses à tous ces jeunes hommes et femmes qui ont perdu la vie.';
    'Le temps a été mauvais toute la semaine et il n''y a aucun signe d''amélioration.';
    'Un enfant que tu aimes t''avoue se faire maltraiter par les autres à l''école.'};
        exp_settings.Emostimuli.NeutralVignettes = {'L''Alouette à queue blanche est un oiseau d''Afrique qui mesure 13 cm pour une masse de 20 à 25 g.';
    'La Lituanie est un pays d''Europe du Nord situé sur la rive orientale de la mer Baltique.';
    'Un atome est la plus petite partie d''un corps simple pouvant se combiner chimiquement avec un autre.';
    'Roald Dahl est un écrivain britannique, auteur de romans et de nouvelles, qui s''adressent aussi bien aux enfants qu''aux adultes.';
    'En dehors de l''orchestre, le piano et l''orgue sont les seuls instruments solistes pour lesquels des compositeurs ont écrit des symphonies.';
    'En 2021, le RER d''Île-de-France est composé de cinq lignes et dessert au total 257 points d''arrêt dont 33 à Paris.'};
        exp_settings.Emostimuli.ExampleVignettes_m = {'Après plusieurs jours froids et pluvieux, tu découvres au réveil un magnifique ciel bleu et ensoleillé pour commencer le weekend.';
    'Ton meilleur ami vient de se marier et t''annonce qu''il va déménager à l''étranger.';
    'Au bistrot le serveur est emballé de te reconnaitre et t''offre un café gratuit.';
    'Une collègue ou une camarade dit qu''elle ne veut pas travailler avec toi dans un travail de groupe parce qu''elle te trouve égoïste et arrogant.';
    'À l''origine un peuple nomade, les Aztèques se sont installés dans la vallée de Mexico en 1345.';
    'Le calendrier grégorien, qui compte 365 jours (et un quart), est le calendrier actuellement utilisé par la grande majorité des pays dans le monde.'
    'Tu découvres sur ton bureau un mot d''une de tes collègues te disant combien elle est heureuse de travailler avec toi.';
    'Tu apprends qu''un professeur de lycée que tu aimais beaucoup est désormais décédé.';
    'Le mur de Berlin a été érigé dans la nuit du 12 au 13 août 1961.';
    'Tu joues à un quizz avec des amis. Ton équipe gagne parce que tu as trouvé énormément de bonnes réponses.';
    'Aujourd''hui c''était ton anniversaire. Personne au travail ne l''a remarqué.';
    'Gertrude Stein passa la majeure partie de sa vie en France et fut un catalyseur pour la littérature et l''art moderne.' 
    'Tes parents ont acheté un chiot très mignon qui ne se lasse jamais de jouer avec toi.';
    'Tu achètes des billets de loto mais ils se révèlent tous perdants et tu réalises que tu as perdu ton argent.';};
        exp_settings.Emostimuli.ExampleVignettes_f = {'Après plusieurs jours froids et pluvieux, tu découvres au réveil un magnifique ciel bleu et ensoleillé pour commencer le weekend.';
    'Ton meilleur ami vient de se marier et t''annonce qu''il va déménager à l''étranger.';
    'Au bistrot le serveur est emballé de te reconnaitre et t''offre un café gratuit.';
    'Une collègue ou une camarade dit qu''elle ne veut pas travailler avec toi dans un travail de groupe parce qu''elle te trouve égoïste et arrogante.';
    'À l''origine un peuple nomade, les Aztèques se sont installés dans la vallée de Mexico en 1345.';
    'Le calendrier grégorien, qui compte 365 jours (et un quart), est le calendrier actuellement utilisé par la grande majorité des pays dans le monde.';
    'Tu découvres sur ton bureau un mot d''une de tes collègues te disant combien elle est heureuse de travailler avec toi.';
    'Tu apprends qu''un professeur de lycée que tu aimais beaucoup est désormais décédé.';
    'Le mur de Berlin a été érigé dans la nuit du 12 au 13 août 1961.';
    'Tu joues à un quizz avec des amis. Ton équipe gagne parce que tu as trouvé énormément de bonnes réponses.';
    'Aujourd''hui c''était ton anniversaire. Personne au travail ne l''a remarqué.';
    'Gertrude Stein passa la majeure partie de sa vie en France et fut un catalyseur pour la littérature et l''art moderne.' 
    'Tes parents ont acheté un chiot très mignon qui ne se lasse jamais de jouer avec toi.';
    'Tu achètes des billets de loto mais ils se révèlent tous perdants et tu réalises que tu as perdu ton argent.';};
