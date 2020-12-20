function BEC_Visualize_OTG(AllData,choicetrial)
% Visualization of online trial generation, per trial

% Settings
    try OTG_settings = AllData.exp_settings.OTG;
    catch; OTG_settings = GetDefaultSettings;
    end
    grid = OTG_settings.grid;
    hf = gcf; %Setup figure "hf" if not already open
        
% Get data
    %Get data trialinfo
        all_choices = [AllData.trialinfo.choiceSS]';
        all_costs = [AllData.trialinfo.Cost]';
        all_rewards = [AllData.trialinfo.SSReward]';
        all_choicetypes = [AllData.trialinfo.choicetype]';
    %Get choicetypes, costs, rewards, and choices of all trials of the given choice type, up to and including the current trial
        choicetype = all_choicetypes(choicetrial);
        trials_choicetype = find(all_choicetypes==choicetype);
            trials_choicetype = trials_choicetype(trials_choicetype<=choicetrial)';
        type_trialno = find(trials_choicetype==choicetrial);
        costs_choicetype = all_costs(all_choicetypes==choicetype);
            costs_choicetype = costs_choicetype(1:length(trials_choicetype)); 
        rewards_choicetype = all_rewards(all_choicetypes==choicetype);
            rewards_choicetype = rewards_choicetype(1:length(trials_choicetype)); 
        choices_choicetype = all_choices(all_choicetypes==choicetype); 
            choices_choicetype = choices_choicetype(1:length(trials_choicetype));
    %Get parameter estimates of the current trial
        all_muPhi = AllData.OTG_posterior.(OTG_settings.typenames{choicetype}).all_muPhi;
        try
            muPhi = cell2mat(all_muPhi(choicetrial,:));
        catch
            muPhi = [];
        end
        if ~isempty(muPhi)
            converged = 1;
        else %find the last inverted parameter values
            converged = 0;
            for trl = trials_choicetype(end:-1:1)
                try
                    muPhi = cell2mat(all_muPhi(trl,:));
                catch
                    muPhi = [];
                end
                if ~isempty(muPhi); break; end
            end
            if isempty(muPhi)
                muPhi = cell2mat(all_muPhi(1,:)); %Hack due to a bug in S11 (pilot study Oct. 2020)
            end
        end
        
% Plot
    %Plot P_indiff
        P_indiff = Compute_P_indiff(OTG_settings.grid,muPhi,OTG_settings);
        ha1 = subplot(2,2,1,'parent',hf); cla; hold on
        Im = imagesc(ha1,grid.gridX([2 end]),grid.gridY([1 end]),P_indiff);
        Im.AlphaData = 0.75;
        colorbar; caxis([0 1]); 
    %Get prior estimates and overlay
        prior_muPhi = AllData.OTG_prior.(OTG_settings.typenames{choicetype}).muPhi;
        for bin = 1:grid.nbins
            mu0 = prior_muPhi{bin};
            k0 = exp(mu0(1));
            if bin == 1; b0 = exp(mu0(2));
            else; b0 = mu0(2);
            end
            X_bin = linspace(grid.binlimits(bin,1),grid.binlimits(bin,2),grid.bincostlevels);
            Y_fit = 1 - k0.*X_bin - b0;
            plot(ha1,X_bin,Y_fit,'k:','LineWidth',1.5);
        end
    %Plot simulated choice function, if present
        if isfield(AllData,'sim')
            LLCost = linspace(0,1);
            V2 = AllData.sim.kRew - AllData.sim.kC.*LLCost.^AllData.sim.gamma; %Value of option 2 (costly option)
            sim_indiff = (V2 - AllData.sim.bias)./AllData.sim.kRew;
            plot(ha1,LLCost,sim_indiff,'r:','Linewidth',1.5);
        end
    %Figure layout
        axis([0 1 0 1])
        title(['Prior and P(indiff)' '    [TRIAL #' num2str(type_trialno) ']'])
        xlabel('LL Cost'); ylabel('SS Reward')
    %Show recent choice history and current fitted model
        ha2 = subplot(2,2,2,'parent',hf); cla; hold on
        %Show rectangle to indicate if the algorithm converted on the current trial
            current_bin = find(all_costs(choicetrial)>grid.binlimits(:,1) & all_costs(choicetrial)<=grid.binlimits(:,2));
            trls_current_bin = sum(costs_choicetype>grid.binlimits(current_bin,1) & costs_choicetype<=grid.binlimits(current_bin,2)); %Number of trials belonging to selected bin
            if trls_current_bin <= OTG_settings.burntrials
                rectangle('Position',[grid.binlimits(current_bin,1) 0 1/grid.nbins 1],'EdgeColor',[0.5 0.5 0.5])
                title('Recent choices and current model [BURN TRIALS]')
            elseif converged
                rectangle('Position',[grid.binlimits(current_bin,1) 0 1/grid.nbins 1],'EdgeColor','g')
                title('Recent choices and current model [CONVERGED]')
            else
                rectangle('Position',[grid.binlimits(current_bin,1) 0 1/grid.nbins 1],'EdgeColor','r')
                title('Recent choices and current model [FAILED]')
            end
        %Loop through bins
            for bin = 1:grid.nbins
                %Get choices per bin
                    i_choices = find(costs_choicetype>grid.binlimits(bin,1) & costs_choicetype<=grid.binlimits(bin,2)); %Indices of choices belonging to selected bin
                    if length(i_choices)>OTG_settings.maxperbin %Correct the selection of choices for this bin
                        i_choices = i_choices(end-OTG_settings.maxperbin+1:end); %Get the most recent choices of this bin only (apply recency criterion from settings)
                    end
                    bin_costs = costs_choicetype(i_choices);
                    bin_rewards = rewards_choicetype(i_choices);
                    bin_choices = choices_choicetype(i_choices);
                %Scatter choices
                    scatter(ha2,bin_costs(bin_choices==1),bin_rewards(bin_choices==1),30,'r','filled');
                    scatter(ha2,bin_costs(bin_choices==0),bin_rewards(bin_choices==0),30,'b','filled');
                %Plot estimated indifference curve of current bin
                    k = exp(muPhi(1,bin));
                    if bin == 1
                        bias = exp(muPhi(2,bin));
                    else
                        bias = muPhi(2,bin);
                    end
                    X_bin = linspace(grid.binlimits(bin,1),grid.binlimits(bin,2),grid.bincostlevels);
                    Y_fit = 1 - k.*X_bin - bias;
                    plot(ha2,X_bin,Y_fit,'color','k'); %,'LineWidth',1.5);
                %Figre layout
                    xlabel('LL Cost'); ylabel('SS Reward')
                    axis([0 1 0 1])
            end
        
    %Fitted parameters per cost bin
%         for bin = 1:grid.nbins
%             ha3 = subplot(4,grid.nbins,3*grid.nbins+bin,'parent',hf); hold on
%             Y1 = muPhi_k(bin,:); X = 1:length(Y1); %Discount factor
%                 E1 = SigmaPhi_k(bin,:);
%                 hp1 = patch(ha3,[X X(end:-1:1)], [Y1+E1 Y1(end:-1:1)-E1(end:-1:1)], [0.2 0.2 0.6], 'facealpha', 0.2, 'Edgecolor', 'none');
%                 set(get(get(hp1,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
%                 plot(ha3, X, Y1, 'linestyle', '-', 'LineWidth', 1, 'color', [0.2 0.2 0.6]);
%             Y2 = all_bias(bin,:);
%                 if bin == 1 %This is the only "real" bias that is inverted
%                     E2 = SigmaPhi_bias;
%                     hp2 = patch(ha3,[X X(end:-1:1)], [Y2+E2 Y2(end:-1:1)-E2(end:-1:1)], [0.6 0 0], 'facealpha', 0.2, 'Edgecolor', 'none');
%                     set(get(get(hp2,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
%                 end
%                 plot(ha3, X, Y2, 'linestyle', '-', 'LineWidth', 1, 'color', [0.6 0 0]);
%             %Figure layout
% %                 legend({'k','bias','k','bias'},'Location','northoutside','Orientation','horizontal')
% %                 title('Parameter estimates'); 
%                 if bin == 1; ylabel('Parameter estimates'); end
%                 xlabel('Trials');
%         end

end

function [OTG_settings] = GetDefaultSettings
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
end

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
        elseif isa(muPhi,'double')
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