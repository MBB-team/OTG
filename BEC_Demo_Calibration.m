% Demo of the choice calibration procedure

%% Startup
    %Get the experiment settings
        exp_settings = BEC_Settings;
    %Start the experiment from the beginning, or at an arbitrary point. This depends on whether AllData exists.
        startpoint = 0;
        %Create data structure and get experiment settings structure
            AllData = struct;
            AllData.exp_settings = exp_settings; 
        %Participant data
            AllData.initials = input('Initials: ','s');
        %Get the settings and directories
            savename = [AllData.initials '_' datestr(clock,30)]; %Directory name where the dataset will be saved
            AllData.savedir = [exp_settings.datadir filesep savename]; %Path of the directory where the data will be saved      
            mkdir(exp_settings.datadir,savename); %Create the directory where the data will be stored
    %Add all experiment scripts and functions to the path
        addpath(genpath(exp_settings.expdir))     
    %Open a screen
        Screen('Preference', 'SkipSyncTests', 1); %Skip sync tests: yes
        Screen('Preference', 'VisualDebugLevel', 3); %Visual debug level
        Screen('Preference', 'SuppressAllWarnings', 1);
        KbName('UnifyKeyNames'); %unify across platforms
        [w,h] = Screen('WindowSize',0); demo_rect = [0.1*w 0.1*h 0.9*w 0.9*h]; %The demo screen will not fill the entire screen
        [window,winRect] = Screen('OpenWindow',0,exp_settings.backgrounds.default,demo_rect); %0 for Windows Desktop screen
    %Save
        save([AllData.savedir filesep 'AllData'],'AllData'); 
        
% %% Show example trials
%     for trial = 1:3
%         trialinfo = struct;
%         trialinfo.trial = trial;        %Trial number
%         trialinfo.choicetype = 1;       %Set number (1:delay/2:risk/3:physical effort/4:mental effort)
%         trialinfo.SSReward = rand;      %Reward for the uncostly (SS) option (between 0 and 1)
%         trialinfo.Cost = rand;          %Cost level or the costly (LL) option (between 0 and 1)
%         trialinfo.Example = 1;
%         [~,exitflag] = BEC_ShowChoice(window,exp_settings,trialinfo);
%     end
    
%% Run calibration
    % Choice calibration settings
        exp_settings.calibration.ntrials = 20; 
        exp_settings.calibration.grid.nbins = 5; % # bins
        exp_settings.calibration.grid.bincostlevels = 10;    % # cost levels per bin  
        exp_settings.calibration.grid.binrewardlevels = 60;  % # reward levels per bin
        exp_settings.calibration.grid.costlimits = [0 1];    % [min max] cost (note: bin 1's first value is nonzero)
        exp_settings.calibration.grid.rewardlimits = [1/60 59/60]; % [min max] reward for uncostly option
        exp_settings.fixation_choice_cal = [0.25 0.75];      % fixation time [min max]
    % Run the calibration
        [trialinfo] = Demo_Calibration(exp_settings,1,window);
    
%% Terminate
    sca

%% Subfunction: calibration script
function [trialinfo] = Demo_Calibration(exp_settings,choicetype,window)

%% Configuration
    grid = exp_settings.calibration.grid;
    ntrials = exp_settings.calibration.ntrials;
    trialinfo = struct;        
    [options,dim,grid] = GetDefaultSettings(grid); %NB: options are updated each trial
    inv_options = options; %options for parameter estimation only (invariable)!
    trialinfo.options = options;
    trialinfo.grid = grid;
    all_R1 = repmat(grid.gridY',1,grid.nbins*grid.bincostlevels); %All rewards
    all_cost = repmat(grid.gridX(2:end),grid.binrewardlevels,1); %All costs
    u_ind = [reshape(all_R1,[numel(all_R1) 1]) reshape(all_cost,[numel(all_cost) 1])]'; %Full grid
    typenames = {'delay','risk','effort'};
    sidenames = {'left','right'};
        
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
                                if i_bin == 1; bias = options.priors.muPhi(options.inG.ind.bias);
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
                    fit_R1 = 1 - exp(options.priors.muPhi(options.inG.ind.bias+bin))*cost - trialinfo.bin_bias(bin,trial);
                    %Get index of reward level to be selected
                        if fit_R1 > max(grid.gridY)
                            ind_indiff = length(grid.gridY); %maximum reward if indifference reward is above upper bound
                        elseif fit_R1 < min(grid.gridY)
                            ind_indiff = 1; %minimum nonzero reward if indifference reward is below lower bound
                        else %within bounds
                            [~,ind_indiff] = min(abs(grid.gridY-fit_R1));
                        end
                        reward = grid.gridY(ind_indiff); %indifference reward level
            end %burn trials or not
        %Present the choice, record decision
            %Trial input
                switch choicetype
                    case 1; cost_delay = cost; cost_risk = 0; cost_effort = 0;
                    case 2; cost_delay = 0; cost_risk = cost; cost_effort = 0;
                    case 3; cost_delay = 0; cost_risk = 0; cost_effort = cost;
                end
                trialinput = struct;
                trialinput.SSReward = reward;
                trialinput.LLReward = 1;
                trialinput.Delay = cost_delay;
                trialinput.Risk = cost_risk;    
                trialinput.Effort = cost_effort;
                trialinput.Cost = sum([cost_delay,cost_risk,cost_effort]);
                trialinput.Choicetype = typenames{choicetype};
                trialinput.choicetype = choicetype;
                trialinput.SideSS = sidenames{1+round(rand)};
                trialinput.timestamp = clock;
                trialinput.Example = 0;
                trialinput.pupil = 0;
                trialinput.biopac = 0;
            %Fixation cross
                t_fix = RH_RandInt(1,exp_settings.fixation_choice_cal(1),exp_settings.fixation_choice_cal(2));
                BEC_Fixation(window,exp_settings,t_fix)
            %Load choice trial screen and record decision             
                [trialoutput,exitflag] = BEC_ShowChoice(window,exp_settings,trialinput);
                if exitflag; BEC_ExitExperiment(AllData); return; end
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
%         set(0,'DefaultFigureVisible','off');
        CalibrationFigure(trialinfo,grid);
%         F = getframe(hf);
%         Im = frame2im(F);
%         filename = ['Calibration_' typenames{choicetype}];
%         imwrite(Im,[exp_settings.savedata filesep filename '.png'])
%         close
%         set(0,'DefaultFigureVisible','on');

end %function

%% Subuction: Get default settings
function [options,dim,grid] = GetDefaultSettings(grid)
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
        options.priors.SigmaPhi = 2*eye(dim.n_phi);
        options.priors.muPhi(1) = 0; %Prior for choice bias
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
        for i_bin = 1:in.grid.nbins
            %Get this bin's indifference line's two parameters
                %Weight on cost
                    k = exp(P(in.ind.bias+i_bin));
                    all_k(i_bin) = k;
                %Choice bias
                    if i_bin == 1; bias = P(in.ind.bias);
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
        Z = 1./(1 + exp(-DV)); %Probability of chosing option 1
        Z = Z';
end

%% Subfunction: Make and update figure
function [hf] = CalibrationFigure(trialinfo,grid)
    %Setup figure
        hf = figure('color',[1 1 1],'units','normalized','outerposition',[0 0 1 1]); % set(hf,'Position',[100 300 1500 700]);       
    %Parameter values
        muPhi_k = exp(trialinfo.muPhi(2:end,:));
        SigmaPhi_k = trialinfo.SigmaPhi(2:end,:);
        all_bias = trialinfo.bin_bias;
        SigmaPhi_bias = trialinfo.SigmaPhi(1,:);
    %Generated trials and probability of indifference
        ha1 = subplot(4,grid.nbins,1:3*grid.nbins,'parent',hf); hold on
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
        for bin = 1:grid.nbins
            ha3 = subplot(4,grid.nbins,3*grid.nbins+bin,'parent',hf); hold on
            Y1 = muPhi_k(bin,:); X = 1:length(Y1); %Discount factor
                E1 = SigmaPhi_k(bin,:);
                hp1 = patch(ha3,[X X(end:-1:1)], [Y1+E1 Y1(end:-1:1)-E1(end:-1:1)], [0.2 0.2 0.6], 'facealpha', 0.2, 'Edgecolor', 'none');
                set(get(get(hp1,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
                plot(ha3, X, Y1, 'linestyle', '-', 'LineWidth', 1, 'color', [0.2 0.2 0.6]);
            Y2 = all_bias(bin,:);
                if bin == 1 %This is the only "real" bias that is inverted
                    E2 = SigmaPhi_bias;
                    hp2 = patch(ha3,[X X(end:-1:1)], [Y2+E2 Y2(end:-1:1)-E2(end:-1:1)], [0.6 0 0], 'facealpha', 0.2, 'Edgecolor', 'none');
                    set(get(get(hp2,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
                end
                plot(ha3, X, Y2, 'linestyle', '-', 'LineWidth', 1, 'color', [0.6 0 0]);
            %Figure layout
%                 legend({'k','bias','k','bias'},'Location','northoutside','Orientation','horizontal')
%                 title('Parameter estimates'); 
                if bin == 1; ylabel('Parameter estimates'); end
                xlabel('Trials');
        end
        drawnow
end %function


        
