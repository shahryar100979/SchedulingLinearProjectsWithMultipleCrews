%% Description
% Linear Scheduling of Repetitive Construction Projects

%% Deriving results of:
% Altuwaim, A., & El-Rayes, K. (2018). Optimizing the scheduling of repetitive construction to minimize interruption cost. Journal of Construction Engineering and Management, 144(7), 04018051.

%{

Highlights:
(a) Linear scheduling model for repetitive construction projects
(b) Untypical projects where the quantity of works at units can be different
(c) Considers crew idle cost and dismissal cost
(d) Identifies the optimal order of units
(e) Capable of considering buffer time between activities
(f) Capable of considering multiple crews

%}

%% Initialization
clc
clear
close all

%% Start the counter for recording computational time
tic

% instantiate the variable to store computational time
elapsed_time = zeros(1) ;
%% Load repetitive project and construction crews data
load Zuo2020_caseStudyData.mat

%% Validation Purpose Only
% if you want to validate the results with Dr. Elrayes 2018 paper results that includes one crew only

validation_only          = false  ; % boolean for deriving the results of Dr. Elrayes 2018 paper
if validation_only
    % set order of executing unit fixed
    fixed_order_of_execution = true ;
    
    % use only one crew
    crew_num_in_validation = 1 ;
    Productivity         = Productivity(:,crew_num_in_validation)  ;
    DailyCrewCost        = DailyCrewCost(:,crew_num_in_validation) ;
    CrewMobilizationCost = CrewMobilizationCost(:,crew_num_in_validation) ;
    CrewMobilizationTime = CrewMobilizationTime(:,crew_num_in_validation) ;
else
    fixed_order_of_execution = false ; % boolean for the order of executing units
end

%% Define the problem input data

K  = size(Quantity,1) ; % number of repetitive activities
NI = size(Quantity,2) ; % number of units

NF = 1  ; % number of dummy finish unit for each crew
NS = 1  ; % number of dummy start unit for each crew
NT = NI ; % number of dummy interruption unit for each crew
NP = 1 ; % number of dummy temporary dismissal unit for each crew

num_crews     = sum(Productivity./Productivity,2,'omitnan') ; % number of available crews for each activity
max_num_crews = max(num_crews) ; % identify the maximum number of crews available accross all the activities

T_min = 1 ; % minimum work duration in another project

daily_indirect_cost = 20000 ; % from paper "Optimization model for resource assignment problems of linear construction projects"
if validation_only
    daily_indirect_cost = 5000 ; % to derive El-rayes results a high indirect cost is set to ensure the duration of project is minimized
end

strict_LOB_project_duration = LOB_scheduling(Quantity,Productivity,BufferTime) ;
M_T = strict_LOB_project_duration * 2 ; % a large number that is >>> project duration
% M_T = 180 ; % a large number that is >>> project duration
M_R = 50  ; % maximum duration of interuption at each unit in days

time_limit = 60*10 ; % optimization time limit (seconds)
constraint_tolerance = 1e-6 ;
num_optimization_round = 2 ; % numbe of times the optimization will be restarted
iterative_optimization_time_limit = 10*60 ;
%% Define the optimization problem

% Instantiate the minimization problem
LS_Problem = optimproblem('Description','Linear Scheduling of Repetitive Construction Projects',...
    'ObjectiveSense','min');

%% Identify the decision variables

%% crews movement - Integer

% instantiate x for NI --> NI
lb = zeros(NI,NI,K,max_num_crews) ;
ub = ones(NI,NI,K,max_num_crews) ;
for k = 1:K
    for it_crew = 1:num_crews(k)
        ub(:,:,k,it_crew) = ub(:,:,k,it_crew) - diag(ones(1,NI)) ;
    end
    for it_crew = num_crews(k)+1:max_num_crews
        ub(:,:,k,it_crew) = zeros(NI,NI) ;
    end
end
x_NI_NI = optimvar('x_NI_NI',NI,NI,K,max_num_crews,'LowerBound',lb,'UpperBound',ub,'Type','integer');


% instantiate x for NI --> NF
lb = zeros(NI,NF,K,max_num_crews) ;
ub = ones(NI,NF,K,max_num_crews)  ;
for k = 1:K
    for it_crew = num_crews(k)+1:max_num_crews
        ub(:,:,k,it_crew) = zeros(NI,NF) ;
    end
end
x_NI_NF = optimvar('x_NI_NF',NI,NF,K,max_num_crews,'LowerBound',lb,'UpperBound',ub,'Type','integer');


% instantiate x for NI --> NT
lb = zeros(NI,NT,K,max_num_crews) ;
ub = ones(NI,NT,K,max_num_crews)  ;
for k = 1:K
    for it_crew = num_crews(k)+1:max_num_crews
        ub(:,:,k,it_crew) = zeros(NI,NT) ;
    end
end
x_NI_NT = optimvar('x_NI_NT',NI,NT,K,max_num_crews,'LowerBound',lb,'UpperBound',ub,'Type','integer');


% instantiate x for NS --> NI
lb = zeros(NS,NI,K,max_num_crews) ;
ub = ones(NS,NI,K,max_num_crews)  ;
for k = 1:K
    for it_crew = num_crews(k)+1:max_num_crews
        ub(:,:,k,it_crew) = zeros(NS,NI) ;
    end
end
x_NS_NI = optimvar('x_NS_NI',NS,NI,K,max_num_crews,'LowerBound',lb,'UpperBound',ub,'Type','integer');


% instantiate x for NT --> NI
lb = zeros(NT,NI,K,max_num_crews) ;
ub = ones(NT,NI,K,max_num_crews)  ;
for k = 1:K
    for it_crew = num_crews(k)+1:max_num_crews
        ub(:,:,k,it_crew) = zeros(NT,NI) ;
    end
end
x_NT_NI = optimvar('x_NT_NI',NT,NI,K,max_num_crews,'LowerBound',lb,'UpperBound',ub,'Type','integer');


% instantiate x for NT --> NP
lb = zeros(NT,NP,K,max_num_crews) ;
ub = zeros(NT,NP,K,max_num_crews)  ;
for k = 1:K
    for it_crew = num_crews(k)+1:max_num_crews
        ub(:,:,k,it_crew) = zeros(NT,NP) ;
    end
end
x_NT_NP = optimvar('x_NT_NP',NT,NP,K,max_num_crews,'LowerBound',lb,'UpperBound',ub,'Type','integer');


% instantiate x for NP --> NI
lb = zeros(NP,NI,K,max_num_crews) ;
ub = zeros(NP,NI,K,max_num_crews)  ;
for k = 1:K
    for it_crew = num_crews(k)+1:max_num_crews
        ub(:,:,k,it_crew) = zeros(NP,NI) ;
    end
end
x_NP_NI = optimvar('x_NP_NI',NP,NI,K,max_num_crews,'LowerBound',lb,'UpperBound',ub,'Type','integer');

%% Start times  - continuous
% start time of crews at units and all other dummy activities

% instantiate x for NI --> NI
lb = zeros(NI,K,max_num_crews)    ;
ub = M_T*ones(NI,K,max_num_crews) ;
for k = 1:K
    for it_crew = num_crews(k)+1:max_num_crews
        ub(:,k,it_crew) = zeros(NI,1) ;
    end
end
xs_NI = optimvar('xs_NI',NI,K,max_num_crews,'LowerBound',lb,'UpperBound',ub,'Type','continuous');


lb = zeros(NS,K,max_num_crews)    ;
ub = M_T*ones(NS,K,max_num_crews) ;
for k = 1:K
    for it_crew = num_crews(k)+1:max_num_crews
        ub(:,k,it_crew) = zeros(NS,1) ;
    end
end
xs_NS = optimvar('xs_NS',NS,K,max_num_crews,'LowerBound',lb,'UpperBound',ub,'Type','continuous');


lb = zeros(NF,K,max_num_crews)    ;
ub = M_T*ones(NF,K,max_num_crews) ;
for k = 1:K
    for it_crew = num_crews(k)+1:max_num_crews
        ub(:,k,it_crew) = zeros(NF,1) ;
    end
end
xs_NF = optimvar('xs_NF',NF,K,max_num_crews,'LowerBound',lb,'UpperBound',ub,'Type','continuous');


lb = zeros(NT,K,max_num_crews)    ;
ub = M_T*ones(NT,K,max_num_crews) ;
for k = 1:K
    for it_crew = num_crews(k)+1:max_num_crews
        ub(:,k,it_crew) = zeros(NT,1) ;
    end
end
xs_NT = optimvar('xs_NT',NT,K,max_num_crews,'LowerBound',lb,'UpperBound',ub,'Type','continuous');


lb = zeros(NP,K,max_num_crews)    ;
ub = M_T*ones(NP,K,max_num_crews) ;
for k = 1:K
    for it_crew = num_crews(k)+1:max_num_crews
        ub(:,k,it_crew) = zeros(NP,1) ;
    end
end
xs_NP = optimvar('xs_NP',NP,K,max_num_crews,'LowerBound',lb,'UpperBound',ub,'Type','continuous');


%% interruptions duration at current project
lb = zeros(NT,K,max_num_crews) ;
ub = M_R*ones(NT,K,max_num_crews) ;
for k = 1:K
    for it_crew = num_crews(k)+1:max_num_crews
        ub(:,k,it_crew) = zeros(NT,1) ;
    end
end
it_NT = optimvar('it_NT',NT,K,max_num_crews,'LowerBound',lb,'UpperBound',ub,'Type','continuous');

%% dismissal duration at another project
lb = T_min*ones(NP,K,max_num_crews) ;
ub = M_R*ones(NP,K,max_num_crews)   ;
pt_NT = optimvar('pt_NT',NP,K,max_num_crews,'LowerBound',lb,'UpperBound',ub,'Type','continuous');


%% Formulate the constraints

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Consistency %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% consistency at units: flow conservation
cons1b = optimconstr(1);
count = 1 ;
for k = 1:K
    for it_crew = 1:num_crews(k)
        for i = 1:NI
            cons1b(count) = sum(x_NI_NI(i,:,k,it_crew)) + sum(x_NI_NF(i,:,k,it_crew)) + sum(x_NI_NT(i,:,k,it_crew)) - ...
                sum(x_NI_NI(:,i,k,it_crew)) - sum(x_NS_NI(:,i,k,it_crew)) - sum(x_NT_NI(:,i,k,it_crew)) - sum(x_NP_NI(:,i,k,it_crew))  == 0 ;
            count = count + 1 ;
        end
    end
end

% consistency at interruptions: flow conservation
cons1c = optimconstr(1);
count = 1 ;
for k = 1:K
    for it_crew = 1:num_crews(k)
        for i = 1:NT
            cons1c(count) = sum(x_NT_NI(i,:,k,it_crew)) + sum(x_NT_NP(i,:,k,it_crew)) - sum(x_NI_NT(:,i,k,it_crew)) == 0 ;
            count = count + 1 ;
        end
    end
end


% consistency at dummy projects: flow conservation
cons1d = optimconstr(1);
count = 1 ;
for k = 1:K
    for it_crew = 1:num_crews(k)
        for i = 1:NP
            cons1d(count) = sum(x_NP_NI(i,:,k,it_crew)) - sum(x_NT_NP(:,i,k,it_crew)) == 0 ;
            count = count + 1 ;
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%% Assignments %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Units completion: all units should be completed
cons1a = optimconstr(1);
count  = 1 ;
for k = 1:K
    for i = 1:NI
        cons1a(count) = sum(sum(x_NI_NI(i,:,k,:))) + sum(sum(x_NI_NF(i,:,k,:))) + sum(sum(x_NI_NT(i,:,k,:))) == 1 ;
        count = count + 1 ;
    end
end


% all crews start at the dummy start activity
cons1e = optimconstr(1);
count  = 1 ;
for k = 1:K
    for it_crew = 1:num_crews(k)
        for i = 1:NS
            cons1e(count) = sum(x_NS_NI(i,:,k,it_crew)) == 1 ;
            count = count + 1 ;
        end
    end
end


% all crews finish at the dummy finish activity
cons1f = optimconstr(1);
count  = 1 ;
for k = 1:K
    for it_crew = 1:num_crews(k)
        for i = 1:NF
            cons1f(count) = sum(x_NI_NF(:,i,k,it_crew)) == 1 ;
            count = count + 1 ;
        end
    end
end

% relaxed single assignment at dummy interruption activities
cons1g = optimconstr(1);
count  = 1 ;
for k = 1:K
    for it_crew = 1:num_crews(k)
        for i = 1:NT
            cons1g(count) = sum(x_NT_NI(i,:,k,it_crew)) + sum(x_NT_NP(i,:,k,it_crew)) <= 1 ;
            count = count + 1 ;
        end
    end
end

% relaxed single assignment at dummy projects
cons1h = optimconstr(1);
count  = 1 ;
for k = 1:K
    for it_crew = 1:num_crews(k)
        for i = 1:NP
            cons1h(count) = sum(x_NP_NI(i,:,k,it_crew)) <= 1 ;
            count = count + 1 ;
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  Routing  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% routing at dummy interruption activities
cons1i = optimconstr(1);
count  = 1 ;
M      = -2*NT ;
for k = 1:K
    for it_crew = 1:num_crews(k)
        for i = 1:NT
            cons1i(count) = sum(x_NT_NI(i,:,k,it_crew)) + sum(x_NT_NP(i,:,k,it_crew)) >= M*( 1-sum(x_NI_NT(:,i,k,it_crew)) ) + 1 ;
            count = count + 1 ;
        end
    end
end



% routing assignment at dummy projects
cons1j = optimconstr(1);
count  = 1 ;
M      = -2*NI ;
for k = 1:K
    for it_crew = 1:num_crews(k)
        for i = 1:NP
            cons1j(count) = sum(x_NP_NI(i,:,k,it_crew)) >= M*( 1-sum(x_NT_NP(:,i,k,it_crew)) ) + 1  ;
            count = count + 1 ;
        end
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Interruption  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cons1k = optimconstr(1);
count  = 1 ;
M      = -M_T ;
for k = 1:K
    for it_crew = 1:num_crews(k)
        for i = 1:NT
            for j = 1:NI
                cons1k(count) = it_NT(i,k,it_crew) >= M*( 1-sum(x_NI_NT(j,i,k,it_crew)) ) ;
                count = count + 1 ;
            end
        end
    end
end


cons1l = optimconstr(1);
count  = 1 ;
M      = -M_T ;
for k = 1:K
    for it_crew = 1:num_crews(k)
        for i = 1:NP
            for j = 1:NT
                cons1l(count) = pt_NT(i,k,it_crew) >= M*( 1-sum(x_NT_NP(j,i,k,it_crew)) ) + T_min ;
                count = count + 1 ;
            end
        end
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Time %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% start time at unit j should be greater or equal than finish time of the
% preceding activity (NI ---> NI)
cons2a = optimconstr(1);
count  = 1 ;
for k = 1:K
    for it_crew = 1:num_crews(k)
        for i = 1:NI
            for j = 1:NI
                if i == j; continue; end
                cons2a(count) = xs_NI(i,k,it_crew)  + Quantity(k,i)/Productivity(k,it_crew) + 1 - ...
                    xs_NI(j,k,it_crew) <= M_T*(1-x_NI_NI(i,j,k,it_crew)) ;
                count = count + 1 ;
                cons2a(count) = -xs_NI(i,k,it_crew) - Quantity(k,i)/Productivity(k,it_crew) - 1 + ...
                    xs_NI(j,k,it_crew) <= M_T*(1-x_NI_NI(i,j,k,it_crew)) ;
                count = count + 1 ;
            end
        end
    end
end


% start time at unit j should be greater or equal than finish time of the
% preceding activity (NI ---> NF)
cons2b = optimconstr(1);
count  = 1 ;
for k = 1:K
    for it_crew = 1:num_crews(k)
        for i = 1:NI
            for j = 1:NF
                cons2b(count) = xs_NI(i,k,it_crew)  + Quantity(k,i)/Productivity(k,it_crew) - ...
                    xs_NF(j,k,it_crew) <= M_T*(1-x_NI_NF(i,j,k,it_crew)) ;
                count = count + 1 ;
                cons2b(count) = -xs_NI(i,k,it_crew) - Quantity(k,i)/Productivity(k,it_crew) + ...
                    xs_NF(j,k,it_crew) <= M_T*(1-x_NI_NF(i,j,k,it_crew)) ;
                count = count + 1 ;
            end
        end
    end
end


% start time at unit j should be greater or equal than finish time of the
% preceding activity (NI ---> NT)
cons2c = optimconstr(1);
count  = 1 ;
for k = 1:K
    for it_crew = 1:num_crews(k)
        for i = 1:NI
            for j = 1:NT
                cons2c(count) = xs_NI(i,k,it_crew)  + Quantity(k,i)/Productivity(k,it_crew) + 1 - ...
                    xs_NT(j,k,it_crew) <= M_T*(1-x_NI_NT(i,j,k,it_crew)) ;
                count = count + 1 ;
                cons2c(count) = -xs_NI(i,k,it_crew) - Quantity(k,i)/Productivity(k,it_crew) - 1 + ...
                    xs_NT(j,k,it_crew) <= M_T*(1-x_NI_NT(i,j,k,it_crew)) ;
                count = count + 1 ;
            end
        end
    end
end


% start time at unit j should be greater or equal than finish time of the
% preceding activity (NS ---> NI)
cons2d = optimconstr(1);
count  = 1 ;
for k = 1:K
    for it_crew = 1:num_crews(k)
        for i = 1:NS
            for j = 1:NI
                cons2d(count) = xs_NS(i,k,it_crew)  - xs_NI(j,k,it_crew) <= M_T*(1-x_NS_NI(i,j,k,it_crew)) ;
                count = count + 1 ;
                cons2d(count) = -xs_NS(i,k,it_crew) + xs_NI(j,k,it_crew) <= M_T*(1-x_NS_NI(i,j,k,it_crew)) ;
                count = count + 1 ;
            end
        end
    end
end


% start time at unit j should be greater or equal than finish time of the
% preceding activity (NT ---> NI)
cons2e = optimconstr(1);
count  = 1 ;
for k = 1:K
    for it_crew = 1:num_crews(k)
        for i = 1:NT
            for j = 1:NI
                cons2e(count) = xs_NT(i,k,it_crew) + it_NT(i,k,it_crew) - xs_NI(j,k,it_crew) <= M_T*(1-x_NT_NI(i,j,k,it_crew)) ;
                count = count + 1 ;
                cons2e(count) = -xs_NT(i,k,it_crew) - it_NT(i,k,it_crew) + xs_NI(j,k,it_crew) <= M_T*(1-x_NT_NI(i,j,k,it_crew)) ;
                count = count + 1 ;
            end
        end
    end
end

% start time at unit j should be greater or equal than finish time of the
% preceding activity (NT ---> NP)
cons2f = optimconstr(1);
count  = 1 ;
for k = 1:K
    for it_crew = 1:num_crews(k)
        for i = 1:NT
            for j = 1:NP
                cons2f(count) = xs_NT(i,k,it_crew) + it_NT(i,k,it_crew) - xs_NP(j,k,it_crew) <= M_T*(1-x_NT_NP(i,j,k,it_crew)) ;
                count = count + 1 ;
                cons2f(count) = -xs_NT(i,k,it_crew) - it_NT(i,k,it_crew) + xs_NP(j,k,it_crew) <= M_T*(1-x_NT_NP(i,j,k,it_crew)) ;
                count = count + 1 ;
            end
        end
    end
end


% start time at unit j should be greater or equal than finish time of the
% preceding activity (NP ---> NI)
cons2g = optimconstr(1);
count  = 1 ;
for k = 1:K
    for it_crew = 1:num_crews(k)
        for i = 1:NP
            for j = 1:NI
                cons2g(count) = xs_NP(i,k,it_crew)  + pt_NT(i,k,it_crew) + ...
                    CrewMobilizationTime(k,it_crew) - xs_NI(j,k,it_crew) <= M_T*(1-x_NP_NI(i,j,k,it_crew)) ;
                count = count + 1 ;
                cons2g(count) = -xs_NP(i,k,it_crew) - pt_NT(i,k,it_crew) - ...
                    CrewMobilizationTime(k,it_crew) + xs_NI(j,k,it_crew) <= M_T*(1-x_NP_NI(i,j,k,it_crew)) ;
                count = count + 1 ;
            end
        end
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% JOB LOGIC %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% start time of activity k at unit i should be equal or greater than the
% start time of its preceding activity (k-1) at unit i (same unit) plus 
% the duration of activity (k-1) and its buffet time (NI ---> NI)
cons3a = optimconstr(1);
count  = 1 ;
for i = 1:NI
    for j = 1:NI
        if i == j ; continue ; end
        for k = 2:K
            for it_crew_1 = 1:num_crews(k-1)
                for it_crew_2 = 1:num_crews(k)
                    cons3a(count) = xs_NI(j,k-1,it_crew_1) + Quantity(k-1,j)/Productivity(k-1,it_crew_1) + ...
                        BufferTime(k-1) - xs_NI(j,k,it_crew_2) <= M_T*(1-x_NI_NI(i,j,k,it_crew_2)) ;
                    count = count + 1 ;
                end
            end
        end
    end
end

% start time of activity k at unit i should be equal or greater than the
% start time of its preceding activity (k-1) at unit i (same unit) plus 
% the duration of activity (k-1) and its buffet time (NS ---> NI)
cons3b = optimconstr(1);
count  = 1 ;
for i = 1:NS
    for j = 1:NI
        for k = 2:K
            for it_crew_1 = 1:num_crews(k-1)
                for it_crew_2 = 1:num_crews(k)
                    cons3b(count) = xs_NI(j,k-1,it_crew_1) + Quantity(k-1,j)/Productivity(k-1,it_crew_1) + ...
                        BufferTime(k-1) - xs_NI(j,k,it_crew_2) <= M_T*(1-x_NS_NI(i,j,k,it_crew_2)) ;
                    count = count + 1 ;
                end
            end
        end
    end
end


% start time of activity k at unit i should be equal or greater than the
% start time of its preceding activity (k-1) at unit i (same unit) plus 
% the duration of activity (k-1) and its buffet time (NT ---> NI)
cons3c = optimconstr(1);
count  = 1 ;
for i = 1:NT
    for j = 1:NI
        for k = 2:K
            for it_crew_1 = 1:num_crews(k-1)
                for it_crew_2 = 1:num_crews(k)
                    cons3c(count) = xs_NI(j,k-1,it_crew_1) + Quantity(k-1,j)/Productivity(k-1,it_crew_1) + ...
                        BufferTime(k-1) - xs_NI(j,k,it_crew_2) <= M_T*(1-x_NT_NI(i,j,k,it_crew_2)) ;
                    count = count + 1 ;
                end
            end
        end
    end
end


% start time of activity k at unit i should be equal or greater than the
% start time of its preceding activity (k-1) at unit i (same unit) plus 
% the duration of activity (k-1) and its buffet time (NP ---> NI)
cons3d = optimconstr(1);
count  = 1 ;
for i = 1:NP
    for j = 1:NI
        for k = 2:K
            for it_crew_1 = 1:num_crews(k-1)
                for it_crew_2 = 1:num_crews(k)
                    cons3d(count) = xs_NI(j,k-1,it_crew_1) + Quantity(k-1,j)/Productivity(k-1,it_crew_1) + ...
                        BufferTime(k-1) - xs_NI(j,k,it_crew_2) <= M_T*(1-x_NP_NI(i,j,k,it_crew_2)) ;
                    count = count + 1 ;
                end
            end
        end
    end
end


%% logic sequence of unit to move crews from one unit to another
%{

This might be integarted to derive the results from the literature

%}
cons4a = optimconstr(1);
count  = 1 ;
for k = 1:K
    for it_crew = 1:num_crews(k)
        for i = 1:NI-1
            cons4a(count) = xs_NI(i,k,it_crew) - xs_NI(i+1,k,it_crew) <= 0 ;
            count = count + 1 ;
        end
    end
end


load zuo_order.mat
cons_zuo = optimconstr(1);
count  = 1 ;
for k = 1:K
    for it_crew = 1:num_crews(k)
        fixed_order = zuo_order{k,it_crew} ;
        for i = 1:length(fixed_order)-1
            cons_zuo(count) = xs_NI(fixed_order(i),k,it_crew) + Quantity(k,fixed_order(i))/Productivity(k,it_crew) - xs_NI(fixed_order(i+1),k,it_crew) <= 0 ;
            count = count + 1 ;
        end
    end
end


%% Project duration constraint to identify maximum start time at dummy finish unit
% define decision variable
lb = 0   ;
ub = M_T ;
xf_NF = optimvar('xf_NF',1,1,'LowerBound',lb,'UpperBound',ub,'Type','continuous');

cons7a = optimconstr(1);
count  = 1 ;
for j = 1:NF
    for it_crew = 1:num_crews(K)
        cons7a(count) = xf_NF(1,1) >= xs_NF(j,K,it_crew) ;
        count  = count + 1 ;
    end
end

%% Integarte constraints into the optimization model

%%%%%%%%%% Assignment and Consistency Constraints %%%%%%%%%%%%%%%%%%%%%%%%%
LS_Problem.Constraints.cons1a = cons1a;
LS_Problem.Constraints.cons1b = cons1b;
LS_Problem.Constraints.cons1c = cons1c;
LS_Problem.Constraints.cons1d = cons1d;
LS_Problem.Constraints.cons1e = cons1e;
LS_Problem.Constraints.cons1f = cons1f;
LS_Problem.Constraints.cons1g = cons1g;
LS_Problem.Constraints.cons1h = cons1h;
LS_Problem.Constraints.cons1i = cons1i;
LS_Problem.Constraints.cons1j = cons1j;
LS_Problem.Constraints.cons1k = cons1k;
LS_Problem.Constraints.cons1l = cons1l;

%%%%%%%%% Start Time of Each Activity at Each Unit %%%%%%%%%%%%%%%%%%%%%%%%
LS_Problem.Constraints.cons2a = cons2a;
LS_Problem.Constraints.cons2b = cons2b;
LS_Problem.Constraints.cons2c = cons2c;
LS_Problem.Constraints.cons2d = cons2d;
LS_Problem.Constraints.cons2e = cons2e;
LS_Problem.Constraints.cons2f = cons2f;
LS_Problem.Constraints.cons2g = cons2g;

%%%%%%%% Job Logic Constraints %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
LS_Problem.Constraints.cons3a = cons3a;
LS_Problem.Constraints.cons3b = cons3b;
LS_Problem.Constraints.cons3c = cons3c;
LS_Problem.Constraints.cons3d = cons3d;

%%%%%%% Logic Sequence Unit %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if fixed_order_of_execution
    LS_Problem.Constraints.cons4a = cons4a;
end

%%%%%%% Project Duration Constraints %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
LS_Problem.Constraints.cons7a = cons7a;
LS_Problem.Constraints.cons_zuo = cons_zuo;

%% Formulate Objective Function

% interruption cost
interruption_cost = 0 ;
for k = 1:K
    for it_crew = 1:num_crews(k)
        for i = 1:NT
            interruption_cost = interruption_cost + it_NT(i,k,it_crew)*DailyCrewCost(k,it_crew)  ;
        end
    end
end


% dismissal cost
dismissal_cost = 0 ;
for j = 1:NT
    for k = 1:K
        for it_crew = 1:num_crews(k)
            for i = 1:NP
                dismissal_cost = dismissal_cost + (CrewMobilizationCost(k,it_crew) + ...
                    CrewMobilizationTime(k,it_crew)*DailyCrewCost(k,it_crew))*sum(x_NT_NP(j,i,k,it_crew)) ;
            end
        end
    end
end


% indirect cost
indirect_cost    = xf_NF(1,1) * daily_indirect_cost ;

% integarte the objective function into the model
LS_Problem.Objective = indirect_cost + dismissal_cost + interruption_cost ;

% solve the optimization problem
options = optimoptions('intlinprog','MaxTime',time_limit, 'ConstraintTolerance', constraint_tolerance)  ;
sol     = solve(LS_Problem,'Options',options) ;

for it_opt = 1:num_optimization_round
    options = optimoptions('intlinprog','MaxTime',...
        iterative_optimization_time_limit, 'ConstraintTolerance', constraint_tolerance)  ;
    sol     = solve(LS_Problem,sol,'Options',options) ;
end


%% Next Round of Optimization
%{

The 2nd round of optimization is to minimize the interruption and dismissal
costs while the minimum project duration is a constraint in the model

%}
% 
% % set the indirect cost (i.e., minimum project duration) as constraint
% cons5a    = optimconstr(1);
% cons5a(1) = indirect_cost <= evaluate(indirect_cost,sol)*1.0001 ;
% LS_Problem_modified = LS_Problem ;
% LS_Problem_modified.Constraints.cons5a = cons5a ;
% 
% % set the objective as to minimize the interruption and dismissal cost
% LS_Problem_modified.Objective = interruption_cost + dismissal_cost ;
% 
% % solve the modified model
% sol     = solve(LS_Problem_modified,sol,'Options',options ) ;

% %% next round -- minimzing the number of interruptions and total sum of interruptions
% cons6a    = optimconstr(1) ;
% cons6a(1) = LS_Problem.Objective <= ...
%     evaluate(LS_Problem.Objective , sol)*1.001 ;
% 
% % set the objective as to minimize the number of interruptions
% number_of_interruption = 0 ;
% for k = 1:K
%     for it_crew = 1:num_crews(k)
%         for i = 1:NI
%             number_of_interruption = number_of_interruption + sum(x_NI_NT(i,:,k,it_crew)) ;
%         end
%     end
% end
% 
% LS_Problem.Objective = number_of_interruption ;
% LS_Problem.Constraints.cons6a = cons6a ;
% options = optimoptions('intlinprog','MaxTime',time_limit, 'ConstraintTolerance', constraint_tolerance)  ;
% sol     = solve(LS_Problem,sol,'options',options) ;
% 

%% Final round of optimization is to ensure the duration of interruption is minimized
cons8a    = optimconstr(1) ;
cons8a(1) = LS_Problem.Objective <= ...
    evaluate(LS_Problem.Objective , sol)*1.00001 ;

% Calculate total interruption time
total_idle_time = 0 ;
for k = 1:K
    for it_crew = 1:num_crews(k)
        for i = 1:NI
            for j = 1:NT
                total_idle_time = total_idle_time + it_NT(j,k,it_crew) ;
            end
        end
    end
end

for k = 1:K
    for it_crew = 1:num_crews(k)
        for i = 1:NP
            for j = 1:NI
                total_idle_time = total_idle_time + pt_NT(i,k,it_crew) - T_min ;
            end
        end
    end
end

LS_Problem.Objective = total_idle_time ;
LS_Problem.Constraints.cons8a = cons8a ;
options = optimoptions('intlinprog','MaxTime',time_limit, ...
    'ConstraintTolerance', constraint_tolerance)  ;
sol     = solve(LS_Problem,sol,'options',options) ;

%% Save Workspace

% get the filename
filename_running_code = mfilename('fullpath') ;
if ismac
    delimeter = '/' ;
elseif ispc
    delimeter = '\' ;
end
filename_running_code = strsplit(filename_running_code,delimeter) ;
filename_running_code = filename_running_code{end} ;

% get the current date
current_date = datetime ;
current_date = datestr(current_date,'dd_mm_yyyy_HH_MM_SS') ;

% format the filename based on filename and date
str = sprintf('result_%s_(%s).mat',filename_running_code,current_date) ;

% save the entire workspace
save(str) ;









