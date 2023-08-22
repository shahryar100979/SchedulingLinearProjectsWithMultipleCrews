mod_sol_prev = sol ;
field_names = fieldnames(LS_Problem.Constraints) ;
epsilon = 0.01 ;
for it_field = 1:numel(field_names)
    
    % field name
    field_name = field_names{it_field} ;
    
    constr = getfield(LS_Problem.Constraints,field_name) ;
    
    infeas = infeasibility(constr,mod_sol_prev) ;
    
    if any(infeas > epsilon)
        field_name
    end
end


infeas = infeasibility(LS_Problem.Constraints.cons8i,mod_sol_prev) ;
