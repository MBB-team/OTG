function [AllData,exitflag] = BEC_ShowQuizQuestion(window,question,AllData)

%% Prepare
    %Settings
        exp_settings = AllData.exp_settings;
    %Texts
        if isstruct(question) %Example trial - "question" is a structure
            isneutral = question.IsNeutral;
            correctanswer = question.CorrectAnswer;
            questiontext = question.Question;
            answer_A = ['A. ' question.ans_A];
            answer_B = ['B. ' question.ans_B];
            answer_C = ['C. ' question.ans_C];
            answer_D = ['D. ' question.ans_D];
            question = [];
        else %Main experiment trial - "question" is the quiz trial number
            isneutral = AllData.quiztrialinfo(question).IsNeutral;
            correctanswer = AllData.quiztrialinfo(question).CorrectAnswer;
            questiontext = AllData.quiztrialinfo(question).Question;
            answer_A = ['A. ' AllData.quiztrialinfo(question).ans_A];
            answer_B = ['B. ' AllData.quiztrialinfo(question).ans_B];
            answer_C = ['C. ' AllData.quiztrialinfo(question).ans_C];
            answer_D = ['D. ' AllData.quiztrialinfo(question).ans_D];
        end
    %Prepare screen
        Screen('TextSize',window,exp_settings.font.EmoFontSize);    
        Screen('TextFont',window,exp_settings.font.FontType);
        Screen('FillRect',window,exp_settings.backgrounds.mood);
    %Prepare rects
        [Xsize, Ysize] = Screen('WindowSize', window); 
        %Box within which the answers are written
            boxheight = exp_settings.Moodstimuli.answers_ymax-exp_settings.Moodstimuli.answers_ymin;
            answer_X = exp_settings.Moodstimuli.answers_xmin .* Xsize;
            answer_Y = (exp_settings.Moodstimuli.answers_ymin + (0:3)./4 .* boxheight) .* Ysize;
        %Draw a rectangle around the selected answer
            margin = 25; 
            width = 5;
            select_color = exp_settings.colors.orange;
    %Keyboard
        KbReleaseWait;  % wait until all keys are released before presenting quiz
        escapeKey = KbName(exp_settings.keys.escapekey);
        A_Key = KbName(exp_settings.keys.quiz_A); 
        B_Key = KbName(exp_settings.keys.quiz_B); 
        C_Key = KbName(exp_settings.keys.quiz_C);
        D_Key = KbName(exp_settings.keys.quiz_D);
        keyCode([A_Key B_Key C_Key D_Key]) = 0;
        keyCode(escapeKey) = 0; exitflag = 0;

%% Fixation
    %Duration: jittered between minimum and maximum
        ITI = exp_settings.timings.fix_pre_quiz(1) + ...
            rand*(exp_settings.timings.fix_pre_quiz(2)-exp_settings.timings.fix_pre_quiz(1));
    %Pupil mark
        if AllData.pupil && ~isempty(question)
            S10_Exp_PhysiologyMark(AllData,'fix_pre_quiz')
        end
    %Flip
        tic
        exitflag = BEC_Fixation(window,exp_settings,ITI);
        if exitflag; return; end        

%% Draw quiz screen
    t1 = clock; %Start time
    i_loop = 0; %For precise onset time for pupil    
    terminate = 0;
    i_select = 0;
    while ~terminate
        %Write question
            Screen('TextSize',window,exp_settings.font.QuestionFontSize); 
            DrawFormattedText(window, questiontext, 'center', exp_settings.Moodstimuli.quizquestion_y*Ysize, exp_settings.font.QuizFontColor, exp_settings.font.Wrapat, [], [], exp_settings.font.vSpacing);
        %Write answers
            if etime(clock,t1) > exp_settings.timings.delay_answers            
            %Write text
                [~,~,textbounds_A] = DrawFormattedText(window, answer_A, answer_X, answer_Y(1), exp_settings.font.QuizFontColor, [], [], [], [], [], []);      
                [~,~,textbounds_B] = DrawFormattedText(window, answer_B, answer_X, answer_Y(2), exp_settings.font.QuizFontColor, [], [], [], [], [], []);
                [~,~,textbounds_C] = DrawFormattedText(window, answer_C, answer_X, answer_Y(3), exp_settings.font.QuizFontColor, [], [], [], [], [], []);
                [~,~,textbounds_D] = DrawFormattedText(window, answer_D, answer_X, answer_Y(4), exp_settings.font.QuizFontColor, [], [], [], [], [], []);
            end
        %Draw a rectangle around an answer and record response
            if etime(clock,t1) > exp_settings.timings.delay_answers
                %Monitor keypress
                    if etime(clock,t1) > exp_settings.timings.min_quiz_time %Wait for minimum response time
                        keyCode([A_Key B_Key C_Key D_Key]) = 0;
                        if keyCode(A_Key) == 0 && keyCode(B_Key) == 0 && keyCode(C_Key) == 0 && keyCode(D_Key) == 0
                            [~, ~, keyCode] = KbCheck(-1);
                        end
                        if keyCode(A_Key); i_select = 1;
                        elseif keyCode(B_Key); i_select = 2;
                        elseif keyCode(C_Key); i_select = 3;
                        elseif keyCode(D_Key); i_select = 4;
                        elseif keyCode(escapeKey); exitflag = 1; break;
                        else; i_select = 0;
                        end                                                    
                    end
               %Draw the rectangle
                    if isneutral %Around the correct answer
                        switch correctanswer
                            case 1; correct_rect = [textbounds_A(1)-margin textbounds_A(2)-margin textbounds_A(3)+margin textbounds_A(4)+margin];
                            case 2; correct_rect = [textbounds_B(1)-margin textbounds_B(2)-margin textbounds_B(3)+margin textbounds_B(4)+margin];
                            case 3; correct_rect = [textbounds_C(1)-margin textbounds_C(2)-margin textbounds_C(3)+margin textbounds_C(4)+margin];
                            case 4; correct_rect = [textbounds_D(1)-margin textbounds_D(2)-margin textbounds_D(3)+margin textbounds_D(4)+margin];
                        end
                        Screen('FrameRect',window,select_color,correct_rect,width);
                    elseif i_select ~= 0 %Around the selected answer
                        switch i_select
                            case 1; select_rect = [textbounds_A(1)-margin textbounds_A(2)-margin textbounds_A(3)+margin textbounds_A(4)+margin];
                            case 2; select_rect = [textbounds_B(1)-margin textbounds_B(2)-margin textbounds_B(3)+margin textbounds_B(4)+margin];
                            case 3; select_rect = [textbounds_C(1)-margin textbounds_C(2)-margin textbounds_C(3)+margin textbounds_C(4)+margin];
                            case 4; select_rect = [textbounds_D(1)-margin textbounds_D(2)-margin textbounds_D(3)+margin textbounds_D(4)+margin];
                        end
                        Screen('FrameRect',window,select_color,select_rect,width);
                    end
                %Record valid keypress
                    if isneutral
                        if i_select == i_correct
                            SelectedAnswer = i_select;
                            IsCorrect = NaN;
                            terminate = 1;
                            RT = etime(clock,t1);
                        end
                    elseif i_select ~= 0
                        terminate = 1;
                        RT = etime(clock,t1);
                        SelectedAnswer = i_select;
                        if i_select == correctanswer
                            IsCorrect = 1;
                        else
                            IsCorrect = 0;
                        end
                    end
            end
        %Monitor for timeout
            if etime(clock,t1) > exp_settings.timings.quiz_timeout
                terminate = 1;
                RT = NaN;
                SelectedAnswer = NaN;
                IsCorrect = -1;
            end
        %Pupil -- TO DO
            if AllData.pupil && ~isempty(question) && i_loop == 0
                S10_Exp_PhysiologyMark(AllData,'fix_pre_quiz')
            end
        %Flip
            Screen('Flip', window);
            if i_loop == 0 && ~isempty(question)
                AllData.timings.fix_pre_quiz(question,1) = toc;
            end
            i_loop = 1;
    end %while
    
%% Store
    FlushEvents('keyDown');
    if exitflag; return
    else
        HideCursor
        if isempty(question); question = 1; end %for the output in example trials
        AllData.quiztrialinfo(question).SelectedAnswer = SelectedAnswer;
        AllData.quiztrialinfo(question).IsCorrect = IsCorrect;
        AllData.quiztrialinfo(question).RT = RT;
        WaitSecs(0.3); %Confirmation time
    end

end