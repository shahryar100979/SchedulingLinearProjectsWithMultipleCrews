function strict_LOB_project_duration = LOB_scheduling(Quantity,Productivity,BufferTime)


num_activity = size(Quantity,1) ; % number fo activities
num_units    = size(Quantity,2) ; % number of repetitive units

% for each activity
for it_activity = 1:num_activity
    
    % identify the slowest crew
    min_productivity = Inf ;
    for it_crew = 1:size(Productivity,2)
        if Productivity(it_activity,it_crew) == 0 ; break ; end
        if Productivity(it_activity,it_crew) < min_productivity
            min_productivity = Productivity(it_activity,it_crew) ;
        end 
    end
    
    if it_activity == 1
        start_time  = 0 ;
        finish_time = start_time + num_units * max(Quantity(it_activity,:))/min_productivity ;
    else
        if finish_time + BufferTime(it_activity-1,1) >= num_units * max(Quantity(it_activity,:))/min_productivity
            start_time  = finish_time + BufferTime(it_activity-1,1) - num_units * max(Quantity(it_activity,:))/min_productivity ;
            finish_time = finish_time + BufferTime(it_activity-1,1) ;
        else
            start_time  = start_time + BufferTime(it_activity-1,1) ;
            finish_time = start_time + BufferTime(it_activity-1,1) + num_units * max(Quantity(it_activity,:))/min_productivity ;
        end
    end
    
end

strict_LOB_project_duration = finish_time ;