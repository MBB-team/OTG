function [timings] = BEC_Timekeeping(event,plugins,seconds)
% Keeps track of events, their timing, and sends trigger to plugged-in devices
% Outputs a structure with fields:
%   timings.event : the name of the event
%   timings.time : the exact onset time
%   (if plugged in) timings.trigger_iEEG : the trigger that was sent to Arduino for iEEG recordings
%   (if plugged in) timings.trigger_pupil : the {mark,scene} that was sent to EyeTribe for pupil recordings

%Get time in format [year month day hour minute seconds], this is system-dependent but should suffice in most cases
    timings.time = clock;    
%Store the *exact* amount of seconds since arbitrary system zero at the time of event onset, if high precision is needed
    if exist('seconds','var') && ~isempty(seconds) %"seconds" can be the output of Screen('Flip',window), for example
        timings.seconds = seconds;
    else
        timings.seconds = [];
    end
%Set trigger
    switch event
        %Start and end of experiment
            case {'StartExperiment','EndExperiment'}
                trigger_iEEG = 88*ones(1,5); %RH's unique trigger stamp to mark the beginning/end of the experiment
        %Instructions
            case 'InstructionScreen'
                trigger_iEEG = 1;
        %Emotion induction
            case 'Induction_fixation_pre'
                trigger_iEEG = 2;
            case 'Induction'
                trigger_iEEG = 3;
            case 'Induction_fixation_post'
                trigger_iEEG = 4;
        %Choices
            case 'Choice_fixation'
                trigger_iEEG = 5;
            case 'Choice_screenonset' %The screen appears, but you can't make a decision yet
                trigger_iEEG = 6;
            case 'Choice_decisiononset' %The "+" turns into a "?", you may now make a decision
                trigger_iEEG = 7;
            case 'Choice_decisiontime' %The time stamp of the decision
                trigger_iEEG = 8;
            case 'Choice_confirmation' %The confirmation on screen
                trigger_iEEG = 9;
        %Ratings
            case 'RatingScreenOnset'
                trigger_iEEG = 10;
            case 'RatingConfirmation'
                trigger_iEEG = 11;
            case 'RatingCompleted'
                trigger_iEEG = 12;
        %Washout
            case 'Washout'
                trigger_iEEG = 13;
    end
%Send trigger
    if exist('plugins','var')
        %iEEG
            if isfield(plugins,'iEEG') && plugins.iEEG == 1
                if ~exist('trigger_iEEG','var') %No trigger for iEEG has been set
                    timings.trigger_iEEG = []; %Output: empty
                else %A trigger has been set
                    timings.trigger_iEEG = trigger_iEEG; %Store the trigger
                    for i = 1:length(timings.trigger_iEEG) %Loop through trigger values in case there are multiple
                        SendArduinoTrigger(timings.trigger_iEEG(i)) %Send trigger to Arduino
                        if length(timings.trigger_iEEG)>1 %In case of a loop: pause for 50ms
                            pause(0.05)
                        end
                    end %for i
                end %if ~exist
            end %if isfield
        %pupil
            if isfield(plugins,'pupil') && plugins.pupil == 1
                if ~exist('trigger_pupil','var') %No trigger for iEEG has been set
                    timings.trigger_pupil = []; %Output: empty
                else %A trigger has been set
                    timings.trigger_pupil = trigger_pupil; %Store the trigger
                    for i = 1:length(timings.trigger_pupil) %Loop through trigger values in case there are multiple
    %                     Set EyeTribe...
    %                     if length(timings.trigger_pupil)>1 %In case of a loop: pause for 50ms
    %                         pause(0.05)
    %                     end
                    end %for i
                end %if ~exist
            end %if isfield
    end %if exist plugins
%Output
    timings.event = event;
end