function [triallist] = BEC_MakeTriallist_Emotions(AllData,which_half,triallist)
% input: which_half, exp_settings
%        muPhi, triallist (only in second half)
%Choice trial generation settings 
    exp_settings = AllData.exp_settings;
    exp_settings.trialgen_emotions.inductions_per_emo = [12 12 6];     %number of inductions per emotion condition
    exp_settings.trialgen_choice.which_choicetypes = [1 2 4];   %Selection of choice types
    exp_settings.trialgen_choice.n_choicetypes = 3;
    prior.delay.muPhi = [-3.6628;0.2041;-2.2642;-2.8915;-3.2661;-1.8419];
    prior.risk.muPhi = [-1.4083;0.8217;-1.1018;-1.1148;-0.6224;0.2078];
    prior.mental_effort.muPhi = [-4.0760;0.2680;-0.5499;-2.0245;-2.6053;-1.9991];

if strcmp(which_half,'first_half')
    triallist = struct;

%% Induction level
    %Emotion trial generation settings
        emotions_per_5 = [1 1 2 2 3];
        n_block = length(emotions_per_5);
    %Which emotion
        triallist.conditions = NaN(exp_settings.trialgen_emotions.n_inductions,1);
        for i = 1:(exp_settings.trialgen_emotions.n_inductions/n_block)
            OK = false;
            while ~OK
                shuffled = emotions_per_5(randperm(5));
                if ~any(shuffled(2:end)==shuffled(1:end-1))
                    if i == 1
                        OK = true;
                    else
                        if triallist.conditions((i-1)*n_block) ~= shuffled(1)
                            OK = true;
                        end
                    end
                end
            end
            triallist.conditions((i-1)*n_block+(1:n_block)) = shuffled;
        end
        triallist.i_induction = (1:length(triallist.conditions))';
    %Which music stimulus
        triallist.music_num = NaN(length(triallist.conditions),1);
        for emotion = exp_settings.trialgen_emotions.i_music_emo
            nRepetitions = exp_settings.trialgen_emotions.inductions_per_emo(emotion)/exp_settings.trialgen_emotions.n_music_stim;
            emo_music = ShuffleConditions(exp_settings.trialgen_emotions.n_music_stim,nRepetitions);
            triallist.music_num(triallist.conditions == emotion) = emo_music;
        end
        triallist.music_name = cell(length(triallist.conditions),1);
        for i = 1:length(triallist.conditions)
            if ~isnan(triallist.music_num(i))
                musicname = [exp_settings.trialgen_emotions.emotionnames{triallist.conditions(i)} '_0' num2str(triallist.music_num(i))];
                triallist.music_name{i} = musicname;
            end
        end
    %Which vignette stimulus
        triallist.vignette_num = NaN(length(triallist.conditions),1);
        triallist.vignette_text = cell(length(triallist.conditions),1);
        for emotion = 1:exp_settings.trialgen_emotions.n_emotions
            whichvignettes = randperm(exp_settings.trialgen_emotions.inductions_per_emo(emotion));
            triallist.vignette_num(triallist.conditions==emotion) = whichvignettes;
            if ismember(emotion,exp_settings.trialgen_emotions.i_music_emo)
                name = {[exp_settings.trialgen_emotions.emotionnames{emotion} 'Vignettes_' AllData.gender]};
            else
                name = {[exp_settings.trialgen_emotions.emotionnames{emotion} 'Vignettes']};
            end
            vignettestimuli = getfield(exp_settings.Emostimuli,name{:});
            triallist.vignette_text(triallist.conditions==emotion) = vignettestimuli(whichvignettes);
        end
        
%% Choice level
    %Choice triallist
        triallist.choices.induction = kron(triallist.i_induction,ones(exp_settings.trialgen_emotions.choices_per_induction,1));
        triallist.choices.choiceno = (1:length(triallist.choices.induction))';
        nRepetitions = exp_settings.trialgen_emotions.choices_per_induction/exp_settings.trialgen_choice.n_choicetypes*exp_settings.trialgen_emotions.n_inductions;
        triallist.choices.choicetype = ShuffleConditions(exp_settings.trialgen_choice.n_choicetypes,nRepetitions);
        triallist.choices.choicetype = exp_settings.trialgen_choice.which_choicetypes(triallist.choices.choicetype)';
        triallist.choices.condition = kron(triallist.conditions,ones(exp_settings.trialgen_emotions.choices_per_induction,1));
        sideSS = [ones(floor(length(triallist.choices.choiceno)/2),1); zeros(ceil(length(triallist.choices.choiceno)/2),1)];
        triallist.choices.sideSS = sideSS(randperm(length(sideSS)));
        triallist.choices.LLCost = NaN(length(triallist.choices.choicetype),1);
        triallist.choices.SSReward = NaN(length(triallist.choices.choicetype),1);
        triallist.choices.indifference = NaN(length(triallist.choices.choicetype),1);

end %First half
        
%% Sample choices based on models
    %Generate half of all the choice trials (first based on population average, then based on ppt's own behavior)
        for type = exp_settings.trialgen_choice.which_choicetypes
            %Get muPhi, per type across emotions
                if strcmp(which_half,'first_half')
                    i_half = triallist.choices.choiceno <= length(triallist.choices.choiceno)/2;
                    muPhi = prior.(exp_settings.trialgen_choice.typenames{type}).muPhi;
                else
                    i_half = triallist.choices.choiceno > length(triallist.choices.choiceno)/2;
                    muPhi = InvertChoiceModel(AllData,type);
                end
            %Sample choices separately per emotion
                for emotion = 1:exp_settings.trialgen_emotions.n_emotions
                    choices = SampleChoices(muPhi,emotion,exp_settings);
                    i_choices = find(i_half & triallist.choices.choicetype==type & triallist.choices.condition==emotion);
                    i_choices_1 = i_choices(1:2:end); %First choice after given emotion induction of given choice type
                    i_choices_2 = i_choices(2:2:end); %Second choice after given emotion induction of given choice type
                    if emotion == 3 %4 indifference, 2 off indifference
                        %Choose the off-indifference trials first
                            i_nonindif_1 = false(3,1); i_nonindif_1(randperm(3,1)) = true;
                            i_nonindif_2 = false(3,1); i_nonindif_2(randperm(3,1)) = true;
                            triallist.choices.indifference(i_choices_1(i_nonindif_1)) = 0;
                            triallist.choices.LLCost(i_choices_1(i_nonindif_1)) = choices.costs(strcmp(choices.indifference,'above'));
                            triallist.choices.SSReward(i_choices_1(i_nonindif_1)) = choices.rewards(strcmp(choices.indifference,'above'));
                            triallist.choices.indifference(i_choices_2(i_nonindif_2)) = 0;
                            triallist.choices.LLCost(i_choices_2(i_nonindif_2)) = choices.costs(strcmp(choices.indifference,'below'));
                            triallist.choices.SSReward(i_choices_2(i_nonindif_2)) = choices.rewards(strcmp(choices.indifference,'below'));
                        %Then fill in for the at-indifference trials
                            indifference_choices = randperm(sum(strcmp(choices.indifference,'indifference')));
                            triallist.choices.indifference(i_choices_1(~i_nonindif_1)) = 1;
                            triallist.choices.LLCost(i_choices_1(~i_nonindif_1)) = choices.costs(indifference_choices(1:2));
                            triallist.choices.SSReward(i_choices_1(~i_nonindif_1)) = choices.rewards(indifference_choices(1:2));
                            triallist.choices.indifference(i_choices_2(~i_nonindif_2)) = 1;
                            triallist.choices.LLCost(i_choices_2(~i_nonindif_2)) = choices.costs(indifference_choices(3:4));
                            triallist.choices.SSReward(i_choices_2(~i_nonindif_2)) = choices.rewards(indifference_choices(3:4));                    
                    else %Happiness and sadness
                        i_choices_1 = i_choices(1:2:end); %First choice after given emotion induction of given choice type
                        i_choices_2 = i_choices(2:2:end); %Second choice after given emotion induction of given choice type
                        %Determine whether selected choices are at indifference
                            dist_indiff = logical([1 1 1 0 0 0]);
                            is_indiff = dist_indiff(randperm(length(dist_indiff)));
                            triallist.choices.indifference(i_choices_1) = is_indiff;
                            triallist.choices.indifference(i_choices_2) = ~is_indiff;
                        %Fill in the costs and rewards of the indifference choices
                            indifference_choices = find(strcmp(choices.indifference,'indifference'));
                            indifference_choices = indifference_choices(randperm(length(indifference_choices)));
                            triallist.choices.LLCost(i_choices_1(is_indiff')) = choices.costs(indifference_choices(1:3));
                            triallist.choices.LLCost(i_choices_2(~is_indiff')) = choices.costs(indifference_choices(4:6));
                            triallist.choices.SSReward(i_choices_1(is_indiff')) = choices.rewards(indifference_choices(1:3));
                            triallist.choices.SSReward(i_choices_2(~is_indiff')) = choices.rewards(indifference_choices(4:6));
                        %Fill in the costs and rewards of the non-indifference choices
                            nonindifference_choices = find(~strcmp(choices.indifference,'indifference'));
                            nonindifference_choices = nonindifference_choices(randperm(length(nonindifference_choices)));
                            triallist.choices.LLCost(i_choices_1(~is_indiff')) = choices.costs(nonindifference_choices(1:3));
                            triallist.choices.LLCost(i_choices_2(is_indiff')) = choices.costs(nonindifference_choices(4:6));
                            triallist.choices.SSReward(i_choices_1(~is_indiff')) = choices.rewards(nonindifference_choices(1:3));
                            triallist.choices.SSReward(i_choices_2(is_indiff')) = choices.rewards(nonindifference_choices(4:6));
                    end
                end
        end
end
        
%% Choice trial sampling
function [choices] = SampleChoices(muPhi,emotion,exp_settings)
    %Sampling settings
        crit_corr = 0.4; %Maximum correlation coefficient between sampled rewards and costs
        crit_div = 0.4; %Diversity criterion
        lim_samp = [0.3 0.6]; %Range above/below the indifference value for off-indifference sampling
        n_sample_emo = [6 3 3]; %Number of choices to be sampled [at/below/above] indifference
        n_sample_neutral = [4 1 1]; %Select a subset of the sampled trials for the emotion conditions
    %Calculate indifference grid
        grid = exp_settings.OTG.grid;
        X = grid.gridX(2:end); Y = NaN(size(X));
        for bin = 1:grid.nbins
            k = exp(muPhi(1+bin));
            if bin == 1
                b = exp(muPhi(1));
            else
                b = 1 - k.*C_i - R_i; %C_i0 and R_i0 obtained from previous bin, see below
            end
            C_i = grid.binlimits(bin,2); %Cost level of the bin edge
            R_i = 1 - k*C_i - b; %Indifference reward level at cost bin edge
            X_bin = X((bin-1)*grid.bincostlevels + (1:grid.bincostlevels));
            Y_bin = 1 - k.*X_bin - b;
                Y((bin-1)*grid.bincostlevels+(1:grid.bincostlevels)) = Y_bin;
        end    
    %Sample choices
        uncorrelated = false;
        i_iter = 1;
        while ~uncorrelated
            %Sample the costs
                %Cost sampling criterion 1: positive reward range
                    i_select = Y>0;
                %Cost sampling criterion 2: minimally sample 40% of the grid
                    if mean(i_select) < crit_div
                        i_select(1:round(crit_div*length(X))) = true;
                    end
                %Cost sampling criterion 3: trials equidistant across cost range
                    %Indifference trials
                        stepsize = floor(sum(i_select)/n_sample_emo(1));
                        i_cost_indiff = randperm(stepsize,1):stepsize:sum(i_select);
                        i_cost_indiff = i_cost_indiff(1:n_sample_emo(1));
                        cost_indiff = X(i_cost_indiff);
                    %Trials above indifference
                        stepsize = floor(sum(i_select)/n_sample_emo(2));
                        isOK = false;
                        while ~isOK %sample until the first sampled cost level has a value different than the first indifferent cost level
                            i_cost_above = randperm(stepsize,1):stepsize:sum(i_select);
                            i_cost_above = i_cost_above(1:n_sample_emo(2));
                            if i_cost_above(1) ~= i_cost_indiff(1); isOK = true;
                            end
                        end
                        cost_above = X(i_cost_above);
                    %Trials below indifference
                        stepsize = floor(sum(i_select)/n_sample_emo(3));
                        isOK = false;
                        while ~isOK %sample until the first sampled cost level has a value different than the first indifferent cost level
                            i_cost_below = randperm(stepsize,1):stepsize:sum(i_select);
                            i_cost_below = i_cost_below(1:n_sample_emo(3));
                            if i_cost_below(1) ~= i_cost_indiff(1) && i_cost_below(1) ~= i_cost_above(1)
                                isOK = true;
                            end
                        end
                        cost_below = X(i_cost_below);
            %Sample the rewards
                %Indifference
                    reward_indiff = Y(i_cost_indiff);
                %Above (sampling criterion 4: trials presented within a range above/below indifference)
                    reward_above = Y(i_cost_above) + ...
                        (lim_samp(1)+(lim_samp(2)-lim_samp(1)).*rand(1,length(i_cost_above))) .* ... % random values within specified range
                        (grid.rewardlimits(2)-Y(i_cost_above));
                %Below (sampling criterion 4: trials presented within a range above/below indifference)
                    reward_below = Y(i_cost_below) - ...
                        (lim_samp(1)+(lim_samp(2)-lim_samp(1)).*rand(1,length(i_cost_above))) .* ... % random values within specified range
                        (Y(i_cost_below)-grid.rewardlimits(1));
            %Make a trial list
                choices = table;
                choices.costs = [cost_indiff'; cost_above'; cost_below'];
                choices.rewards = [reward_indiff'; reward_above'; reward_below'];
                choices.indifference = [repmat({'indifference'},n_sample_emo(1),1);repmat({'above'},n_sample_emo(2),1);repmat({'below'},n_sample_emo(3),1)];
            %Calculate correlation between costs and rewards
                C = corrcoef(choices.costs,choices.rewards);
                if abs(C(2)) < crit_corr
                    uncorrelated = true;
                end
                i_iter = i_iter+1;
            %End the loop if stuck
                if i_iter == 100
                    uncorrelated = true;
                end
        end %while
    %Visualize sampled trials
%         close all; figure; hold on
%         cla; hold on
%         plot(X,Y,':','color',[0.5 0.5 0.5],'LineWidth',1.5)
%         ylim([0 1])
%         scatter(choices.costs,choices.rewards)
%         title(['Correlation: ' num2str(C(2)) ' (p = ' num2str(p(2)) ')'])
    %Sample a subset from these generated choices in case of the neutral condition
        if emotion == 3
            i_neutral_indiff = randperm(n_sample_emo(1),n_sample_neutral(1));
            i_neutral_above = randperm(n_sample_emo(2),n_sample_neutral(2));
            i_neutral_below = randperm(n_sample_emo(3),n_sample_neutral(3));
            choices = table;
            choices.costs = [cost_indiff(i_neutral_indiff)'; cost_above(i_neutral_above)'; cost_below(i_neutral_below)'];
            choices.rewards = [reward_indiff(i_neutral_indiff)'; reward_above(i_neutral_above)'; reward_below(i_neutral_below)'];
            choices.indifference = [repmat({'indifference'},n_sample_neutral(1),1);repmat({'above'},n_sample_neutral(2),1);repmat({'below'},n_sample_neutral(3),1)];
        end                
end
               

%% Subfunction: Shuffle Conditions
function [conditions] = ShuffleConditions(nConditions,nRepetitions)
% nConditions: how many unique conditions are there?
% nRepetitions: how many instances of each condition should occur?
% conditions: list all repetitions of all conditions, such that:
%   - there is no fixed repeated pattern, and
%   - no two subsequent conditions are the same
        conditions = [];
        for k = 1:nRepetitions
            addconditions = randperm(nConditions)';
            if ~isempty(conditions)
                while addconditions(1) == conditions(end)
                    addconditions = randperm(nConditions)';
                end
            end
            conditions = [conditions; addconditions];
        end 
end

%% Subfunctions for model inversion
function [muPhi] = InvertChoiceModel(AllData,choicetype)
% Settings
    OTG_settings = AllData.exp_settings.OTG;
    typenames = OTG_settings.typenames;
    AllData.OTG_prior.delay.muPhi = [-3.6628;0.2041;-2.2642;-2.8915;-3.2661;-1.8419];
    AllData.OTG_prior.risk.muPhi = [-1.4083;0.8217;-1.1018;-1.1148;-0.6224;0.2078];
    AllData.OTG_prior.physical_effort.muPhi = [-5.4728;-2.9728;-2.4963;-1.8911;-0.3541;-1.7483];
    AllData.OTG_prior.mental_effort.muPhi = [-4.0760;0.2680;-0.5499;-2.0245;-2.6053;-1.9991];
% Update parameter estimates
    %Get trial history from given choice type        
        trialinfo = struct2table(AllData.trialinfo);
        u = [trialinfo.SSReward(trialinfo.choicetype==choicetype)'; %uncostly-option rewards;
             trialinfo.Cost(trialinfo.choicetype==choicetype)']; %costly-option costs
        y = trialinfo.choiceSS(trialinfo.choicetype==choicetype)'; %choices
        n = sum(trialinfo.choicetype==choicetype);
    %Get priors
        options = OTG_settings.options;
        options.priors.muPhi = AllData.OTG_prior.(typenames{choicetype}).muPhi; %prior estimates of the parameter values
        options.priors.SigmaPhi = OTG_settings.priorvar; %prior variance of the parameter estimates
    %Invert the model and update the posterior
        dim = OTG_settings.dim;
        dim.n_t = n;
        posterior = VBA_NLStateSpaceModel(y,u,[],@ObservationFunction,dim,options);
        muPhi = posterior.muPhi;
end
    
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