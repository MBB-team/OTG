function [AUC] = BEC_AUC(~, P, ~, in)
% function [AUC] = BEC_AUC(~, P, ~, in)
%
% This function returns the area under the discounting function.
% The AUC (Area under the curve) is a model free measure of the discouting
% behavior. See for example: DOI:10.1901/jeab.2001.76-235
%
% Author: Antonius Wiehler <antonius.wiehler@gmail.com>
%
% Original: 2021-03-29
% Modified: 2021-04-01




% on which range do we want to compute the AUC ?
% ---------------------------------------------------------------------
Cost = linspace(in.grid.costlimits(1), in.grid.costlimits(2), 10000);




% Loop bins to get parameters for each bin (two parameters per bin)
% ---------------------------------------------------------------------
all_bias = zeros(in.grid.nbins,1);
all_k = zeros(in.grid.nbins,1);

for i_bin = 1 : in.grid.nbins
    
    % Get this bin's indifference line's two parameters
    % Weight on cost
    k = exp(P(in.ind.bias + i_bin));
    all_k(i_bin) = k;  % store k
    
    %Choice bias
    if i_bin == 1
        bias = exp(P(in.ind.bias));
    else
        bias = 1 - k * C_i - R_i;
    end
    
    all_bias(i_bin) = bias;  % store bias
    
    % Get the intersection point with the next bin
    C_i = in.grid.binlimits(i_bin, 2); %Cost level of the bin edge
    R_i = 1 - k * C_i - bias; %Indifference reward level
    
end  % loop bins




% Compute subjective values for each trial, based on the corresponding bin
% function
% ---------------------------------------------------------------------
SV = zeros(1,length(Cost));

for i_trl = 1:length(Cost)
    bin = (Cost(i_trl) >= in.grid.binlimits(:, 1) & Cost(i_trl) <= in.grid.binlimits(:, 2));
    SV(i_trl) = 1 - all_k(bin) .* Cost(i_trl);
end




% compute the area under the curve (AUC) aka the integral
% ---------------------------------------------------------------------
AUC = trapz(Cost, SV);

end  % function
