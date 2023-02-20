function BEC_ConnectEyetribe
% This function is part of the OTG toolbox, used for generating and presenting a battery of economic choices.
% The function is used to set up the "EyeTribe" eyetracker that can be used as a plugin during choice experiments.
% (Script adapted from Gilles Rautureau from the PRISME platform of the Paris Brain Institute)

% init EyeTribe at 60Hz and 60 seconds buffer
    EyeTribeInit(60,60); 

% check EyeTribe connection
% offer possibility of (unplug/)replug device
    [ retVal, ETversion, ETtrackerstate, ETframerate, ETiscalibrated, ETiscalibrating ] = EyeTribeGetServerState();
    iRetries = 0;
    if ETtrackerstate ~= 0
        fprintf('Eyetribe device not found or bad connection.\nPlease try to replug device.\n');
        while ETtrackerstate ~= 0
            iRetries = iRetries + 1;
            WaitSecs(1);
             fprintf('.');
            [ retVal, ETversion, ETtrackerstate, ETframerate, ETiscalibrated, ETiscalibrating ] = EyeTribeGetServerState();
            if iRetries > 30
                EyeTribeUnInit();
                error('EyeTribe : connection error');
            end
        end
    end

%check EyeTribe framerate
    if ETframerate ~= 60
        warning('Eyetribe : framerate = %d', ETframerate);
    end

    fprintf('versionET : %d', ETversion);

end