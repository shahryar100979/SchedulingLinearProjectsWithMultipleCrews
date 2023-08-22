function concat_decision_variable = concateDecisionVariables_v5(K,NI,NS,NF,NT,NP,sol,max_num_crews)



% specify the order
order = 'NI+NS+NF+NT+NP' ;

% instantiate variable
concat_decision_variable = zeros(NI+NS+NF+NT+NP, NI+NS+NF+NT+NP, K, max_num_crews) ;

% identify the list of attributes in a structure
field_names = fieldnames(sol) ;

% for every field
for it_field = 1:numel(field_names)
    
    % field name
    field_name = field_names{it_field} ;
    
    % check if it is x type decision variable
    if contains (field_name , 'x_')
        split = strsplit(field_name,'_') ;
        
        start = strfind(order,split{2}) ;
        range_1_start =  strcat(string(order(1:start-1)),'1') ;
        range_1_end   =  order(1:start+length(split{2})-1) ;
        
        start = strfind(order,split{3}) ;
        range_2_start =  strcat(string(order(1:start-1)),'1') ;
        range_2_end   =  order(1:start+length(split{3})-1) ;
        
        
        range_indices = sprintf('%s:%s,%s:%s',range_1_start,...
            range_1_end ,range_2_start, range_2_end ) ;
        
        eval_str = sprintf('concat_decision_variable(%s,:,:) = round(sol.%s) ;' , ...
            range_indices , ...
            field_name ) ;
        
        eval(eval_str)
    end
end