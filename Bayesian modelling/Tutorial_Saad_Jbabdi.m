% Bayesian Modelling
% Tutorial by Saad Jbabdi
%---------------------------------------------------------------------------------------------------

%% Linear models

% Generate some data using this generative model:
  a = 5;                 % true mean (it's winter...)
  s = 4;                 % true noise std 
  n = 4;                 % # data points
  y = a + s*randn(n,1);  % Simulates fake data
  
% Let us plot the data and the likelihood function as a function of a.
  va  = linspace(-15,15,1000);
  N   = length(va);
  lik = exp(-.5*sum((repmat(y,1,N)-repmat(va,n,1)).^2,1)/s^2);
  lik = lik/sum(lik); % normalise

  figure,hold on,grid on
  plot(y,0,'.','color','g','markersize',20);
  hli=plot(va,lik,'r','linewidth',2);
  
% Now we turn to choosing a prior distribution on the temperature. We will use a Gaussian prior 
% distribution (for simplicity) with zero mean and standard deviation 5 degrees:
  a0  = 0;
  s0  = 5;
  pr  = exp(-.5*(va-a0).^2./s0^2);
  pr  = pr/sum(pr);
  hpr = plot(va,pr,'b','linewidth',2);
  
% And finally we can write down the posterior distribution, which in this case is also a Gaussian 
% (the product of two Gaussians is a Gaussian), where the mean/variance are given by combinations of the noise mean/variance and the prior mean/variance in what is referred to as "precision weighting":

  beta  = 1/s^2;   % noise precision
  beta0 = 1/s0^2;  % prior precision

  sp = 1/sqrt(n*beta+beta0);                       % posterior std
  ap = (n*beta*mean(y)+beta0*a0)/(n*beta+beta0);   % posterior mean

  po = normpdf(va,ap,sp);
  po = po/sum(po);
  hpo= plot(va,po,'k','linewidth',2);

  legend([hli hpr hpo],{'likelihood','prior','posterior'},'orientation','horizontal');
  
%% Linear regression
% Use the code below to generate some data and plot likelihood/prior/posterior like before:

  % Generate some data  (you can play with changing mean, std, and #points)
  a = 5;                  % true slope
  s = 3;                  % true noise std
  n = 20;                 % # data points
  x = linspace(-1,1,n)';  % regressor
  y = a*x + s*randn(n,1); % Simulates fake data

  % plot likelihood
      va=linspace(-15,15,100);N=length(va);
      li = exp(-.5*sum((repmat(y,1,N)-x*va).^2,1)/s^2);
      li = li/sum(li);
      figure,
      hold on
      hli = plot(va,li,'r','linewidth',2);
  % prior
      a0  = 0;
      s0  = 3;
      pr  = exp(-.5*(va-a0).^2./s0^2);
      pr  = pr/sum(pr);
      hpr = plot(va,pr,'b','linewidth',2);
   % posterior
      beta  = 1/s^2;
      beta0 = 1/s0^2;
      sp    = 1/(beta0+beta*(x'*x));
      ap    = ( beta0*a0 + beta*x'*y  ) / (beta0 + beta*(x'*x));
      po  = normpdf(va,ap,sp);
      po  = po/sum(po);
      hpo = plot(va,po,'k','linewidth',2);
      legend([hli hpr hpo],{'likelihood','prior','posterior'},'orientation','horizontal');
      axis([-10 10 0 max(po)])
      
% Now we will generate "samples" from the prior and the posterior distribution by generating random 
% "slopes" that follow either prior or posterior distribution and plotting a line with the 
% corresponding slope:

  figure
  axis([-1 1 -5 5])
  plot(x,y,'k.','markersize',20); % draw data points
  for i=1:20
  samp  = normrnd(a0,s0);   % from prior
  l1=line([-1 1],samp*[-1 1],'color','b','linestyle','--');
  samp  = normrnd(ap,sp);   % from posterior
  l2=line([-1 1],samp*[-1 1],'color','k');
  end
  legend([l1 l2],{'from prior','from posterior'},'orientation','horizontal');  

%% Sampling
% Begin by generating some random data that obays this generative model:
  a   = 2; % true a
  sig = 5; % true sigma
  t   = linspace(0,10,20)'; % regressor (known)
  % generate data
    y = a*t + sig*randn(size(t));
  % plot data
      figure
      plot(t,y,'.','linewidth',2)
% Next we generate a grid for a and s^2, and compute the posterior distribution at each point on the grid.

  % grid
  va = linspace(0,5,100);     % values of a
  vs = linspace(.01,80,100);  % values of s^2

  posterior = zeros(length(vs),length(va));

  for i=1:length(vs)
   for j=1:length(va)
    S  = va(j)*t;                                        % prediction
    li = vs(i).^(-n/2)*exp(-sum((y-S).^2)/2/vs(i));      % likelihood
    pr = 1/vs(i) * normpdf(va(i),0,1000);                % prior
    posterior(i,j) = li*pr;                              % posterior
   end
  end
  posterior = posterior / sum(posterior(:));
%   Now we can have a look at the (joint) posterior distribution:

  figure
  imagesc(va,vs,posterior);
  xlabel('a');
  ylabel('s^2')
  
  % gibbs sampling
  niter = 10000;      % number of iterations
  a_s=zeros(niter,1); % container for samples for a
  v_s=zeros(niter,1); % container for samples for s^2

  % initial samples (you can change this to the maximum likelihood):
  a_s(1)=2;
  v_s(1)=10;

  for i=2:niter
    % samples a (Gaussian)
    a_s(i) = normrnd(sum(t.*y)./sum(t.*t),sqrt(v_s(i-1)/sum(t.*t)));

    % sample sig^2 (inverse-Gamma)
    v_s(i) = 1/gamrnd( n/2, 2/sum( (y-a_s(i-1)*t).^2 ) );
  end
  
% Now plot both the grid solution and the samples

  figure
  imagesc(va,vs,posterior);
  xlabel('a');
  ylabel('s^2');
  hold on
  plot(a_s(1:20:end),v_s(1:20:end),'.k')  % plot every 20th sample
  
%  Finally, we can calculate the marginal distributions in both cases (samples and grid) and compare them:

  % plot marginals
  figure
  subplot(1,2,1),hold on
  [n,x]=hist(a_s,va);n=n/sum(n);            % histogram from samples
  bar(x,n,'r');
  plot(va,sum(posterior,1)','linewidth',2); % sum one dimension of grid

  subplot(1,2,2),hold on
  [n,x]=hist(v_s,vs);n=n/sum(n);
  bar(x,n,'r');
  plot(vs,sum(posterior,2),'linewidth',2);
  
%% Nonlinear models
% Let's start by generating some data under this model:

  a = 10; % true a
  b = 2;  % true b
  t = linspace(0,2,100)';

  sig = 5; % noise standard deviation

  % data
  y = a*exp(-b*t) + sig*randn(size(t));

  % plot the data
  figure
  plot(t,y,'linewidth',2)
  title('y=a*exp(-b*t)','fontsize',14)
  
% First, we do a grid search. Run the code below and make sure you understand it:

  % %%%%%%%%% grid %%%%%%%%%
  w1 = linspace(0,20,50);
  w2 = linspace(0,10,50);
  [vw1,vw2] = meshgrid(w1,w2);
  n = length(y);
  N = length(vw1(:));
  Y = repmat(y,1,N);
  S = repmat(vw1(:)',n,1).*exp(-t*vw2(:)');
  mu = sum((Y-S).^2,1)'/2/sig^2;
  li = exp(-mu);
  li = li/sum(li(:));
  li = reshape(li,size(vw1));
  
  % plot grid
  imagesc(w1,w2,li);
  hold on
  h=plot(a,b,'+','color','k','markersize',20,'linewidth',2);
  xlabel('a','fontsize',14);
  ylabel('b','fontsize',14);
  
  ind = find(li==max(li(:)));
  [i,j]=ind2sub(size(vw1),ind);
  l=line([min(w1) max(w1)],[w2(i) w2(i)]);set(l,'color','w');
  l=line([w1(j) w1(j)],[min(w2) max(w2)]);set(l,'color','w');
  
  % maximum likelihood solution (from grid search, which is cheating... normally you would use fminsearch or something like that...)
  ind = find(li==max(li(:)));
  mu  =[vw1(ind) vw2(ind)]; 
  
  % derivatives of a.exp(-bt)
  f   = mu(1)*exp(-mu(2)*t);
  fa  = exp(-mu(2)*t);
  fb  = -mu(1)*t.*exp(-mu(2)*t);
  faa = 0;
  fab = -t.*exp(-mu(2)*t);
  fbb = mu(1)*t.^2.*exp(-mu(2)*t);
  
  % Hessian
  Haa = sum( 2*fa.^2  - 2*(y-f).*(-faa) );
  Hab = sum( 2*fa.*fb - 2*(y-f).*(-fab) );
  Hbb = sum( 2*fb.^2  - 2*(y-f).*(-fbb) );

  % Covariance 
  S   = inv([Haa Hab;Hab Hbb]/2/sig^2);

  % calculate on same grid using analytic formula for multivariate normal
  lap = mvnpdf([vw1(:) vw2(:)],mu,S);
  lap = lap/sum(lap(:));
  lap = reshape(lap,size(vw1));
  
  % plot Laplace
  imagesc(w1,w2,lap);
  [i,j]=ind2sub(size(vw1),ind);
  l=line([w1(j) w1(j)],[min(w2) max(w2)]);set(l,'color','w');
  l=line([min(w1) max(w1)],[w2(i) w2(i)]);set(l,'color','w');
  
  xlabel('a','fontsize',14);
  ylabel('b','fontsize',14);
  
  % plot marginals
  figure,  
  subplot(1,2,1),hold on
  plot(w1,[sum(li,1)' sum(lap,1)']);
  l=line([a a],[0 .2]);set(l,'color','k');
  xlabel('a');
  subplot(1,2,2),hold on
  plot(w2,[sum(li,2) sum(lap,2)]);
  l=line([b b],[0 .2]);set(l,'color','k');
  xlabel('b')
  
  % define a forward model (here y=a*exp(-bx))
  myfun=@(x,c)(x(1)*exp(-x(2)*c));
  % estimate parameters
  x0=[8;1]; % you can get x0 using nonlinear opt
  c=t;
  samples=mh(y,x0,@(x)(myfun(x,c)));
  a_mh=samples(:,1);
  b_mh=samples(:,2);
  % plot samples
  figure
  subplot(1,2,1),plot(a_mh)
  subplot(1,2,2),plot(b_mh)
  
% The next bit of code compares the three distributions (two that can be viewed on a grid and one that consists of samples)

  % plot samples on joint posterior
  figure
  subplot(1,2,1)
  imagesc(w1,w2,lap);
  xlabel('a','fontsize',14);
  ylabel('b','fontsize',14);
  hold on
  plot(a_mh,b_mh,'.k')
  subplot(1,2,2)
  imagesc(w1,w2,li);
  xlabel('a','fontsize',14);
  ylabel('b','fontsize',14);
  hold on
  plot(a_mh,b_mh,'.k')