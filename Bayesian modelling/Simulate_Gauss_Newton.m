



% Simulate choice data
    n = 20;                        %number of choices
    true_muPhi = [0.75; 0.25];      %"true" parameter values
    a = true_muPhi(1);              %weight on reward
    b = true_muPhi(2);              %bias on uncostly option
    beta = 5;                       %inverse choice temperature (for simulation)
    R = [rand(1,n); ones(1,n)];     %reward for the [uncostly;costly] option
    C = [zeros(1,n); rand(1,n)];    %cost for the [uncostly;costly] option
    V1 = R(1,:) + b;                %value of uncostly option
    V2 = 1 - a*C(2,:);              %value of costly option
    DV = beta*(V1 - V2);            %decision value of the uncostly option
    P_SS = 1./(1+exp(-DV));         %probability of uncostly choice
    y = NaN(1,n);                   %simulated choices
    for i = 1:n
        y(i) = sampleFromArbitraryP([P_SS(i),1-P_SS(i)]',[1,0]',1);
    end
    
%     figure
%     subplot(1,2,1); hold on
%     scatter(R(1,:),C(2,:),[],y,'filled')
%     plot(linspace(0,1),1-a*linspace(0,1)-b)
%     xlabel('Cost'),ylabel('Reward'),title('Utility function and choices')
%     ha = subplot(1,2,2); hold on
%     RH_PsychometricCurve(P_SS,y,15,0,ha)
%     title('Psychometric curve')
    
% Model inversion
    % Priors
        mu0 = [1;1]; %parameter values
        S0 = eye(length(mu0)); %parameter variances
    % Gauss-Newton algorithm
        n_iter = 1000;
        mu = mu0; %Starting value
        all_mu = NaN(length(mu),n_iter);
        for i = 1:n_iter
            %Fill in current value of mu
                all_mu(:,i) = mu;
            %Derivative of DV over theta
                dDVdth = [C(2,:); ones(1,n)];
            %First derivative of f over theta
                dfdth = -inv(S0) * (mu - mu0) + dDVdth * (y - P_SS)';
            %Second derivative of f over theta
                ddfddth = -inv(S0) * sum(P_SS .* (1-P_SS)) * (dfdth'*dfdth);
            %Delta-mu
                delta = -inv(ddfddth) * dfdth;
            %Update mu
                mu = mu + delta;
        end
        figure;plot(all_mu')