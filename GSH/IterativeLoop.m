clear;
close all;
clc;

HOME = pwd;
addpath([HOME '\Tools\'])


%% iteration setup
% plot parameters
aa=24;
whether_to_plot = true;

% numerical parameters
Dr = 10e3; % km
ITRmax = 1;
ModelMax = 3;

% store results
objective = [];

% degree variance


% variables
crust_Te = 54.7e3; %range [20e3,229.5]; % elastic thickness [km]
crust_Tc = 43.1e3; %range [12.5e3,162.5e3]; % mean crustal thickness [km]

%% create baseline planetary model
%% import gravity and topography model
% load spherical gravity harmonics and digital elevation model according to
% model grid
RefModel

% reference degree variance
[n_ref, DV_ref] = degreeVariance(V_ref);

% baseline harmonics
disp(['Model baseline', ' - ITRmax ', num2str(ITRmax), ' - test', num2str(3)]);
tic;
[V_base] = model_SH_analysis(Model);
toc
V_base = sortrows([0 0 1 0; V_base(:, 1:4)],1);
[n_base, DV_base] = degreeVariance(V_base);

%% parameter optimisation
M = 1;
while M<ModelMax+1
    % model setup
    if M==0
        VAR = 0;
    elseif M==1
        VAR = crust_Tc;
    elseif M ==2
        VAR = crust_Tc;
    else
        VAR = crust_Te;
    end

    % fitting for model X
    ITR = 0;    
    while(ITR<ITRmax+1)
        % loop setup 
        Phi_der = 0; % derivative of variable wrt objective function
        Phi_test = [
            VAR-Dr, VAR+Dr, VAR
        ];
        disp(Phi_test);
        Phi_result = [];

        if (ITR==0) | (ITR+1 == ITRmax)
            whether_to_plot = true;
        else
            whether_to_plot = false;
        end

        % test model for each variable
        WTP = whether_to_plot;
        for test=1:length(Phi_test)
            disp(['Model ', num2str(M), ' - ITR ', num2str(ITR), ' - test', num2str(test)]);
            
            if whether_to_plot & (test==3)
                whether_to_plot = true;
            else
                whether_to_plot = false;
            end

            % model crustal inversion
            if M==0
                Dref = crust_Tc;
                DT = zeros("like",A);
            elseif M==1
                Dref = Phi_test(test);
                DT = InversionM1(Dref, whether_to_plot,aa,ITR);
                Gain = 4*10^19;
            elseif M ==2
                Dref = Phi_test(test);
                DT = InversionM2(Dref, whether_to_plot,aa,ITR);
                Gain = 4*10^19;
            else
                %Dref = crust_Tc; %or use previous value opti for M1
                Te = Phi_test(test);
                DT = InversionM3(Dref, Te, whether_to_plot,aa,ITR);
                Gain = -4*10^19;
            end

            % alter boundary gmt
            newbound = matrix2gmt(DT,Lon,Lat);
            %Model.l2.bound = newbound;
            save([HOME '/Data/MercuryCrust/mantle_bd_test.gmt'],'newbound',"-ascii");
            Model.l2.bound = [HOME '/Data/MercuryCrust/mantle_bd_test.gmt'];

            % compute gravity harmonics
            tic;
            [V_test] = model_SH_analysis(Model);
            toc

            % get variance error
            V_test = sortrows([0 0 1 0; V_test(:, 1:4)],1);
            [n_test, DV_test] = degreeVariance(V_test);
            
            DVerr = DV_test - DV_ref;
            OBJ = sum(DVerr);

            % save result
            Phi_result(end+1) = OBJ;

            whether_to_plot = WTP;
        end
        
        % compute slope of VAR wrt OBJ
        Phi_der = (Phi_result(2)-Phi_result(1))/(2*Dr);
        objective(end+1)=Phi_result(3);

        % adapt variable such that OBJ error is minimized
        dVAR = - Phi_der * (Phi_result(3)) * Gain;
        VAR = VAR + dVAR;

        disp([Phi_result(3), Phi_der, dVAR]);

        % next loop
        ITR = ITR+1;
    end
    
    % print out results
    disp(['Model ' num2str(M), 'results:']);
    disp(['SUM(DVerr)=' num2str(objective(end)) 'VAR=' num2str(VAR)]);

    if M==1
        DV_1 = DV_test;
    elseif M==2
        DV_2 = DV_test;
    elseif M==3
        DV_3 = DV_test;
    end
    
    % plot gravity response
    bb = (3/2)*aa;

    sc = clm2sc(V_test);
    gravity_map_norm = GSHS(sc, lonT, 90-latT, L);
    gravity_map = (1+gravity_map_norm) * g_ref;
    gravity_anomaly_map = gravity_map_norm * g_ref;

    figure
    imagesc(lonT,latT,gravity_anomaly_map*1e5);cc=colorbar;
    title(['Gravity Anomaly w.r.t. g_0 of model ' num2str(M)])
    xlabel('Longitude (\circ)','Fontsize',bb)
    ylabel('Latitude (\circ)','Fontsize',bb)
    ylabel(cc,'Gravitational acceleration (mGal)','Fontsize',bb)

    % next model
    M = M +1;
end

% plot all degree variance
title('Degree variance of each model')
xlabel('Spherical harmonics degree','Fontsize',bb)
ylabel('Coefficient','Fontsize',bb)
semilogy(DV_ref,DV_base,DV_1,DV_2,DV_3);
legend('ref','baseline', 'M1', 'M2', 'M3' ,'Location','northwest')
grid on

disp('END');