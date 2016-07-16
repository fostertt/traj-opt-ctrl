clear variables;
% derive_dpendcart();
load('doublePendCartSys.mat', 'sys');
% 3/4 in x 18 swg
% % p.m1 = 0.125; p.b1 = 0;%0.01;
% % p.m2 = 0.098; p.I2 = 0.00205; p.c2 = 0.20956; p.l2 = 0.422; p.b2 = 0.00125;
% % % 2nd pendulum with bob at end
% % % p.m3 = 0.13971; p.I3 = 0.0030865; p.c3 = 0.26557; p.l3 = 0.4; p.b3 = 0.005;
% % % 2nd pendulum w/o bob
% % p.m3 = 0.08646; p.I3 = 0.001446; p.c3 = 0.18; p.l3 = 0.411; p.b3 = 0.00125;
% % p.g = 9.81;

% % 10 swg thick ali tube
% p.m1 = .125; p.b1 = 0;%.01;
% p.m2 = 0.19931639; p.I2 = 0.00338952; p.c2 = 0.21172; p.l2 = 0.422; p.b2 = 0.00125;
% % 2nd pendulum w/o bob
% p.m3 = 0.186976; p.I3 = 0.002831; p.c3 = 0.19704; p.l3 = 0.411; p.b3 = 0.00125;
% p.g = 9.81;
% 
% sys.param = p;

% If parameters change, run these two lines to update gradient function
sys = createDircolNlConGrads2(sys);
save([sys.name 'Sys.mat'], 'sys');
return;

method = 'dircol';
gradients = 'analytic';  % solvergrads/centraldiff/analytic

nPoints = 200;
x0 = [0 0 0 0 0 0]';
xf = [0 pi 0 0 0 0]';

guess = 'trajectories\doublePendCart_2ndequib_120_dircol_1usq_25uMx';%'doublePendCart_30_dircol_1Tsq_1usq_40uMx';

% guess.traj = (xf-x0)*linspace(0, 1, nPoints);
% guess.T = 1.5;
% guess.traj(4:5,:) = (pi/guess.T)*ones(2, nPoints);
% guess.u = zeros(1, nPoints);

% guess = 0;

xLims = [-0.7 -Inf -Inf -8 -Inf -Inf; 0.7 Inf Inf 8 Inf Inf]';
uMax = 25;
tLims = [.1 3];
cost.u = 1;%30/nPoints;
cost.T = 0;%10;%50;
[traj, u, T, param, exitflag, output] = trajOpt2(sys, method, gradients, cost, nPoints, x0, xf, guess, xLims, uMax, tLims);

% typeStr = '2ndequib';
% % % Construct name and save trajectory
% str = [sys.name '_' typeStr '_' num2str(nPoints) '_' method '_'];
% if cost.T > 0, str = [str num2str(cost.T, 2) 'Tsq_']; end
% if cost.u > 0, str = [str num2str(cost.u, 2) 'usq_']; end
% str = ['trajectories/' str num2str(uMax) 'uMx'];
% filename = str;
% condition = true;
% n = 2;
% while condition
%     if exist([filename '.mat'], 'file') == 2
%         filename = [str '_(' num2str(n) ')'];
%     else
%         condition = false;
%     end
%     n = n + 1;
% end
% filename = strrep(filename, '.', '_');
% disp(['Saving trajectory ' filename]);
% saveTrajectory(filename);