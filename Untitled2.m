

cons30    = optimconstr(1);
cons30(1) = x_NI_NT(2,1,2,1) == 1 ;
cons30(2) = it_NT(1,2,1) == 5.38 ;
cons30(3) = x_NI_NT(5,2,2,1) == 1 ;
cons30(4) = it_NT(2,2,1) == 10.69 ;
cons30(5) = x_NI_NT(2,3,3,1) == 1 ;
cons30(6) = it_NT(3,3,1) == 7.95 ;
cons30(7) = x_NI_NT(2,4,4,1) == 1 ;
cons30(8) = it_NT(4,4,1) == 7.13 ;

LS_Problem_modified = LS_Problem ;
LS_Problem_modified.Constraints.cons30 = cons30 ;
sol     = solve(LS_Problem_modified,sol,'Options',options) ;