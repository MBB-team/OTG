% This function is part of the OTG toolbox, used for generating and presenting a battery of economic choices.
% It is a convenience function that listens to the keyboard as the participant needs to press a certain key or set of keys.

function [resp,time]=BEC_WaitForKeyPress(keys,timeOutTime)
%Takes a cell array of keys, to which it will listen and return the index
%if any of those keys are pressed. Returns -1 when q is pressed. If it
%takes longer than timeOutTime in seconds, the function returns -2

t0=clock;

if ~exist('timeOutTime')
    timeOutTime=10000;
end

if ~exist('keys')
    keyIsDown=0;
    while~keyIsDown
        [keyIsDown,secs,keyCode] = KbCheck;
        if strcmp('q',KbName(keyCode)),
            resp=-1;
        else
            resp=find(keyCode==1);
        end
    end
else
    while 1
        [keyIsDown,secs,keyCode] = KbCheck;
        if keyIsDown 
            if strcmp('q',KbName(keyCode)),
                resp=-1;
                FlushEvents('keyDown');
                break;
            end
            for i=1:length(keys)
               if strcmp(KbName(keyCode),keys{i})
                   resp=i;
                   break;
               end
            end
            FlushEvents('keyDown');
            if exist('resp')
                break;
            end

        end
        if etime(clock,t0)>timeOutTime
            resp=-2;
            break;
        end
    end

end


time=clock;