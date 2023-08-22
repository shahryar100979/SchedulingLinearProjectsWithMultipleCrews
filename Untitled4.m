

cons30    = optimconstr(1);
cons31    = optimconstr(1);
cons30(1) = x_NI_NT(4,1,3,1) == 1 ;
cons31(1) = it_NT(1,3,1) >= 3.2 ;
cons30(2) = x_NI_NT(4,2,4,1) == 1 ;
cons31(2) = it_NT(2,4,1) >= 2.8 ;
% cons30(3) = x_NI_NT(2,3,4,1) == 1 ;
% cons31(3) = it_NT(3,4,1) >= 3.6 ;
% cons30(7) = x_NI_NT(2,4,3,2) == 1 ;
% cons30(8) = it_NT(4,3,2) == 7.5 ;

LS_Problem_modified = LS_Problem ;
LS_Problem_modified.Constraints.cons30 = cons30 ;
LS_Problem_modified.Constraints.cons31 = cons31 ;
soll     = solve(LS_Problem_modified,sol,'Options',options) ;