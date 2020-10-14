%% Exit experiment (cleanup and close)
function BEC_ExitExperiment(AllData)
    sca; %Screen: close all
    clear player %Terminate the music player, if active
    save([AllData.savedir filesep 'AllData'],'AllData');
    if isfield(AllData,'pupil') && AllData.pupil == 1 
        EyeTribeUnInit;
    end
end
