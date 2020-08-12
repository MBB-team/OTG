function [exitflag,AllData,player] = BEC_EmotionInduction(window,stim,AllData)
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
    
% Get the stimuli
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

% Fixation cross
    %Duration: jittered between minimum and maximum
        ITI = exp_settings.timings.fix_pre_induction(1) + ...
            rand*(exp_settings.timings.fix_pre_induction(2)-exp_settings.timings.fix_pre_induction(1));
    %Pupil mark
        if AllData.pupil && ~isempty(trial)
            S10_Exp_PhysiologyMark(AllData,'fix_pre_induction')
        end
    %Flip
        tic
        exitflag = BEC_Fixation(window,exp_settings,ITI);
        if exitflag; return; end
        
% Sound    
    if ~isempty(sound)
        %Read sound file
            soundfile = [exp_settings.stimdir filesep sound '.wav'];
            [audio, FS] = audioread(soundfile);
        %Make a player object at the specified volume
            player = audioplayer(AllData.volume .* audio, FS); %,16,ID); %nBits = 16 by default
            player.StopFcn = @(src, event) play(src); %Makes sure the sound loops until the player is deleted       
            play(player);
    end
        
% Vignette
    %Prepare
        Screen('TextSize',window,exp_settings.font.EmoFontSize);    
        Screen('TextFont',window,exp_settings.font.FontType);
        Screen('FillRect',window,exp_settings.backgrounds.emotion);
    %Text
        if ~isempty(text)
            DrawFormattedText(window,text,'center','center',exp_settings.EmoFontColor,exp_settings.EmoFontWrapat,[],[],...
                exp_settings.EmoFontvSpacing,[],[]); %horizontally and vertically centered.
        end
    %Flip
        Screen('Flip',window);
    %Timings
        if ~isempty(trial)
            AllData.timings.fix_pre_induction(trial,1) = toc;
            AllData.timings.induction(trial,:) = clock;
        end
    %Trigger
        if AllData.pupil && ~isempty(trial)
            S10_Exp_PhysiologyMark(AllData,'vignette')
        end
    %Wait
        pause(duration);
        
% Fixation cross
    %Pupil mark
        if AllData.pupil && ~isempty(trial)
            S10_Exp_PhysiologyMark(AllData,'fix_post_induction')
        end
    %Flip (note: fixed duration in the settings structure)
        exitflag = BEC_Fixation(window,exp_settings,exp_settings.timings.fix_post_induction);
        if exitflag; return; end    
    
end
