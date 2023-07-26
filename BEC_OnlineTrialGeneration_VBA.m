function [AllData,exitflag] = BEC_OnlineTrialGeneration_VBA(AllData,window)
% This function is part of the OTG toolbox, used for generating and presenting a battery of economic choices.
% It generates one trial each time it is called, based on a choice model fitted on the history of choices of the participant.
% Note that this is the version of the algorithm that makes uses of VBA and should be preferred in Matlab-based experiments.
% This function requires the following inputs:
%       AllData:    the structure that contains all the necessary data and settings. May be an empty
%                   structure at the time of the first choice trial, in that case all the necessary 
%                   fields will be filled in, but these fields will be required in all subsequent
%                   choice trials so make sure that the outputted AllData is also the input on each
%                   subsequent trial.
%       window:     PsychToolbox window for presenting the choice with Matlab. When not entered or 
%                   when left empty, it is assumed this function is being used for a simulation.

%% Get necessary input
    %simulate: run a simulation on the online trial generation
        if ~exist('window','var') || isempty(window) %If there is no Psychtoolbox window open, this function is not used to sample and present choices to participants, but to run simulations
            if ~isfield(AllData,'sim') 
                %Create a simulation structure containing specifics of the simulated choice model
                %This is a more sophisticated choice model that is usually only used to fit choices
                %post-hoc, and here it is used to generate the choices. The purpose of the
                %model-fitting algorithm here is to approach this choice function as closely as
                %possible.
                    AllData.sim.visualize = 1; %Visualize the simulation ([1:yes / 0:no])
                    AllData.sim.model = 'exponential'; %Name of the model; options: 'additive','exponential','hyperbolic'
                    AllData.sim.kC = 8; %Weight on cost
                    AllData.sim.gamma = 1; %Power on cost
                    AllData.sim.beta = 20; %Choice temperature
                    AllData.sim.bias = 0; %Choice bias
                    AllData.sim.kRew = 1; %Weight on reward
                %Triallist of the simulated choices:
                    AllData.triallist.choicetypes = 1; %Simulate trials of only one choice type (here arbitrarily set to 1 for Delay)
            end
        end
    %exp_settings: containing all the settings necessary to generate and present a trial
        if ~isfield(AllData,'exp_settings')
            %If this function is used in a real experiment, load the settings structure so that trials 
                %can properly be presented on screen using the Psychtoolbox.
                if exist('window','var') && ~isempty(window)
                    AllData.exp_settings = BEC_Settings; %Full settings structure
                else %In case the function is used for simulations; enter these default settings only:
                    %Choice types
                        OTG_settings.choicetypes = 1; %[1 2 3 4];
                        OTG_settings.typenames = {'delay','risk','physical_effort','mental_effort'};
                    %Sampling grid
                        OTG_settings.grid.nbins = 5;             % number of cost bins
                        OTG_settings.grid.bincostlevels = 10;    % number of cost levels per bin  
                        OTG_settings.grid.binrewardlevels = 50;  % number of reward levels (only for computing indifference grid)
                        OTG_settings.grid.costlimits = [0 1];    % [min max] cost (note: bin 1's first value is nonzero)
                        OTG_settings.grid.rewardlimits = [0.1/30 29.9/30]; % [min max] reward for uncostly option
                        OTG_settings.grid.binlimits = OTG_settings.grid.costlimits(1) + ([0:OTG_settings.grid.nbins-1; 1:OTG_settings.grid.nbins])'  * (OTG_settings.grid.costlimits(2)-OTG_settings.grid.costlimits(1))/OTG_settings.grid.nbins; % Upper limit and lower limit of each cost bin
                        OTG_settings.grid.gridY = OTG_settings.grid.rewardlimits(1):(OTG_settings.grid.rewardlimits(2)-OTG_settings.grid.rewardlimits(1))/(OTG_settings.grid.binrewardlevels-1):OTG_settings.grid.rewardlimits(2);  % Uncostly option rewards for the indifference grid
                        OTG_settings.grid.gridX = OTG_settings.grid.costlimits(1):(OTG_settings.grid.costlimits(2)-OTG_settings.grid.costlimits(1))/(OTG_settings.grid.bincostlevels*OTG_settings.grid.nbins):OTG_settings.grid.costlimits(2);   % Cost amounts for sampling grid
                    %Model inversion settings
                        OTG_settings.fixed_beta = 5;        % Fix the inverse choice temperature in the calculation of the indifference grid (optional, default = 5)
                        OTG_settings.priorvar = 2*eye(OTG_settings.grid.nbins+1);   % Prior variance for each parameter
                        OTG_settings.max_n_inv = Inf;       % Max. # of trials entered in model inversion algorithm
                        OTG_settings.burntrials = 0;        % Min. # of trials that have to be presented before the model is inverted
                    %VBA: Dimensions
                        OTG_settings.dim.n_theta = 0;
                        OTG_settings.dim.n = 0;
                        OTG_settings.dim.p = 1;    
                        OTG_settings.dim.n_phi = 6;
                    %VBA: Options
                        OTG_settings.options.sources.type = 1;
                        OTG_settings.options.verbose = 0;
                        OTG_settings.options.DisplayWin = 0;
                        OTG_settings.options.inG.ind.bias = 1;
                        OTG_settings.options.inG.ind.k1 = 2;
                        OTG_settings.options.inG.ind.k2 = 3;
                        OTG_settings.options.inG.ind.k3 = 4;
                        OTG_settings.options.inG.ind.k4 = 5;
                        OTG_settings.options.inG.ind.k5 = 6;
                        OTG_settings.options.inG.beta = OTG_settings.fixed_beta; %Inv. choice temp. for observation function
                        OTG_settings.options.inG.grid = OTG_settings.grid; %Grid is entered in observation function too
                    %Store
                        AllData.exp_settings.OTG = OTG_settings; %Default sampling settings
                end
        end
        OTG_settings = AllData.exp_settings.OTG;
        grid = OTG_settings.grid;
        typenames = OTG_settings.typenames;
    %trialinfo: history of choices (empty structure at first trial)
        if ~isfield(AllData,'trialinfo')
            AllData.trialinfo = struct;
            choicetrial = 1;
        end
    %choicetrial: the number of the choice to be generated
        if ~exist('choicetrial','var')
            choicetrial = size(AllData.trialinfo,2) + 1;
        end
    %choicetype: whether the choice is about delay, risk, physical effort, or mental effort
        if ~isfield(AllData,'triallist') || ~isfield(AllData.triallist,'choicetypes') %Select the choice type to be presented in this trial
            if choicetrial == 1 %If this is the first trial, select a choice type at random if no trial list is present
                choicetype = OTG_settings.choicetypes(randperm(length(OTG_settings.choicetypes),1));
            else %After the first trial, use the sampling procedure in the subfunction below
                choicetype = SampleChoiceType(AllData.trialinfo,OTG_settings); %See subfunction below
            end
        else %If a triallist of choice types is predefined, select the choice type of this trial
            if size(AllData.triallist.choicetypes,1) < choicetrial
                %No choice type is pre-specified: take the same type as the last trial by default
                    AllData.triallist.choicetypes(choicetrial) = AllData.triallist.choicetypes(choicetrial-1);
            end
            choicetype = AllData.triallist.choicetypes(choicetrial);
        end
    %type_trialno: the trial number of this particular choice type
        if choicetrial == 1
            type_trialno = 1;
        else
            all_choicetypes = [AllData.trialinfo.choicetype]; %History of presented choice types
            type_trialno = sum(all_choicetypes==choicetype) + 1;
        end
    %OTG_prior: prior estimates of model parameters, per choice type
        if ~isfield(AllData,'OTG_prior')
            AllData.OTG_prior = struct;
        end
        if type_trialno == 1 %Before starting, get values from choice calibration if present, or enter population average
            %Get the participant's calibrated parameters if available
                if isfield(AllData,'calibration') && isfield(AllData.calibration,typenames{choicetype})
                    AllData.OTG_prior.(typenames{choicetype}).muPhi = AllData.calibration.(typenames{choicetype}).posterior.muPhi;
                else %Otherwise, use naive priors or population averages as priors
                    %Naieve priors
                        AllData.OTG_prior.(typenames{choicetype}).muPhi = [-3; zeros(OTG_settings.grid.nbins,1)];
                    %Population average priors (not recommended unless you have *very* few trials in your experiment) and no idea of how a "normal"
%                       participant might behave.
%                             AllData.OTG_prior.delay.muPhi = [-3.6628;0.2041;-2.2642;-2.8915;-3.2661;-1.8419];
%                             AllData.OTG_prior.risk.muPhi = [-1.4083;0.8217;-1.1018;-1.1148;-0.6224;0.2078];
%                             AllData.OTG_prior.physical_effort.muPhi = [-5.4728;-2.9728;-2.4963;-1.8911;-0.3541;-1.7483];
%                             AllData.OTG_prior.mental_effort.muPhi = [-4.0760;0.2680;-0.5499;-2.0245;-2.6053;-1.9991];
                end
        end
    %OTG_posterior: posterior estimates from the online trial generation, per choice type
        if ~isfield(AllData,'OTG_posterior')
            AllData.OTG_posterior = struct; %Contains the most recent model estimation
        end
        if type_trialno == 1 %On the first trial, set the posterior equal to the prior
            muPhi = AllData.OTG_prior.(typenames{choicetype}).muPhi; %"muPhi" contains the parameter estimates per cost bin
            AllData.OTG_posterior.(typenames{choicetype}).muPhi = muPhi; %Posterior of the last trial (here: set equal to prior)
            AllData.OTG_posterior.(typenames{choicetype}).all_muPhi(:,1) = muPhi; %History of posteriors for this choice type (here: set posterior parameter estimates from first trial of given choice type equal to prior)
            AllData.OTG_posterior.(typenames{choicetype}).P_indiff = Compute_P_indiff(muPhi,OTG_settings); %Grid of the probability-of-indifference (computed in subfunction below)
        end
        
%% Sample and present a choice of the given choice type
    %Sample cost level of the costly option using P_indiff
        P_indiff = AllData.OTG_posterior.(typenames{choicetype}).P_indiff; %Grid with degree of indifference for each cost/reward combination
        PDF = sum(P_indiff); PDF = PDF/sum(PDF); %Make probability density function
        cost = BEC_sampleFromArbitraryP(PDF',grid.gridX(2:end)',1); %Sample a cost level (see subfunction below)
        costbin = find(cost>grid.binlimits(:,1) & cost<=grid.binlimits(:,2)); %get cost bin number
    %Get parameter values: b and k
        muPhi = AllData.OTG_posterior.(typenames{choicetype}).muPhi; %get the most recent estimate of parameter values
        for bin = 1:grid.nbins %Loop through cost bins
            k = exp(muPhi(1+bin)); 
            if bin == 1
                b = exp(muPhi(1));
            else
                b = 1 - k.*C_i - R_i; %C_i and R_i obtained from previous bin, see below
            end
            if bin == costbin
                break
            else
                C_i = OTG_settings.grid.binlimits(bin,2); %Cost level of the bin edge
                R_i = 1 - k*C_i - b; %Indifference reward level at cost bin edge
            end
        end
    %Compute the reward (at indifference) for the corresponding uncostly option
        reward = 1 - k*cost - b; %Reward for the uncostly option
        if reward > grid.rewardlimits(2) %Correct the presented reward if it is out of bounds (too large)
            reward = grid.rewardlimits(2);
        elseif reward < grid.rewardlimits(1) %Correct the presented reward if it is out of bounds (too small)
            reward = grid.rewardlimits(1);
        end
    %Present the choice, record decision
        if isfield(AllData,'sim') %Simulation
            %Visualize the cost sampling procedure
                if AllData.sim.visualize == 1
                    gcf;
                    subplot(2,2,3); cla; hold on
                    X = grid.gridX(2:end);
                    plot(X,PDF)
                    scatter(cost,PDF(X==cost))
                    xlabel('LL Cost'); ylabel('normalized probability')
                    title('Probability distribution')
                    legend({'PDF','sampled cost'},'Location','SouthOutside','Orientation','horizontal')
                end
            %Simulate a choice
                AllData = Simulate_Decision(AllData,reward,cost,choicetrial,choicetype);
        else %Present the sampled choice to the participant on the BECHAMEL choice screen
            trialinput.choicetype = choicetype;
            trialinput.SSReward = reward;
            trialinput.Cost = cost;       
            try trialinput.plugins = AllData.plugins; %When in a lab experiment with eyetracker, tactile screen, BIOPAC, Arduino, etc...
            catch; trialinput.plugins = []; %In all other cases: leave empty
            end
            [trialoutput,exitflag] = BEC_ShowChoice(window,AllData.exp_settings,trialinput);
            if exitflag % ESCAPE was pressed, terminate experiment
                return
            else %Record the participant's decision
                if choicetrial == 1
                    AllData.trialinfo = trialoutput;
                else
                    AllData.trialinfo(choicetrial) = trialoutput;
                end
            end
        end
        
%% Update parameter estimates
    %Get trial history from given choice type        
        try %for compatibility with Octave
            trialinfo = struct2table(AllData.trialinfo,'AsArray',true);
        catch
            trialinfo = struct;
            listFields = fieldnames(AllData.trialinfo);
            for iField = 1:length(listFields)
                trialinfo.(listFields{iField}) = [AllData.trialinfo.(listFields{iField})]';
            end
        end
        u = [trialinfo.SSReward(trialinfo.choicetype==choicetype)'; %uncostly-option rewards;
             trialinfo.Cost(trialinfo.choicetype==choicetype)']; %costly-option costs
        y = trialinfo.choiceSS(trialinfo.choicetype==choicetype)'; %choices
    %Remove NaN trials (these occur when the participant takes longer for a trial than a set time limit)
        u = u(:,~isnan(y));
        y = y(~isnan(y));
    %Restrict data for inversion to the most recent trials, according to a predefined recency criterion
        n = length(y);
        if n > OTG_settings.max_n_inv
            n = OTG_settings.max_n_inv;
            u = u(:,end-(n-1):end);
            y = y(end-(n-1):end);
        end
    %Get priors
        options = OTG_settings.options;
        options.priors.muPhi = AllData.OTG_prior.(typenames{choicetype}).muPhi; %prior estimates of the parameter values
        options.priors.SigmaPhi = OTG_settings.priorvar; %prior variance of the parameter estimates
    %Invert the model and update the posterior
        dim = OTG_settings.dim;
        dim.n_t = n;
        posterior = VBA_NLStateSpaceModel(y,u,[],@ObservationFunction,dim,options);
        AllData.OTG_posterior.(typenames{choicetype}).muPhi = posterior.muPhi;
        AllData.OTG_posterior.(typenames{choicetype}).all_muPhi(:,type_trialno) = posterior.muPhi;
        AllData.OTG_posterior.(typenames{choicetype}).all_SigmaPhi(:,type_trialno) = diag(posterior.SigmaPhi);
        AllData.OTG_posterior.(typenames{choicetype}).P_indiff = Compute_P_indiff(posterior.muPhi,OTG_settings); %Grid of the probability-of-indifference (computed in subfunction below)
    %Visualize (in the case of simulations)
        if isfield(AllData,'sim') && AllData.sim.visualize == 1
            BEC_Visualize_OTG(AllData,choicetrial)
        end
end %function

%% Subfunctions

function [choicetype] = SampleChoiceType(trialinfo,OTG_settings)
% Decide which choice type the next choice should be. There should be one occurrence of each of (4)
% choicetypes in every set of (4) trials, and two subsequent trials should not be of the same type.
% A choice type can have values: 1 (delay), 2 (risk), 3 (physical effort), or 4 (mental effort).
    all_choicetypes = [trialinfo.choicetype]; %History of presented choice types
    n_types = length(OTG_settings.choicetypes); %Number of different choice types
    n_choices = length(all_choicetypes); %Number of choices already made
    n_recent_types = mod(n_choices,n_types); %Number of choices in the current set of 4 different types
% Criterion 1: in every set of 4 trials, there should be one occurrence of each choice type
    recent_types = all_choicetypes(end-n_recent_types+1:end); %Recent history of different choice types in current set of 4 different types
% Criterion 2: no two subsequent trials may be of the same type
    previous_type = all_choicetypes(end); %The type of the previous choice (if the current choice is the first of a set, it may not sample a type that is the same as the last of a previous set)
% Sample the choice based on 2 criteria
    sample_types = setdiff(OTG_settings.choicetypes,[recent_types previous_type]); %These are the choice types that may be sampled
    if isempty(sample_types) %there is only one type to sample
        choicetype = OTG_settings.choicetypes;
    else
        i_select = randperm(length(sample_types),1); %Randomly select one of the types that may be sampled
        choicetype = sample_types(i_select); %Sample the choice type - this is the output of the function    
    end
end

function [P_indiff] = Compute_P_indiff(muPhi,OTG_settings)
%Compute the probability-of-indifference "P_indiff" for the full sampling grid. At each point of the
%grid, there is a value that expresses the probability (between 0 and 1) that that point is at
%indifference. A point of the grid represents a combination between a cost of the costly option
%(X-axis) and a reward of the uncostly option (Y-axis).
% INPUT:    muPhi: the parameter estimates, for each bin    
%           OTG_settings: the structure of settings for online trial generation
    grid = OTG_settings.grid;
    all_reward = repmat(grid.gridY',1,grid.nbins*grid.bincostlevels); %All possible rewards for the uncostly option in the grid
    all_cost = repmat(grid.gridX(2:end),grid.binrewardlevels,1); %All possible costs for the costly option in the grid
    u_ind = [reshape(all_reward,[numel(all_reward) 1]) reshape(all_cost,[numel(all_cost) 1])]'; %Full grid, reshaped to two rows
    P_U = NaN(1,length(u_ind)); %Probability of choosing the uncostly option, to be calculated below
    for bin = 1:grid.nbins %Loop through cost bins        
        %Get indices of the grid points of the current bin        
            i_bin = u_ind(2,:)>grid.binlimits(bin,1) & u_ind(2,:)<=grid.binlimits(bin,2);
        %Get parameters
            %Weight on cost for this bin (parameters 2-6 from muPhi)
                k = exp(muPhi(1+bin));
            %Choice bias (first parameter of muPhi)
                if bin == 1
                    b = exp(muPhi(1));
                else
                    b = 1 - k.*C_i - R_i; %C_i and R_i obtained from previous bin, see below
                end
                C_i = OTG_settings.grid.binlimits(bin,2); %Cost level of the bin edge
                R_i = 1 - k*C_i - b; %Indifference reward level at cost bin edge 
            %Inverse choice temperature (a constant)
                beta = OTG_settings.fixed_beta; %Choice temperature
        %Compute decision value and probability of choosing the uncostly option
            DV = u_ind(1,i_bin) - 1 + b + k .* u_ind(2,i_bin); %Decision value: (option 1) - (option 2)
            try
                P_U(i_bin) = VBA_sigmoid(DV*beta); %P(choose uncostly)
            catch %for compatibility with older VBA versions
                P_U(i_bin) = sigmoid(DV*beta); %P(choose uncostly)
            end
    end
    %Output: probability-of-indifference (= 1 when P_U is 0.5 and goes to 0 as P_U goes to 0 or 1)
        P_indiff = (0.5-abs(P_U'-0.5))./0.5; %When P_U = 0.5, P_indiff = 1
        P_indiff = reshape(P_indiff,grid.binrewardlevels,grid.nbins*grid.bincostlevels); %Reshape P_indiff back to the original grid format
end

function [Z] = ObservationFunction(~,P,u,in)
    %Inputs (u)
        R1 = u(1,:); %Reward for (uncostly) option 1
        C = u(2,:);  %Cost
    %Parameters of each indifference line (two parameters per bin)
        all_bias = zeros(in.grid.nbins,1); 
        all_k = zeros(in.grid.nbins,1);
        beta = in.beta; %Assume a fixed inv. choice temperature for better model fitting (value based on past results)
        for i_bin = 1:in.grid.nbins
            %Get this bin's indifference line's two parameters
                %Weight on cost
                    k = exp(P(in.ind.bias+i_bin));
                    all_k(i_bin) = k;
                %Choice bias
                    if i_bin == 1; bias = exp(P(in.ind.bias));
                    else; bias = 1 - k*C_i - R_i;
                    end
                    all_bias(i_bin) = bias;
            %Get the intersection point with the next bin
                C_i = in.grid.binlimits(i_bin,2); %Cost level of the bin edge
                R_i = 1 - k*C_i - bias; %Indifference reward level
        end
    %Compute value of choice options per bin
        V1 = zeros(1,size(u,2)); V2 = zeros(1,size(u,2));
        for i_trl = 1:size(u,2)
            bin = (C(i_trl) > in.grid.binlimits(:,1) & C(i_trl) <= in.grid.binlimits(:,2));
            V1(i_trl) = R1(i_trl) + all_bias(bin); % Uncostly option 1
            V2(i_trl) = 1 - all_k(bin) .* C(i_trl);
        end
    %Compute probability of choosing option 1 (Z)
        DV = V1 - V2; %Decision value
        Z = 1./(1 + exp(-beta*DV)); %Probability of chosing option 1
        Z = Z';
end

function AllData = Simulate_Decision(AllData,reward,cost,choicetrial,choicetype)
% Simulate a decision, given the "true" choice model and the sampled reward and cost

%Compute option values for simulated decision-maker (using a different value function)
    SSRew = reward; %Reward for the uncostly option (sampled above)
    LLRew = 1; %Reward for the costly ("larger-later") option: 1 by default
    SSCost = 0; %Cost for the uncostly option: 0 by default
    LLCost = cost; %Cost for the costly option (sampled above)
    X = AllData.exp_settings.OTG.grid.gridX; %The cost grid (for the calculation of the indifference curve - for visualization only)
    switch AllData.sim.model %Note: bias is in the value function!
        case 'additive'
            V1 = AllData.sim.kRew * SSRew - AllData.sim.kC*SSCost ^ AllData.sim.gamma + AllData.sim.bias; %Value of option 1 (uncostly option)
            V2 = AllData.sim.kRew * LLRew - AllData.sim.kC*LLCost ^ AllData.sim.gamma; %Value of option 2 (costly option)
            %Indifference curve (for visualization only)
                AllData.sim.indiff_curve = LLRew - AllData.sim.kC/AllData.sim.kRew .* X .^ AllData.sim.gamma - AllData.sim.bias/AllData.sim.kRew; 
        case 'exponential'
            V1 = AllData.sim.kRew * SSRew * exp( -AllData.sim.kC * SSCost ^ AllData.sim.gamma) + AllData.sim.bias; %Value of option 1 (uncostly option)
            V2 = AllData.sim.kRew * LLRew * exp( -AllData.sim.kC * LLCost ^ AllData.sim.gamma); %Value of option 2 (costly option)
            %Indifference curve (for visualization only)
                AllData.sim.indiff_curve = LLRew .* exp( -AllData.sim.kC .* X .^ AllData.sim.gamma) - AllData.sim.bias/AllData.sim.kRew;
        case 'hyperbolic'
            V1 = AllData.sim.kRew * SSRew / (1 + AllData.sim.kC * SSCost ^ AllData.sim.gamma) + AllData.sim.bias; %Value of option 1 (uncostly option)
            V2 = AllData.sim.kRew * LLRew / (1 + AllData.sim.kC * LLCost ^ AllData.sim.gamma); %Value of option 2 (costly option)
            %Indifference curve (for visualization only)
                AllData.sim.indiff_curve = LLRew ./ (1 + AllData.sim.kC .* X .^ AllData.sim.gamma) - AllData.sim.bias/AllData.sim.kRew;
    end
    DV = AllData.sim.beta*(V1 - V2); %Decision value = inverse temperature x value difference
%Simulate the decision
    try
        P_U = VBA_sigmoid(DV); %Probability of choosing the uncostly option
    catch %for compatibility with older VBA versions
        P_U = sigmoid(DV); %Probability of choosing the uncostly option
    end
    y = BEC_sampleFromArbitraryP([P_U,1-P_U]',[1,0]',1); %Choice: uncostly option (1) or costly option (0)
%Enter the simulated choice in trialinfo
    AllData.trialinfo(choicetrial).choicetype = choicetype; %numeric choicetype (1:4)
    AllData.trialinfo(choicetrial).SSReward = reward; %reward of the uncostly ("SS": smaller & sooner) option
    AllData.trialinfo(choicetrial).Cost = cost; %cost of the costly option
    AllData.trialinfo(choicetrial).choiceSS = y; %choice: 1 = uncostly (smaller&sooner) option; 0 = costly option
end