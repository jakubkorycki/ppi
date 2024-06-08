% makefile for the complete GSH circle for a particular model
clear;
close all;
clc;

addpath('GSH\')
addpath('GSH\Data')
addpath('GSH\Tools')
addpath('GSH\Results')

HOME = pwd;

% Model
% Load previous saved model

%model_name = 'Crust01_crust';
%load(model_name);

% Construct new model
disp("Planetary Model");
ModelFit_bd = 0;
PlanetaryModel

%%%%%%%%%%%%%%%%%%% Computation area %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%% Part that can be modified %%%%%%%%%%%%%%%%%%%%%%%

latLim =    [-89.5 89.5 1];  % [deg] min latitude, max latitude, resolution latitude (preferable similar to latitude)
lonLim =    [-180 180 1];% [deg] min longitude, max longitude, resolution longitude (preferable similar to latitude)
height =    0.0; % height of computation above spheroid
SHbounds =  [0 49]; % Truncation settings: lower limit, upper limit SH-coefficients used


lats = fliplr(latLim(1):latLim(3):latLim(2));
lons = lonLim(1):lonLim(3):lonLim(2);

%%%%%%%%%%%%%% Part that can be modified %%%%%%%%%%%%%%%%%%%%%%%

%% Reference Model
disp("Reference Model");
RefModel

%% Global Spherical Harmonic Analysis 

% new
disp("GSHA new");
tic;
%Model.l1.bound = [HOME '/Data/MercuryCrust/crust_bd_new.gmt'];
[V_new] = model_SH_analysis(Model);
toc
save([HOME '/GSH/Results/' Model.name '_V_new.mat'],'V_new')

% low
disp("GSHA low");
tic;
Model.l1.bound = [HOME '/GSH/Data/MercuryCrust/crust_bd_low.gmt'];
[V_low] = model_SH_analysis(Model);
toc

% high
disp("GSHA high");
tic;
Model.l1.bound = [HOME '/GSH/Data/MercuryCrust/crust_bd_high.gmt'];
[V_high] = model_SH_analysis(Model);
toc

%% Error between ModelNew and Reference
disp("Delta V");
V_residual = V_ref - V_new;
V_residual(:,1:2) = V_ref(:,1:2);

%% Global Spherical Harmonic Synthesis

% new
disp("GSHS residual");
tic;
Model.l1.bound = [HOME '/GSH/Data/MercuryCrust/crust_bd_new.gmt'];
[data] = model_SH_synthesis(lonLim,latLim,height,SHbounds,V_residual,Model);
toc
save([HOME '/GSH/Results/' Model.name '_' num2str(SHbounds(1)) '_' num2str(SHbounds(2)) '_data.mat'],'data')

