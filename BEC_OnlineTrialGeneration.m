function [AllData,exitflag] = BEC_OnlineTrialGeneration(AllData,window)
% Generates trials based on history of choices of the participant. This function
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
        if ~exist('window','var') || ~isempty(window) %If there is no Psychtoolbox window open, this function is not used to sample and present choices to participants, but to run simulations
            if ~isfield(AllData,'sim') %Create a simulation structure containing parameters of the simulated choice model
                AllData.sim.kC = 2.5; %Weight on cost
                AllData.sim.gamma = 0.5; %Power on cost
                AllData.sim.beta = 10; %Choice temperature
                AllData.sim.bias = 0.15; %Choice bias
                AllData.sim.kRew = 3; %Weight on reward
                AllData.triallist.choicetypes = ones(100,1); %Simulate 100 trials of only one choice type
            end
        end
    %exp_settings: containing all the default settings necessary to generate and present a trial
        %Default settings:
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
                OTG_settings.prior_beta = 5;        % Assume this prior value for the inverse choice temperature (based on past results) to improve model fit.
                OTG_settings.burntrials = 2;        % # of trials per bin that must have been sampled before inverting
                OTG_settings.priorvar = eye(3);     % Prior variance for each parameter
                OTG_settings.max_iter = 100;        % Max. # of iterations, after which we conclude the algorithm does not converge
                OTG_settings.maxperbin = 10;        % Max. # of trials in a bin - pick the most recent ones.
                OTG_settings.min_k = 0.01;          % Minimum value for k when updating bins
        if ~isfield(AllData,'exp_settings')
            %If this function is used in a real experiment, load the settings structure so that
            %trials can properly be presented on screen using the Psychtoolbox. Otherwise, default settings suffise.
                if exist('window','var') && ~isempty(window)
                    AllData.exp_settings = BEC_settings;
                    OTG_settings = AllData.exp_settings.OTG;
                else %In case the function is used for simulations
                    AllData.exp_settings.OTG = OTG_settings; %Default sampling settings
                end
        elseif ~isfield(AllData.exp_settings,'OTG')
            AllData.exp_settings.OTG = OTG_settings;
        end
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
        if ~isfield(AllData.triallist,'choicetypes') %Select the choice type to be presented in this trial
            choicetype = SampleChoiceType(AllData.trialinfo,choicetrial,OTG_settings); %See subfunction below
        else %If a triallist of choice types is predefined, select the choice type of this trial
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
            AllData = GetPriorEstimates(AllData,typenames{choicetype},grid);
        end
    %OTG_posterior: posterior estimates from the online trial generation, per choice type
        if ~isfield(AllData,'OTG_posterior')
            AllData.OTG_posterior = struct; %Contains the most recent model estimation
        end
        if type_trialno == 1 %On the first trial, set the posterior equal to the prior
            muPhi = AllData.OTG_prior.(typenames{choicetype}).muPhi; %"muPhi" contains the parameter estimates per cost bin
            AllData.OTG_posterior.(typenames{choicetype}).muPhi = muPhi; %Posterior of the last trial (here: set equal to prior)
            AllData.OTG_posterior.(typenames{choicetype}).all_muPhi(choicetrial,:) = muPhi; %History of posteriors for this choice type (here: set posterior parameter estimates from first trial of given choice type equal to prior)
            AllData.OTG_posterior.(typenames{choicetype}).P_indiff = Compute_P_indiff(grid,muPhi,OTG_settings); %Grid of the probability-of-indifference (computed in subfunction below)
        end
        
%% Sample and present a choice of the given choice type
    %Sample cost level of the costly option using P_indiff
        P_indiff = AllData.OTG_posterior.(typenames{choicetype}).P_indiff; %Grid with probability of indifference for each cost/reward combination
        PDF = sum(P_indiff); PDF = PDF/sum(PDF); %Make probability density function
        cost = sampleFromArbitraryP(PDF',grid.gridX(2:end)',1); %Sample a cost level (see subfunction below)
    %Compute the reward (at indifference) for the corresponding uncostly option
        costbin = find(cost>grid.binlimits(:,1) & cost<=grid.binlimits(:,2)); %get cost bin number
        muPhi = AllData.OTG_posterior.(typenames{choicetype}).muPhi{costbin}; %get the most recent estimate of parameter values
        if costbin == 1
            k = exp(muPhi(1)); %weight on cost
            bias = exp(muPhi(2)); %bias in favor of uncostly option (in bin 1, this is value is constrained to be positive)            
        else
            k = exp(muPhi(1)); %weight on cost
            bias = muPhi(2); %bias in favor of uncostly option (in all bins >1, this value can be positive or negative)
        end
        reward = 1 - k*cost - bias; %Reward for the uncostly option
        %Correct the presented reward if it is out of bounds:
            if reward > grid.rewardlimits(2)
                reward = grid.rewardlimits(2);
            elseif reward < grid.rewardlimits(1)
                reward = grid.rewardlimits(1);
            end
    %Present the choice, record decision
        if isfield(AllData,'sim') %Simulation
            %Compute option values
                SSRew = reward; %Reward for the uncostly option (sampled above)
                LLRew = 1; %Reward for the costly ("larger-later") option: 1 by default
                SSCost = 0; %Cost for the uncostly option: 0 by default
                LLCost = cost; %Cost for the costly option (sampled above)
                V1 = AllData.sim.kRew*SSRew - AllData.sim.kC*SSCost^AllData.sim.gamma + AllData.sim.bias; %Value of option 1 (uncostly option)
                V2 = AllData.sim.kRew*LLRew - AllData.sim.kC*LLCost^AllData.sim.gamma; %Value of option 2 (costly option)
                DV = AllData.sim.beta*(V1 - V2); %Decision value: (option 1) - (option 2)
            %Simulate the decision
                P_U = sigmoid(DV); %Probability of choosing the uncostly option (see sigmoid function below)
                y = sampleFromArbitraryP([P_U,1-P_U]',[1,0]',1); %Choice: uncostly option (1) or costly option (0)
            %Enter the simulated choice in trialinfo
                AllData.trialinfo(choicetrial).choicetype = choicetype; %numeric choicetype (1:4)
                AllData.trialinfo(choicetrial).SSReward = reward; %reward of the uncostly ("SS": smaller & sooner) option
                AllData.trialinfo(choicetrial).Cost = cost; %cost of the costly option
                AllData.trialinfo(choicetrial).choiceSS = y; %choice: 1 = uncostly (smaller&sooner) option; 0 = costly option
        else %Present the sampled choice to the participant on the BECHAMEL choice screen
            trialinput.choicetype = choicetype;
            trialinput.SSReward = reward;
            trialinput.Cost = cost;       
            [trialoutput,exitflag] = BEC_ShowChoice(window,exp_settings,trialinput);
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
    %Get history of choices for given choice type
        trialinfo = struct2table(AllData.trialinfo);
        u = [trialinfo.SSReward(trialinfo.choicetype==choicetype) trialinfo.Cost(trialinfo.choicetype==choicetype)]'; %[uncostly-option rewards; costly-option costs]
        y = trialinfo.choiceSS(trialinfo.choicetype==choicetype)'; %Choices       
        bins = NaN(1,size(u,2)); %Get cost bin numbers of the past trials
        for i = 1:length(bins)
            bins(i) = find(u(2,i)>grid.binlimits(:,1) & u(2,i)<=grid.binlimits(:,2));
        end
    %Do inversion of the model parameters of the selected costbin AFTER burn trials
        n = sum(bins==costbin); %number of trials in the cost bin
        if n > OTG_settings.burntrials % invert parameters after burn trials
            %Get priors
                mu0 = AllData.OTG_prior.(typenames{choicetype}).muPhi{costbin}; %prior estimates of the parameter values
                S0 = OTG_settings.priorvar; %prior variance of the parameter estimates
            %Get trial features of this bin
                X1 = [u(1,bins==costbin)' zeros(n,1) ones(n,1)]; %utility features of the uncostly option: [small reward, no cost, bias]
                X2 = [ones(n,1) u(2,bins==costbin)' zeros(n,1)]; %utility features of the uncostly option: [large reward, cost, no bias]
                y = y(bins==costbin);   
            %Restrict data for inversion to the most recent trials, according to a predefined recencry criterion
                if n > OTG_settings.maxperbin
                    n = OTG_settings.maxperbin;
                    X1 = X1(end-(n-1):end,:);
                    X2 = X2(end-(n-1):end,:);
                    y = y(end-(n-1):end);
                end
            %Run Gauss-Newton algorithm for the given bin 
                [mu,converged] = Run_GaussNewton(mu0, S0, X1, X2, n, y, costbin, OTG_settings);
                disp(['Trial ' num2str(choicetrial) ' -- Converged: ' num2str(converged)])
            %If the model converged:
                if converged
                    %Update parameter estimates for the selected cost bin
                        if mu(1) < log(OTG_settings.min_k)
                            mu(1) = log(OTG_settings.min_k);
                        end
                        AllData.OTG_posterior.(typenames{choicetype}).muPhi{costbin} = mu;
                    %Update the parameters of the neighboring bins
                        if ismember(costbin,2:grid.nbins) %update parameters of the previous bins
                            for i_bin = costbin:-1:2
                                %Current bin (i):
                                    mu_i = AllData.OTG_posterior.(typenames{choicetype}).muPhi{i_bin}; %Updated parameters
                                    C_i = grid.binlimits(i_bin,1); %Cost level of the bin lower limit
                                    R_i = 1 - exp(mu_i(1))*C_i - mu_i(2); %UPDATED indifference reward level at the lower limit
                                    %check out-of-bounds criterion
                                        if R_i > 0.99 - C_i * OTG_settings.min_k 
                                            R_i = 0.99 - C_i * OTG_settings.min_k; %Correct the maximum reward level
                                            R_UL = 1 - exp(mu_i(1))*grid.binlimits(i_bin,2) - mu_i(2); %Reward at the upper limit of this bin
                                            if R_UL >= R_i %check out-of-bounds criterion
                                                R_UL = 0.99 - grid.binlimits(i_bin,2) * OTG_settings.min_k; %Correct the maximum reward level
                                            end
                                            k_i = (R_i-R_UL)/diff(grid.binlimits(i_bin,:)); %Update slope
                                            b_i = 1 - k_i*C_i - R_i;
                                            %Store this bin's corrected parameters
                                                mu_i(1:2) = [log(k_i); b_i];
                                                AllData.OTG_posterior.(typenames{choicetype}).muPhi{i_bin} = mu_i;
                                        end
                                %Previous bin (j): update k and b based on the new value of R_i
                                    mu_j = AllData.OTG_posterior.(typenames{choicetype}).muPhi{i_bin-1};
                                    C_j = grid.binlimits(i_bin-1,1); %Cost level of the bin lower limit
                                    if i_bin == 2
                                        R_j = 1 - exp(mu_j(1))*C_j - exp(mu_j(2)); %Indifference reward level at the lower limit
                                    else
                                        R_j = 1 - exp(mu_j(1))*C_j - mu_j(2); %Indifference reward level at the lower limit
                                    end
                                    k_j = (R_j - R_i)/(C_i - C_j);
                                        if k_j < 0 %slope is upward
                                            k_j = OTG_settings.min_k; %correct slope of next bin to almost flat slope (not zero due to log)
                                            R_j = R_i + k_j*(C_i - C_j); %also correct next bin's upper limit reward level
                                        end
                                    b_j = 1 - k_j*C_j - R_j;
                                %Store previous bin's parameters
                                    if i_bin == 2
                                        mu_j(1:2) = [log(k_j); log(b_j)];
                                    else
                                        mu_j(1:2) = [log(k_j); b_j];
                                    end
                                    AllData.OTG_posterior.(typenames{choicetype}).muPhi{i_bin-1} = mu_j;
                            end
                        end                    
                        if ismember(costbin,1:grid.nbins-1) %update parameters of the next bins
                            for i_bin = costbin:grid.nbins-1
                                %Current bin (i):
                                    mu_i = AllData.OTG_posterior.(typenames{choicetype}).muPhi{i_bin}; %Updated parameters
                                    C_i = grid.binlimits(i_bin,2); %Cost level of the bin upper limit
                                    if i_bin == 1
                                        R_i = 1 - exp(mu_i(1))*C_i - exp(mu_i(2)); %UPDATED indifference reward level at the upper limit of the current bin
                                    else
                                        R_i = 1 - exp(mu_i(1))*C_i - mu_i(2); %UPDATED indifference reward level at the upper limit of the current bin
                                    end
                                %Next bin (j): update k and b based on the new value of R_i
                                    mu_j = AllData.OTG_posterior.(typenames{choicetype}).muPhi{i_bin+1};
                                    C_j = grid.binlimits(i_bin+1,2); %Cost level of the bin upper limit
                                    R_j = 1 - exp(mu_j(1))*C_j - mu_j(2); %Indifference reward level at the upper limit of the next bin
                                    k_j = (R_j-R_i)/(C_i-C_j); %Updated weight on cost
                                    if k_j < 0 %slope is upward
                                        k_j = OTG_settings.min_k; %correct slope of next bin to almost flat slope (not zero due to log)
                                        R_j = R_i - k_j*(C_j - C_i); %also correct next bin's upper limit reward level
                                    elseif k_j > 10 %Control that the values don't go crazy
                                        k_j = 10;
                                        R_j = R_i - k_j*(C_j - C_i);
                                    end
                                    b_j = 1 - k_j*C_j - R_j;
                                %Store next bin's parameters
                                    mu_j(1:2) = [log(k_j); b_j];
                                    AllData.OTG_posterior.(typenames{choicetype}).muPhi{i_bin+1} = mu_j;
                            end
                        end
                    %Record evolution of posteriors
                        AllData.OTG_posterior.(typenames{choicetype}).all_muPhi(choicetrial,:) = AllData.OTG_posterior.(typenames{choicetype}).muPhi;                    
                end %if converged
            %Compute the indifference grid (subfunction)
                P_indiff = Compute_P_indiff(grid,AllData.OTG_posterior.(typenames{choicetype}).muPhi,OTG_settings);
                AllData.OTG_posterior.(typenames{choicetype}).P_indiff = P_indiff;
        end 
    %Visualize (in the case of simulations)
        if isfield(AllData,'sim')
            BEC_Visualize_OTG(AllData,choicetrial)
        end
end %function

%% Subfunctions

function [choicetype] = SampleChoiceType(trialinfo,choicetrial,OTG_settings)
% Decide which choice type the next choice should be. There should be one occurrence of each of n
% choicetypes in every set of n trials, and two subsequent trials should not be of the same type.
% A choice type can have values: 1 (delay), 2 (risk), 3 (physical effort), or 4 (mental effort).
    ntypes = length(OTG_settings.choicetypes); %Number of different choice types
    all_choicetypes = [trialinfo.choicetype]; %History of presented choice types
    if choicetrial <= ntypes
        last_choicetypes = all_choicetypes; %The choices already sampled in the current set
    else
        i_last_choicetypes = floor(choicetrial/ntypes)*ntypes+1 : choicetrial; %Index of the choices since the last full set of n choices
        last_choicetypes = all_choicetypes(i_last_choicetypes); %The choices already sampled in the current set
    end
    previous_type = all_choicetypes(end); %The type of the previous choice (if the current choice is the first of a set, it may not sample a type that is the same as the last of a previous set)
    sample_types = setdiff(OTG_settings.choicetypes,[last_choicetypes previous_type]); %These are the choice types that may be sampled
    i_select = randperm(length(sample_types),1); %Randomly select one of the types that may be sampled
    choicetype = sample_types(i_select); %Sample the choice type - this is the output of the function    
end

function [AllData] = GetPriorEstimates(AllData,type_name,grid)
% Get prior estimates of the parameter values. They can either come from the calibration per choice
% type, or from the population average.
    if isfield(AllData,'calibration') && isfield(AllData.calibration,type_name)
        %Get priors from calibration
            %Parameter values
                AllData.OTG_prior.(type_name).muPhi = cell(1,grid.nbins); %Parameter estimates of each cost bin, to be filled in
                priors = AllData.calibration.(type_name).posterior; %from VBA
                options = AllData.calibration.(type_name).options; %from VBA
                for i_bin = 1:grid.nbins
                    %Get this bin's indifference line's three parameters
                        %Weight on cost
                            k = exp(priors.muPhi(options.inG.ind.bias+i_bin));
                        %Choice bias
                            if i_bin == 1 %In bin 1, the bias is predefined
                                bias = exp(priors.muPhi(options.inG.ind.bias));
                            else %In the other bins, the value of the bias is calculated
                                bias = 1 - k*C_i - R_i; %Note: C_i and R_i are defined below
                            end
                        %Store
                            if i_bin == 1
                                AllData.OTG_prior.(type_name).muPhi{i_bin} = [log(k); log(bias); log(OTG_settings.prior_beta)];
                            else
                                AllData.OTG_prior.(type_name).muPhi{i_bin} = [log(k); bias; log(OTG_settings.prior_beta)];
                            end
                    %Get the intersection point with the next bin
                        C_i = grid.binlimits(i_bin,2); %Cost level of the bin edge
                        R_i = 1 - k*C_i - bias; %Indifference reward level
                end
            %Indifference grid
                AllData.OTG_prior.(type_name).P_indiff = AllData.calibration.(type_name).P_indiff; %Grid of the probability-of-indifference
    else
        %Get priors from population average
            AllData.OTG_prior.(type_name).muPhi = [{[0 -5 log(5)]'} repmat({[0 0 log(5)]'},1,4)];
    end
end

function [mu,converged] = Run_GaussNewton(mu0, S0, X1, X2, n, y, costbin, OTG_settings)
    mu = mu0; %Start with prior estimates
    stop = 0; %This will stop the looping
    iter = 0; %Iteration count
    while ~stop
        %Check mu: if mu or exp(mu) have "weird" values (Inf, NaN, or irrational), then
            %the inversion has failed.
            if any(isinf([mu exp(mu)]) | isnan([mu exp(mu)]) | ~isreal([mu exp(mu)]))
                converged = 0; break
            end
        %First and second derivative of log posterior function:
            df = -pinv(S0)*(mu-mu0); % Gradient (first derivative) of log(p(b|y))
            df2 = -pinv(S0); % Hessian (second derivative) of log(p(b|y))
        %Decision value and its derivative
            if costbin == 1 %In cost bin 1, the bias term must be > 0;
                DV = (X1-X2)*(exp(mu(3))*[1; -exp(mu(1)); exp(mu(2))]); %Decision value
                dDV = [exp(mu(3))*exp(mu(1))*X2(:,2)';   %dDV/dk
                       exp(mu(3))*exp(mu(2))*ones(1,n);  %dDV/db0
                       exp(mu(3))*(X1(:,1)'-1 + exp(mu(1)).*X2(:,2)' + exp(mu(2)))]; %dDV/dbeta        
            else
                DV = (X1-X2)*(exp(mu(3))*[1; -exp(mu(1)); mu(2)]); %Decision value
                dDV = [exp(mu(3))*exp(mu(1))*X2(:,2)';   %dDV/dk
                       exp(mu(3))*mu(2)*ones(1,n);  %dDV/db0
                       exp(mu(3))*(X1(:,1)'-1 + exp(mu(1)).*X2(:,2)' + mu(2))]; %dDV/dbeta        
            end
        %Loop through trials
            for trl = 1:n % loop through choice trials
                P_C = sigmoid(DV(trl)); % p(y(i)=1|b=mu)
                df = df + (y(trl)-P_C)*dDV(:,trl);
                df2 = df2 - P_C*(1-P_C)*dDV(:,trl)*dDV(:,trl)';
            end
        %Gauss-Newton iteration        
            dmu = -pinv(df2)*df; % Gauss-Newton step
            grad = sum(abs(dmu./mu)); % for convergence criterion
            mu = mu + dmu; % Gauss-Newton update
            iter = iter+1;
        %Check convergence
            if grad <= 1e-2 % check convergence (arbitrary criterion)
                stop = 1; converged = 1; %success
            elseif iter > OTG_settings.max_iter % Maximum # of iterations exceeded
                stop = 1; converged = 0; %fail
            end
    end %while
end %function

function [P_indiff] = Compute_P_indiff(grid,muPhi,OTG_settings)
%Compute the probability-of-indifference "P_indiff" for the full sampling grid. At each point of the
%grid, there is a value that expresses the probability (between 0 and 1) that that point is at
%indifference. A point of the grid represents a combination between a cost of the costly option
%(X-axis) and a reward of the uncostly option (Y-axis).
% INPUT:    grid: the sampling grid
%           muPhi: the parameter estimates, for each bin    
    all_R1 = repmat(grid.gridY',1,grid.nbins*grid.bincostlevels); %All rewards in the grid
    all_cost = repmat(grid.gridX(2:end),grid.binrewardlevels,1); %All costs in the grid
    u_ind = [reshape(all_R1,[numel(all_R1) 1]) reshape(all_cost,[numel(all_cost) 1])]'; %Full grid, reshaped to two rows
    P_U = NaN(1,length(u_ind)); %Probability of choosing the uncostly option, to be calculated below
    for i_bin = 1:grid.nbins %Loop through cost bins
        i_u = u_ind(2,:)>grid.binlimits(i_bin,1) & u_ind(2,:)<=grid.binlimits(i_bin,2); %Indices of the grid points of the current bin
        if isa(muPhi,'cell')
            mu_i = muPhi{i_bin}; %Parameter estimates of the current bin
        else
            mu_i = muPhi(:,i_bin);
        end
        k = exp(mu_i(1)); %Weight on cost
        if i_bin == 1
            bias = exp(mu_i(2)); %Bias in favor of the uncostly option (constrained to be positive in bin 1)
        else
            bias = mu_i(2); %Bias in favor of the uncostly option
        end
        beta = OTG_settings.prior_beta; %Choice temperature
        DV = u_ind(1,i_u) + bias - 1 + k * u_ind(2,i_u); %Decision value: (option 1) - (option 2)
        P_U(i_u) = sigmoid(DV*beta); %P(choose uncostly)
    end
    P_indiff = (0.5-abs(P_U'-0.5))./0.5; %When P_U = 0.5, P_indiff = 1
    P_indiff = reshape(P_indiff,grid.binrewardlevels,grid.nbins*grid.bincostlevels); %Reshape P_indiff back to the original grid format
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
            X(i,:) = gridX(below(1),:);
        end
    end    
end