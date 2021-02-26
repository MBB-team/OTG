function [player,timings,exitflag] = BEC_EmotionInduction(window,stim,AllData)
% Emotion induction screen: write vignette text and play music if not neutral
% The stimuli can be selected automatically from the triallist and the settings if "stim" is the
% trial number from the induction battery; or the stimuli can be entered manually, in which case
% "stim" must be a struct with fields "text" and "music" (leave empty if no music must be played)
% and optionally "duration", specifying the duration of the vignette on screen.
% Input:
%       window: the Psychtoolbox window handle
%       stim: the trial number from the battery, or a structure as described above
%       AllData: the experiment dataset

% Settings
    exp_settings = AllData.exp_settings;
    player = []; %Will be filled in if music is specified, but must be predefined before exit is possible
    escapeKey = KbName('ESCAPE'); %27
    
% Get the stimuli
    %Either from trial list or entered manually
        if isstruct(stim) %The stimulus is entered manually
            trial = []; %No trial number from the induction battery
            text = stim.text;
            if isfield(stim,'music')
                sound = stim.music;
            else
                sound = [];
            end
            if isfield(stim,'duration')
                duration = stim.duration;
            else
                duration = exp_settings.timings.inductiontime;
            end        
        else %The stimulus is taken from the triallist
            trial = stim; %The trial number from the induction battery
            text = AllData.triallist.vignette_text{trial};
            sound = AllData.triallist.music_name{trial}; %Will be empty when no music is specified
            duration = exp_settings.timings.inductiontime;        
        end
    %Prepare sound    
        if ~isempty(sound)
            %Read sound file
                soundfile = [exp_settings.stimdir filesep sound '.wav'];
                [audio, FS] = audioread(soundfile);
            %Make a player object at the specified volume
                player = audioplayer(AllData.volume .* audio, FS); %,16,ID); %nBits = 16 by default
                player.StopFcn = @(src, event) play(src); %Makes sure the sound loops until the player is deleted       
        end

% Fixation cross
    %Duration: jittered between minimum and maximum
        ITI = exp_settings.timings.fix_pre_induction(1) + ...
            rand*(exp_settings.timings.fix_pre_induction(2)-exp_settings.timings.fix_pre_induction(1));
    %Get timings
        timings = BEC_Timekeeping('Induction_fixation_pre',AllData.plugins);
    %Flip
        [exitflag,timestamp] = BEC_Fixation(window,exp_settings,ITI);
        if exitflag; return; end
        timings.seconds = timestamp; %The exact onset time, in GetSecs
        if isempty(trial); timings.event = ['ex_' timings.event]; end
        
% Present stimulus
    %Write vignette
        if ~isempty(text)
            Screen('TextSize',window,exp_settings.font.EmoFontSize);    
            Screen('TextFont',window,exp_settings.font.FontType);
            Screen('FillRect',window,exp_settings.backgrounds.emotion);
            DrawFormattedText(window,text,'center','center',exp_settings.font.EmoFontColor,exp_settings.font.Wrapat,[],[],exp_settings.font.vSpacing,[],[]);
        end
    %Flip and play
    try
        if ~isempty(sound); play(player); end
    catch
        sca; keyboard
    end
        timestamp = Screen('Flip',window);
    %Timings
        timings = [timings BEC_Timekeeping('Induction',AllData.plugins,timestamp)];
        if isempty(trial); timings(2).event = ['ex_' timings(2).event]; end
    %Wait until time has expired or Escape is pressed
        [~, ~, keyCode, ~] = KbCheck(-1); 
        while keyCode(escapeKey) == 0 && GetSecs-timestamp < duration
            [~, ~, keyCode, ~] = KbCheck(-1); 
        end
        if keyCode(escapeKey) %Proceed to exit in master
            exitflag = 1; return
        end
        
% Fixation cross
    %Get timings
        timings = [timings BEC_Timekeeping('Induction_fixation_pre',AllData.plugins)];
    %Flip
        [exitflag,timestamp] = BEC_Fixation(window,exp_settings,exp_settings.timings.fix_post_induction);
        if exitflag; return; end
        timings(3).seconds = timestamp; %The exact onset time, in GetSecs 
        if isempty(trial); timings(3).event = ['ex_' timings(3).event]; end
end
