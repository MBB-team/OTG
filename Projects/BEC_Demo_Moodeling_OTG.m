% Moodeling online trial generation demonstration

%Day 0: Calibration
    for trial = 1:84
        if trial == 1 %Create the dataset upon the first iteration
            AllData = BEC_Moodeling_DEER;
        else
            AllData = BEC_Moodeling_DEER(AllData);
        end
    end
    
%Visualize calibration
    trialinfo = struct2table(AllData.trialinfo);
    figure
    typenames = {'delay','risk','physical_effort','mental_effort'};
    for type = 1:4
        subplot(2,2,type); hold on
        Im = imagesc(AllData.exp_settings.OTG.grid.gridX([2 end]),AllData.exp_settings.OTG.grid.gridY([1 end]),AllData.OTG_posterior.(typenames{type}).P_indiff);
        set(gca,'YDir','normal');
        Im.AlphaData = 0.75;
        c = colorbar; caxis([0 1]); ylabel(c,'P(indifference)')
        scatter(trialinfo.Cost(trialinfo.choicetype==type),trialinfo.SSReward(trialinfo.choicetype==type),[],trialinfo.choiceSS(trialinfo.choicetype==type),'filled')
        title(typenames{type}); xlabel('LL Cost'); ylabel('SS Reward'); axis([0 1 0 1])
    end
    
%Day 1,2,3,...: Daily follow-up
    for day = 1:365
        AllData = BEC_Moodeling_DEER(AllData);
    end