function [eye_calibration] = BEC_SetupEyetracker(window)
% Set up the eyetracker
% Script mostly borrowed from Gilles Rautureau, April 2019

EyeTribeInit(60,90); % init EyeTribe at 60Hz and 90 seconds buffer
eye_calibration = struct;

%% check EyeTribe connection
    % offer possibility of (unplug/)replug device
    [ retVal, ETversion, ETtrackerstate, ETframerate, ETiscalibrated, ETiscalibrating ] = EyeTribeGetServerState();
    iRetries = 0;
    if ETtrackerstate ~= 0
        fprintf('Eyetribe device not found or bad connexion.\nPlease try to replug device.\n');
        while ETtrackerstate ~= 0
            iRetries = iRetries + 1;
            WaitSecs(1);
             fprintf('.');
            [ retVal, ETversion, ETtrackerstate, ETframerate, ETiscalibrated, ETiscalibrating ] = EyeTribeGetServerState();
            if iRetries > 10
                EyeTribeUnInit();
                sca
                clc
                error('EyeTribe : connection error');
            end
        end
    end

%% Center on the eyes
    pause(0.5);
    b = 0; kdown = 0;
    while kdown == 0 || b < 1
        [b] = EyeTribeCheckCenterPsy(window, 1);
        if b == 1
            WaitSecs(0.75);
            kdown = KbCheck(-1);            
        end
    end
    Screen('Flip', window);
    KbReleaseWait;    

%% Calibrate
    pause(0.25);
    EyeTribeCalibratePsy( window, 16, 900 ); %Shorter: (window, 9, 500)
    pause(0.5);
    [ eye_calibration.retVal,eye_calibration.result,eye_calibration.deg,eye_calibration.degl,eye_calibration.degr ] = EyeTribePrintCalibrationResult( );

    %Do calibration again if it failed the first time
        if ~eye_calibration.result
            pause(1);
            EyeTribeCheckCalibrationPsy(window, 16, 900);
            pause(1);
            [ eye_calibration.retVal,eye_calibration.result,eye_calibration.deg,eye_calibration.degl,eye_calibration.degr ] = EyeTribePrintCalibrationResult( );
        end
end
