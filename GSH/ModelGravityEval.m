% makefile for the complete GSH circle for a particular model
clear;
close all;
clc;

addpath('GSH\')
addpath('GSH\Data')
addpath('GSH\Tools')
addpath('GSH\Results')

HOME = pwd;

aa = 12;

D_ref = 125e3;

% Model
% Load previous saved model

%model_name = 'Crust01_crust';
%load(model_name);

% Construct planetary model
disp("Planetary Model");
ModelFit_bd = 0;
PlanetaryModel
save([HOME '/GSH/Results/' Model.name '_new.mat'],'Model');

% Construct gravity model
RefModel

%%%%%%%%%%%%%%%%%%% Computation area %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%% Part that can be modified %%%%%%%%%%%%%%%%%%%%%%%

latLim =    [-89.5 89.5 1];  % [deg] min latitude, max latitude, resolution latitude (preferable similar to latitude)
lonLim =    [-180 180 1];% [deg] min longitude, max longitude, resolution longitude (preferable similar to latitude)
height =    0.0; % height of computation above spheroid
SHbounds =  [0 49]; % Truncation settings: lower limit, upper limit SH-coefficients used


lats = fliplr(latLim(1):latLim(3):latLim(2));
lons = lonLim(1):lonLim(3):lonLim(2);

%%%%%%%%%%%%%% Part that can be modified %%%%%%%%%%%%%%%%%%%%%%%

%% Modify boundary height
% file structure
file_type = 'block';
d = load(Model.l2.bound);

% make gmt editable
if strcmp(file_type,'block')
    [A,Lon,Lat] = gmt2matrix(d);
elseif strcmp(file_type,'gauss')
    [A,Lon,Lat] = gmt2matrix_gauss(d);
else
    error('File type must be string: block or gauss')
end

%% Inversion
% Model 1: Bouguer Inversion
free_air_correction = 2*g_ref*resized_topo_map/R_ref;
free_air_gravity_anomaly = gravity_anomaly_map + free_air_correction;
bouguer_correction = 2*pi*G*rho_crust*resized_topo_map;
bouguer_anomaly=gravity_anomaly_map-bouguer_correction;

deltaR1 = bouguer_anomaly/(2*pi*G*rho_crust);
crustal_thickness_model1 = D_ref + deltaR1;

bound_M1 = matrix2gmt(A + crustal_thickness_model1,Lon,Lat);
save([HOME '/GSH/Data/MercuryCrust/crust_bd_M1.gmt'],'bound_M1',"-ascii");
M1 = Model;
M1.l2.bound = [HOME '/GSH/Data/MercuryCrust/mantle_bd_M1.gmt'];
save([HOME '/GSH/Results/' Model.name '_M1.mat'],'Model');

% Model 2: Airy Isostasy
deltaR2 = resized_topo_map * rho_crust / (rho_mantle - rho_crust);
crustal_thickness_model2 = D_ref + deltaR2;

bound_M2 = matrix2gmt(A + crustal_thickness_model2,Lon,Lat);
save([HOME '/GSH/Data/MercuryCrust/crust_bd_M2.gmt'],'bound_M2',"-ascii");
M2 = Model;
M2.l2.bound = [HOME '/GSH/Data/MercuryCrust/mantle_bd_M2.gmt'];
save([HOME '/GSH/Results/' Model.name '_M2.mat'],'Model');

% Flexure Model
cs3 = GSHA(resized_topo_map, 160);
sc3 = cs2sc(cs3);
Te_ref = 31e3; % Reference elastic thickness in meters
n = 1:size(sc,1);

D = 200e9 * (Te_ref)^3 / (12 * (1 - 0.5^2));
PHI = (1 + D / (500 * 2 / g_ref) .* (2 .* (n + 1) / (2 * R_ref)).^4).^-1;

sc_flex = zeros(size(sc3));
for m = 1:size(sc3,2)
    sc_flex(:,m) = sc3(:,m) .* PHI';
end

mapf = GSHS(sc_flex, lonT, 90-latT, 160);

bound_M3 = matrix2gmt(A + mapf,Lon,Lat);
save([HOME '/GSH/Data/MercuryCrust/crust_bd_M3.gmt'],'bound_M3',"-ascii");
M3 = Model;
M3.l2.bound = [HOME '/GSH/Data/MercuryCrust/mantle_bd_M3.gmt'];
save([HOME '/GSH/Results/' Model.name '_M3.mat'],'Model');

%% Global Spherical Harmonic Analysis 

% baseline
disp("GSHA baseline");
tic;
[V_base] = model_SH_analysis(Model);
toc
save([HOME '/GSH/Results/' Model.name '_V_new.mat'],'V_base')

% M1
M1 = load([HOME '/GSH/Results/' Model.name '_M1.mat']);
disp("GSHA M1");
tic;

[V_M1] = model_SH_analysis(M1.Model);
toc

% M2
M2 = load([HOME '/GSH/Results/' Model.name '_M2.mat']);
disp("GSHA M2");
tic;
[V_M2] = model_SH_analysis(M2.Model);
toc

% M3
M3 = load([HOME '/GSH/Results/' Model.name '_M3.mat']);
disp("GSHA M3");
tic;
[V_M3] = model_SH_analysis(M3.Model);
toc

%% Error between ModelNew and Reference
disp("Delta V");
V_residual = V_ref - V_new;
V_residual(:,1:2) = V_ref(:,1:2);

[n, DV] = degreeVariance(clm);
figure
semilogy(DV)

%% Global Spherical Harmonic Synthesis

% new
disp("GSHS model");
tic;
[data] = model_SH_synthesis(lonLim,latLim,height,SHbounds,V_new,Model);
toc
save([HOME '/GSH/Results/' Model.name '_' num2str(SHbounds(1)) '_' num2str(SHbounds(2)) '_data.mat'],'data')

% new
disp("GSHS ref");
tic;
[data] = model_SH_synthesis(lonLim,latLim,height,SHbounds,V_new,Model);
toc
save([HOME '/GSH/Results/' Model.name '_' num2str(SHbounds(1)) '_' num2str(SHbounds(2)) '_data.mat'],'data')