% This function is part of the OTG toolbox, used for generating and presenting a battery of economic choices.
% This is a convenience function for Psychtoolbox experiments. It closes the Psychtoolbox session in a controlled manner, notably by calling functions
% needed to close any plugged in devices.

function BEC_ExitExperiment(AllData)
    sca; %Screen: close all
    clear player %Terminate the music player, if active
    save([AllData.savedir filesep 'AllData'],'AllData');
    %Un-initialize the eyetracker
        if isfield(AllData.plugins,'pupil') && AllData.plugins.pupil == 1 
            try
                EyeTribeUnInit;
            catch
            end
        end
    %Close the Arduino port
        if isfield(AllData.plugins,'Arduino') && AllData.plugins.Arduino == 1 
            try
                CloseArduinoPort
            catch
            end
        end
    %Close the BIOPAC trigger channel
        if isfield(AllData.plugins,'BIOPAC') && AllData.plugins.BIOPAC == 1 
            try
                triggerbiopac_V2_01('close'); 
            catch
            end
        end
end
