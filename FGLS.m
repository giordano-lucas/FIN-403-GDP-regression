function [statistics,mapping] = FGLS(X,y,method)
% Compute FGLS on the given data using the given method .
% Methods(slide 6 of GLM lecture) : -'hetero': heteroscedasticity model
%                                 : -'time-series' : time series model 
%Outputs:
%statistics : statistics of the computed FGLS (refer to the compute_statistics function)
%mapping :  function mapping the original space to the transformed
%space (takes (X,y) and return (X2,y2) in the transformed space)
beta = 0;
% if no method specified us classic FGLS
if nargin <= 2
    % number of iteration for the estimation process
    n_iteration = 20;
    % initial ols
    stats_ols = ols(X,y);
    % initial residuals
    residuals = stats_ols.residuals;
    % inital omega matrix
    omega=diag(residuals.^2);

    for i = 1:n_iteration
        % fit model
        invW = omega\eye(size(X,1));
        Q = X'* invW;
        beta=(Q*X)\(Q*y);
        %beta=X'*inv(omega)*X\X'*inv(omega)*y;
        y_hat=X*beta;
        % improve variance matrix estimator
        residuals = y - y_hat;
        est_var = residuals.*residuals;
        % clip variance to avoid division by 0
        est_var(est_var<1e-10) = 1e-10;
        omega = diag(est_var);    
    end
    % output
    statistics = compute_statistics(X,y,beta);
    C = sqrt(invW); % C from lectures slides
    mapping = @(X,y) map(X,y,C);
elseif method == 'hetero' 
    % use the following model for residuals: log(e^T*e) = 1 +
    % log(X+min(X)+1) alpha 
    model = ols(X,y);
    tX    = X(:,2:end);
    minX  =  min(tX);
    tX    = tX - minX + 1;
    one_v = ones(size(X,1),1);
    Z  = [one_v, log(tX)];
    tX = [one_v, tX];
    s  = log(model.residuals.^2);
    % ln(?2i)= Z * alpha
    alpha = ols(Z,s);
    % ??^2=exp(Z * alpha)
    W     = diag(exp(Z*alpha.beta));  
    beta  = inv(tX'*inv(W)*tX)*tX'*inv(W)*y;
    % output
    statistics = compute_statistics(tX,y,beta);
    C = sqrt(inv(W)); % C from lectures slides
    mapping = @(X,y) map(logtransform(X,minX),y,C);
else
    disp("Error bad argument")
end

end

function [tX]  = logtransform(X,minX)
    tX = X(:,2:end);
    tX = tX - minX + 1;
    tX = [ones(size(X,1),1), tX];
end

function [tX,ty] = map(X,y,C) 
    tX = C*X;
    ty = C*y;
end
