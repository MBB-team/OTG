% This function is part of the OTG toolbox, used for generating and presenting a battery of economic choices.
% It visualizes of online trial generation, per trial. This function is made such that it is compatible both with simulations of the OTG, as well 
% as with datasets of results that are acquired experimentally.

function BEC_Visualize_OTG(AllData,choicetrial)

% Settings
    OTG_settings = AllData.exp_settings.OTG;
    grid = OTG_settings.grid;
    hf = gcf; %Setup figure "hf" if not already open

%% Get data
    %Information about all trials, and this trial in particular
        try %for compatibility with Octave
            trialinfo = struct2table(AllData.trialinfo,'AsArray',true);
        catch
            trialinfo = struct;
            listField = fieldnames(AllData.trialinfo);
            for iField = 1:length(listField)
             trialinfo.(listField{iField}) = [AllData.trialinfo.(listField{iField})]';
            end
        end
        choicetype = trialinfo.choicetype(choicetrial); %current trial's choice type
        trials_choicetype = find(trialinfo.choicetype(1:choicetrial)==choicetype); %all trials up to current one of the current choice type
        type_trialno = find(trials_choicetype==choicetrial); %trial number of the current choice type
    %Get parameter estimates of the current trial
        all_muPhi = AllData.OTG_posterior.(OTG_settings.typenames{choicetype}).all_muPhi;
        muPhi = all_muPhi(:,type_trialno);
        if ~all(isnan(muPhi))
            converged = 1;
        else %find the last inverted parameter values
            converged = 0;
            muPhi = AllData.OTG_posterior.(OTG_settings.typenames{choicetype}).muPhi;
        end

%% Estimated indifference
    %Plot P_indiff
        P_indiff = Compute_P_indiff(muPhi,OTG_settings);
        ha1 = subplot(2,2,1,'parent',hf); cla; hold on
        Im = imagesc(ha1,grid.gridX([2 end]),grid.gridY([1 end]),P_indiff);
        try %for compatibility with Octabe
            Im.AlphaData = 0.75;
        catch
            set(Im, 'alphadata', 0.75)
        end
        c = colorbar; caxis([0 1]); ylabel(c,'P(indifference)')
    %Get prior estimates and overlay
        prior_muPhi = AllData.OTG_prior.(OTG_settings.typenames{choicetype}).muPhi;
        X = NaN(1,grid.bincostlevels*grid.nbins);
        Y = X; Y0 = X;
        for bin = 1:grid.nbins
            k = exp(muPhi(1+bin));
            k0 = exp(prior_muPhi(1+bin));
            if bin == 1
                b = exp(muPhi(1));
                b0 = exp(prior_muPhi(1));
            else
                b = 1 - k.*C_i - R_i; %C_i and R_i obtained from previous bin, see below
                b0 = 1 - k0.*C_i - R_i0; %C_i0 and R_i0 obtained from previous bin, see below
            end
            C_i = OTG_settings.grid.binlimits(bin,2); %Cost level of the bin edge
            R_i = 1 - k*C_i - b; %Indifference reward level at cost bin edge
            R_i0 = 1 - k0*C_i - b0; %Indifference reward level at cost bin edge
            X_bin = linspace(grid.binlimits(bin,1),grid.binlimits(bin,2),grid.bincostlevels);
                X((bin-1)*grid.bincostlevels+(1:grid.bincostlevels)) = X_bin;
            Y_bin = 1 - k.*X_bin - b;
                Y((bin-1)*grid.bincostlevels+(1:grid.bincostlevels)) = Y_bin;
            Y0_bin = 1 - k0.*X_bin - b0;
                Y0((bin-1)*grid.bincostlevels+(1:grid.bincostlevels)) = Y0_bin;
        end
        plot(ha1,X,Y,'k:','LineWidth',1.5);
        plot(ha1,X,Y0,':','color',[0.5 0.5 0.5],'LineWidth',1.5)
    %Plot simulated choice function, if present
        if isfield(AllData,'sim')
            try
                plot(ha1,grid.gridX,AllData.sim.indiff_curve,'r:','Linewidth',1.5);
            catch %for compatibility with previous versions
                indiff_curve = (AllData.sim.kRew - AllData.sim.kC.*grid.gridX.^AllData.sim.gamma - AllData.sim.bias)./AllData.sim.kRew;
                plot(ha1,grid.gridX,indiff_curve,'r:','Linewidth',1.5); 
            end
            legend({'Fitted','Prior','Simulated'},'Orientation','horizontal','Location','southoutside')
        else
            legend({'Fitted','Prior'})
        end
    %Figure layout
        axis([0 1 0 1])
        title(['Indifference curve   [TRIAL #' num2str(type_trialno) ']'])
        xlabel('LL Cost'); ylabel('SS Reward')

%% Choice history
    %Show recent choice history and current fitted model
        ha2 = subplot(2,2,2,'parent',hf); cla; hold on
        try %#ok<TRYNC>
            L = legend; delete(L); %This is a bit of a hack but it prevents legend entries to be filled in while looping through bins
        end
        %Show rectangle to indicate if the algorithm converted on the current trial
            current_bin = find(trialinfo.Cost(choicetrial)>grid.binlimits(:,1) & trialinfo.Cost(choicetrial)<=grid.binlimits(:,2));
            if type_trialno <= OTG_settings.burntrials
                burntrials = true;
            else
                burntrials = false;
            end
            if burntrials
                rectangle('Position',[grid.binlimits(current_bin,1) 0 1/grid.nbins 1],'EdgeColor',[0.5 0.5 0.5])
                title('Recent choices and current model [BURN TRIALS]')
            elseif converged
                rectangle('Position',[grid.binlimits(current_bin,1) 0 1/grid.nbins 1],'EdgeColor','g')
                title('Recent choices and current model [CONVERGED]')
            else
                rectangle('Position',[grid.binlimits(current_bin,1) 0 1/grid.nbins 1],'EdgeColor','r')
                title('Recent choices and current model [FAILED]')
            end
        %Restrict data to most recent trials (simulations)
            if type_trialno > OTG_settings.max_n_inv %Correct the selection of choices for this bin
                trials_choicetype = trials_choicetype(type_trialno-OTG_settings.max_n_inv+1:type_trialno);
            end
        %Loop through bins
            for bin = 1:grid.nbins
                %Get choices per bin
                    i_bin = find(trialinfo.Cost>grid.binlimits(bin,1) & trialinfo.Cost<=grid.binlimits(bin,2)); %Indices of choices belonging to selected bin
                    bin_costs = trialinfo.Cost(intersect(trials_choicetype,i_bin));
                    bin_rewards = trialinfo.SSReward(intersect(trials_choicetype,i_bin));
                    bin_choices = trialinfo.choiceSS(intersect(trials_choicetype,i_bin));
                %Scatter choices
                    scatter(ha2,bin_costs(bin_choices==1),bin_rewards(bin_choices==1),30,'r','filled');
                    scatter(ha2,bin_costs(bin_choices==0),bin_rewards(bin_choices==0),30,'b','filled');
                %Plot estimated indifference curve of current bin
                    k = exp(muPhi(bin+1));
                    if bin == 1; b = exp(muPhi(1));
                    else; b = 1 - k.*C_i - R_i; %C_i and R_i obtained from previous bin, see below
                    end
                    C_i = OTG_settings.grid.binlimits(bin,2); %Cost level of the bin edge
                    R_i = 1 - k*C_i - b; %Indifference reward level at cost bin edge
                    X_bin = linspace(grid.binlimits(bin,1),grid.binlimits(bin,2),grid.bincostlevels);
                    Y_fit = 1 - k.*X_bin - b;
                    plot(ha2,X_bin,Y_fit,'color','k'); %,'LineWidth',1.5);
            end
        %Figure layout
            xlabel('LL Cost'); ylabel('SS Reward')
            axis([0 1 0 1])
            legend({'SS choices','LL choices','fitted'},'Location','southoutside','Orientation','Horizontal')
        %Draw now
            drawnow
end

function [P_indiff] = Compute_P_indiff(muPhi,OTG_settings)
%Compute the probability-of-indifference "P_indiff" for the full sampling grid.
    grid = OTG_settings.grid;
    all_R1 = repmat(grid.gridY',1,grid.nbins*grid.bincostlevels); %All rewards in the grid
    all_cost = repmat(grid.gridX(2:end),grid.binrewardlevels,1); %All costs in the grid
    u_ind = [reshape(all_R1,[numel(all_R1) 1]) reshape(all_cost,[numel(all_cost) 1])]'; %Full grid, reshaped to two rows
    P_U = NaN(1,length(u_ind)); %Probability of choosing the uncostly option, to be calculated below
    for bin = 1:grid.nbins %Loop through cost bins
        i_bin = u_ind(2,:)>grid.binlimits(bin,1) & u_ind(2,:)<=grid.binlimits(bin,2); %Indices of the grid points of the current bin
        k = exp(muPhi(1+bin));
        if bin == 1; b = exp(muPhi(1));
        else; b = 1 - k.*C_i - R_i; %C_i and R_i obtained from previous bin, see below
        end
        C_i = OTG_settings.grid.binlimits(bin,2); %Cost level of the bin edge
        R_i = 1 - k*C_i - b; %Indifference reward level at cost bin edge
        beta = OTG_settings.fixed_beta; %Choice temperature
        DV = u_ind(1,i_bin) + b - 1 + k * u_ind(2,i_bin); %Decision value: (option 1) - (option 2)
        try
            P_U(i_bin) = VBA_sigmoid(DV*beta); %P(choose uncostly)
        catch %for compatibility with older versions of VBA
            P_U(i_bin) = sigmoid(DV*beta); %P(choose uncostly)
        end
    end
    P_indiff = (0.5-abs(P_U'-0.5))./0.5; %When P_U = 0.5, P_indiff = 1
    P_indiff = reshape(P_indiff,grid.binrewardlevels,grid.nbins*grid.bincostlevels); %Reshape P_indiff back to the original grid format
end
