close all
%% Configuration of Visualization

% Dimensions
flow_bar_thickness          = 0.7        ; % flow bar width (day)
interruption_bar_thickness  = 7          ; % interruption bar thickness (unitless)
curvature                   = [0.2 0.2]  ; % ratio of curvature at interruption bars corners
arrow_line_width            = 2.0        ; % arrow line thicnkess (unitless)
arrow_head_height           = 0.15       ; % crew movement arrow head height (unitless)
arrow_head_theta            = 150/180*pi ; % angle of arrow head (radian)

% Colors
interruption_font_color = 'k'          ; % color of font for showing the value of interruption
Color                   = linspecer(K) ; % get colormap for showing crews
arrow_head_edge_color   = 'k'          ; % arrow head color

% Transparency
alpha_interruption = 0.99 ;
alpha_arrow_line   = 0.90 ;
alpha_arrow_head   = 0.90 ;
alpha_flow_bar     = 0.70 ;

% minimum idle time to be indicated on plots
min_idle_time = 0.1 ; % expressed in days
arrow_style = '--' ;

%% Instantiate the Figure for Visualization
f            = figure   ;
f.Color      = 'w'      ;
h            = gca      ;
h.FontName   = 'Arial'  ;
h.FontWeight = 'bold'   ;
h.FontSize   = 20       ;
h.YTick      = 0:NI     ;
h.XTick      = 0:20:sol.xf_NF(1,1) ;
h.XLim       = [0 inf]  ;
ylabel('Units')
xlabel('Time (Days)')
hold on
grid on

%% Preprocess the model results
% concatenate decision variables
concat_decision_variable = concateDecisionVariables_v5(K,NI,NS,NF,NT,NP,sol,max_num_crews) ;

% order of units
UnitSequence = PostProcessResult_v3(K,NI,NS,concat_decision_variable, num_crews) ;

%% Indicate Project Duration in the Schedule

project_duration = sol.xf_NF(1,1)-1 ;
% plot vertical line to show project finish time
plot([project_duration , project_duration] , [0 , NI], 'LineWidth',1,...
    'LineStyle','-','Color','k')

% calculate arrow head polygon
x_end = project_duration ;
y_end = 0 ;
b  = 2*arrow_head_height*tan(arrow_head_theta/2) ;
x1 = x_end - b/2                          ;
y1 = y_end + arrow_head_height            ;
x2 = x_end + b/2                          ;
y2 = y_end + arrow_head_height            ;

% vertices of polygons and their order
v = [x1 y1 ; x2 y2 ; x_end  y_end] ;
f = [1 2 3] ;

% plot the arrow head
patch('Faces',f,'Vertices',v,'FaceColor','k', ...
    'FaceAlpha',1,'EdgeAlpha',1,...
    'EdgeColor','k') ;

% specify idle time
str_project_duration = sprintf('%0.2f days',project_duration) ;
text(project_duration+1.5, 0.2 , ...
    str_project_duration, 'HorizontalAlignment','left',...
    'Color',interruption_font_color,'FontSize',18,'FontWeight','bold',...
    'FontName','Arial', 'Rotation',90)

%% Visualize the Schedule of Each Crew
% for each activity/crew
for k = 1:K
    for it_crew = 1:num_crews(k)
        
        % instantiate the counter for the units
        unit_cnt = 0 ;
        
        % find the order of units and other dummy units
        order = UnitSequence{k,1,it_crew} ;
        
        % for every unit except the start dummy unit
        for it_order = 2:length(order)
            
            % find the number of unit
            nodeStart = order(it_order) ;
            
            % check if it belongs to work units
            if ismember(nodeStart , 1:NI)
                
                % increment counter of units
                unit_cnt = unit_cnt + 1 ;
                
                % find start time at unit
                start_time = sol.xs_NI(nodeStart,k,it_crew) ;
                
                % find duration
                duration = Quantity(k,nodeStart)/Productivity(k,it_crew) ;
                
                % find finish time
                finish_time = start_time + duration ;
                
                
                % plot flow line
                
                % vertices of polygons and their order
                x1 = start_time - flow_bar_thickness ;
                y1 = nodeStart-1     ;
                x2 = start_time + flow_bar_thickness  ;
                y2 = nodeStart-1     ;
                x3 = finish_time + flow_bar_thickness ;
                y3 = nodeStart ;
                x4 = finish_time - flow_bar_thickness ;
                y4 = nodeStart ;
                v = [x1 y1 ; x2 y2 ; x3  y3 ; x4 y4] ;
                f = [1 2 3 4] ;
                if it_crew == 1
                    patch('Faces',f,'Vertices',v,'FaceColor',Color(k,:), ...
                        'FaceAlpha',alpha_flow_bar,'EdgeAlpha',1,...
                        'EdgeColor','none') ;
                elseif it_crew == 2
                    patch('Faces',f,'Vertices',v,'FaceColor',Color(k,:), ...
                        'FaceAlpha',alpha_flow_bar*0.8,'EdgeAlpha',1,...
                        'EdgeColor','k','LineWidth',1.5, 'LineStyle', '-') ;
                elseif it_crew == 3
                    patch('Faces',f,'Vertices',v,'FaceColor',Color(k,:), ...
                        'FaceAlpha',alpha_flow_bar*0.5,'EdgeAlpha',1,...
                        'EdgeColor','k','LineWidth',2.5, 'LineStyle', '--') ;
                end
                    
                    
                
                % if this is not the first unit
                if unit_cnt > 1
                    
                    % draw rectangle of interruption
                    dur    = start_time - prev_unit_finish_time   ; % duration of interruption
                    
                    % draw crew movement with arrow
                    x_begin = start_time       ;
                    y_begin = prev_unit_number ;
                    x_end   = start_time       ;
                    y_end   = nodeStart-1      ;
                    
                    if y_begin < y_end  % upward arrow
                        
                        % plot arrow line
                        plot([x_begin , x_end ] , [y_begin , y_end-arrow_head_height], ...
                            'Color',[Color(k,:) , alpha_arrow_line] , ...
                            'LineStyle',arrow_style,...
                            'LineWidth', arrow_line_width)
                        
                        % calculate arrow head polygon
                        b  = 2*arrow_head_height*tan(arrow_head_theta/2) ;
                        x1 = x_end - b/2                          ;
                        y1 = y_end - arrow_head_height            ;
                        x2 = x_end + b/2                          ;
                        y2 = y_end - arrow_head_height            ;
                        
                        % vertices of polygons and their order
                        v = [x1 y1 ; x2 y2 ; x_end y_end ] ;
                        f = [1 2 3]                ;
                        
                        % plot the arrow head
                        patch('Faces',f,'Vertices',v,'FaceColor',Color(k,:), ...
                            'FaceAlpha',alpha_arrow_head,...
                            'EdgeAlpha',alpha_arrow_head,...
                            'EdgeColor',arrow_head_edge_color) ;
                        
                    elseif y_begin > y_end % downward arrow
                        
                        % plot arrow line
                        plot([x_begin , x_end ] , [y_begin , y_end+arrow_head_height], ...
                            'Color',[Color(k,:) , alpha_arrow_line] ,...
                            'LineStyle',arrow_style,...
                            'LineWidth', arrow_line_width)
                        
                        % calculate arrow head polygon
                        b  = 2*arrow_head_height*tan(arrow_head_theta/2) ;
                        x1 = x_end - b/2                          ;
                        y1 = y_end + arrow_head_height            ;
                        x2 = x_end + b/2                          ;
                        y2 = y_end + arrow_head_height            ;
                        
                        % vertices of polygons and their order
                        v = [x1 y1 ; x2 y2 ; x_end  y_end] ;
                        f = [1 2 3]                        ;
                        
                        % plot the arrow head
                        patch('Faces',f,'Vertices',v,'FaceColor',Color(k,:), ...
                            'FaceAlpha',alpha_arrow_head,...
                            'EdgeAlpha',alpha_arrow_head,...
                            'EdgeColor',arrow_head_edge_color) ;
                    end
                    
                end
                
                % record the finish time
                prev_unit_finish_time = finish_time ;
                prev_unit_number      = nodeStart   ;
                
            end
        end
    end
end




% for each activity
for k = 1:K
    for it_crew = 1:num_crews(k)
        % instantiate the counter for the units
        unit_cnt = 0 ;
        
        % find the order of units and other dummy units
        order = UnitSequence{k,1,it_crew} ;
        
        % for every unit except the start dummy unit
        for it_order = 2:length(order)
            
            % find the number of unit
            nodeStart = order(it_order) ;
            
            % check if it belongs to work units
            if ismember(nodeStart , 1:NI)
                
                % increment counter of units
                unit_cnt = unit_cnt + 1 ;
                
                % find start time at unit
                start_time = sol.xs_NI(nodeStart,k,it_crew) ;
                
                % find duration
                duration = Quantity(k,nodeStart)/Productivity(k,it_crew) ;
                
                % find finish time
                finish_time = start_time + duration ;
                
                
                % if this is not the first unit
                if unit_cnt > 1
                    
                    % draw rectangle of interruption
                    dur    = start_time - prev_unit_finish_time   ; % duration of interruption
                    
                    % check if the interruption duration is less than the minimum threshold
                    if dur > min_idle_time
                        
                        plot([prev_unit_finish_time , prev_unit_finish_time + dur] ,...
                            [prev_unit_number , prev_unit_number] ,...
                            'LineWidth',interruption_bar_thickness,...
                            'LineStyle','-',...
                            'Color',[Color(k,:) , alpha_interruption])
                        
                        plot(prev_unit_finish_time + dur ,prev_unit_number,'MarkerSize',40,'Marker','.','Color',[0.3 0.3 0.3 , alpha_interruption])
                        plot(prev_unit_finish_time       ,prev_unit_number,'MarkerSize',40,'Marker','.','Color',[0.3 0.3 0.3 , alpha_interruption])
                        plot(prev_unit_finish_time + dur ,prev_unit_number,'MarkerSize',20,'Marker','.','Color',[Color(k,:)  , alpha_interruption])
                        plot(prev_unit_finish_time       ,prev_unit_number,'MarkerSize',20,'Marker','.','Color',[Color(k,:)  , alpha_interruption])
                        
                        % check if it was idle time or relocation time
                        node_prev = order(it_order-1) ;
                        
                        if ismember(node_prev , NI+NS+NF+NT+1:NI+NS+NF+NT+NP)
                            
                            % specify deployment time
                            str_idle_time = sprintf('%0.2f^{days}',dur) ;
                            text(prev_unit_finish_time + dur/2-0.35*dur, ...
                                prev_unit_number + 0.12 , ...
                                str_idle_time, 'HorizontalAlignment','left',...
                                'Color',interruption_font_color,'FontSize',20,...
                                'FontWeight','bold','FontName','Arial')
                        else
                            % specify idle time
                            str_idle_time = sprintf('%0.2f^{days}_{idle}',dur) ;
                            text(prev_unit_finish_time + dur/2-0.35*dur, ...
                                prev_unit_number + 0.12, ...
                                str_idle_time, 'HorizontalAlignment','left',...
                                'Color',interruption_font_color,'FontSize',20,...
                                'FontWeight','bold','FontName','Arial')
                        end
                        
                    end
                    
                    % draw crew movement with arrow
                    x_begin = start_time       ;
                    y_begin = prev_unit_number ;
                    x_end   = start_time       ;
                    y_end   = nodeStart-1      ;
                    
                end
                
                % record the finish time
                prev_unit_finish_time = finish_time ;
                prev_unit_number      = nodeStart   ;
                
            end
        end
    end
end




%% Include the Project Schedule Summary

% Calculate total interruption time
total_idle_time = 0 ;
for k = 1:K
    for it_crew = 1:num_crews(k)
        for i = 1:NI
            for j = 1:NT
                if round(sol.x_NI_NT(i,j,k,it_crew)) ~= 0
                    total_idle_time = total_idle_time + sol.it_NT(j,k,it_crew) ;
                end
            end
        end
    end
end

for k = 1:K
    for it_crew = 1:num_crews(k)
        for i = 1:NP
            for j = 1:NI
                if round(sol.x_NP_NI(i,j,k,it_crew)) ~= 0
                    total_idle_time = total_idle_time + sol.pt_NT(i,k,it_crew) + CrewMobilizationTime(k,it_crew) ;
                end
            end
        end
    end
end

Project_Indirect_Cost   = num2bank(round(evaluate(indirect_cost     ,sol))) ;
Crew_Idle_Cost          = num2bank(round(evaluate(interruption_cost ,sol))) ;
Crew_Deployment_Cost    = num2bank(round(evaluate(dismissal_cost    ,sol))) ;
Interruption_Cost       = evaluate(interruption_cost ,sol) + evaluate(dismissal_cost    ,sol) ;
Interruption_Cost       = num2bank(round(Interruption_Cost)) ;
Total_Work_Interruption = round(total_idle_time,2) ;

%% Calculate Project Material and Equipment Cost
load Material_Cost_Zuo2020.mat
total_material_cost  = 0 ;
total_equipment_cost = 0 ;
total_labor_cost     = 0 ;
for k = 1:K
    for it_crew = 1:num_crews(k)
        for i = 1:NI
            if sum(sol.x_NI_NI(i,:,k,it_crew)) + sum(sol.x_NI_NF(i,:,k,it_crew)) + sum(sol.x_NI_NT(i,:,k,it_crew)) == 1
                total_material_cost  = total_material_cost + ...
                    Material_Cost(k,it_crew)*Quantity(k,i) ;
                total_equipment_cost = 0 ;
                total_labor_cost = total_labor_cost + ...
                    Quantity(k,i)/Productivity(k,it_crew)*DailyCrewCost(k,it_crew) ;
            end
        end
    end
end

total_project_cost = evaluate(indirect_cost,sol) + ...
    evaluate(interruption_cost ,sol) + ...
    evaluate(dismissal_cost    ,sol) + ...
    total_material_cost  + ...
    total_equipment_cost + ...
    total_labor_cost       ;

Total_Project_Cost   = num2bank(round(total_project_cost))   ;
Total_Material_Cost  = num2bank(round(total_material_cost))  ;
Total_Equipment_Cost = num2bank(round(total_equipment_cost)) ;
Total_Labor_Cost     = num2bank(round(total_labor_cost))     ;

str_schedule_summary = sprintf('\a Total Project Cost = $%s\n\a Project Indirect Cost = $%s\n\a Interruption Cost = $%s\n         - Crew Idle Cost = $%s\n         - Crew Deployement Cost = $%s\n\a Total Work Interruptions = %.2f days\n\a Total Material Cost = $%s\n\a Total Equipment Cost = $%s\n\a Total Labor Cost = $%s',...
    Total_Project_Cost(1:end-1)    ,...
    Project_Indirect_Cost(1:end-1) ,...
    Interruption_Cost(1:end-1)     ,...
    Crew_Idle_Cost(1:end-1)        ,...
    Crew_Deployment_Cost(1:end-1)  ,...
    abs(Total_Work_Interruption)        ,...
    Total_Material_Cost(1:end-1)   ,...
    Total_Equipment_Cost(1:end-1)  ,...
    Total_Labor_Cost(1:end-1)            ) ;

annotation('textbox', [0.6, 0.2, 0.1, 0.1], 'String', str_schedule_summary,...
    'HorizontalAlignment','left',...
    'Color',interruption_font_color,'FontSize',15,...
    'FontWeight','bold','FontName','Arial')