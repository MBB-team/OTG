function BEC_Visualize_OTG(trialinfo,muPhi,OTG_settings,converged)
%% Visualization of online trial generation, per trial
% trialinfo: AllData.trialinfo(trial)
% muPhi: all_muPhi(trl,:)

%% From calibration -- recode
    %Setup figure
        hf = figure('color',[1 1 1],'units','normalized','outerposition',[0 0 1 1]); % set(hf,'Position',[100 300 1500 700]);       
    %Parameter values
        muPhi_k = exp(trialinfo.muPhi(2:end,:));
        all_bias = trialinfo.bin_bias;
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

end

function [P_indiff] = Compute_P_indiff(grid,muPhi)
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
        mu_i = muPhi{i_bin}; %Parameter estimates of the current bin
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