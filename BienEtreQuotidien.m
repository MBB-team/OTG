%% Daily ratings of well-being for implanted epileptic patients
% This script is made to be displayed on the Windows Surface 7 Pro with tactile screen. Therefore, some settings are
% altered for that purpose.

%Settings
    clear
    exp_settings = BEC_Settings;
    exp_settings.font.RatingFontSize = 60; %Larger for the tablet, which has a high PPI
    exp_settings.font.FixationFontSize = 80;
    RatingQuestions = {...
        'Comment vous sentez-vous ?';
        'Comment vous sentez-vous ?';
        'Comment vous sentez-vous ?';
        'Comment vous sentez-vous ?';
        'Comment vous sentez-vous ?';
        'Comment était votre sommeil cette nuit ?';
        'Comment estimez-vous votre risque de faire une crise d''épilepsie aujourd''hui ?';
        'Etes-vous gêné par le bruit ou la lumière ?'
        'Avez-vous des difficultés à vous concentrer, à réfléchir ?'
        'Vous sentez-vous bizarre, comme si quelque chose n''allait pas ?'};
    RatingLabels = {...
        'triste','heureux';
        'très fatigué','plein d''énergie';
        'stressé','détendu';
        'douleur maximale','aucune douleur';
        'de mauvaise humeur','de bonne humeur';
        'très mauvais','excellent';
        'très élevé','très faible';
        'énormément','pas du tout';
        'énormément','pas du tout';
        'énormément','pas du tout'};
%Create participant dataset
    AllData.ID = 'PatMarsiEEG';
    AllData.gender = 'm';
    AllData.exp_settings = exp_settings;
    AllData.plugins.MSSurface = 1;
%Save participant dataset
    mkdir(exp_settings.datadir,AllData.ID); %Create the directory where the data will be stored
    AllData.savedir = [exp_settings.datadir filesep AllData.ID]; %Path of the directory where the data will be saved 
    savename = [AllData.ID '_' datestr(clock,30)]; %Daily file save name
%Open screen
    Screen('Preference', 'SkipSyncTests', 1); %Skip sync tests: yes
    Screen('Preference', 'VisualDebugLevel', 3); %Visual debug level
    Screen('Preference', 'SuppressAllWarnings', 1);
    KbName('UnifyKeyNames'); %unify across platforms
    screens=Screen('Screens');
    [window,winRect] = Screen('OpenWindow',0,exp_settings.backgrounds.default); %0 for Windows Desktop screen
    Screen(window,'BlendFunction',GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); %for the Alpha transparency values to take effect

%% Present ratings
    %Instruction text on screen
        text = 'Bonjour. Nous voudrions vous poser quelques questions à propos de votre bien-être. Appuyez sur "OK" pour continuer.';
        CoverScreen(text,window,exp_settings)
    %Loop through ratings
        for i_rate = 1:length(RatingQuestions)
            %Fixation cross
                [exitflag] = BEC_Fixation(window,exp_settings,1); %One second fixation
                if exitflag; sca; return; end %Terminate   
            %Specify the rating
                AllData.exp_settings.ratings.dailymood.Ratingquestion = RatingQuestions{i_rate};
                AllData.exp_settings.ratings.dailymood.Rating_label_min = RatingLabels(i_rate,1);
                AllData.exp_settings.ratings.dailymood.Rating_label_max = RatingLabels(i_rate,2);
            %Present mood rating screens
                [rated_mood,timings,exitflag] = BEC_RateEmotion(window,AllData,'dailymood');
                if exitflag; sca; return; end %Terminate    
            %Store the rated mood
                AllData.DailyRatings(i_rate).Question = RatingQuestions{i_rate};
                AllData.DailyRatings(i_rate).Minimum = RatingLabels(i_rate,1);
                AllData.DailyRatings(i_rate).Maximum = RatingLabels(i_rate,2);
                AllData.DailyRatings(i_rate).Rating = rated_mood; 
                AllData.DailyRatings(i_rate).Timing = timings;
        end
     %Instruction text on screen
        text = 'Merci beaucoup. Appuyez sur "OK" pour fermer l''application.';
        CoverScreen(text,window,exp_settings)
    %Close and save
        sca
        save([AllData.savedir filesep savename],'AllData'); 
        clc; disp('Dataset saved. Rating session completed.')  
        disp('Terminé! Merci beaucoup.')
        quit
        
%% Present choices (to do)

%% Subfunctions
function CoverScreen(text,window,exp_settings)
    %Setup
        textfontsize = 60;
        OKfontfactor = 0.85;
        ratingcolor = [0 114 189];
        buttonsize = [0.1 0.05];
        linethickness = 5;
        Screen('FillRect',window,exp_settings.backgrounds.default);
        Screen('TextSize',window,textfontsize);
        finger_on_OKbutton = false;
    %Pre-loop check: no buttons clicked
        [~,~,buttons] = GetMouse; %GetMouse will always return the state of three buttons.
        while any(buttons) 
            [~,~,buttons] = GetMouse;
        end
    %Loop until button is pressed
        while ~finger_on_OKbutton
            %Draw text
                DrawFormattedText(window,text,'center','center',exp_settings.font.EmoFontColor,exp_settings.font.Wrapat,[],[],exp_settings.font.vSpacing,[],[]);
            %Draw OK button
                [screenX, screenY] = Screen('WindowSize', window); %Screen width, height
                OKbuttonrect = [(1-buttonsize(1))*screenX/2; (1-buttonsize(2))*screenY*2/3; (1+buttonsize(1))*screenX/2; (1+buttonsize(2))*screenY*2/3];
                Screen('TextSize',window,round(textfontsize*OKfontfactor)); %The word "OK" is written slightly smaller
                Screen('FillRect',window,ratingcolor,OKbuttonrect(:,1)'); %The button is filled in the rating theme color
                DrawFormattedText2('OK','win',window,'sx',mean(OKbuttonrect([1 3],1)),'sy',mean(OKbuttonrect([2 4],1)),'xalign','center','yalign','center','baseColor',exp_settings.colors.black); %The word "OK" is written in black instead of grey
                size_button = buttonsize .* [screenX screenY];
                Screen('LineStipple',window,1,2); % Set the next lines to be drawn to be stippled; then draw an inner frame in the button:
                    Screen('DrawLine', window, [0 0 0], OKbuttonrect(1,1)+0.05*size_button(1), OKbuttonrect(2,1)+0.1*size_button(2), OKbuttonrect(3,1)-0.05*size_button(1), OKbuttonrect(2,1)+0.1*size_button(2), linethickness/2);
                    Screen('DrawLine', window, [0 0 0], OKbuttonrect(3,1)-0.05*size_button(1), OKbuttonrect(2,1)+0.1*size_button(2), OKbuttonrect(3,1)-0.05*size_button(1), OKbuttonrect(4,1)-0.1*size_button(2), linethickness/2);
                    Screen('DrawLine', window, [0 0 0], OKbuttonrect(1,1)+0.05*size_button(1), OKbuttonrect(4,1)-0.1*size_button(2), OKbuttonrect(3,1)-0.05*size_button(1), OKbuttonrect(4,1)-0.1*size_button(2), linethickness/2);
                    Screen('DrawLine', window, [0 0 0], OKbuttonrect(1,1)+0.05*size_button(1), OKbuttonrect(2,1)+0.1*size_button(2), OKbuttonrect(1,1)+0.05*size_button(1), OKbuttonrect(4,1)-0.1*size_button(2), linethickness/2);
                Screen('LineStipple',window,0); %Disable line stipple
            %Flip
                Screen('Flip',window);
            %Check if "OK" is pressed
                [x,y] = GetMouse;
                finger_on_OKbutton = x >= OKbuttonrect(1,1) && x <= OKbuttonrect(3,1) && y >= OKbuttonrect(2,1) && y<= OKbuttonrect(4,1); %Logical
        end    
    pause(0.25)
end
    