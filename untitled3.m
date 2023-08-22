% integarte the objective function into the model
LS_Problem.Objective = indirect_cost + dismissal_cost + interruption_cost ;

% solve the optimization problem
options = optimoptions('intlinprog','MaxTime',time_limit, 'ConstraintTolerance', constraint_tolerance)  ;
sol     = solve(LS_Problem,sol,'Options',options) ;