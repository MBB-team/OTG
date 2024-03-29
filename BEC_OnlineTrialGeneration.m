function [AllData,exitflag] = BEC_OnlineTrialGeneration(AllData,window)
% This function is part of the OTG toolbox, used for generating and presenting a battery of economic choices.
% It generates one trial each time it is called, based on a choice model fitted on the history of choices of the participant.
% Note that this is the version of the online trial generation algorithm that does *not* use VBA.
% This function requires the following inputs:
%       AllData:    the structure that contains all the necessary data and settings. May be an empty
%                   structure at the time of the first choice trial, in that case all the necessary 
%                   fields will be filled in, but these fields will be required in all subsequent
%                   choice trials so make sure that the outputted AllData is also the input on each
%                   subsequent trial.
%       window:     PsychToolbox window for presenting the choice with Matlab. When not entered or 
%                   when left empty, it is assumed this function is being used for a simulation.

%% Get necessary input
    %exp_settings: containing all the settings necessary to generate and present a trial
        if ~isfield(AllData,'exp_settings')
            %If this function is used in a real experiment, load the settings structure so that trials 
                %can properly be presented on screen using the Psychtoolbox.
                if exist('window','var') && ~isempty(window)
                    AllData.exp_settings = BEC_Settings;
                else %Otherwise, the function is used for simulations; enter these default settings only:
                    OTG_settings = Get_OTG_Settings;
                    AllData.exp_settings.OTG = OTG_settings; %Default sampling settings
                end
        end
        OTG_settings = AllData.exp_settings.OTG;
        typenames = OTG_settings.typenames;
    %simulate: run a simulation of the online trial generation procedure
        if ~exist('window','var') || isempty(window) %If there is no Psychtoolbox window open, this function is used to run simulations
            if ~isfield(AllData,'sim') %Create the simulation structure if it does not exist yet
                AllData = SimulationSettings(AllData);
            end
        end
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
        if type_trialno == 1 %Get values from choice calibration if present, or enter population average
            %Get the participant's calibrated parameters if available
                if isfield(AllData,'calibration') && isfield(AllData.calibration,typenames{choicetype})
                    AllData.OTG_prior.(typenames{choicetype}).muPhi = AllData.calibration.(typenames{choicetype}).posterior.muPhi;
                else %Otherwise, use population averages as priors
                    %Naieve priors
                        AllData.OTG_prior.(typenames{choicetype}).muPhi = [-3; log(0.99)*ones(OTG_settings.grid.nbins,1)];
                    %Population average priors (not recommended unless you have *very* few trials in your experiment and no idea of what a "normal"
%                         participant's preferences might be
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
        cost = SampleCost(AllData,choicetype);
    %Sample the reward of the uncostly option, based on the indifference value and the sampled cost
        reward = SampleReward(AllData,choicetype,cost);
    %Heuristic when the algorithm does not converge: adjust the reward away from indifference
        if type_trialno > OTG_settings.burntrials && AllData.OTG_posterior.(typenames{choicetype}).converged(end) == 0
            reward = Adjust_Reward(AllData,reward,cost,choicetype);
        end
    %Present the choice, record decision
        if isfield(AllData,'sim') %Simulate the choice
            AllData = Simulate_Choice(AllData,reward,cost,choicetype,choicetrial);
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
    %Get input to the algorithm: SS rewards, LL costs, choices
        [u,y] = GetTrialFeatures(AllData);
    %Get priors
        mu0 = AllData.OTG_prior.(typenames{choicetype}).muPhi; %prior estimates of the parameter values
        S0 = OTG_settings.priorvar; %prior variance of the parameter estimates
    %Run Gauss-Newton algorithm
        [mu,converged,mu_iter] = Run_GaussNewton(mu0, S0, u, y, OTG_settings);
        disp(['Trial ' num2str(choicetrial) ' -- Converged: ' num2str(converged)])
        AllData.OTG_posterior.(typenames{choicetype}).converged(type_trialno) = converged;
    %Update parameter values if the algorithm converged and after burn trials
        if converged && type_trialno > OTG_settings.burntrials
            AllData.OTG_posterior.(typenames{choicetype}).muPhi = mu;
            AllData.OTG_posterior.(typenames{choicetype}).all_muPhi(:,type_trialno) = mu;
            AllData.OTG_posterior.(typenames{choicetype}).P_indiff = Compute_P_indiff(mu,OTG_settings); %Grid of the probability-of-indifference (computed in subfunction below)
        else
            if type_trialno > 1 %At trial 1, the posteriors in all_muPhi have the value of the priors.
                AllData.OTG_posterior.(typenames{choicetype}).all_muPhi(:,choicetrial) = NaN(size(mu));
            end
        end        
    %Visualize (in the case of simulations)
        if isfield(AllData,'sim') && AllData.sim.visualize == 1
            BEC_Visualize_OTG(AllData,choicetrial)
            Visualize_GN_iter(mu_iter,type_trialno,OTG_settings)
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

function [u,y] = GetTrialFeatures(AllData)
% Get trial features that will be entered into the Gauss-Newton algorithm. The names "u" and "y"
% come from the VBA toolbox by Jean Daunizeau and have been kept here for compatibility.
% Get trial history from given choice type
    OTG_settings = AllData.exp_settings.OTG;
    try %for compatibility with Octave
        trialinfo = struct2table(AllData.trialinfo,'AsArray',true);
    catch
        trialinfo = struct;
        listFields = fieldnames(AllData.trialinfo);
        for iField = 1:length(listFields)
            trialinfo.(listFields{iField}) = [AllData.trialinfo.(listFields{iField})]';
        end
    end
    choicetype = AllData.trialinfo(end).choicetype;
    u = [trialinfo.SSReward(trialinfo.choicetype==choicetype)'; %uncostly-option rewards;
         trialinfo.Cost(trialinfo.choicetype==choicetype)']; %costly-option costs
    y = trialinfo.choiceSS(trialinfo.choicetype==choicetype)'; %choices
    n = sum(trialinfo.choicetype==choicetype);
%Remove NaN trials (these occur when the participant takes longer for a trial than a set time limit)
    u = u(:,~isnan(y));
    y = y(~isnan(y));
%Restrict data for inversion to the most recent trials, according to a predefined recency criterion
    if n > OTG_settings.max_n_inv
        n = OTG_settings.max_n_inv;
        u = u(:,end-(n-1):end);
        y = y(end-(n-1):end);
    end
end

function [mu,converged,mu_iter] = Run_GaussNewton(mu0, S0, u, y, OTG_settings)
% In this function, a Bayesian version of the Gauss-Newton algorithm is used to estimate the model
% parameters of the participant's choice function. 
% INPUTS:
%   mu0: prior parameters estimates
%   S0: prior parameter variance estimates
%   u: small reward and cost of presented choices
%   y: choices (1: uncostly option SS / 0: costly option LL)
%   OTG_settings: settings structure

%Trial features
    n = length(y); %Number of choices
    R = u(1,:); %Reward of uncostly option (R < 1)
    C = u(2,:); %Cost of costly option
%Bin limits (used in the calculation of DV and dDV)
    C1 = OTG_settings.grid.binlimits(1,2);
    C2 = OTG_settings.grid.binlimits(2,2);
    C3 = OTG_settings.grid.binlimits(3,2);
    C4 = OTG_settings.grid.binlimits(4,2);
%Iteration start settings
    mu = mu0; %Start with prior estimates
    stop = 0; %This will stop the looping 
    iter = 0; %Iteration count
    mu_iter = mu0; %History of updated parameter values over iterations of the algorithm
%Iteratively update the parameter values
    while ~stop
        %Check mu: if mu or exp(mu) have "weird" values (Inf, NaN, or irrational), then
            %the inversion has failed.
            if any(isinf([mu; exp(mu)]) | isnan([mu; exp(mu)]) | ~isreal([mu; exp(mu)]))
                converged = 0; break
            end
        %First and second derivative of log posterior function:
            df = -pinv(S0)*(mu-mu0); % Gradient (first derivative) of log-prior
            df2 = -pinv(S0); % Hessian (second derivative) of log-prior
        %Get parameter values (1st iteration: priors; afterwards: updated)
            b = exp(mu(1)); %bias term
            k1 = exp(mu(2)); %weight on cost, bin 1
            k2 = exp(mu(3)); %weight on cost, bin 2
            k3 = exp(mu(4)); %weight on cost, bin 3
            k4 = exp(mu(5)); %weight on cost, bin 4
            k5 = exp(mu(6)); %weight on cost, bin 5
        %Loop through selected trials
            DV = NaN(n,1);
            dDV = NaN(length(mu0),n);
            dDV(1,:) = b; %dDV/db is the same for all trials
            for trl = 1:n
                %Find the cost bin that this trial is in
                    bin = find(C(trl)>OTG_settings.grid.binlimits(:,1) & C(trl)<=OTG_settings.grid.binlimits(:,2));
                %Compute the decision value and its derivative per bin
                    switch bin
                        case 1
                            DV(trl) = R(trl) - 1 + k1*C(trl) + b;
                            dDV(2,trl) = k1*C(trl); %dDV/dk1
                            dDV(3:6,trl) = 0; %dDV/dki for i>1
                        case 2
                            DV(trl) = R(trl) - 1 + k1*C1 + k2*(C(trl)-C1) + b;
                            dDV(2,trl) = k1*C1; %dDV/dk1
                            dDV(3,trl) = k2*(C(trl)-C1); %dDV/dk2
                            dDV(4:6,trl) = 0; %dDV/dki for i>2
                        case 3
                            DV(trl) = R(trl) - 1 + k1*C1 + k2*(C2-C1) + k3*(C(trl)-C2) + b;
                            dDV(2,trl) = k1*C1; %dDV/dk1
                            dDV(3,trl) = k2*(C2-C1); %dDV/dk2
                            dDV(4,trl) = k3*(C(trl)-C2); %dDV/dk3
                            dDV(5:6,trl) = 0; %dDV/dki for i>3
                        case 4
                            DV(trl) = R(trl) - 1 + k1*C1 + k2*(C2-C1) + k3*(C3-C2) + k4*(C(trl)-C3) + b;
                            dDV(2,trl) = k1*C1; %dDV/dk1
                            dDV(3,trl) = k2*(C2-C1); %dDV/dk2
                            dDV(4,trl) = k3*(C3-C2); %dDV/dk3
                            dDV(5,trl) = k4*(C(trl)-C3); %dDV/dk4
                            dDV(6,trl) = 0; %dDV/dk5
                        case 5
                            DV(trl) = R(trl) - 1 + k1*C1 + k2*(C2-C1) + k3*(C3-C2) + k4*(C4-C3) + k5*(C(trl)-C4) + b;
                            dDV(2,trl) = k1*C1; %dDV/dk1
                            dDV(3,trl) = k2*(C2-C1); %dDV/dk2
                            dDV(4,trl) = k3*(C3-C2); %dDV/dk3
                            dDV(5,trl) = k4*(C4-C3); %dDV/dk4
                            dDV(6,trl) = k5*(C(trl)-C4); %dDV/dk5
                    end
                %Compute the choice probability (expressed as probability of chosing the uncostly option)
                    P_U = 1./(1+exp(-DV(trl))); %Softmax function
                %Update gradient and hessian of the log posterior
                    df = df + (y(trl)-P_U)*dDV(:,trl);
                    df2 = df2 - P_U*(1-P_U)*dDV(:,trl)*dDV(:,trl)';
            end %for trl
        %Gauss-Newton iteration        
            dmu = -pinv(df2)*df; % Gauss-Newton step
            grad = sum(abs(dmu./mu)); % For convergence criterion
            mu = mu + dmu; % Gauss-Newton update
            mu_iter = [mu_iter mu]; %#ok<AGROW> --- suppress warning
            iter = iter+1;
        %Check convergence
            if grad <= OTG_settings.conv_crit % Check convergence (arbitrary criterion)
                stop = 1; converged = 1; %success
            elseif iter > OTG_settings.max_iter % Maximum # of iterations exceeded
                stop = 1; converged = 0; %fail
                disp(['Max. iteration limit reached. Grad = ' num2str(grad)])
            end
    end %while
end %function

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
            P_U(i_bin) = sigmoid(DV*beta); %P(choose uncostly)
    end
    %Output: probability-of-indifference (= 1 when P_U is 0.5 and goes to 0 as P_U goes to 0 or 1)
        P_indiff = (0.5-abs(P_U'-0.5))./0.5; %When P_U = 0.5, P_indiff = 1
        P_indiff = reshape(P_indiff,grid.binrewardlevels,grid.nbins*grid.bincostlevels); %Reshape P_indiff back to the original grid format
end

function [AllData] = Simulate_Choice(AllData,reward,cost,choicetype,choicetrial)
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
        P_U = sigmoid(DV); %Probability of choosing the uncostly option
        y = BEC_sampleFromArbitraryP([P_U,1-P_U]',[1,0]',1); %Choice: uncostly option (1) or costly option (0)
    %Enter the simulated choice in trialinfo
        AllData.trialinfo(choicetrial).choicetype = choicetype; %numeric choicetype (1:4)
        AllData.trialinfo(choicetrial).SSReward = reward; %reward of the uncostly ("SS": smaller & sooner) option
        AllData.trialinfo(choicetrial).Cost = cost; %cost of the costly option
        AllData.trialinfo(choicetrial).choiceSS = y; %choice: 1 = uncostly (smaller&sooner) option; 0 = costly option
end

function [cost] = SampleCost(AllData,choicetype)
    %Settings
        typenames = AllData.exp_settings.OTG.typenames;
        grid = AllData.exp_settings.OTG.grid;
    %Grid with degree of indifference for each cost/reward combination
        P_indiff = AllData.OTG_posterior.(typenames{choicetype}).P_indiff; 
    %Make probability density function by summing P_indiff per cost level
        PDF = sum(P_indiff); 
        PDF = PDF/sum(PDF); %normalize
        cost = sampleFromArbitraryP(PDF',grid.gridX(2:end)',1); %Sample a cost level (see subfunction below)       
    %Visualize the cost sampling procedure
        if isfield(AllData,'sim') && isfield(AllData.sim,'visualize') && AllData.sim.visualize == 1
            gcf;
            subplot(2,2,3); cla; hold on
            X = grid.gridX(2:end);
            plot(X,PDF)
            scatter(cost,PDF(X==cost))
            xlabel('LL Cost'); ylabel('normalized probability')
            title('Probability distribution')
            legend({'PDF','sampled cost'},'Location','SouthOutside','Orientation','horizontal')
        end
end

function [reward] = SampleReward(AllData,choicetype,cost)
%Sample the reward of the uncostly option, based on the indifference value and the sampled cost. The
%indifference value is calculated with the parameters of the inverted model.
    %Settings
        OTG_settings = AllData.exp_settings.OTG;
        typenames = OTG_settings.typenames;
        grid = AllData.exp_settings.OTG.grid;
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
end

function [adjusted_reward] = Adjust_Reward(AllData,reward,cost,choicetype)
% This function uses simple heuristics to adjust the reward *away* from the currently estimated indifference curve, in case the algorithm fails to
% converge. Failure to converge may proliferate if the algorithm is "stuck" with an estimation of the indifference curve that is wrong.
    %Settings
        grid = AllData.exp_settings.OTG.grid;
        costbin = find(cost>grid.binlimits(:,1) & cost<=grid.binlimits(:,2)); %get cost bin number
    %Get choice data
        all_costs = [AllData.trialinfo.Cost]';
        all_choicetypes = [AllData.trialinfo.choicetype]';
        all_choiceSS = [AllData.trialinfo.choiceSS]';
        %Limit to current choice type
            all_costs = all_costs(all_choicetypes==choicetype);
            all_choiceSS = all_choiceSS(all_choicetypes==choicetype);
        %Limit to most recent choices if a recency criterion is applied
            if length(all_choiceSS) > AllData.exp_settings.OTG.max_n_inv
                all_costs = all_costs(end-AllData.exp_settings.OTG.max_n_inv+1 : end);
                all_choiceSS = all_choiceSS(end-AllData.exp_settings.OTG.max_n_inv+1 : end);
            end
    %Identify choices in current cost bin
        i_bin = all_costs>grid.binlimits(costbin,1) & all_costs<=grid.binlimits(costbin,2);
        choicerate_bin = mean(all_choiceSS(i_bin));
    %Apply adjustment
        if ~isnan(choicerate_bin) %if NaN: no choices presented yet in this bin => don't correct
            delta = 0.5 - choicerate_bin; %difference w.r.t. the target choice rate (50% for indifference)
            k = 2/(1+exp(2-sum(i_bin))); %weighing factor of the number of choices already made in this bin
            if choicerate_bin >= 0.5 %Mostly SS: SSRew is too high => adjust downward (delta is negative)
                adjusted_reward = reward + k*delta*(reward - grid.rewardlimits(1));
            else %Mostly LL: SSRew is too low => adjust upward (delta is positive)
                adjusted_reward = reward + k*delta*(grid.rewardlimits(2)-reward);
            end
        else
            adjusted_reward = reward;
        end
end

function Visualize_GN_iter(mu_iter,n,OTG_settings)
%Add visualization of the parameter updating process (not in BEC_Visualize)
    if n > OTG_settings.burntrials
        gcf;
        subplot(2,2,4); cla; hold on
        plot(1:size(mu_iter,2),mu_iter'); xlim([1 size(mu_iter,2)])
        xlabel('iteration'); ylabel('parameter value')
        title('Gauss-Newton iterations')
        legend({'b','k1','k2','k3','k4','k5'},'Location','EastOutside')
    end
end

function y = sigmoid(x) % --- from VBA toolbox by Daunizeau & Rigoux
% sigmoid mapping, a.k.a. softmax function
    y=1./(1+exp(-x));
    y(y<1e-4) = 1e-4;
    y(y>(1-1e-4)) = 1-1e-4;
end

function [X] = sampleFromArbitraryP(p,gridX,N) % --- from VBA toolbox by Daunizeau & Rigoux
% inverse transform sampling scheme
% function [X] = sampleFromArbitraryP(p,gridX,N)
% This function samples from an arbitrary 1D probability distribution
% IN:
%   - p: pX1 vector (the density evaluated along the grid)
%   - gridX: pX1 vector (the grid over which the density is evaluated)
%   - N: the number of samples to be sampled
% OUT:
%   - X: NX1 vector of samples
    p = vec(p);
    if size(gridX,1)==1
        gridX = vec(gridX);
    end
    k = size(gridX,2);
    if any(isnan(p))
        X = nan(N,k);
    else
        pcdf = cumsum(p(:));
        X = zeros(N,k);
        for i=1:N
            below = find(rand<=pcdf);
            X(i,:) = gridX(below(1),:); %Error that can happen: Index exceeds matrix dimensions.
        end
    end    
end

function vx = vec(X) % --- from VBA toolbox by Daunizeau & Rigoux
    % computes the Vec operator
    % function vx = vec(X)
    % JD, 2/03/2007.
    if isempty(X)
        vx = [];
    else
        vx = full(X(:));
    end
end

function AllData = SimulationSettings(AllData)
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
    AllData.triallist.choicetypes = 1; %Simulate choices of type 1 (arbitrary)
end

function OTG_settings = Get_OTG_Settings
% Create a basic structure with the settings needed to run the algorithm.
% Note that these settings must correspond to the settings in "exp_settings.OTG" in the BEC_Settings
% function.
    %Choice types
        OTG_settings.choicetypes = [1 2 3 4];
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
    %Parameter settings
        OTG_settings.fixed_beta = 5;        % Fix the inverse choice temperature in the calculation of the indifference grid (optional, default = 5)
        OTG_settings.priorvar = 3*eye(OTG_settings.grid.nbins+1);   % Prior variance for each parameter
    %Algorithm settings:
        OTG_settings.burntrials = 1;        % # of trials that must have been sampled before inverting the model (minimum: 1)
        OTG_settings.max_iter = 200;        % Max. # of iterations, after which we conclude the algorithm does not converge
        OTG_settings.max_n_inv = Inf;       % Max. # of trials entered in model inversion algorithm
        OTG_settings.conv_crit = 1e-2;      % Max. # of iterations for the model inversion algorithm, after which it is forced to stop
end