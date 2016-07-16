function [traj, u, T, param, exitflag, output] = trajOpt(sys, method, cost, nPoints, x0, xf, guess, xLims, uMax, tLims)
    clear varss; close all;
    
    % System mechanics properties
    param = sys.param;
    % Trajectory optimization parameters
    param.nKnotPoints = nPoints;
    param.nStates = sys.nStates;
    param.dynFun = sys.x_dot_fun;
    param.xf = xf;
    param.cost = cost;
    xmin = xLims(:, 1);
    xmax = xLims(:, 2);
    tmin = tLims(1);
    tmax = tLims(2);
    
    % Check method
    if strcmp(method, 'dircol')
        uLen = nPoints;
        nlConFun = @nlConDirCol;
    elseif strcmp(method, 'rk4')
        uLen = nPoints-1;
        nlConFun = @nlConRk4;
    else
        error('Unknown method specified');
    end
    param.xIdx = [1 param.nKnotPoints*param.nStates];
    param.uIdx = [param.xIdx(2)+1, param.xIdx(2)+uLen];
    param.tIdx = param.uIdx(end)+1;

    % Initialize decision variables
    % Decision variables look like this: decVars = [ [x0 xdot0] ... [xn xdotn] u0 ... uN T]'

    if ischar(guess)
        [traj, u, T, ~] = loadTrajectory([guess '.mat'], param.nKnotPoints);
        guess = reshape(traj, 1, param.nStates*param.nKnotPoints);
        guess = [guess, u(1:uLen), T];
    elseif isstruct(guess)
        u = guess.u;
        T = guess.T;
        guess = reshape(guess.traj, 1, param.nStates*param.nKnotPoints);
        guess = [guess, u(1:uLen), T];
    elseif guess == 0
        guess = zeros(1, param.nKnotPoints*param.nStates + uLen + 1);
    else
        error('Problem with initial guess');
    end
    
    options = optimoptions(@fmincon, ...
        'Algorithm', 'interior-point', ...     %'sqp'); , 'interior-point',
        'TolFun', 1e-12, ...         %         'TolX', 1e-6, ...
        'TolCon', 1e-12, ...
        'TolX', 1e-12, ...
        'MaxFunEvals', 10000000, ...
        'UseParallel','always', ...
        'Display', 'iter-detailed', ...
        'MaxIter', 1000000 ...
    );
%     options = optimoptions(options,'GradObj','on','GradConstr','on');

    lb = [x0' repmat(xmin', 1, param.nKnotPoints-2) xf' -uMax*ones(1, uLen) tmin];
    ub = [x0' repmat(xmax', 1, param.nKnotPoints-2) xf' uMax*ones(1, uLen) tmax];
    tic
    [x, fval, exitflag, output] = fmincon(@(decVars)costfun(decVars, param), guess, [], [], [], [], lb, ub, @(decVars) nlConFun(decVars, param), options);
    toc
    % Repackage decision variables as states, controls and end time
    T = x(param.tIdx);
    traj = reshape(x(param.xIdx(1):param.xIdx(2)), param.nStates, param.nKnotPoints);
    u = x(param.uIdx(1):param.uIdx(2));
end

function cost = costfun(decVars, param)
    u = decVars(param.uIdx(1):param.uIdx(2));
    T = decVars(param.tIdx);
%     cost = sum(u.^2) + 200*T^2;% + norm(d)^2;
    cost = param.cost.u*sum(u.^2) + param.cost.T*T^2;
%     T = decVars(end);
%     cost = T^2;
end

function plotPhaseDiagram(x, u, param)
    persistent callCount;
    
    [nStates, ~] = size(x);
    % Plot this trajectory
    if isempty(callCount)
        callCount = 1;
    else
        callCount = callCount+1;
    end
    if ~(callCount == 1) && rem(callCount, 10) == 0
        for n = 1:nStates/2
%         disp(num2str(callCount));
            tStr = ['q' num2str(n)];
            subplot(nStates/2+1, 1, n);
            plot(x(n, :), x(n+nStates/2, :), '-+'); grid on;
            xlabel(tStr); ylabel([tStr ' dot']);
%             subplot(2, 1, 2);
%             plot(x(2, :), x(4, :), '-+'); grid on;
%             xlabel('theta'); ylabel('theta_dot');
        end
        subplot(nStates/2+1, 1, nStates/2+1);
        plot(u);
        ylabel('u');
        drawnow;
    end
end    

function [cineq, ceq] = nlConRk4(decVars, param)
    T = decVars(param.tIdx);
    x = reshape(decVars(param.xIdx(1):param.xIdx(2)), param.nStates, param.nKnotPoints);
    u = decVars(param.uIdx(1):param.uIdx(2));
    % Plot phase diagram
    plotPhaseDiagram(x, u, param);
    % Create time vector
    t = linspace(0, T, param.nKnotPoints);
    % Step size
    h = t(2) - t(1);
    defects = zeros(param.nStates, param.nKnotPoints-1);
    for n = 1:param.nKnotPoints-1;
        x0 = x(:, n);
        k1 = param.dynFun(t(n), x0, u(n), param);
        k2 = param.dynFun(t(n) + h/2, x0 + k1*h/2, u(n), param);
        k3 = param.dynFun(t(n) + h/2, x0 + k2*h/2, u(n), param);
        k4 = param.dynFun(t(n) + h, x0 + h*k3, u(n), param);
        x1 = (x0 + (h/6)*(k1 + 2*k2 + 2*k3 + k4));
        defects(:, n) = x1 - x(:, n+1);
    end
    defects = reshape(defects, 1, param.nStates*(param.nKnotPoints-1));
    boundaryEnd = (x(:, end) - param.xf)';
    ceq = [defects boundaryEnd];
    % No inequality constraints
    cineq = [];
end

function [cineq, ceq] = nlConDirCol(decVars, param)
    T = decVars(param.tIdx);
    x = reshape(decVars(param.xIdx(1):param.xIdx(2)), param.nStates, param.nKnotPoints);
    u = decVars(param.uIdx(1):param.uIdx(2));
    % Plot phase diagram
    plotPhaseDiagram(x, u, param);
    % Create time vector
    t = linspace(0, T, param.nKnotPoints);
    % Step size
    h = t(2) - t(1);
    defects = zeros(param.nStates, param.nKnotPoints-1);
    for n = 1:param.nKnotPoints-1;
        x0 = x(:, n);
        x1 = x(:, n+1);
        u0 = u(n);
        u1 = u(n+1);
        f0 = param.dynFun(t(n), x0, u0, param);
        f1 = param.dynFun(t(n+1), x1, u1, param); % pendulum_cart_eom
        x_c = .5*(x0 + x1) + .125*h*(f0-f1);
        x_dot_c = 3*(x1 - x0)/(2*h) - .25*(f0+f1); 
        u_c = (u0 + u1)/2;  % First order hold (linear)
        t_c = (t(n)+t(n+1))/2;
        f_c = param.dynFun(t_c, x_c, u_c, param); 
        defects(:, n) = x_dot_c - f_c;
    end
    defects = reshape(defects, 1, param.nStates*(param.nKnotPoints-1));
%     boundaryEnd = (x(:, end) - param.xf)';
    ceq = [defects];% boundaryEnd];
    % No inequality constraints
    cineq = [];
end