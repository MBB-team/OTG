%% Exit experiment (cleanup and close)
function BEC_ExitExperiment(AllData,player)
    sca; %Screen: close all
    clear player %Terminate the music player, if active
    save([AllData.savedir filesep 'AllData'],'AllData');
    if isfield(AllData.plugins,'pupil') && AllData.plugins.pupil == 1 
        EyeTribeUnInit;
    end
    if isfield(AllData.plugins,'iEEG') && AllData.plugins.iEEG == 1 
        CloseArduinoPort
    end
end
