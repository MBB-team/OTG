%% BEC_Sim_PrePostTest
% Question: can a 10% increase in the weight on cost be detected?
%   - in all sets of parameters?
%   - after how many trials?
%   - both using model-based and model-free measures?
%   - only with OTG using informed priors, or also with a second ("naïve") calibration?

%Settings
    n_sims = 10; %Number of simulations of each parameter set (the number of "participants" -- to which power level does it correspond for an effect size of 10%?)
    n_trials = 50; %Max. number of trials to be simulated
    invert_model_trls = 15:5:n_trials; %Multisession model inversion: how many trials per session to include
    par_constraints = {'safepos','safepos','safepos','safepos','none'}; %[beta, kRew, kC, gamma, bias]: how to constrain each parameter in the model-based analysis
    i_par_compare = 3; %Index of the parameter that will be compared pre/post
    simresults = struct; %Output
    RH_ParallelComputing
%Simulation parameter values
    betas = [0.75 2.5 5 10 20]'; %Choice temperatures
    par = [2.5,0.50,0.20,3;12,1.5,0.33,1.5;0.75,4.5,0.10,0.50;1,2,0.050,3.5;0.75,0.10,0.25,5;2.5,0.50,0.050,5;5.5,0.30,0.10,6;8,2,0.10,3;4,1,0.15,2;1.5,2.5,0.050,1.5]; %Other parameter values (cf. infra)
    parvalues = repmat(array2table(par),length(betas),1); %Table of various indifference curves
    parvalues.beta = kron(betas,ones(size(par,1),1)); %Add different choice temperatures
%Loop through parameter sets
    parfor set = 1:size(parvalues,1)
        %Model-free and model-based measures of 
            fit_errors = cell(n_sims,3); %pre/post1/post2
            AUC = cell(n_sims,3); %pre/post1/post2
            delta_par1 = NaN(n_sims,length(invert_model_trls)); %delta1/delta2
            delta_par2 = NaN(n_sims,length(invert_model_trls)); %delta1/delta2
        for sim = 1:n_sims
            disp(['Set ' num2str(set) ' sim ' num2str(sim)])
            AllData = AllDataDefaults(n_trials);
            %Simulation parameter values
                AllData.sim.beta = parvalues.beta(set); %Choice temperature
                AllData.sim.kC = parvalues.par1(set); %Weight on cost
                AllData.sim.gamma = parvalues.par2(set); %Power on cost
                AllData.sim.bias = parvalues.par3(set); %Choice bias
                AllData.sim.kRew = parvalues.par4(set); %Weight on reward
            %PRE-TEST: calibration            
                AllData = Sim_Calibration(AllData);
                fit_errors{sim,1} = AllData.calibration.(AllData.exp_settings.trialgen_choice.typenames{1}).all_fit_errors;
                AUC{sim,1} = AllData.calibration.(AllData.exp_settings.trialgen_choice.typenames{1}).all_AUC;
                u_pre = AllData.calibration.(AllData.exp_settings.trialgen_choice.typenames{1}).u;
                y_pre = AllData.calibration.(AllData.exp_settings.trialgen_choice.typenames{1}).y;
            %POST-TEST
                %Update parameter value: kC + 10%
                    AllData.sim.kC = 1.1*AllData.sim.kC;
                %(Option 1) Get choice data from OTG
                    AllData.exp_settings.OTG.choicetypes = 1; %Define choice type (1: delay)
                    AllData.OTG_prior.delay.muPhi = AllData.calibration.(AllData.exp_settings.trialgen_choice.typenames{1}).posterior.muPhi;
                    all_fit_errors = NaN(1,n_trials);
                    all_AUC = NaN(1,n_trials);
                    for trial = 1:n_trials
                        AllData = BEC_OnlineTrialGeneration_VBA(AllData,[]);
                        [trl_fit_err,trl_AUC] = Compute_Error_And_AUC(AllData,AllData.OTG_posterior.(AllData.exp_settings.trialgen_choice.typenames{1}));
                        all_fit_errors(trial) = nanmean(trl_fit_err); %#ok<NANMEAN>
                        all_AUC(trial) = trl_AUC;
                    end
                    fit_errors(sim,2) = {all_fit_errors};
                    AUC(sim,2) = {all_AUC};
                    u_post_OTG = [[AllData.trialinfo.SSReward];[AllData.trialinfo.Cost]];
                    y_post_OTG = [AllData.trialinfo.choiceSS];
                    AllData = rmfield(AllData,'trialinfo');
                %(Option 2) Do a second calibration
                    AllData = Sim_Calibration(AllData);
                    fit_errors{sim,3} = AllData.calibration.(AllData.exp_settings.trialgen_choice.typenames{1}).all_fit_errors;
                    AUC{sim,3} = AllData.calibration.(AllData.exp_settings.trialgen_choice.typenames{1}).all_AUC;
                    u_post_cal = AllData.calibration.(AllData.exp_settings.trialgen_choice.typenames{1}).u;
                    y_post_cal = AllData.calibration.(AllData.exp_settings.trialgen_choice.typenames{1}).y;
                %Invert model in multisession analysis (Cf. model inversion from Clécy...)
                    for trls = 1:length(invert_model_trls)
                        %Option 1: Cal/OTG
                            y = [y_pre(1:invert_model_trls(trls)) y_post_OTG(1:invert_model_trls(trls))];
                            u = [u_pre(:,1:invert_model_trls(trls)) u_post_OTG(:,1:invert_model_trls(trls))];
                            [muPhi_pre,muPhi_post] = InvertModels(y,u,par_constraints);
                            delta_par1(sim,trls) = muPhi_post(i_par_compare)-muPhi_pre(i_par_compare);
                        %Option 2: Cal/Cal
                            y = [y_pre(1:invert_model_trls(trls)) y_post_cal(1:invert_model_trls(trls))];
                            u = [u_pre(:,1:invert_model_trls(trls)) u_post_cal(:,1:invert_model_trls(trls))];
                            [muPhi_pre,muPhi_post] = InvertModels(y,u,par_constraints);
                            delta_par2(sim,trls) = muPhi_post(i_par_compare)-muPhi_pre(i_par_compare);
                    end
        end %for sim
        %Store results
            simresults(set).fit_errors = fit_errors; %Compute difference in fit errors between [2] (calOTG) and [3] (calcal)
            simresults(set).AUC = AUC; %Compare AUC [2] and [3] to AUC [1]: can you detect a model-free difference? (after how many trials?)
            simresults(set).delta_par_calOTG = delta_par1; %Parameter difference between session 1 and 2: when does it become significant? [calOTG]
            simresults(set).delta_par_calcal = delta_par2; %Parameter difference between session 1 and 2: when does it become significant? [calcal]
    end %for set
    save('simresults','simresults')

%% Analysis
    %Cf supra, and:
    %Count the number of significant results across parameter settings (do separately for each choice temp)


%% Run calibration
function AllData = Sim_Calibration(AllData)
% Configuration
    exp_settings = AllData.exp_settings;
    burntrials = exp_settings.OTG.burntrials_cal; %Predefined "burn trials" (the first trials, for the model (and participant) to know the "boundaries"
    grid = exp_settings.OTG.grid; %Sampling grid 
    dim = exp_settings.OTG.dim; %Model dimensions (VBA)
    options = exp_settings.OTG.options; %Model options (VBA)
    calinfo.options = options; %output
    calinfo.grid = grid; %output
    all_R1 = repmat(grid.gridY',1,grid.nbins*grid.bincostlevels); %Sampling grid: all rewards
    all_cost = repmat(grid.gridX(2:end),grid.binrewardlevels,1); %Sampling grid: all costs
    u_ind = [reshape(all_R1,[numel(all_R1) 1]) reshape(all_cost,[numel(all_cost) 1])]'; %Full grid
% Loop through trials
    for trial = 1:exp_settings.OTG.ntrials_cal
        %Prepare the trial
            if trial <= size(burntrials,2) %First: burn trials
                reward = burntrials(1,trial);
                cost = burntrials(2,trial);
            else %Update after previous trial and sample new trial
                %Parameter values
                    if trial == 1
                        muPhi = options.priors.muPhi;
                    else
                        muPhi = calinfo.posterior.muPhi;
                    end
                %Update indifference estimates across cost bins
                    for i_bin = 1:grid.nbins
                        %Get this bin's indifference line's two parameters
                            %Weight on cost
                                k = exp(muPhi(options.inG.ind.bias+i_bin));                                
                            %Choice bias
                                R2 = 1; %(invariable)
                                if i_bin == 1; bias = exp(muPhi(options.inG.ind.bias));
                                else; bias = R2 - k*C_i - R_i;
                                end
                                calinfo.bin_bias(i_bin,trial) = bias;
                        %Get the intersection point with the next bin
                            C_i = grid.binlimits(i_bin,2); %Cost level of the bin edge
                            R_i = R2 - k*C_i - bias; %Indifference reward level
                    end
                %Compute the probability of being at indifference, scaled from zero to one
                    P_SS = Cal_ObservationFunction([],muPhi,u_ind,options.inG);
                    P_indiff = (0.5-abs(P_SS'-0.5))./0.5; 
                    calinfo.P_indiff = reshape(P_indiff,grid.binrewardlevels,grid.nbins*grid.bincostlevels);
                %Sample this upcoming trial's cost level
                    PDF = sum(calinfo.P_indiff);
                    PDF = PDF/sum(PDF);
                    cost = BEC_sampleFromArbitraryP(PDF',grid.gridX(2:end)',1);
                %Compute the selected cost level's reward (at indifference)
                    bin = find(cost>grid.binlimits(:,1) & cost<=grid.binlimits(:,2)); %equal-sized bins, all larger than zero.
                    reward = 1 - exp(muPhi(options.inG.ind.bias+bin))*cost - calinfo.bin_bias(bin,trial);
                    if reward > max(grid.gridY)
                        reward = max(grid.gridY);
                    elseif reward < min(grid.gridY)
                        reward = min(grid.gridY);
                    end
            end %burn trials or not
        %Compute option values for simulated decision-maker (using a different value function)
            SSRew = reward; %Reward for the uncostly option (sampled above)
            LLRew = 1; %Reward for the costly ("larger-later") option: 1 by default
            SSCost = 0; %Cost for the uncostly option: 0 by default
            LLCost = cost; %Cost for the costly option (sampled above)
            V1 = AllData.sim.kRew*SSRew - AllData.sim.kC*SSCost^AllData.sim.gamma + AllData.sim.bias; %Value of option 1 (uncostly option)
            V2 = AllData.sim.kRew*LLRew - AllData.sim.kC*LLCost^AllData.sim.gamma; %Value of option 2 (costly option)
            DV = AllData.sim.beta*(V1 - V2); %Decision value: (option 1) - (option 2)
        %Simulate the decision
            P_U = VBA_sigmoid(DV); %Probability of choosing the uncostly option
            y = BEC_sampleFromArbitraryP([P_U,1-P_U]',[1,0]',1); %Choice: uncostly option (1) or costly option (0)
        %Store selected trial
            calinfo.u(:,trial) = [reward; cost];
            calinfo.y(trial) = y;
        %Invert model with all inputs and choices
            dim.n_t = trial;
            posterior = VBA_NLStateSpaceModel(calinfo.y,calinfo.u,[],@Cal_ObservationFunction,dim,options);
            calinfo.muPhi(:,trial) = posterior.muPhi;
            calinfo.SigmaPhi(:,trial) = diag(posterior.SigmaPhi); 
            calinfo.posterior = posterior;        
        %Compute calibrated indifference curve and fitting error
            [fit_err,AUC] = Compute_Error_And_AUC(AllData,posterior);
            calinfo.all_fit_errors(trial) = nanmean(fit_err); %#ok<NANMEAN>
            calinfo.all_AUC(trial) = AUC;
    end %for trial  
    %Store "calinfo" in AllData
        AllData.calibration.(exp_settings.trialgen_choice.typenames{1}) = calinfo;
end %Sim_Calibration
    
%% Observation function for calibration
function [Z] = Cal_ObservationFunction(~,P,u,in)
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
    
%% Compute fitting error and AUC
function [fit_err,AUC] = Compute_Error_And_AUC(AllData,posterior)
% AllData is for "sim" and for "exp_settings"
% Posterior contains the currently fitted parameters using OTG.

%Compute "true" indifference curve
    X = AllData.exp_settings.OTG.grid.gridX(2:end);
    Y_true = (AllData.sim.kRew - AllData.sim.kC.*X.^AllData.sim.gamma - AllData.sim.bias)./AllData.sim.kRew;
%Compute fitted indifference curve and fitting error
    Y_ind = NaN(size(X));
    fit_err = NaN(size(X));
    AUC = 0;
    for i = 1:length(X)
        C = X(i); %Cost
        bin = find(C > AllData.exp_settings.OTG.grid.binlimits(:,1) & C <= AllData.exp_settings.OTG.grid.binlimits(:,2)); %Costbin
        k = exp(posterior.muPhi(1+bin)); %Weight on cost per bin
        if bin == 1
            b = exp(posterior.muPhi(1));
        else
            b = 1 - k.*C_i - R_i; %C_i and R_i obtained from previous bin, see below
        end
        C_i = AllData.exp_settings.OTG.grid.binlimits(bin,2); %Cost level of the bin edge
        R_i = 1 - k*C_i - b; %Indifference reward level at cost bin edge
        Y_ind(i) = 1 - k*C - b; %Indifference reward of the given cost level
        %Compute fitting error (only in positive domain)
            if Y_true(i)>0 
                fit_err(i) = abs(Y_ind(i)-Y_true(i))/Y_true(i);
            end
        %Compute area under the curve (only in positive domain)
            if Y_ind(i) > 0
                AUC = AUC + Y_ind(i)*(1/length(X));
            end
    end
end

function [muPhi_pre,muPhi_post] = InvertModels(y,u,par_constraints)
% par_constraints: how to constrain each parameter

% Input
    u = [u; 4*ones(1,length(y))]; %Invert choice type 4 - this was used for the simulations
% Inversion settings
    %Dimensions
        dim.n_theta = 0; % # evolution parameters
        dim.n = 0;       % # hidden states
        dim.p = 1;       % # output (data) dimension (# observations per time sample)          
        dim.n_phi = length(par_constraints);   % # of parameters to be fitted
        dim.n_t = length(y);   % # of time points
    %Options
        options.sources.type = 1;
        options.verbose = 0; 
        options.DisplayWin = 0; 
        options.inG.parameternames = {'beta','kRew','kME','gammaME','biasME'};
        options.inG.constraints = par_constraints; 
        options.priors.SigmaPhi = 10*eye(dim.n_phi);
        options.priors.muPhi = [ones(4,1); 0];
        options.inG.P0 = options.priors.muPhi;
        options.multisession.split = [length(y)/2 length(y)/2]; %pre/post
        options.multisession.fixed.phi = 4:5; %fixed pre/post  
% Invert
    posterior = VBA_NLStateSpaceModel(y,u,[],@ObservationFunction,dim,options);
    posterior_muPhi = cell(1,2);
    for prepost = 1:2
        muPhi = posterior.perSession(prepost).muPhi;
        for i_par = 1:length(muPhi)
            if strcmp(options.inG.constraints(i_par),'safepos')
                muPhi(i_par) = Safepos(muPhi(i_par));
            elseif strcmp(options.inG.constraints(i_par),'exponential')
                muPhi(i_par) = exp(muPhi(i_par));
            end
        end
        posterior_muPhi{prepost} = muPhi';
    end
    muPhi_pre = posterior_muPhi{1};
    muPhi_post = posterior_muPhi{2};
end %function

%% Observation function for model-based analysis
function [Z] = ObservationFunction(~,P,u,in)
%  For the inversion of delay and mental effort discounting data
%  Inputs:
%       P: vector of parameters
%       u: Experimental design inputs (choice options 1 and 2; choice type)
%       in: any extra relevant information

%Parameters
    par = struct;
    for i_par = 1:length(in.parameternames)
        switch in.constraints{i_par}
            case 'none'
                par.(in.parameternames{i_par}) = P(i_par);
            case 'safepos'
                par.(in.parameternames{i_par}) = Safepos(P(i_par));
            case 'exponential'
                par.(in.parameternames{i_par}) = exp(P(i_par));
            case 'fixed'
                par.(in.parameternames{i_par}) = in.P0(i_par);
        end
    end
    
%Loop through choices
    Z = NaN(size(u,2),1);   %Probability of chosing (uncostly) option 1
    for i = 1:length(Z)
        %Inputs (u)
            R1 = u(1,i); %Reward for uncostly option 1
            R2 = 1; %Reward for costly option 2
            C = u(2,i); %Cost of costly option 2
            type = u(3,i); %Choice type
        %Get basic parameters: weights on cost and reward, choice temperature, and bias
            k_Reward = par.kRew;
            beta = par.beta;
            switch type
                case 1 %Delay
                    k_Cost = par.kD;
                    bias = par.biasD;  
                    gamma = par.gammaD;
                case 4 %Mental effort
                    k_Cost = par.kME;
                    bias = par.biasME;
                    gamma = par.gammaME;
            end                                        
        %Compute decision values per choice type
            if type == 1 %Delay
                V2 = k_Reward .* R2 .* exp(-k_Cost .* C .^ gamma);
            elseif type == 4 %Mental Effort
                V2 = k_Reward .* R2 - k_Cost .* C .^ gamma; 
            end
        %Compute probability of chosing option 1 (uncostly option)
            V1 = k_Reward .* R1;
            DV = V1 - V2; %Decision value
            Z(i) = 1./(1 + exp( -(bias + beta.*DV) ) );
    end %for i
end %function
    
%% Safepos
function [y1,y2] = Safepos(x)
% This function produces a close approximation of the absolute value of input x, without the
% nonlinearity around zero.
% RLH - June 2019

%smoothness parameter
    k = 10;     
    
%approximate absolute value
    y1 = log(1 + exp(k .* x)) ./ k;
    
%compute the original value of x if input is y1
    y2 = log(exp(k .* x) - 1) ./ k;
    
end

%% Data structure defaults
function AllData = AllDataDefaults(n_trials)
    AllData = struct;
    AllData.exp_settings = BEC_Settings;
    AllData.sim.visualize = 0;
    AllData.triallist.choicetypes = ones(n_trials,1);
    AllData.exp_settings.OTG.ntrials_cal = n_trials;
    AllData.exp_settings.options.priors.SigmaPhi = AllData.exp_settings.OTG.prior_var_cal*eye(AllData.exp_settings.OTG.dim.n_phi); %Prior for parameter variance: 2
    AllData.exp_settings.options.priors.muPhi(1) = AllData.exp_settings.OTG.prior_bias_cal; %Prior for choice bias: -3
    AllData.exp_settings.options.priors.muPhi(2:AllData.exp_settings.OTG.dim.n_phi,1) = log(1/diff(AllData.exp_settings.OTG.grid.rewardlimits)); %Priors for weights on cost: ~0
end