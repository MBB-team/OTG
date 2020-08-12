%% Exit experiment (cleanup and close)
function BEC_ExitExperiment(AllData)
    sca; %Screen: close all
    clear player %Terminate the music player, if active
    save([AllData.exp_settings.savedir filesep 'AllData'],'AllData');
    if AllData.pupil; EyeTribeUnInit; end
end
