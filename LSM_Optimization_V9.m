%% Description
% Linear Scheduling of Repetitive Construction Projects

%% Deriving results of:
% Altuwaim, A., & El-Rayes, K. (2018). Optimizing the scheduling of repetitive construction to minimize interruption cost. Journal of Construction Engineering and Management, 144(7), 04018051.

%{

Highlights:
(a) Linear scheduling model for repetitive construction projects
(b) Untypical projects where the quantity of works at units can be different
(c) Considers crews idle cost and dismissal cost
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
load Quantity.mat
load Productivity.mat
load DailyCrewCost.mat
load CrewMobilizationCost.mat
load CrewMobilizationTime.mat
load BufferTime.mat

%% Validation Purpose Only
% if you want to validate the results with Dr. Elrayes 2018 paper results that includes one crew only
validation_only = true ;
if validation_only
    Productivity  = Productivity(:,1)  ; %#ok<UNRCH>
    DailyCrewCost = DailyCrewCost(:,1) ;
    CrewMobilizationCost = CrewMobilizationCost(:,1) ;
    CrewMobilizationTime = CrewMobilizationTime(:,1) ;
    fixed_order_of_execution = true ;
else
    fixed_order_of_execution = false ;
end

%% Define the problem input data

K  = size(Quantity,1) ; % number of repetitive activities
NI = size(Quantity,2) ; % number of units

NF = 1  ; % number of dummy finish unit
NS = 1  ; % number of dummy start unit
NT = NI ; % number of dummy interruption unit
NP = NT ; % number of dummy temporary dismissal unit

num_crews  = sum(Productivity./Productivity,2,'omitnan') ; % number of available crews for each activity
max_num_crews = max(num_crews) ; % identify the maximum number of crews available accross all the activities

T_min = 1 ; % minimum work duration in another project

if validation_only
    daily_indirect_cost = 1000 ; %#ok<UNRCH>  % to derive El-rayes results a high indirect cost is set to ensure the duration of project is minimized
else
    daily_indirect_cost = 1000 ; % from paper "Optimization model for resource assignment problems of linear construction projects"
end

M_T = 300 ; % a large number that is >>> project duration
M_R = 20  ; % maximum duration of interuption at each unit in days

time_limit = 60*10 ; % optimization time limit (seconds)
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
ub = ones(NT,NP,K,max_num_crews)  ;
for k = 1:K
    for it_crew = num_crews(k)+1:max_num_crews
        ub(:,:,k,it_crew) = zeros(NT,NP) ;
    end
end
x_NT_NP = optimvar('x_NT_NP',NT,NP,K,max_num_crews,'LowerBound',lb,'UpperBound',ub,'Type','integer');

% instantiate x for NP --> NI
lb = zeros(NP,NI,K,max_num_crews) ;
ub = ones(NP,NI,K,max_num_crews)  ;
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
                cons2a(count) = xs_NI(i,k,it_crew)  + Quantity(k,i)/Productivity(k,it_crew) - xs_NI(j,k,it_crew) <= M_T*(1-x_NI_NI(i,j,k,it_crew)) ;
                count = count + 1 ;
                cons2a(count) = -xs_NI(i,k,it_crew) - Quantity(k,i)/Productivity(k,it_crew) + xs_NI(j,k,it_crew) <= M_T*(1-x_NI_NI(i,j,k,it_crew)) ;
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
                cons2b(count) = xs_NI(i,k,it_crew)  + Quantity(k,i)/Productivity(k,it_crew) - xs_NF(j,k,it_crew) <= M_T*(1-x_NI_NF(i,j,k,it_crew)) ;
                count = count + 1 ;
                cons2b(count) = -xs_NI(i,k,it_crew) - Quantity(k,i)/Productivity(k,it_crew) + xs_NF(j,k,it_crew) <= M_T*(1-x_NI_NF(i,j,k,it_crew)) ;
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
                cons2c(count) = xs_NI(i,k,it_crew)  + Quantity(k,i)/Productivity(k,it_crew) - xs_NT(j,k,it_crew) <= M_T*(1-x_NI_NT(i,j,k,it_crew)) ;
                count = count + 1 ;
                cons2c(count) = -xs_NI(i,k,it_crew) - Quantity(k,i)/Productivity(k,it_crew) + xs_NT(j,k,it_crew) <= M_T*(1-x_NI_NT(i,j,k,it_crew)) ;
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
                cons2g(count) = xs_NP(i,k,it_crew)  + pt_NT(i,k,it_crew) + CrewMobilizationTime(k,it_crew) - xs_NI(j,k,it_crew) <= M_T*(1-x_NP_NI(i,j,k,it_crew)) ;
                count = count + 1 ;
                cons2g(count) = -xs_NP(i,k,it_crew) - pt_NT(i,k,it_crew) - CrewMobilizationTime(k,it_crew) + xs_NI(j,k,it_crew) <= M_T*(1-x_NP_NI(i,j,k,it_crew)) ;
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

%% Project duration constraint to identify maximum start time at dummy finish unit
% define decision variable
lb = 0   ;
ub = M_T ;
xf_NF = optimvar('xf_NF',1,1,'LowerBound',lb,'UpperBound',ub,'Type','continuous');

cons7a = optimconstr(1);
count  = 1 ;
for j = 1:NF
    for k = 1:K
        for it_crew = 1:num_crews(k)
            cons7a(count) = xf_NF(1,1) >= xs_NF(j,k,it_crew) ;
            count  = count + 1 ;
        end
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
    LS_Problem.Constraints.cons4a = cons4a; %#ok<UNRCH>
end

%%%%%%% Project Duration Constraints %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
LS_Problem.Constraints.cons7a = cons7a;

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
                dismissal_cost = dismissal_cost + (CrewMobilizationCost(k,it_crew) + CrewMobilizationTime(k,it_crew)*DailyCrewCost(k,it_crew))*sum(x_NT_NP(j,i,k,it_crew)) ;
            end
        end
    end
end


% indirect cost
indirect_cost    = xf_NF(1,1) * daily_indirect_cost ;

% integarte the objective function into the model
LS_Problem.Objective = indirect_cost + dismissal_cost + interruption_cost ;

% solve the optimization problem
options = optimoptions('intlinprog','MaxTime',time_limit, 'ConstraintTolerance', 1.0e-3)  ;
sol_min_duration     = solve(LS_Problem,'Options',options) ;

% evaluate the fitness function
eval_opt_objective_sol_min_dur         = evaluate(LS_Problem.Objective,sol_min_duration) ;
eval_opt_interruption_cost_sol_min_dur = evaluate(interruption_cost,sol_min_duration)    ;
eval_opt_dismissal_cost_sol_min_dur    = evaluate(dismissal_cost,sol_min_duration)       ;
eval_opt_indirect_cost_sol_min_dur     = evaluate(indirect_cost,sol_min_duration)        ;


%% Next Round of Optimization 
%{

The 2nd round of optimization is to minimize the interruption and dismissal
costs while the minimum project duration is a constraint in the model

%}

% set the indirect cost (i.e., minimum project duration) as constraint
cons5a    = optimconstr(1);
cons5a(1) = indirect_cost <= evaluate(indirect_cost,sol_min_duration)*1.0001 ;
LS_Problem_modified = LS_Problem ;
LS_Problem_modified.Constraints.cons5a = cons5a ;

% set the objective as to minimize the interruption and dismissal cost
LS_Problem_modified.Objective = interruption_cost + dismissal_cost ;

% solve the modified model
sol_min_duration_min_cost     = solve(LS_Problem_modified,sol_min_duration,'Options',options ) ;

%% next round -- minimzing the number of interruptions and total sum of interruptions

LS_Problem_modified_v2 = LS_Problem_modified ;

cons6a    = optimconstr(1) ;
cons6a(1) = LS_Problem_modified_v2.Objective <= ...
    evaluate(LS_Problem_modified_v2.Objective , sol_min_duration_min_cost) ;

% set the objective as to minimize the number of interruptions
number_of_interruption = 0 ;
for k = 1:K
    for it_crew = 1:num_crews(k)
        for i = 1:NI
            number_of_interruption = number_of_interruption + sum(x_NI_NT(i,:,k,it_crew)) ;
        end
    end
end

LS_Problem_modified_v2.Objective = number_of_interruption ;
LS_Problem_modified_v2.Constraints.cons6a = cons6a ;
sol_min_duration_min_cost     = solve(LS_Problem_modified_v2,sol_min_duration_min_cost) ;


%% Final roundof optimization is to ensure the duration of interruption is minimized
LS_Problem_modified_v3 = LS_Problem_modified ;

cons8a    = optimconstr(1) ;
cons8a(1) = LS_Problem_modified.Objective <= ...
    evaluate(LS_Problem_modified.Objective , sol_min_duration_min_cost)*1.00001 ;

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
                total_idle_time = total_idle_time + pt_NT(i,k,it_crew) ;
            end
        end
    end
end

LS_Problem_modified_v3.Objective = total_idle_time ;
LS_Problem_modified_v3.Constraints.cons8a = cons8a ;
sol_min_duration_min_cost_min_interrupt     = solve(LS_Problem_modified_v3,sol_min_duration_min_cost) ;
sol = sol_min_duration_min_cost_min_interrupt ;


%%   Evaluation of Fitness Function
% evaluate the fitness function components
eval_opt_objective         = evaluate(LS_Problem_modified.Objective , sol_min_duration_min_cost_min_interrupt) ;
eval_opt_interruption_cost = evaluate(interruption_cost             , sol_min_duration_min_cost_min_interrupt) ;
eval_opt_dismissal_cost    = evaluate(dismissal_cost                , sol_min_duration_min_cost_min_interrupt) ;
eval_opt_indirect_cost     = evaluate(indirect_cost                 , sol_min_duration_min_cost_min_interrupt) ;

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









