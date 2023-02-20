% This function is part of the OTG toolbox, used for generating and presenting a battery of economic choices.
% It is a convenience function for experiments on a tactile screen: a screen appears and asks to fill in the patient ID (with the digits/symbols that 
% are provided). This ID will feature in the filename that the dataset will be saved with.

function [ID,exitflag] = BEC_Tactile_PatientID(exp_settings,window)
% Settings
    header_text = 'Avant de commencer, remplissez le numéro du patient :';
    [Xsize, Ysize] = Screen('WindowSize',window); %Get screen size
    Screen('TextSize',window,exp_settings.tactile.PatientIDFontSize);    
    Screen('FillRect',window,exp_settings.colors.black);
    buttonrect = [1/4*Xsize 1/2*Ysize 3/4*Xsize 3/4*Ysize]; %The rectangle within which the 10 number buttons will be entered
    number_button_rects = zeros(10,4); %The rects for the 10 number buttons
        number_button_rects(:,1) = repmat(buttonrect(1) + (0:2:8)'./9 .* diff(buttonrect([1 3])),2,1);
        number_button_rects(:,2) = [buttonrect(2)*ones(5,1); (buttonrect(4)-diff(buttonrect([1 3]))/9)*ones(5,1)];
        number_button_rects(:,3) = repmat(buttonrect(1) + (1:2:9)'./9 .* diff(buttonrect([1 3])),2,1);
        number_button_rects(:,4) = [buttonrect(2)*ones(5,1) + diff(buttonrect([1 3]))/9; buttonrect(4)*ones(5,1)];
    number_button_rects(11,:) = [2*number_button_rects(end,1)-number_button_rects(end-1,1), mean([number_button_rects(1,2) number_button_rects(end,2)]), ...
        2*number_button_rects(end,3)-number_button_rects(end-1,3), mean([number_button_rects(1,4) number_button_rects(end,4)])];
    bottom_buttons = [buttonrect(1) 0.8*Ysize buttonrect(1)+1/3*diff(buttonrect([1 3])) 0.9*Ysize;
                      buttonrect(3)-1/3*diff(buttonrect([1 3])) 0.8*Ysize buttonrect(3) 0.9*Ysize];    
    escapeCrossSize = exp_settings.tactile.escapeCross_ySize*Ysize;
    escapeCrossRect = [Xsize-1.5*escapeCrossSize 0.5*escapeCrossSize Xsize-0.5*escapeCrossSize 1.5*escapeCrossSize];
    
% Loop until response is confirmed
    exitflag = false;
    confirmed = false;
    ID = '';
    while ~confirmed
        % Header text
            DrawFormattedText(window,header_text,'center',Ysize/4,exp_settings.colors.white,exp_settings.font.Wrapat,[],[],exp_settings.font.vSpacing,[],[]);
        % ID # XXXX
            ID_text = ['ID # ' ID];
            DrawFormattedText(window,ID_text,'center',Ysize/3,exp_settings.colors.white,exp_settings.font.Wrapat,[],[],exp_settings.font.vSpacing,[],[]);
        % Number buttons
            Screen('FrameRect',window,exp_settings.colors.white,number_button_rects',3);
            for button = 1:11
                if button < 11 %number buttons
                    DrawFormattedText(window,num2str(button-1),'center','center',exp_settings.colors.white,[],[],[],[],[],number_button_rects(button,:));
                else
                    DrawFormattedText(window,'-','center','center',exp_settings.colors.white,[],[],[],[],[],number_button_rects(button,:));
                end
            end
        % Confirmation/correction buttons
            if ~isempty(ID)
                Screen('FillRect',window,exp_settings.colors.grey,bottom_buttons');
                DrawFormattedText(window,'Confirmer','center','center',exp_settings.colors.white,[],[],[],[],[],bottom_buttons(1,:));
                DrawFormattedText(window,'Corriger','center','center',exp_settings.colors.white,[],[],[],[],[],bottom_buttons(2,:));
            end
        % Escape cross
            Screen('FillRect',window,exp_settings.colors.red,escapeCrossRect);
            Screen('TextSize',window,exp_settings.tactile.escapeCrossFontSize); %Careful to set the text size back to what it was before
            DrawFormattedText(window, 'X', 'center', 'center', exp_settings.colors.white,[],[],[],[],[],escapeCrossRect);
            Screen('TextSize',window,exp_settings.tactile.PatientIDFontSize);    
        % Flip
            Screen('Flip',window);
        % Monitor button presses
            %Get finger coordinates
                [x,y,pressed] = GetMouse(window);
            %Escape cross press
                press_escape = x >= escapeCrossRect(1) & x <= escapeCrossRect(3) & y >= escapeCrossRect(2) & y <= escapeCrossRect(4);
                if press_escape && ~any(pressed) %Verify that the user REALLY wants to quit; otherwise, proceed.
                    escape_experiment = BEC_Tactile_EscapeScreen(exp_settings,window);
                    if escape_experiment
                        exitflag = true;
                        ID = '';
                        confirmed = true;
                    end
                end
            %Number button presses
                i_button_pressed = x >= number_button_rects(:,1) & x <= number_button_rects(:,3) & y >= number_button_rects(:,2) & y <= number_button_rects(:,4);
                if sum(i_button_pressed) == 1 && ~any(pressed) %Only one button can be pressed
                   if find(i_button_pressed) == 11
                       ID = [ID '-']; %#ok<AGROW>
                   else
                       ID = [ID num2str(find(i_button_pressed)-1)]; %#ok<AGROW>
                   end
                   SetMouse(0,0,window); %Hack to prevent the ID from keeping to get updated with the same number in every loop
                end
            %Confirmation/correction button presses
                press_confirm = x >= bottom_buttons(1,1) & x <= bottom_buttons(1,3) & y >= bottom_buttons(1,2) & y <= bottom_buttons(1,4);
                press_correct = x >= bottom_buttons(2,1) & x <= bottom_buttons(2,3) & y >= bottom_buttons(2,2) & y <= bottom_buttons(2,4);
                if press_confirm && ~press_correct && sum(i_button_pressed) == 0 && ~isempty(ID) && ~any(pressed)
                    confirmed = true; %Break out of loop
                elseif press_correct && ~press_confirm && sum(i_button_pressed) == 0 && ~isempty(ID) && ~any(pressed)
                    ID = '';
                end
    end %while ~confirmed
end %function