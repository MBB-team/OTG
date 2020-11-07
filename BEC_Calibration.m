function [trialinfo,exitflag] = BEC_Calibration(exp_settings,choicetype,window,save_figure)
% Calibrate choice preferences using an online trial generation and parameter estimation procedure.
% RLH - Update: October 2020
% Note: entirely coded for 5 cost bins

%% Configuration
    ntrials = exp_settings.ATG.ntrials;        
    [options,dim,grid] = GetDefaultSettings(exp_settings); %NB: options are updated each trial
    inv_options = options; %options for parameter estimation only (invariable)!
    trialinfo.options = options;
    trialinfo.grid = grid;
    all_R1 = repmat(grid.gridY',1,grid.nbins*grid.bincostlevels); %All rewards
    all_cost = repmat(grid.gridX(2:end),grid.binrewardlevels,1); %All costs
    u_ind = [reshape(all_R1,[numel(all_R1) 1]) reshape(all_cost,[numel(all_cost) 1])]'; %Full grid
        
%% Loop through trials
    for trial = 1:ntrials           
        %Prepare the trial
            if trial <= size(grid.burntrials,2) %First: burn trials
                reward = grid.burntrials(1,trial);
                cost = grid.burntrials(2,trial);
            else %Update after previous trial and sample new trial
                %Priors (after first trial)
                    if trial > 1
                        options.priors = trialinfo.posterior;
                    end
                %Update indifference estimates across cost bins
                    for i_bin = 1:grid.nbins
                        %Get this bin's indifference line's two parameters
                            %Weight on cost
                                k = exp(options.priors.muPhi(options.inG.ind.bias+i_bin));                                
                            %Choice bias
                                R2 = 1; %(invariable)
                                if i_bin == 1; bias = exp(options.priors.muPhi(options.inG.ind.bias));
                                else; bias = R2 - k*C_i - R_i;
                                end
                                trialinfo.bin_bias(i_bin,trial) = bias;
                        %Get the intersection point with the next bin
                            C_i = grid.binlimits(i_bin,2); %Cost level of the bin edge
                            R_i = R2 - k*C_i - bias; %Indifference reward level
                    end
                %Compute the probability of being at indifference, scaled from zero to one
                    P_SS = ObservationFunction([],options.priors.muPhi,u_ind,options.inG);
                    P_indiff = (0.5-abs(P_SS'-0.5))./0.5; 
                    trialinfo.P_indiff = reshape(P_indiff,grid.binrewardlevels,grid.nbins*grid.bincostlevels);
                %Sample this upcoming trial's cost level
                    PDF = sum(trialinfo.P_indiff);
                    PDF = PDF/sum(PDF);
                    cost = sampleFromArbitraryP(PDF',grid.gridX(2:end)',1);
                %Compute the selected cost level's reward (at indifference)
                    bin = find(cost>grid.binlimits(:,1) & cost<=grid.binlimits(:,2)); %equal-sized bins, all larger than zero.
                    reward = 1 - exp(options.priors.muPhi(options.inG.ind.bias+bin))*cost - trialinfo.bin_bias(bin,trial);
                    if reward > max(grid.gridY)
                        reward = max(grid.gridY);
                    elseif reward < min(grid.gridY)
                        reward = min(grid.gridY);
                    end
            end %burn trials or not
        %Present the choice, record decision
            trialinput.choicetype = choicetype;
            trialinput.SSReward = reward;
            trialinput.Cost = cost;       
            [trialoutput,exitflag] = BEC_ShowChoice(window,exp_settings,trialinput);
            if exitflag; return; end
        %Store selected trial
            trialinfo.u(:,trial) = [reward; cost];
            trialinfo.y(trial) = trialoutput.choiceSS;
        %Invert model with all inputs and choices
            dim.n_t = trial;
            posterior = VBA_NLStateSpaceModel(trialinfo.y,trialinfo.u,[],@ObservationFunction,dim,inv_options);
            trialinfo.muPhi(:,trial) = posterior.muPhi;
            trialinfo.SigmaPhi(:,trial) = diag(posterior.SigmaPhi); 
            trialinfo.posterior = posterior;
    end %for trial     
    %Output: the probability of being at indifference, scaled from zero to one
        P_SS = ObservationFunction([],posterior.muPhi,u_ind,options.inG);
        P_indiff = (0.5-abs(P_SS'-0.5))./0.5; 
        trialinfo.P_indiff = reshape(P_indiff,grid.binrewardlevels,grid.nbins*grid.bincostlevels);
    %Visualize calibration process and save figure
        if exist('save_figure','var') && ~isempty(save_figure)
            set(0,'DefaultFigureVisible','off');
            hf = CalibrationFigure(trialinfo,grid);
            F = getframe(hf);
            Im = frame2im(F);
            filename = ['Calibration_' exp_settings.trialgen_choice.typenames{choicetype}];
            imwrite(Im,[save_figure filesep filename '.png'])
            close
            set(0,'DefaultFigureVisible','on');
        end

end %function

%% Subfunction: Get default settings
function [options,dim,grid] = GetDefaultSettings(exp_settings)
    %Get sampling grid
        grid = exp_settings.ATG.grid;
    %Dimensions
        dim.n_theta = 0;
        dim.n = 0;
        dim.p = 1;    
        dim.n_phi = 6;
    %Options
        options.binomial = 1;
        options.verbose = 0;
        options.DisplayWin = 0;
        options.inG.ind.bias = 1;
        options.inG.ind.k1 = 2;
        options.inG.ind.k2 = 3;
        options.inG.ind.k3 = 4;
        options.inG.ind.k4 = 5;
        options.inG.ind.k5 = 6;
        options.inG.beta = exp_settings.ATG.fixed_beta; %Assume this (fixed) value for inverse choice temperature
        options.priors.SigmaPhi = exp_settings.ATG.prior_var*eye(dim.n_phi);
        options.priors.muPhi(1) = exp_settings.ATG.prior_bias; %Prior for choice bias
        options.priors.muPhi(2:dim.n_phi) = log(1/diff(grid.rewardlimits)); %Priors for weights on cost
    %Sampling grid
        grid.binlimits = grid.costlimits(1) + ([0:grid.nbins-1;1:grid.nbins])'  * (grid.costlimits(2)-grid.costlimits(1))/grid.nbins;
        grid.gridY = grid.rewardlimits(1):(grid.rewardlimits(2)-grid.rewardlimits(1))/(grid.binrewardlevels-1):grid.rewardlimits(2);
        grid.gridX = grid.costlimits(1):(grid.costlimits(2)-grid.costlimits(1))/(grid.bincostlevels*grid.nbins):grid.costlimits(2);
        grid.burntrials = [59/60  0     55/60  2/30;
                           46/50  5/50  1      1/50]; 
        options.inG.grid = grid; %Store in options structure too
end

%% Subfunction: Observation function
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

%% Subfunction: Make and update figure
function [hf] = CalibrationFigure(trialinfo,grid)
    %Setup figure
        hf = figure('color',[1 1 1],'units','normalized','outerposition',[0 0 1 1]); % set(hf,'Position',[100 300 1500 700]);       
    %Parameter values
        muPhi_k = exp(trialinfo.muPhi(2:end,:));
%         SigmaPhi_k = trialinfo.SigmaPhi(2:end,:);
        all_bias = trialinfo.bin_bias;
%         SigmaPhi_bias = trialinfo.SigmaPhi(1,:);
    %Generated trials and probability of indifference
        ha1 = subplot(3,grid.nbins,1:3*grid.nbins,'parent',hf); hold on
        %P(indifference)
            Im = imagesc(ha1,grid.gridX([2 end]),grid.gridY([1 end]),trialinfo.P_indiff);
            Im.AlphaData = 0.75;
            colorbar; caxis([0 1]); %Somehow this removes the im from the rest of the bins.
        %Choices
            scatter(ha1,trialinfo.u(2,trialinfo.y==1),trialinfo.u(1,trialinfo.y==1),40,'r','filled');
            scatter(ha1,trialinfo.u(2,trialinfo.y==0),trialinfo.u(1,trialinfo.y==0),40,'b','filled');
        %Plot estimated indifference lines
            for bin = 1:grid.nbins
                X_bin = linspace(grid.binlimits(bin,1),grid.binlimits(bin,2),grid.bincostlevels);
                Y_fit = 1 - muPhi_k(bin,end-1).*X_bin - all_bias(bin,end);
                plot(ha1,X_bin,Y_fit,'k:','LineWidth',1.5);
            end
        %Plot layout
            axis(ha1,[grid.costlimits grid.rewardlimits])
            title(ha1,'Generated trials & P(indifference)')
            ylabel(ha1,'SS Reward')
            xlabel(ha1,'LL Cost') 
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
        drawnow
end %function
