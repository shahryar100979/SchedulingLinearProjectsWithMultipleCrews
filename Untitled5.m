

cons30    = optimconstr(1);
cons31    = optimconstr(1);
cons30(1) = sum(x_NI_NT(:)) >= 4 ;
cons31(1) = sum(it_NT(:)) >= 18 ;

LS_Problem_modified = LS_Problem ;
LS_Problem_modified.Constraints.cons30 = cons30 ;
LS_Problem_modified.Constraints.cons31 = cons31 ;
soll     = solve(LS_Problem_modified,sol,'Options',options) ;