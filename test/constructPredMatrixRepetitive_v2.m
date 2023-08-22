function predMatrix = constructPredMatrixRepetitive_v2(predCell,units)

%% Description of input data
% pred: is a cell array of size number of activities and number of successor
% activities
% ka: is a vertical vector that shows the activities maximum number of crews
% m: number of units

%% Contruct the predecence matrix
Na = size(predCell,1) ; % number of activities
predMatrix = zeros(Na*length(units)) ; % precedence relationship


% for every activity
for it_act = 1:Na
    
    % number of crews for activity
%     num_crew = ka(it_act) ;
    num_crew = 1 ;
    
    % for every unit
    for it_unit = units
        % for every successor
        for it_suc = 1:size(predCell,2)
            
            % if the successor is not NaN
            if ~isnan(predCell{it_act,it_suc})
                suc_act = predCell{it_act,it_suc} ; % find the successor activity number
                suc_act = (it_unit-1)*Na + suc_act ; % find the successor activity number based on its unit number
                pre_act = (it_unit-1)*Na + it_act ; % find the predecessor activity number based on its unit number
                predMatrix(pre_act,suc_act) = 1 ; % put a one in the matrix
                
                % relationship between units
                if it_unit ~= units(end)
                    suc_unit_act = (it_unit-1)*Na + num_crew*Na + it_act ;
                    predMatrix(pre_act,suc_unit_act) = 1 ; % put a one in the matrix
                end
                
            end
        end 
    end
    
end