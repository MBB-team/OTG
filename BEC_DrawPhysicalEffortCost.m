function [timings] = BEC_DrawPhysicalEffortCost(window,exp_settings,drawchoice)
% Draw the staircases that visualize the physical effort cost from the BECHAMEL toolbox.
% This function is an auxiliary function to BEC_DrawChoiceScreen, which draws the choice to be visualized in the
% idiosyncracies of Psychtoolbox.

%Settings for drawing staircases:
    nrows = floor(sqrt(exp_settings.Max_phys_effort));  %Number of rows of pages
    ncols = ceil(sqrt(exp_settings.Max_phys_effort));   %Numbers of columns of pages
    if rem(nrows*ncols,exp_settings.Max_ment_effort)>0
        ncols = ncols+1;
    end
    nsteps = 9; %Number of steps per floor
    gapratio = 1/3; %Width width of the gap between staircases/width of the base of a staircase
    
%Identify the rectangle ("box") inside of which the costs will be drawn
    [Xsize, Ysize] = Screen('WindowSize', window); screensize = [Xsize Ysize Xsize Ysize];
    if drawchoice.example
        rect_leftbox = exp_settings.choicescreen.costbox_left_example .* screensize;
        rect_rightbox = exp_settings.choicescreen.costbox_right_example .* screensize;
    else
        rect_leftbox = exp_settings.choicescreen.costbox_left .* screensize;
        rect_rightbox = exp_settings.choicescreen.costbox_right .* screensize;
    end

%Get the staircase coordinates 
    X = rect_leftbox(3)-rect_leftbox(1);    %Total width of the cost box
    side = X/(ncols + gapratio*(ncols-1));  %Dimension of the sides of a box that contains a staircase
    gap = side*gapratio;                    %Horizontal width between two staircase boxes
    steps = [0:1:nsteps-1;                  %Draw template staircase
             nsteps-1:-1:0;
             nsteps*ones(1,nsteps);
             nsteps:-1:1].*side/nsteps;
    allsteps = NaN(4,exp_settings.Max_phys_effort*nsteps);
    for i = 1:exp_settings.Max_phys_effort
        i_row = ceil(i/ncols);
        i_col = i-(i_row-1)*ncols;
        allsteps(:,(i-1)*nsteps+(1:nsteps)) = (i_col-1)*(side+gap)*[1;0;1;0] + (i_row-1)*(side+gap)*[0;1;0;1] + steps;
    end
    allsteps_left = [rect_leftbox(1) rect_leftbox(2) rect_leftbox(1) rect_leftbox(2)]' + allsteps; %Coordinates of the left cost box steps
    allsteps_right = [rect_rightbox(1) rect_rightbox(2) rect_rightbox(1) rect_rightbox(2)]' + allsteps; %Coordinates of the right cost box steps
    
%Translate cost level into amount of steps:
    costlevel = max([drawchoice.costleft,drawchoice.costright]); %Effort level in terms of flights of stairs
    cost = costlevel/exp_settings.Max_phys_effort; %Effort level of the costly option, expressed as fraction of max effort level
    cost_steps = floor(cost*size(allsteps,2)); %Integer number of steps to fill for the costly option
    last_step = round(((costlevel-floor(costlevel)) - (cost_steps/nsteps - floor(cost_steps/nsteps)))*exp_settings.choicescreen.flightsteps)/exp_settings.choicescreen.flightsteps*nsteps; %Height of the last step (fraction of a full step)         
%Draw the steps
    %Left
        if drawchoice.costleft ~= 0 %Left is the costly side
            %Fill steps above cost level with line color (white)
                if cost_steps ~= length(allsteps)
                    Screen('FillRect',window,exp_settings.choicescreen.linecolor,allsteps_left(:,cost_steps:end));
                end
            %Fill steps until cost level with cost color (red)
                if cost_steps ~= 0
                    if cost_steps == 1 %Write function differently
                        Screen('FillRect',window,exp_settings.choicescreen.fillcolor,allsteps_left(:,1)');
                    else
                        Screen('FillRect',window,exp_settings.choicescreen.fillcolor,allsteps_left(:,1:cost_steps));
                    end
                end
            %Draw the last (fractional) cost step
                if last_step ~= 0
                    last_step = allsteps_left(:,cost_steps+1)' + [0 (1-last_step)*side/nsteps 0 0];
                    Screen('FillRect',window,exp_settings.choicescreen.fillcolor,last_step); %Last costly step (if not whole step)
                end
        else
            Screen('FillRect',window,exp_settings.choicescreen.linecolor,allsteps_left); %No-cost steps
        end
    %Right
        if drawchoice.costright ~= 0 %Right is the costly side
            %Fill steps above cost level with line color (white)
                if cost_steps ~= length(allsteps)
                    Screen('FillRect',window,exp_settings.choicescreen.linecolor,allsteps_right(:,cost_steps:end));
                end
            %Fill steps until cost level with cost color (red)
                if cost_steps ~= 0
                    if cost_steps == 1 %Write function differently
                        Screen('FillRect',window,exp_settings.choicescreen.fillcolor,allsteps_right(:,1)');
                    else
                        Screen('FillRect',window,exp_settings.choicescreen.fillcolor,allsteps_right(:,1:cost_steps));
                    end
                end
            %Draw the last (fractional) cost step
                if last_step ~= 0
                    last_step = allsteps_right(:,cost_steps+1)' + [0 (1-last_step)*side/nsteps 0 0];
                    Screen('FillRect',window,exp_settings.choicescreen.fillcolor,last_step); %Last costly step (if not whole step)
                end
        else
            Screen('FillRect',window,exp_settings.choicescreen.linecolor,allsteps_right); %No-cost steps
        end
    
%Flip
    timestamp = Screen('Flip', window); 
    timings = BEC_Timekeeping(drawchoice.event,drawchoice.plugins,timestamp);
end
