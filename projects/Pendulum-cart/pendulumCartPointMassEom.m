function x_dot = pendulumCartPointMassEom(t, x, u, param)
g = param.g;
l = param.l;
m1 = param.m1;
m2 = param.m2;
q1 = x(1);
q1_dot = x(3);
q2 = x(2);
q2_dot = x(4);
x_dot(1:2) = x(3:4);
x_dot(3:4) = pendulumCartPointMass_auto(g,l,m1,m2,q2,q2_dot,u);
x_dot = x_dot';
