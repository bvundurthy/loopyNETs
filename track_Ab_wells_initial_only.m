% close all
% clear variables
% clc
% run('Step0_change_directory.m'); % cd into the condition folder
% run('parameters.m'); % import all necessary parameters for all Steps
% % cd(replicate_path_name); 
% live_times = 1;
% dead_times = num_Ab_sheets;
% live_sheets = {'wells'};
% dead_sheets = Ab_sheets; 

function [] = track_Ab_wells_initial_only(live_times, dead_times, live_sheets, dead_sheets, replicate_path_name)
    data_live = cell(live_times,1);
    data_dead = cell(dead_times,1);
    % Reading live and dead cell data sheets
    data_live{1} = readmatrix('Track_Cells','sheet',live_sheets{1}); 
    for i = 1:dead_times
        data_dead{i} = readmatrix('Cells_Wells','sheet',dead_sheets{i});    
    end

    % If cells are too close in live image, ignore both of them
    %% Identifying the stage of cells throughout
    num_live_wells = length(data_live{1}(:,1)); % Total number of live cells in Track_Cells file
    tracking_mat_wells = data_live{1}; % Copying the tracking matrix to add a new column
    tracking_mat_wells(:,end+1) = zeros(num_live_wells,1); % Adding new column for antibody staining
    
    for each_cell = 1:num_live_wells
        curr_cell = data_live{1}(each_cell,:); 
        curr_well = curr_cell(2); 
        curr_centroid = curr_cell(5:6); % Identifying the centroid of the current cell
        pass = 0; % Initializing a variable that indicates if a dead counterpart is found
     
        for each_time = 1:dead_times
            cells_time_well = data_dead{each_time}((data_dead{each_time}(:,1)==curr_well),:); % Reading all dead cells in current time point
            centroid_time = cells_time_well(:,4:5); % Identifying centroids of all dead cells in current time point
            idx = knnsearch(centroid_time, curr_centroid); % Searching for the cell whose centroid is closest to the current live cell at first time point within this well
            cell_disp = abs(round(centroid_time(idx,:)-curr_centroid)); % Identifying the distance between the closest dead cell at this time point and the current live cell within this well
            if (isempty(idx) || any(cell_disp>500)) % Ensuring that it is indeed the same cell by restricting the distance between centroids to be no greater than 25 pixels (in both x and y)
                continue; %If its not the cell the code is looking for, this will move the search to the next time point
            else
                pass = pass + 1; 
            end
        end
        tracking_mat_wells(each_time,end) = pass; % updating the file with the current status            
    end

    write_name = strcat(replicate_path_name,'Track_Cells.xlsx'); % Writing into the excel file
    writematrix(tracking_mat_wells, write_name, 'Sheet', 'wells','WriteMode','overwritesheet'); % wells have their own sheet
    fprintf('Antibody stain tracking done. \n');
end
