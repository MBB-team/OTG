function [AllData] = BEC_SetVolume(window,AllData)
%Shows a screen where the volume is set to the desired level. This level will be used to play all
%sounds throughout the experiment. Note: set the computer volume to 50% for a comfortable starting
%level.

%% Settings
    %Define the range of volume levels
        n_levels = 20;  %Amount of volume levels
        disp_levels = 1/n_levels:1/n_levels:1;  %For display: evenly distributed volume levels from min to max volume
        all_vol = exp(0.25 * (1:n_levels))/(exp(0.25*n_levels)); %Exponential scale
    %Read audio to be played for setting the volume.
        musicfile = [AllData.exp_settings.stimdir filesep 'Happy_04.wav'];
        [audio, FS] = audioread(musicfile);
    %Prepare volume setting screen by creating players for every volume level, put them in one struct
        all_players = struct;
        for i_lvl = 1:n_levels
            all_players(i_lvl).vol = all_vol(i_lvl);
            all_players(i_lvl).player = audioplayer(all_vol(i_lvl).*audio,FS); %#ok<TNMLP>
        end

%% Instructions
    text = ['Vous entendrez un morceau de musique. Vous pouvez ajuster le volume avec les flèches ' ...
        'du clavier. Pour confirmer, appyez sur la barre espace. Vous n''aurez plus l''occason de ' ...
        'changer le volume après, il restera à ce niveau durant l''expérience. '...
        'Appuyez sur la barre espace pour écouter.'];
    Screen('TextSize',window,24);    
    Screen('TextFont',window,AllData.exp_settings.font.FontType);
    Screen('FillRect',window,AllData.exp_settings.backgrounds.default);
    DrawFormattedText(window,text,'center','center',255,100,[],[],2); %White text, horizontally and vertically centered.
    Screen('Flip',window);
    BEC_WaitForKeyPress({'space'})
    KbReleaseWait; pause(0.5)

%% Play music and detect keystrokes
    i_lvl = ceil(n_levels/2);  %Start volume: middle level
    volOK = false;
    while ~volOK
        %Check if sound is playing
            if ~isplaying(all_players(i_lvl).player)
                play(all_players(i_lvl).player);
            end
        %Write on screen
            disp_volume = disp_levels(i_lvl);
            text = [sprintf(['Appuyez sur les flèches vers le haut/bas pour ajuster le volume. ' ...
                'Appyez sur la barre espace pour confirmer.\n\nNiveau de volume:\t ']) num2str(100*disp_volume) '%'];
            DrawFormattedText(window,text,'center','center',255,100,[],[],2); %White text, horizontally and vertically centered.
            Screen('Flip',window);
        %Trace keys
            j_lvl = i_lvl; %The updated level (to be determined)
            [keyIsDown,~,keyCode]= KbCheck;
            if sum(keyIsDown)
                if find(keyCode) == KbName('UpArrow')
                    j_lvl = i_lvl + 1;
                    if j_lvl > n_levels; j_lvl = n_levels; end %Check: new level cannot go beyond maximum volume
                elseif find(keyCode) == KbName('DownArrow')
                    j_lvl = i_lvl - 1;
                    if j_lvl < 1; j_lvl = 1; end %Check: new level cannot go below minimum volume
                elseif find(keyCode) == KbName('space')
                    volOK = true;
                end
%                 WaitSecs(0.1)
            end
        %Update volume
            if ~volOK && i_lvl ~= j_lvl
                i_interrupt = all_players(i_lvl).player.CurrentSample; %Interrupt current player at this sample
                play(all_players(j_lvl).player,i_interrupt); %Start playing from this sample at the new level
                stop(all_players(i_lvl).player); %Stop playing at the previous level
            end
            i_lvl = j_lvl; %Update the index
    end %while    
    %Cleanup
        AllData.volume = all_players(j_lvl).vol;    
        clear all_players %turn sound off
end