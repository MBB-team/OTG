function BEC_ConnectEyetribe

EyeTribeInit(60,60); % init EyeTribe at 60Hz and 60 seconds buffer

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