% This function is part of the OTG toolbox, used for generating and presenting a battery of economic choices.
% It generates the settings structure for OTG-based experiments. It spans settings that are directly relevant to the 
% online trial generation algorithm, but also e.g. the visual appearance of choice and rating windows.

function [exp_settings] = BEC_Settings

%% Setup
    rng('shuffle')              %Shuffle the random number generator
    exp_settings = struct;      %Predefine output
    expdir = fileparts(mfilename('fullpath'));  %Get the directory where this function is stored
    cd(expdir);                 %Change directory to the directory where this function is situated
% Keyboard defaults:
    % ESCAPE is the key to terminate the experiment. This key can be used at various points throughout the
    % experiment and cannot be changed. Same is the case for the keys used in decision-making: left and right
    % arrow keys by default. For browsing trough instuction slides, the arrow keys are used as well, or the space
    % bar.
    
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
        exp_settings.font.RatingFontSize = 36;      %Rating screen font size (note: this is the base font size, two other font sizes are used in this function => see settings there)
        exp_settings.font.FontType = 'Arial';       %Font type (universal)
        exp_settings.font.Wrapat = 75;              %Wrapping (for longer texts of induction screens)
        exp_settings.font.vSpacing = 2;             %Vertical spacing (universal)
    %Colors 
        %Define colors
            exp_settings.colors.black = [0 0 0];
            exp_settings.colors.white = [255 255 255];
            exp_settings.colors.grey = [128 128 128];
            exp_settings.colors.orange = [0.8500, 0.3250, 0.0980].*255; 
            exp_settings.colors.green = [59 199 118]; %update to accomodate red-green colorblindness
            exp_settings.colors.red = [218 37 37]; %update to accomodate red-green colorblindness
        %Background colors
            exp_settings.backgrounds.default = exp_settings.colors.black;   %Default background
            exp_settings.backgrounds.fixation = exp_settings.colors.black;  %Fixation screen
            exp_settings.backgrounds.choice = exp_settings.colors.black;    %Choice screen
            exp_settings.backgrounds.rating = exp_settings.colors.black;    %Rating screen      
        %Font colors
            exp_settings.font.FixationFontColor = exp_settings.colors.white;%Fixation screen
            exp_settings.font.ChoiceFontColor = exp_settings.colors.white;  %Choice screen
            exp_settings.font.LossFontColor = exp_settings.colors.red;      %Loss amount on choice screen
            exp_settings.font.RatingFontColor = exp_settings.colors.white;  %Rating screen
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
            exp_settings.OTG.grid.nbins = 5;             % # bins (currently only coded for 5 bins)
            exp_settings.OTG.grid.bincostlevels = 10;    % # cost levels per bin  
            exp_settings.OTG.grid.binrewardlevels = 50;  % # reward levels (= 2*exp_settings.MaxReward so that the step size is 0.50 euros)
            exp_settings.OTG.grid.costlimits = [0 1];    % [min max] cost (note: bin 1's first value is nonzero)
            exp_settings.OTG.grid.rewardlimits = [0.1/30 29.9/30]; % [min max] reward for uncostly option
            exp_settings.OTG.grid.binlimits = exp_settings.OTG.grid.costlimits(1) + ([0:exp_settings.OTG.grid.nbins-1;1:exp_settings.OTG.grid.nbins])'  * (exp_settings.OTG.grid.costlimits(2)-exp_settings.OTG.grid.costlimits(1))/exp_settings.OTG.grid.nbins; % Upper limit and lower limit of each cost bin
            exp_settings.OTG.grid.gridY = exp_settings.OTG.grid.rewardlimits(1):(exp_settings.OTG.grid.rewardlimits(2)-exp_settings.OTG.grid.rewardlimits(1))/(exp_settings.OTG.grid.binrewardlevels-1):exp_settings.OTG.grid.rewardlimits(2);  % Uncostly option rewards for the indifference grid
            exp_settings.OTG.grid.gridX = exp_settings.OTG.grid.costlimits(1):(exp_settings.OTG.grid.costlimits(2)-exp_settings.OTG.grid.costlimits(1))/(exp_settings.OTG.grid.bincostlevels*exp_settings.OTG.grid.nbins):exp_settings.OTG.grid.costlimits(2);   % Cost amounts for sampling grid
        %Parameter settings
            exp_settings.OTG.priorvar = 2*eye(exp_settings.OTG.grid.nbins+1);   % Prior variance for each parameter
            exp_settings.OTG.fixed_beta = 5;        % Fix the inverse choice temperature in the calculation of the indifference grid (optional, default = 5) -- this makes the cost selection distribution curve a bit more dense
        %Calibration settings
            exp_settings.OTG.prior_bias_cal = -3;   % Note: this is log(prior) [used in calibration only]
            exp_settings.OTG.prior_var_cal = 2;     % Note: applies to all parameters [used in calibration only]
            exp_settings.OTG.ntrials_cal = 60;      %Number of trials per choice type in the calibration
            exp_settings.OTG.burntrials_cal = [59/60  0     55/60  2/30;  %Present these "burn trials" at the beginning of the calibration, for the participant (and the algorithm) to start with some 'easy' choices that are rather extreme.
                                               46/50  5/50  1      1/50]; %(Note that presenting these burn trials is optional)
        %Algorithm settings
            exp_settings.OTG.max_n_inv = Inf;       % Max. # of trials entered in model inversion algorithm
            exp_settings.OTG.max_iter = 200;        % [Gauss-Newton] Max. # of iterations, after which we conclude the algorithm does not converge
            exp_settings.OTG.conv_crit = 1e-2;      % [Gauss-Newton] Max. # of iterations for the model inversion algorithm, after which it is forced to stop
            exp_settings.OTG.burntrials = 3;        % [Gauss-Newton] # of trials that must have been sampled before inverting the model
        %VBA: Dimensions
            exp_settings.OTG.dim.n_theta = 0;   % Number of evolution parameters
            exp_settings.OTG.dim.n = 0;         % Number of hidden states
            exp_settings.OTG.dim.p = 1;         % Output data dimension (# of observations per time sample)
            exp_settings.OTG.dim.n_phi = 6;     % Number of observation parameters: 1 intercept (bias) and 5 slopes
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
            exp_settings.OTG.options.inG.grid = exp_settings.OTG.grid; %Grid is entered in observation function too
            exp_settings.OTG.options.inG.beta = exp_settings.OTG.fixed_beta; %Inv. choice temp. for observation function
    
%% Rating screen settings
% These are examples of ratings that can be presented with the "BEC_RateEmotion" function.
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