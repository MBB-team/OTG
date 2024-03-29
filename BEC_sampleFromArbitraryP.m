% This function is part of the OTG toolbox, used for generating and presenting a battery of economic choices.
% NOTE: this function is copied from an old version of VBA, by Jean Daunizeau and Lionel Rigoux

function [X] = BEC_sampleFromArbitraryP(p,gridX,N)
% inverse transform sampling scheme
% function [X] = sampleFromArbitraryP(p,gridX,N)
% This function samples from an arbitrary 1D probability distribution
% IN:
%   - p: pX1 vector (the density evaluated along the grid)
%   - gridX: pX1 vector (the grid over which the density is evaluated)
%   - N: the number of samples to be sampled
% OUT:
%   - X: NX1 vector of samples

try; N; catch, N=1; end
try
    p = VBA_vec(p);
catch %for compatibility with older versions of VBA
    p = vec(p);
end

if size(gridX,1)==1
    gridX = vec(gridX);
end
k = size(gridX,2);

if any(isnan(p))
    X = nan(N,k);
else
    pcdf = cumsum(p(:));
    X = zeros(N,k);
    for i=1:N
        below = find(rand<=pcdf);
        X(i,:) = gridX(below(1),:);
    end
end