function [AllData,exitflag] = BEC_OnlineTrialGeneration(exp_settings,window,AllData,trial)
%     Inputs:
%       exp_settings: experiment settings structure
%       window: PsychToolbox window
%       AllData.trialinfo: history of choices
%       AllData.OTG_posterior: posterior from the previous inversion
%       AllData.OTG_prior: prior from the choice calibration
%       choicetype: 1, 2, 3, or 4
SIMULATE = 0;

%% Sample and present a choice of the given choice type
    %Settings
        typenames = exp_settings.trialgen_choice.typenames;
        choicetype = AllData.triallist.choicetypes(trial);
        type_trialno = sum(AllData.triallist.choicetypes(1:trial)==choicetype);
    %Define sampling grid
        grid = exp_settings.ATG.grid;
        grid.binlimits = grid.costlimits(1) + ([0:grid.nbins-1;1:grid.nbins])'  * (grid.costlimits(2)-grid.costlimits(1))/grid.nbins;
        grid.gridY = grid.rewardlimits(1):(grid.rewardlimits(2)-grid.rewardlimits(1))/(grid.binrewardlevels-1):grid.rewardlimits(2);
        grid.gridX = grid.costlimits(1):(grid.costlimits(2)-grid.costlimits(1))/(grid.bincostlevels*grid.nbins):grid.costlimits(2);
    %First trial of the given choice type: make OTG structures
        if type_trialno == 1
            %Priors from calibration
                AllData.OTG_prior.(typenames{choicetype}).muPhi = cell(1,grid.nbins);
                priors = AllData.(['calibration_' typenames{choicetype}]).posterior; %from VBA
                options = AllData.(['calibration_' typenames{choicetype}]).options; %from VBA
                for i_bin = 1:grid.nbins
                    %Get this bin's indifference line's three parameters
                        %Weight on cost
                            k = exp(priors.muPhi(options.inG.ind.bias+i_bin));
                        %Choice bias
                            if i_bin == 1; bias = exp(priors.muPhi(options.inG.ind.bias));
                            else; bias = 1 - k*C_i - R_i;
                            end
                        %Store
                            if i_bin == 1
                                AllData.OTG_prior.(typenames{choicetype}).muPhi{i_bin} = [log(k); log(bias); log(exp_settings.ATG.fixed_beta)];
                            else
                                AllData.OTG_prior.(typenames{choicetype}).muPhi{i_bin} = [log(k); bias; log(exp_settings.ATG.fixed_beta)];
                            end
                    %Get the intersection point with the next bin
                        C_i = grid.binlimits(i_bin,2); %Cost level of the bin edge
                        R_i = 1 - k*C_i - bias; %Indifference reward level
                end
            %Posterior: set equal to prior (for first trial)
                AllData.OTG_posterior.(typenames{choicetype}).muPhi = AllData.OTG_prior.(typenames{choicetype}).muPhi;
                AllData.OTG_posterior.(typenames{choicetype}).all_muPhi = cell(sum(AllData.triallist.choicetypes==choicetype),grid.nbins);
                    AllData.OTG_posterior.(typenames{choicetype}).all_muPhi(1,:) = AllData.OTG_prior.(typenames{choicetype}).muPhi;
                AllData.OTG_posterior.(typenames{choicetype}).P_indiff = AllData.(['calibration_' typenames{choicetype}]).P_indiff;
        end
    %Sample cost level
        P_indiff = AllData.OTG_posterior.(typenames{choicetype}).P_indiff; %Grid with probability of indifference for each cost/reward combination
        PDF = sum(P_indiff); PDF = PDF/sum(PDF); %Make probability density function
        cost = sampleFromArbitraryP(PDF',grid.gridX(2:end)',1); %Sample a cost level
    %Compute the selected cost level's reward (at indifference)
        costbin = find(cost>grid.binlimits(:,1) & cost<=grid.binlimits(:,2)); %get cost bin number
        muPhi = AllData.OTG_posterior.(typenames{choicetype}).muPhi{costbin};
        if costbin == 1
            reward = 1 - exp(muPhi(1))*cost - exp(muPhi(2));
        else
            reward = 1 - exp(muPhi(1))*cost - muPhi(2);
        end
        if reward > max(grid.gridY)
            reward = max(grid.gridY);
        elseif reward < min(grid.gridY)
            reward = min(grid.gridY);
        end
    %Present the choice, record decision
        if SIMULATE
            mu0 = AllData.OTG_prior.(typenames{choicetype}).muPhi{costbin};
            k = exp(mu0(1));
            if costbin == 1
                b0 = exp(mu0(2));
            else
                b0 = mu0(2);
            end
            beta = exp(mu0(3));
            DV = reward + b0 - 1 + k * cost;
            P_SS = sig(DV*beta);     
            AllData.trialinfo(trial).choicetype = choicetype;
            AllData.trialinfo(trial).SSReward = reward;
            AllData.trialinfo(trial).Cost = cost;
            AllData.trialinfo(trial).choiceSS = sampleFromArbitraryP([P_SS,1-P_SS]',[1,0]',1);
        else
            trialinput.choicetype = choicetype;
            trialinput.SSReward = reward;
            trialinput.Cost = cost;       
            [trialoutput,exitflag] = BEC_ShowChoice(window,exp_settings,trialinput);
            AllData.trialinfo(trial).choicetype = trialoutput.choicetype;
            AllData.trialinfo(trial).SSReward = trialoutput.SSReward;
            AllData.trialinfo(trial).Cost = trialoutput.Cost;
            AllData.trialinfo(trial).SideSS = trialoutput.SideSS;
            AllData.trialinfo(trial).ITI = trialoutput.ITI;
            AllData.trialinfo(trial).choiceSS = trialoutput.choiceSS;
            AllData.trialinfo(trial).RT = trialoutput.RT;
            AllData.trialinfo(trial).LLReward = trialoutput.LLReward;
            AllData.trialinfo(trial).Choicetype = trialoutput.Choicetype;
            AllData.trialinfo(trial).Delay = trialoutput.Delay;
            AllData.trialinfo(trial).Risk = trialoutput.Risk;
            AllData.trialinfo(trial).PhysicalEffort = trialoutput.PhysicalEffort;
            AllData.trialinfo(trial).MentalEffort = trialoutput.MentalEffort;
            AllData.trialinfo(trial).Loss = trialoutput.Loss;
            AllData.trialinfo(trial).timestamp = trialoutput.timestamp;
            if exitflag; return; end
        end
        
%% Update parameter estimates
    %Get history of choices for given choice type
        trialinfo = struct2table(AllData.trialinfo);
        u = [trialinfo.SSReward(trialinfo.choicetype==choicetype) trialinfo.Cost(trialinfo.choicetype==choicetype)]'; %[SSRewards; LLCosts]
        y = trialinfo.choiceSS(trialinfo.choicetype==choicetype)'; %Choices       
        bins = NaN(1,size(u,2)); %Get cost bin numbers
        for i = 1:length(bins)
            bins(i) = find(u(2,i)>grid.binlimits(:,1) & u(2,i)<=grid.binlimits(:,2));
        end
    %Do inversion of the model parameters of the selected costbin AFTER burn trials
        n = sum(bins==costbin); %number of trials in the cost bin
        if n > exp_settings.ATG.online_burntrials % invert parameters after burn trials
            %Get priors
                mu0 = AllData.OTG_prior.(typenames{choicetype}).muPhi{costbin}; %log of the parameter value
                S0 = exp_settings.ATG.online_priorvar; %prior variance of the parameter estimates
            %Get trial features of this bin
                X1 = [u(1,bins==costbin)' zeros(n,1) ones(n,1)]; %utility features of the uncostly option: [small reward, no cost, bias]
                X2 = [ones(n,1) u(2,bins==costbin)' zeros(n,1)]; %utility features of the uncostly option: [large reward, cost, no bias]
                y = y(bins==costbin);   
            %Restrict the inversion to the most recent trials
                if n > exp_settings.ATG.online_maxperbin
                    X1 = X1(end-(exp_settings.ATG.online_maxperbin-1):end,:);
                    X2 = X2(end-(exp_settings.ATG.online_maxperbin-1):end,:);
                    y = y(end-(exp_settings.ATG.online_maxperbin-1):end);
                    n = exp_settings.ATG.online_maxperbin;
                end
%-----------%Run Gauss-Newton algorithm for the given bin -------------------------------------------------------------
                mu = mu0; %Start with prior estimates
                stop = 0; %This will stop the looping
                iter = 0; %Iteration count
                while ~stop
                    %Check mu
                        if isweird(mu) || isweird(exp(mu))
                            converged = 0; break
                        end
                    %First and second derivative of log posterior function:
                        df = -pinv(S0)*(mu-mu0); % gradient of log(p(b|y))
                        df2 = -pinv(S0); % Hessian of log(p(b|y))
                    %Value funtion:
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
                        for i=1:n % loop over trials
                            P_C = sig(DV(i)); % p(y(i)=1|b=mu)
                            df = df + (y(i)-P_C)*dDV(:,i);
                            df2 = df2 - P_C*(1-P_C)*dDV(:,i)*dDV(:,i)';
                        end
                    %Gauss-Newton iteration        
                        dmu = -pinv(df2)*df; % Gauss-Newton step
                        grad = sum(abs(dmu./mu)); % convergence criterion
                        mu = mu + dmu; % Gauss-Newton update
                        iter = iter+1;
                    %Check convergence
                        if grad <= 1e-2 % check convergence
                            stop = 1; converged = 1;
                        elseif iter > exp_settings.ATG.online_max_iter
                            stop = 1; converged = 0;
                        end
                end %while
%---------------------------------------------------------------------------------------------------
            disp(['Trial ' num2str(trial) ' -- Converged: ' num2str(converged)])
            %If the model converged:
                if converged
                    %Update parameter estimates for the selected cost bin
                        if mu(1) < log(exp_settings.ATG.online_min_k)
                            mu(1) = log(exp_settings.ATG.online_min_k);
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
                                        if R_i > 0.99 - C_i * exp_settings.ATG.online_min_k 
                                            R_i = 0.99 - C_i * exp_settings.ATG.online_min_k; %Correct the maximum reward level
                                            R_UL = 1 - exp(mu_i(1))*grid.binlimits(i_bin,2) - mu_i(2); %Reward at the upper limit of this bin
                                            if R_UL >= R_i %check out-of-bounds criterion
                                                R_UL = 0.99 - grid.binlimits(i_bin,2) * exp_settings.ATG.online_min_k; %Correct the maximum reward level
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
                                            k_j = exp_settings.ATG.online_min_k; %correct slope of next bin to almost flat slope (not zero due to log)
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
                                        k_j = exp_settings.ATG.online_min_k; %correct slope of next bin to almost flat slope (not zero due to log)
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
                        AllData.OTG_posterior.(typenames{choicetype}).all_muPhi(trial,:) = AllData.OTG_posterior.(typenames{choicetype}).muPhi;                    
                end
            %Compute the indifference grid
                all_R1 = repmat(grid.gridY',1,grid.nbins*grid.bincostlevels); %All rewards
                all_cost = repmat(grid.gridX(2:end),grid.binrewardlevels,1); %All costs
                u_ind = [reshape(all_R1,[numel(all_R1) 1]) reshape(all_cost,[numel(all_cost) 1])]'; %Full grid
                P_SS = NaN(1,length(u_ind));
                for i_bin = 1:grid.nbins
                    i_u = u_ind(2,:)>grid.binlimits(i_bin,1) & u_ind(2,:)<=grid.binlimits(i_bin,2);
                    mu_i = AllData.OTG_posterior.(typenames{choicetype}).muPhi{i_bin};
                    k = exp(mu_i(1));
                    if i_bin == 1
                        b0 = exp(mu_i(2));
                    else
                        b0 = mu_i(2);
                    end
                    beta = exp_settings.ATG.fixed_beta;
                    DV = u_ind(1,i_u) + b0 - 1 + k * u_ind(2,i_u);
                    P_SS(i_u) = sig(DV*beta);
                    %Visualize
                        if SIMULATE
                            figure(1); subplot(1,2,1); hold on
%                             %True model
%                                 X = linspace(grid.binlimits(i_bin,1),grid.binlimits(i_bin,2),12);
%                                 Y = 1 - k*X - bias;
%                                 plot(X,Y,'k:')
%                                 axis([0,1,0,1])
                            %Estimated curves
                                X = linspace(grid.binlimits(i_bin,1),grid.binlimits(i_bin,2),12);
                                Y = 1 - k*X - b0;
                                plot(X,Y,'r')
                                scatter(X2(:,2),X1(:,1),20,y,'filled')
                                axis([0,1,0,1])
                        end
                end
                P_indiff = (0.5-abs(P_SS'-0.5))./0.5; 
                AllData.OTG_posterior.(typenames{choicetype}).P_indiff = reshape(P_indiff,grid.binrewardlevels,grid.nbins*grid.bincostlevels);
                %Visualize
                    if SIMULATE
                        figure(1); subplot(1,2,2); cla
                        p_indf = reshape(P_indiff,grid.binrewardlevels,grid.nbins*grid.bincostlevels);
                        Im = imagesc(grid.gridX([2 end]),grid.gridY([1 end]),p_indf);
                        Im.AlphaData = 0.75;
                        set(gca,'YDir','normal')
                        colorbar; caxis([0 1]); %Somehow this removes the im from the rest of the bins.
                        axis([grid.costlimits grid.rewardlimits])
                    end
        end %if not burntrials
        
end %function
