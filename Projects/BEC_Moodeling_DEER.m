function [AllData] = BEC_Moodeling_DEER(AllData)
% Experiment script for smartphone application of the Online Trial Generation algorithm of BECHAMEL-type economic choices involving 4 types (DEER):
% Delay / Effort (physical) / Effort (mental) / Risk.
% 
% This function is to be called every day. On "day 0", no "AllData" needs to be specified as input - the dataset will be created and the calibration 
% will be done. From then on, the function needs to be called with "AllData" as input. It will sample the choices that will need to be done every day.
% 
% Written April 2022

%% Settings
% Note, this section is only called when no dataset exists yet for this participant.
    if ~exist('AllData','var')
        %No "AllData" variable is specified: create a dataset
            AllData = struct;
        %Get Online Trial Generation (OTG) settings
            OTG_settings = Get_OTG_Settings;
            AllData.exp_settings.OTG = OTG_settings; %Default sampling settings
        %Set priors for inversion
            for type = OTG_settings.choicetypes
                AllData.OTG_prior.(OTG_settings.typenames{type}).muPhi = [-3; log(0.99)*ones(OTG_settings.grid.nbins,1)];
            end
        %Model posterior
            AllData.OTG_posterior = struct; %Contains the most recent model estimation
            %Set equal to prior at the first iteration
                for type = OTG_settings.choicetypes
                    muPhi = AllData.OTG_prior.(OTG_settings.typenames{type}).muPhi; %"muPhi" contains the parameter estimates
                    AllData.OTG_posterior.(OTG_settings.typenames{type}).muPhi = muPhi; %Posterior of the last trial (here: set equal to prior)
                    AllData.OTG_posterior.(OTG_settings.typenames{type}).all_muPhi(:,1) = muPhi; %History of posteriors for this choice type (here: set posterior parameter estimates from first trial of given choice type equal to prior)
                    AllData.OTG_posterior.(OTG_settings.typenames{type}).P_indiff = Compute_P_indiff(muPhi,OTG_settings); %Grid of the probability-of-indifference (computed in subfunction below)
                end
        %trialinfo: history of choices (empty structure at first trial)
            AllData.trialinfo.choicetype = [];
            AllData.trialinfo.Cost = [];
            AllData.trialinfo.SSReward = [];
            AllData.trialinfo.choiceSS = [];
            AllData.trialinfo.RT = [];
        %triallist: sample the calibration trials            
            AllData.triallist.choicetypes = kron(OTG_settings.choicetypes(randperm(length(OTG_settings.choicetypes)))',ones(OTG_settings.n_calibration_trials,1));
    end
        
%% Part 1: Sample choice trials (costs and rewards)
% Note, this section is different depending on whether a calibration is done ("day 0") or whether a daily set of choices is presented (day 1 onwards)
    trialinput = struct; % this structure is to be filled in and contains the data to be passed on to the smartphone
    choicetrial = length(AllData.trialinfo.choiceSS) + 1; % the number of the choice to be generated
    typenames = AllData.exp_settings.OTG.typenames;
    % CALIBRATION
        total_calibration_trials = length(AllData.exp_settings.OTG.choicetypes)*AllData.exp_settings.OTG.n_calibration_trials;
        if choicetrial <= total_calibration_trials
            %Current trial features
                choicetype = AllData.triallist.choicetypes(choicetrial);
                all_choicetypes = AllData.triallist.choicetypes(1:choicetrial);
                type_trialno = sum(all_choicetypes==choicetype);
            %Sample 1 cost level of the costly option using P_indiff
                cost = SampleCost(AllData,choicetype);
            %Sample 1 reward of the uncostly option, based on the indifference value and the sampled cost
                reward = SampleReward(AllData,choicetype,cost);
                %When the algorithm does not converge: adjust the reward away from indifference
                    if ~AllData.exp_settings.OTG.use_VBA && type_trialno > AllData.exp_settings.OTG.burntrials && ...
                            AllData.OTG_posterior.(typenames{choicetype}).converged(end) == 0
                            reward = Adjust_Reward(AllData,reward,cost,choicetype);
                    end
            %Fill in trial input
                trialinput.choicetype = choicetype;
                trialinput.SSReward = reward;
                trialinput.Cost = cost;      
                trialinput.sideSS = round(rand);
    % DAILY FOLLOW-UP
        else
            % 1. Sample today's choice types: blocked, but in a random order
                today_choicetypes = kron(AllData.exp_settings.OTG.choicetypes(randperm(length(AllData.exp_settings.OTG.choicetypes)))',ones(AllData.exp_settings.OTG.n_daily_trials,1));
                AllData.triallist.choicetypes = [AllData.triallist.choicetypes; today_choicetypes]; %Add to triallist
            % 2. Loop through today's trials
                costs = NaN(size(today_choicetypes));
                rewards = NaN(size(today_choicetypes));
                for trial = 1:length(today_choicetypes)
                    %Current trial features
                        i_trl = choicetrial + trial - 1;
                        choicetype = AllData.triallist.choicetypes(i_trl);
                        all_choicetypes = [AllData.triallist.choicetypes];
                        all_choicetypes = all_choicetypes(1:i_trl);
                        type_trialno = sum(all_choicetypes==choicetype);
                    %Sample cost (and resample if for a given choice type, the same cost is sampled more than once)
                        costs(trial) = SampleCost(AllData,choicetype);
                        type_costs = costs(today_choicetypes==choicetype & (1:length(today_choicetypes))'<=trial);
                        while length(unique(type_costs)) ~= length(type_costs)
                            costs(trial) = SampleCost(AllData,choicetype);
                        end
                    %Calculate reward
                        rewards(trial) = SampleReward(AllData,choicetype,costs(trial));
                        %When the algorithm does not converge: adjust the reward away from indifference
                            if ~AllData.exp_settings.OTG.use_VBA && type_trialno > AllData.exp_settings.OTG.burntrials && ...
                                    AllData.OTG_posterior.(typenames{choicetype}).converged(end) == 0
                                    rewards(trial) = Adjust_Reward(AllData,rewards(trial),costs(trial),choicetype);
                            end                    
                end
            % 3. Fill in trial input
                trialinput.choicetype = today_choicetypes;
                trialinput.SSReward = rewards;
                trialinput.Cost = costs;      
                trialinput.sideSS = round(rand(size(today_choicetypes)));
        end

%% Part 2: Present choice(s)
% Note: this section is done on the smartphone. The input "trialinput" is sent to the smartphone; the choices and reponse times are recorded.
    choiceSS = NaN(length(trialinput.choicetype),1);
    RT = NaN(length(trialinput.choicetype),1);
    for trial = 1:length(trialinput.choicetype)
        tic; 
        clc
        disp(['No ' typenames{trialinput.choicetype(trial)} ' for ' num2str(round(trialinput.SSReward(trial)*30,2)) ' EUR [press 1]'])
        disp('OR')
        disp([num2str(round(trialinput.Cost(trial)*100,1)) '% ' typenames{trialinput.choicetype(trial)} ' for 30 EUR [press 0]'])
        choiceSS(trial) = input('Enter 0 or 1: ');
        RT(trial) = toc;
    end
    
% Record trial data (received from smartphone)
    AllData.trialinfo.choicetype = [AllData.trialinfo.choicetype; trialinput.choicetype];
    AllData.trialinfo.Cost = [AllData.trialinfo.Cost; trialinput.Cost];
    AllData.trialinfo.SSReward = [AllData.trialinfo.SSReward; trialinput.SSReward];
    AllData.trialinfo.choiceSS = [AllData.trialinfo.choiceSS; choiceSS];
    AllData.trialinfo.RT = [AllData.trialinfo.RT; RT];    
    
%% Part 3: Update the model(s)
    %Settings
        choicetrial = length(AllData.trialinfo.choiceSS); %Number of the last choice trial;
        total_calibration_trials = length(AllData.exp_settings.OTG.choicetypes)*AllData.exp_settings.OTG.n_calibration_trials;
        typenames = AllData.exp_settings.OTG.typenames;
        if choicetrial <= total_calibration_trials % CALIBRATION: update only the current choice type's model
            update_choicetypes = AllData.trialinfo.choicetype(end);
        else % DAILY FOLLOW-UP: update all choice types' models
            update_choicetypes = AllData.exp_settings.OTG.choicetypes;
        end
    %Loop through choice types
    for type = update_choicetypes        
        type_trialno = sum(AllData.trialinfo.choicetype==type); %trial number for given choice type
        %Get input to the algorithm: SS rewards, LL costs, choices
            [u,y,n] = GetTrialFeatures(AllData,type);
        %Get inversion priors
            mu0 = AllData.OTG_prior.(typenames{type}).muPhi; %prior estimates of the parameter values
            S0 = AllData.exp_settings.OTG.priorvar; %prior variance of the parameter estimates
        %Invert the model
            if AllData.exp_settings.OTG.use_VBA %Use VBA to invert the model (recommended)
                %Settings
                    options = AllData.exp_settings.OTG.options;
                    options.priors.muPhi = mu0;
                    options.priors.SigmaPhi = S0;
                    dim = AllData.exp_settings.OTG.dim;
                    dim.n_t = n;
                %Run inversion routine
                    posterior = VBA_NLStateSpaceModel(y,u,[],@ObservationFunction,dim,options);
                %Store
                    AllData.OTG_posterior.(typenames{type}).muPhi = posterior.muPhi;
                    AllData.OTG_posterior.(typenames{type}).all_muPhi(:,type_trialno) = posterior.muPhi;
                    AllData.OTG_posterior.(typenames{type}).all_SigmaPhi(:,type_trialno) = diag(posterior.SigmaPhi);
                    AllData.OTG_posterior.(typenames{type}).P_indiff = Compute_P_indiff(posterior.muPhi,AllData.exp_settings.OTG); %Grid of the probability-of-indifference (computed in subfunction below)
            else %Run Gauss-Newton algorithm (non-VBA)
                %Run inversion routine
                    [mu,converged] = Run_GaussNewton(mu0, S0, u, y, AllData.exp_settings.OTG);
                %Store
                    AllData.OTG_posterior.(typenames{type}).converged(type_trialno) = converged;
                    if converged && type_trialno > AllData.exp_settings.OTG.burntrials
                        AllData.OTG_posterior.(typenames{type}).muPhi = mu;
                        AllData.OTG_posterior.(typenames{type}).all_muPhi(:,type_trialno) = mu;
                        AllData.OTG_posterior.(typenames{type}).P_indiff = Compute_P_indiff(mu,AllData.exp_settings.OTG); %Grid of the probability-of-indifference (computed in subfunction below)
                    else
                        if type_trialno > 1 %At trial 1, the posteriors in all_muPhi have the value of the priors.
                            AllData.OTG_posterior.(typenames{type}).all_muPhi(:,choicetrial) = NaN(size(mu));
                        end
                    end  
            end %if use VBA
    end %for type
end %function
    
%% Subfunctions

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
            df = -pinv(S0)*(mu-mu0); % Gradient (first derivative) of log(p(b|y))
            df2 = -pinv(S0); % Hessian (second derivative) of log(p(b|y))
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
            end
    end %while
end %function

function [u,y,n] = GetTrialFeatures(AllData,choicetype)
% Get trial features that will be entered into the model inversion algorithm
% Get trial history from given choice type
    u = [AllData.trialinfo.SSReward(AllData.trialinfo.choicetype==choicetype)'; %uncostly-option rewards;
         AllData.trialinfo.Cost(AllData.trialinfo.choicetype==choicetype)']; %costly-option costs
    y = AllData.trialinfo.choiceSS(AllData.trialinfo.choicetype==choicetype)'; %choices
    n = sum(AllData.trialinfo.choicetype==choicetype);
%Restrict data for inversion to the most recent trials, according to a predefined recency criterion
    if n > AllData.exp_settings.OTG.max_n_inv
        n = AllData.exp_settings.OTG.max_n_inv;
        u = u(:,end-(n-1):end);
        y = y(end-(n-1):end);
    end
end

function [cost] = SampleCost(AllData,choicetype)
    %Settings
        typenames = AllData.exp_settings.OTG.typenames;
        grid = AllData.exp_settings.OTG.grid;
    %Grid with probability of indifference for each cost/reward combination
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

function OTG_settings = Get_OTG_Settings
% Get Online Trial Generation settings. Modify according to the needs of your experiment.
    %Choice types
        OTG_settings.choicetypes = [1 2 3 4];
        OTG_settings.typenames = {'delay','risk','physical_effort','mental_effort'};
    %Choice sampling settings
        OTG_settings.n_calibration_trials = 21; %Number of calibration trials per choice type
        OTG_settings.n_daily_trials = 3;        %Number of daily trials per choice type
        OTG_settings.use_VBA = true;            %If false, use the non-VBA Bayesian Gauss-Newton algorithm instead
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
        OTG_settings.fixed_beta = 5;       % Assume this fixed value for the inverse choice temperature (based on past results) to improve model fit.
        OTG_settings.priorvar = 2*eye(OTG_settings.grid.nbins+1);   % Prior variance for each parameter
    %Gauss-Newton algorithm settings:
        OTG_settings.burntrials = 1;        % # of trials that must have been sampled before inverting the model (minimum: 1)
        OTG_settings.max_iter = 200;        % Max. # of iterations, after which we conclude the algorithm does not converge
        OTG_settings.max_n_inv = 21;        % Max. # of trials entered in model inversion algorithm
        OTG_settings.conv_crit = 1e-2;      % Max. # of iterations for the model inversion algorithm, after which it is forced to stop
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
end