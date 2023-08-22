function UnitSequence = PostProcessResult_v3(K,NI,NS,concat_decision_variables, num_crews)

max_num_crews = max(num_crews) ;
% Instantiate the cell variable to store the trip sequence for every crew
UnitSequence = cell(K, NS, max_num_crews) ;

xmat = concat_decision_variables ;
for k = 1:K
    for it_crew = 1:num_crews(k)
        for i = 1:NS
            % Initialize the start of vehicle i
            tripStart = NI+i ;
            
            % Identify the first end of the trip for vehicle i
            tripEnd = find(xmat(tripStart,:,k,it_crew) == 1, 1) ;
            
            % Store the trip start and end
            UnitSequence{k,i,it_crew} = [UnitSequence{k,i,it_crew} , [tripStart , tripEnd]] ;
            
            % While there is an an end to a trip
            while ~isempty(tripEnd)
                
                % Replace the start of the next trip with the end of the previous trip
                tripStart = tripEnd ;
                
                % Idenitfy the end of the trip
                tripEnd = find(round(xmat(tripStart,:,k,it_crew)) == 1, 1) ;
                
                % Store the trip start and end
                UnitSequence{k,i,it_crew} = [UnitSequence{k,i,it_crew} , tripEnd] ;
            end
        end
    end
end