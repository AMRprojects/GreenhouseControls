clc;clear;close all;
%% Define Parameters

V = 4000;       %Volume of air in greenhouse, m^3
U = 25;         %heat transfer coefficient W/(Km^2)
A = 1000;       %Surface area of greenhouse, m^2
rho = 1.2;      %Density of air, kg/m^3
Cp = 1006;      %specific heat of air, J/kgK
gamma = 2257;   %latent heat of vaporization, J/g
Sr_e = 300;     %solar radiation external to greenhouse @equilibrium (W/m^2)
Tout_e = 25;    %outside temp @equilibrium (degCelcius)
Wout_e = 4;     %outside humidity @equilbrium (g/m^3)
Vt_e = 10;      %ventilation rate @equilibrium (m^3/s)
Qfog_e = 18;    %water capacity of fog system @equilibrium (g/s)
Qh = 0;         %control variable heater, not required (W)
alpha = 0.125;  %leaf cover coefficient

Si = Sr_e*A;
E = alpha * Si/gamma;

% Equilibrium values for outputs
Tin_e = Tout_e + (1/(rho*Vt_e*Cp + U*A))*(Si - gamma*Qfog_e) ;   
win_e = Wout_e + (1/Vt_e)*(Qfog_e + E);


%% Calculate Linearized Matrices

u1e = Vt_e;
u2e = Qfog_e;
d1e = Tout_e;
d2e = Wout_e;
d3e = Sr_e;
x1e = Tin_e;
x2e = win_e;

dfdx1 = (-u1e/V)-((U*A)/(rho*V*Cp));
dfdx2 = 0;
dgdx1 = 0;
dgdx2 = -u1e/(rho*V);

dfdu1 = (-x1e/V)+(d1e/V);
dfdu2 = -gamma/(rho*V*Cp);
dgdu1 = (-x2e/(rho*V))+(d2e/(rho*V));
dgdu2 = 1/(rho*V);

dfdd1 = (u1e/V)+((U*A)/(rho*V*Cp));
dfdd2 = 0;
dfdd3 = A/(rho*V*Cp);
dgdd1 = 0;
dgdd2 = u1e/(rho*V);
dgdd3 = (alpha*A)/(gamma*rho*V);

A_m = [dfdx1 dfdx2; dgdx1 dgdx2];
B = [dfdu1 dfdu2; dgdu1 dgdu2];
Bd = [dfdd1 dfdd2 dfdd3; dgdd1 dgdd2 dgdd3];
C = [1 0;0 1];
D = 0;

%% Transfer Functions
states = {'Temperature' 'Humidity'};
inputs = {'Ventilation' 'Fogging'};
outputs = {'Temperature' 'Humidity'};
G = ss(A_m,B,C,D,'statename',states,'inputname',inputs,'outputname',outputs);

inputs2 = {'Outside Temp' 'Outside Humidity' 'Solar Radiation'};
Gd = ss(A_m,Bd,C,D,'statename',states,'inputname',inputs2,'outputname',outputs);
Gdt =tf(Gd);

td = 147.625;
G_delay = G;
G_delay.IODelay = [td td;td td];
GM = tf(G);

numerators = {-0.212,-0.061; -0.281,0.100};
denoms = {[126.892 1],[130.829 1];[435.488 1],[480.172 1]};
P_art = tf(numerators,denoms,'inputname',inputs,'outputname',outputs);
P = P_art;
P_art.IODelay = [td td;td td];

%% RGA
RGA = dcgain(P).*inv(dcgain(P))';

D_12 = -0.287;              %Decoupler
D_21 = 2.813;               %Decoupler
W_1 = [1 D_12;D_21 1];      %Pre-compensator
Pstar = P*W_1;

RGA_star = dcgain(Pstar).*inv(dcgain(Pstar))';

%% System Insights

% Equilibrium Conditions
Vt = Vt_e;
Qfog = Qfog_e;
Tout = Tout_e;
wout = Wout_e;
Sr = Sr_e;
out = sim("greenhouse_model.slx");
EquiTemp = out.y_NL.data(:,1);
EquiHum = out.y_NL.data(:,2);

% Venting Range
Vt = Vt+8;
out = sim("greenhouse_model.slx");
time = out.time.data./60;
figure(1)
subplot(1,2,1)
plot(time,out.y_NL.data(:,1),time,out.y_Lin.data(:,1))
grid on;
xlabel('Time, min')
ylabel('Temperature, Celcius')
legend('Nonlinear', 'Linear','Location','best')
subplot(1,2,2)
plot(time,out.y_NL.data(:,2),time,out.y_Lin.data(:,2))
grid on;
xlabel('Time, min')
ylabel('Humidity, g/kg')
legend('Nonlinear', 'Linear','Location','best')
sgtitle('Maximum Venting Action')
Vt = Vt_e;

% Fogging Range
Qfog = Qfog+50;
out = sim("greenhouse_model.slx");
time = out.time.data./60;
figure(2)
subplot(1,2,1)
plot(time,out.y_NL.data(:,1),time,out.y_Lin.data(:,1))
grid on;
xlabel('Time, min')
ylabel('Temperature, Celcius')
legend('Nonlinear', 'Linear','Location','best')
subplot(1,2,2)
plot(time,out.y_NL.data(:,2),time,out.y_Lin.data(:,2))
grid on;
xlabel('Time, min')
ylabel('Humidity, g/kg')
legend('Nonlinear', 'Linear','Location','best')
sgtitle('Maximum Fogging Action')
Qfog = Qfog_e;

% Outside Temp Range
Tout = Tout-25;
out = sim("greenhouse_model.slx");
time = out.time.data./60;
figure(3)
subplot(1,2,1)
plot(time,out.y_NL.data(:,1),time,out.y_Lin.data(:,1))
grid on;
xlabel('Time, min')
ylabel('Temperature, Celcius')
legend('Nonlinear', 'Linear','Location','best')
subplot(1,2,2)
plot(time,out.y_NL.data(:,2),time,out.y_Lin.data(:,2))
grid on;
xlabel('Time, min')
ylabel('Humidity, g/kg')
legend('Nonlinear', 'Linear','Location','best')
sgtitle('Maximum Outside Temperature Disturbance')
Tout = Tout_e;

% Outside Humidity Range
wout = wout+20;
out = sim("greenhouse_model.slx");
time = out.time.data./60;
figure(4)
subplot(1,2,1)
plot(time,out.y_NL.data(:,1),time,out.y_Lin.data(:,1))
grid on;
xlabel('Time, min')
ylabel('Temperature, Celcius')
legend('Nonlinear', 'Linear','Location','best')
subplot(1,2,2)
plot(time,out.y_NL.data(:,2),time,out.y_Lin.data(:,2))
grid on;
xlabel('Time, min')
ylabel('Humidity, g/kg')
legend('Nonlinear', 'Linear','Location','best')
sgtitle('Maximum Outside Humidity Disturbance')
wout = Wout_e;

% Solar Radiation Range
Sr = Sr-Sr_e;
out = sim("greenhouse_model.slx");
time = out.time.data./60;
figure(5)
subplot(1,2,1)
plot(time,out.y_NL.data(:,1),time,out.y_Lin.data(:,1))
grid on;
xlabel('Time, min')
ylabel('Temperature, Celcius')
legend('Nonlinear', 'Linear','Location','best')
subplot(1,2,2)
plot(time,out.y_NL.data(:,2),time,out.y_Lin.data(:,2))
grid on;
xlabel('Time, min')
ylabel('Humidity, g/kg')
legend('Nonlinear', 'Linear','Location','best')
sgtitle('Maximum Solar Radiation Disturbance')
Sr = Sr_e;


%% Controller
s = tf('s');
K_art = [-1.014*((126.892*s+1)/(126.892*s)) 0;
    0 3.253*((480.172*s+1)/(480.172*s))];

T = feedback(P_art*W_1*K_art,eye(2));       %with Decoupling
S = eye(2)-T;

Tcouple = feedback(P_art*K_art,eye(2));

% Step Input Comparison with and without Decoupling
figure(6)
step(T,Tcouple)
grid on;

title('Closed Loop Step Response')
legend('Decoupled Plant','Coupled Plant','Location','best')

% Infinity Norms
% Plant vs Disturbance Plant
figure(7)
sigma(P,Gdt)
grid on;
legend('G','Gd')

figure(8)
step(Gdt)
grid on;
figure(9)
step(P)
grid on;

% S,T,SGd
figure(10)
sigma(S,T,S*Gdt)
grid on;
legend('S','T','SGd','Location','best')

[yd toutd] = step(T);
Temperature_d = yd(:,1,1)+yd(:,1,2);
Humidity_d = yd(:,2,1)+yd(:,2,2);
[yc toutc] = step(Tcouple);
Temperature = yc(:,1,1)+yc(:,1,2);
Humidity = yc(:,2,1)+yc(:,2,2);

figure(11)
plot(toutd./60,Temperature_d,toutc./60,Temperature)
grid on;
title('Coupled Temperature Response vs Decoupled Temperature Response')
xlabel('Time, min')
ylabel('Temperature, Celcius')
legend('Decoupled', 'Coupled','Location','best')

figure(12)
plot(toutd./60,Humidity_d,toutc./60,Humidity)
grid on;
title('Coupled Humidity Response vs Decoupled Humidity Response')
xlabel('Time, min')
ylabel('Humidity, g/kg')
legend('Decoupled', 'Coupled','Location','best')








