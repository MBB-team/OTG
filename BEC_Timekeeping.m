% This function is part of the OTG toolbox, used for generating and presenting a battery of economic choices.
% It is a convenience function that keeps track of events, their timing, and sends triggers to plugged-in devices

function [timings] = BEC_Timekeeping(event,plugins,seconds)
% Inputs:
%   event: a string name of the event, from the list defined below
%   plugins: any plugged-in devices that you want to send triggers to, e.g.: Arduino, EyeTribe, BIOPAC
%   seconds: (optional) the exact onset time, i.e. a timestamp in GetSecs format, called just before this function
% Outputs a structure with fields:
%   timings.event : the name of the event
%   timings.time : the onset time in the convenient format [year month day hour minute seconds]
%   timings.seconds : (when "seconds" is specified) the exact onset time, i.e. the timestamp in GetSecs format
%   (if plugged in) timings.trigger_Arduino : the trigger that was sent to Arduino
%   (if plugged in) timings.trigger_BIOPAC : the trigger(s) that were sent to BIOPAC for physiology recordings
%   (if plugged in) timings.pupil_mark,timings.pupil_scene : the marker and scene that were sent to EyeTribe for pupil recordings

%Get time in format [year month day hour minute seconds], this is system-dependent but should suffice in most cases
    timings.time = clock;    
%Store the *exact* amount of seconds since arbitrary system zero at the time of event onset, if high precision is needed
    if exist('seconds','var') %"seconds" can be the output of Screen('Flip',window) or from GetSecs, that you acquire before calling this function
        timings.seconds = seconds;
    else
        timings.seconds = [];
    end
%Set trigger/marker
    timings.event = event;
    switch event
        %Start and end of experiment
            case {'StartExperiment','EndExperiment'}
                trigger_Arduino = 88*ones(1,5); %RH's unique trigger stamp to mark the beginning/end of the experiment
        %Start of main experiment
            case 'StartMainExperiment'
                trigger_Arduino = 50*ones(1,3);
        %Instructions
            case 'InstructionScreen'
                trigger_Arduino = 1;
                pupil_mark = 1;
        %Emotion induction
            case 'Induction_fixation_pre'
                trigger_Arduino = 2;
                pupil_mark = 2;
            case 'Induction'
                trigger_Arduino = 3;
                pupil_mark = 3;
                trigger_BIOPAC = 3; %This is the only event where triggers get sent to BIOPAC
            case 'Induction_fixation_post'
                trigger_Arduino = 4;
                pupil_mark = 4;
        %Choices
            case 'Choice_fixation'
                trigger_Arduino = 5;
                pupil_mark = 5;
            case 'Choice_screenonset' %The screen appears, but you can't make a decision yet
                trigger_Arduino = 6;
                pupil_mark = 6;
            case 'Choice_decisiononset' %The "+" turns into a "?", you may now make a decision
                trigger_Arduino = 7;
                pupil_mark = 7;
            case 'Choice_decisiontime' %The time stamp of the decision
                trigger_Arduino = 8;
                pupil_mark = 8;
            case 'Choice_confirmation' %The confirmation on screen
                trigger_Arduino = 9;
                %pupil_mark = 9; % ---- do not send this to the eyetracker; the time gap between 
                %'Choice_decisiontime' and 'Choice_confirmation' is minimal.
        %Ratings
            case 'RatingScreenOnset'
                trigger_Arduino = 10;
                pupil_mark = 10;
            case 'RatingConfirmation'
                trigger_Arduino = 11;
                pupil_mark = 11;
            case 'RatingCompleted'
                trigger_Arduino = 12;
                pupil_mark = 12;
        %Washout
            case 'Washout'
                trigger_Arduino = 13;
                pupil_mark = 13;
    end
%Send trigger/marker
    if exist('plugins','var')
        %Arduino: send triggers to external device
            if isfield(plugins,'Arduino') && plugins.Arduino == 1 %Note: plugins.Arduino is a logical
                if ~exist('trigger_Arduino','var') %No trigger for iEEG has been set
                    timings.trigger_Arduino = []; %Output: empty
                else %A trigger has been set
                    timings.trigger_Arduino = trigger_Arduino; %Store the trigger
                    for i = 1:length(timings.trigger_Arduino) %Loop through trigger values in case there are multiple
                        SendArduinoTrigger(timings.trigger_Arduino(i)) %Send trigger to Arduino
                        if length(timings.trigger_Arduino)>1 %In case of a loop: pause for 50ms
                            pause(0.05)
                        end
                    end %for i
                end %if ~exist
            end %if isfield
        %PUPIL: send triggers to EyeTribe
            if isfield(plugins,'pupil') && plugins.pupil == 1 % Note: plugins.pupil is a logical
                %Pupil "scene": input to the function, in structure "plugins"
                    if isfield(plugins,'pupil_scene')
                        EyeTribeSetCurrentScene(plugins.pupil_scene)
                        timings.pupil_scene = plugins.pupil_scene; %Record the scene that was set in the timings output structure
                    else
                        timings.pupil_scene = []; %Output: empty
                    end
                %Pupil mark
                    if exist('pupil_mark','var') %A marker has been set above
                        EyeTribeSetCurrentMark(pupil_mark);
                        timings.pupil_mark = pupil_mark; %Record the marker that was set in the timings output structure
                    else %No marker for Eyetribe has been set
                        timings.pupil_mark = [];
                    end
            end %if isfield
        %BIOPAC: 
            if isfield(plugins,'BIOPAC') && plugins.BIOPAC == 1 %Note: plugins.BIOPAC is a logical
                if ~exist('trigger_BIOPAC','var') %No trigger for iEEG has been set
                    timings.trigger_BIOPAC = []; %Output: empty
                else %A trigger has been set
                    timings.trigger_BIOPAC = trigger_BIOPAC; %Store the trigger
                    for i = 1:trigger_BIOPAC
                        triggerbiopac_V2_01('send'); 
                        pause(0.010); % Leave a short interval between BIOPAC triggers
                    end
                end %if ~exist
            end %if isfield
    end %if exist plugins    
end