function [AUC] = BEC_Compute_AUC(muPhi,costlevels_per_bin)
% Calculate area under the curve of value function
%   input: muPhi, the parameter posteriors from the online trial generation (OTG) algorithm
%   output: AUC, the area under the curve

% Verify input
    if isempty(muPhi) || any(isnan(muPhi))
        AUC = NaN;
        return
    end
    if ~exist('costlevels_per_bin','var')
        costlevels_per_bin = 10; %default
    elseif ~isdouble(costlevels_per_bin)
        error('"n_levels" must be a variable of type double')
    end
% Settings
    nbins = length(muPhi)-1;
    binlimits = 0:1/nbins:1;
    AUC = 0;
% Loop through cost bins
    for bin = 1:nbins %Loop through cost bins        
        %Get parameters
            %Weight on cost for this bin (parameters 2-6 from muPhi)
                k = exp(muPhi(1+bin));
            %Choice bias (first parameter of muPhi)
                if bin == 1
                    b = exp(muPhi(1));
                else
                    b = 1 - k.*C_i - R_i; %C_i and R_i obtained from previous bin, see below
                end
                C_i = binlimits(bin+1); %Cost level of the bin edge
                R_i = 1 - k*C_i - b; %Indifference reward level at cost bin edge 
        %Compute area under the curve (positive range only)
            X = linspace(binlimits(bin),binlimits(bin+1),costlevels_per_bin+1);
            Y = 1 - b - k.*X;
            inc = diff(X(1:2));
            AUC = AUC + trapz(Y(Y>0))*inc;
    end
end %function