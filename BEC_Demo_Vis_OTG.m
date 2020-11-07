% Demo: visualize G-N online trial generation

%Settings
    clear all; clc
    load('C:\Users\Roeland\Documents\MATLAB\Experiment data\Pilot 11 Incidental Moods\MD_20201019T175114\AllData.mat')
    close all; figure
    choicetype = 1;
    typenames = {'delay'};
    exp_settings = BEC_Settings;
%Define sampling grid
    grid = exp_settings.ATG.grid;
    grid.binlimits = grid.costlimits(1) + ([0:grid.nbins-1;1:grid.nbins])'  * (grid.costlimits(2)-grid.costlimits(1))/grid.nbins;
    grid.gridY = grid.rewardlimits(1):(grid.rewardlimits(2)-grid.rewardlimits(1))/(grid.binrewardlevels-1):grid.rewardlimits(2);
    grid.gridX = grid.costlimits(1):(grid.costlimits(2)-grid.costlimits(1))/(grid.bincostlevels*grid.nbins):grid.costlimits(2);
    all_R1 = repmat(grid.gridY',1,grid.nbins*grid.bincostlevels); %All rewards
    all_cost = repmat(grid.gridX(2:end),grid.binrewardlevels,1); %All costs
    u_ind = [reshape(all_R1,[numel(all_R1) 1]) reshape(all_cost,[numel(all_cost) 1])]'; %Full grid
%Get data
    trialinfo = struct2table(AllData.trialinfo);
    trials = sum(trialinfo.choicetype==choicetype);
    posterior = AllData.OTG_posterior.(typenames{choicetype}).all_muPhi(1,:);
    all_muPhi = AllData.OTG_posterior.(typenames{choicetype}).all_muPhi(trialinfo.choicetype==choicetype,:);
    
%%
%Loop through trials
for trial = 1:trials
    subplot(1,2,1); cla; hold on
    %Get data up to trial
        u = [trialinfo.SSReward(trialinfo.choicetype==choicetype) trialinfo.Cost(trialinfo.choicetype==choicetype)]'; %[SSRewards; LLCosts]
        all_y = trialinfo.choiceSS(trialinfo.choicetype==choicetype)'; %Choices       
        bins = NaN(1,size(u,2)); %Get cost bin numbers
        for i = 1:length(bins)
            bins(i) = find(u(2,i)>grid.binlimits(:,1) & u(2,i)<=grid.binlimits(:,2));
        end
        u = u(:,1:trial);
        all_y = all_y(1:trial);
        bins = bins(1:trial);
        P_SS = NaN(1,length(u_ind));
    %Get indifference estimations
        if ~isempty(all_muPhi{trial,1})
            posterior = all_muPhi(trial,:);
        end
    %Loop through bins
        for i_bin = 1:grid.nbins
            %Get bin data
                n = sum(bins==i_bin); %number of trials in the cost bin
                X1 = [u(1,bins==i_bin)' zeros(n,1) ones(n,1)]; %utility features of the uncostly option: [small reward, no cost, bias]
                X2 = [ones(n,1) u(2,bins==i_bin)' zeros(n,1)]; %utility features of the uncostly option: [large reward, cost, no bias]
                y = all_y(bins==i_bin);
                if n > exp_settings.ATG.online_maxperbin
                    X1 = X1(end-(exp_settings.ATG.online_maxperbin-1):end,:);
                    X2 = X2(end-(exp_settings.ATG.online_maxperbin-1):end,:);
                    y = y(end-(exp_settings.ATG.online_maxperbin-1):end);
                    n = exp_settings.ATG.online_maxperbin;
                end
            %Get bin parameters
                mu_i = posterior{i_bin};
                k = exp(mu_i(1));
                if i_bin == 1
                    b0 = exp(mu_i(2));
                else
                    b0 = mu_i(2);
                end           
            %Compute indifference
                beta = exp_settings.ATG.fixed_beta;
                i_u = u_ind(2,:)>grid.binlimits(i_bin,1) & u_ind(2,:)<=grid.binlimits(i_bin,2);
                DV = u_ind(1,i_u) + b0 - 1 + k * u_ind(2,i_u);
                P_SS(i_u) = sig(DV*beta);
            %Estimated curves
                X = linspace(grid.binlimits(i_bin,1),grid.binlimits(i_bin,2),12);
                Y = 1 - k*X - b0;
                plot(X,Y,'r')
                scatter(X2(y==1,2),X1(y==1,1),20,'r','filled')
                scatter(X2(y==0,2),X1(y==0,1),20,'b','filled')
                axis([0,1,0,1])
        end
    %Indifference grid        
        subplot(1,2,2); cla
        P_indiff = (0.5-abs(P_SS'-0.5))./0.5; 
        p_indf = reshape(P_indiff,grid.binrewardlevels,grid.nbins*grid.bincostlevels);
        Im = imagesc(grid.gridX([2 end]),grid.gridY([1 end]),p_indf);
        Im.AlphaData = 0.75;
        set(gca,'YDir','normal')
        colorbar; caxis([0 1]); %Somehow this removes the im from the rest of the bins.
        axis([grid.costlimits grid.rewardlimits])
    %Pause
        pause(0.5)
end