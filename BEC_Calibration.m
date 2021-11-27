function [AllData,exitflag] = BEC_Calibration(AllData,choicetype,window,make_figure)
% Calibrate choice preferences using an online trial generation and parameter estimation procedure.
% inputs:
%     "exp_settings": the settings structure produced by BEC_Settings
%     "choicetype": fill in a number (1:delay/2:risk/3:phys.effort/4:ment.effort)
%     "window": the Psychtoolbox window
%     "make_figure": set to value 0, 1 or 2:
%           0: if you do not want to show a figure
%           1: if you want to make and save, but not show on screen, a summary figure of the results
%           2: if you want to show, but not save, the real-time model-fitting during calibration (for demo purposes)
% RLH - Update: October 2020
% Note: entirely coded for 5 cost bins

%% Configuration
    exp_settings = AllData.exp_settings;
    burntrials = exp_settings.OTG.burntrials_cal; %Predefined "burn trials" (the first trials, for the model (and participant) to know the "boundaries"
    grid = exp_settings.OTG.grid; %Sampling grid 
    dim = exp_settings.OTG.dim; %Model dimensions (VBA)
    options = exp_settings.OTG.options; %Model options (VBA)
    %Options: set priors
        options.priors.SigmaPhi = exp_settings.OTG.prior_var_cal*eye(dim.n_phi); %Prior for parameter variance
        options.priors.muPhi(1) = exp_settings.OTG.prior_bias_cal; %Prior for choice bias
        options.priors.muPhi(2:dim.n_phi,1) = log(1/diff(grid.rewardlimits)); %Priors for weights on cost      
    calinfo.options = options; %output
    calinfo.grid = grid; %output
    all_R1 = repmat(grid.gridY',1,grid.nbins*grid.bincostlevels); %Sampling grid: all rewards
    all_cost = repmat(grid.gridX(2:end),grid.binrewardlevels,1); %Sampling grid: all costs
    u_ind = [reshape(all_R1,[numel(all_R1) 1]) reshape(all_cost,[numel(all_cost) 1])]'; %Full grid
        
%% Loop through trials
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
                    P_SS = ObservationFunction([],muPhi,u_ind,options.inG);
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
        %Present the choice, record decision
            trialinput.choicetype = choicetype;
            trialinput.SSReward = reward;
            trialinput.Cost = cost;      
            if isfield(AllData,'plugins') && isfield(AllData.plugins,'touchscreen') && AllData.plugins.touchscreen == 1 %Record finger press on selected option
                trialinput.plugins.touchscreen = 1;
            else
                trialinput.plugins.touchscreen = 0;
            end
            [trialoutput,exitflag] = BEC_ShowChoice(window,exp_settings,trialinput);
            if exitflag; return; end
        %Store selected trial
            calinfo.u(:,trial) = [reward; cost];
            calinfo.y(trial) = trialoutput.choiceSS;
            calinfo.RT(trial) = trialoutput.RT;
        %Invert model with all inputs and choices
            dim.n_t = trial;
            posterior = VBA_NLStateSpaceModel(calinfo.y,calinfo.u,[],@ObservationFunction,dim,options);
            calinfo.muPhi(:,trial) = posterior.muPhi;
            calinfo.SigmaPhi(:,trial) = diag(posterior.SigmaPhi); 
            calinfo.posterior = posterior;
        %Show updated calibration figure during demonstration
            if exist('make_figure','var') && ~isempty(make_figure) && make_figure == 2
                %Create the figure if it does not exist yet
                    if ~exist('hf','var') || ~ishandle(hf)
                        hf = figure('color',[1 1 1]);%,'units','normalized','outerposition',[0 0 1 1]); % set(hf,'Position',[100 300 1500 700]); %Setup figure       
                    end
                %Update figure
                    hf = CalibrationFigure(hf,calinfo,grid);
            end
    end %for trial     
    
%% Store results
    %Store "calinfo" in AllData
        AllData.calibration.(exp_settings.trialgen_choice.typenames{choicetype}) = calinfo;
    %Make and save calibration summary figure (do not show on screen)
        if exist('make_figure','var') && ~isempty(make_figure) && make_figure == 1
            set(0,'DefaultFigureVisible','off'); %Do not show figures (because the Psychtoolbox window is open)
            hf = figure('color',[1 1 1],'units','normalized','outerposition',[0 0 1 1]); %Setup figure
            hf = CalibrationFigure(hf,calinfo,grid);
            F = getframe(hf);
            Im = frame2im(F);
            filename = ['Calibration_' exp_settings.trialgen_choice.typenames{choicetype}];
            imwrite(Im,[AllData.savedir filesep filename '.png'])
            close
            set(0,'DefaultFigureVisible','on');
        end    

end %function

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
function [hf] = CalibrationFigure(hf,calinfo,grid)
% Show the generated trials and the probability-of-indifference grid
    %Clear axis
        figure(hf)
        cla; hold on
    %Plot estimated indifference lines, per bin
        if isfield(calinfo,'muPhi')
            %Get parameters
                muPhi = calinfo.muPhi(:,end);
                in = calinfo.options.inG;
            %Compute the probability of being at indifference, scaled from 0 to 1, for each point in the sampling grid
                all_R1 = repmat(grid.gridY',1,grid.nbins*grid.bincostlevels); %Sampling grid: all rewards
                all_cost = repmat(grid.gridX(2:end),grid.binrewardlevels,1); %Sampling grid: all costs
                u_ind = [reshape(all_R1,[numel(all_R1) 1]) reshape(all_cost,[numel(all_cost) 1])]'; %Full grid - enter in observation function
                P_SS = ObservationFunction([],muPhi,u_ind,in);
                P_indiff = (0.5-abs(P_SS'-0.5))./0.5; 
                P_indiff = reshape(P_indiff,grid.binrewardlevels,grid.nbins*grid.bincostlevels);
                Im = imagesc(grid.gridX([2 end]),grid.gridY([1 end]),P_indiff);
                Im.AlphaData = 0.75;
                colorbar; caxis([0 1]);
            %Plot the fragmented indifference curve
                for i_bin = 1:in.grid.nbins
                    %Get this bin's indifference line's parameters
                        %Weight on cost
                            k = exp(muPhi(in.ind.bias+i_bin));
                        %Choice bias
                            if i_bin == 1; bias = exp(muPhi(in.ind.bias));
                            else; bias = 1 - k*C_i - R_i;
                            end
                    %Get the intersection point with the next bin
                        C_i = in.grid.binlimits(i_bin,2); %Cost level of the bin edge
                        R_i = 1 - k*C_i - bias; %Indifference reward level
                    %Plot
                        X_bin = linspace(grid.binlimits(i_bin,1),grid.binlimits(i_bin,2),grid.bincostlevels);
                        Y_fit = 1 - k.*X_bin - bias;
                        plot(X_bin,Y_fit,'k:','LineWidth',1.5);
                end       
        end %if isfield
    %Plot choices
        scatter(calinfo.u(2,calinfo.y==1),calinfo.u(1,calinfo.y==1),40,'r','filled');
        scatter(calinfo.u(2,calinfo.y==0),calinfo.u(1,calinfo.y==0),40,'b','filled');
    %Plot layout
        axis([0 1 0 1])
        title('Generated trials & P(indifference)')
        ylabel('Reward for the uncostly option')
        xlabel('Cost of the costly option') 
    %Draw now
        drawnow
end %function
