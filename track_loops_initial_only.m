% close all
% clear variables
% clc
function [num_live_loops, cell_not_found, dead_loops_begin] = track_loops_initial_only()
    live_times = 1; % Number of live cell data time points
    dead_times = 5; % Number of live cell data time points
    % List of sheet names for reading
    live_sheets = {
        'live01';
                    };
    dead_sheets = {
        'dead01';
        'dead02';
        'dead03';
        'dead04';
        'dead05';};

    data_live = cell(live_times,1);
    data_dead = cell(dead_times,1);
    % Reading live and dead cell data sheets
    data_live{1} = readmatrix('Cells_Loops','sheet',live_sheets{1}); 
    for i = 1:dead_times
        data_dead{i} = readmatrix('Cells_Loops','sheet',dead_sheets{i});    
    end

    % If cells are too close in live image, ignore both of them
    %% Identifying the stage of cells throughout
    num_live_loops = length(data_live{1}(:,1)); % Total number of live cells in loops
    tracking_mat_loops = zeros(2*num_live_loops, 13); % Initializing the tracking matrix
    count = 0; dead_loops_begin = 0; cell_not_found = 0;  % Initializing count for tracking, and variables to identify dead cells in first time point and cells without a dead counterpart

    % Iterating over loops
    for curr_well = 1:1024
    % curr_well = 314;
        cells_curr_well = data_live{1}((data_live{1}(:,1)==curr_well),:); % Identifying all cells in current well
        if isempty(cells_curr_well) %Skipping this iteration if there are no cells in the well at first time point
            continue;
        end
        num_cells_well = length(cells_curr_well(:,1)); % Number of cells within this specific well

        %Iterating over each cell within the current well
        for each_cell = 1:num_cells_well 
            centroid_curr = cells_curr_well(each_cell,4:5); % Identifying the centroid of the current cell within the current well
            pass = 0; % Initializing a variable that indicates if a dead counterpart is found

            % Iterating over each time point for dead cells to identify the time of death
            for each_time = 1:dead_times 
                cells_time_well = data_dead{each_time}((data_dead{each_time}(:,1)==curr_well),:); % Reading all dead cells in current time point
                centroid_time = cells_time_well(:,4:5); % Identifying centroids of all dead cells in current time point
                idx = knnsearch(centroid_time, centroid_curr); % Searching for the cell whose centroid is closest to the current live cell at first time point within this well
                cell_disp = abs(round(centroid_time(idx,:)-centroid_curr)); % Identifying the distance between the closest dead cell at this time point and the current live cell within this well
                if (isempty(idx) || any(cell_disp>25)) % Ensuring that it is indeed the same cell by restricting the distance between centroids to be no greater than 25 pixels (in both x and y)
                        continue; %If its not the cell the code is looking for, this will move the search to the next time point
                else
                    if (each_time~=1) % Ensuring that the cell died after time point 1
                        pass = 1; % Indicates that the code found a dead cell
                        count = count + 1; % Increments for each dead cell
                        tracking_mat_loops(count,7:12) = [each_time cells_time_well(idx,:)]; % Copying the dead cell with its well number, time of death, area and centroid into the tracking matrix
                        tracking_mat_loops(count,1:6) = [1 cells_curr_well(each_cell,:)];% Copying the live cell with its well number, time = 1, area and centroid into the tracking matrix
                    else % Cells at time point 1 are ignored
                        dead_loops_begin = dead_loops_begin + 1; % this variable counts all the cells that are dead at time point 1 
                    end
                    break; % This will ensure that the code does not keep looking for cells even after finding its time of death
                end
            end

            % Saving time of death and all the cells that have not been considered
            if (pass ~= 1) 
                cell_not_found = cell_not_found + 1; % Adding to the number of cells whose analysis cannot be completed
            end
        end
    end

    tracking_mat_loops(tracking_mat_loops(:,1)==0,:) = []; % Removing all extra cells that have not been considered
    tracking_mat_loops(:,end) = (tracking_mat_loops(:,10)./tracking_mat_loops(:,4)); % Including ratios of areas as the last column
    write_name = 'Track_Cells.xlsx'; % Writing into the excel file
    writematrix(tracking_mat_loops, write_name, 'Sheet', 'loops','WriteMode','overwritesheet'); % loops have their own sheet
    writematrix([num_live_loops, cell_not_found, dead_loops_begin], write_name, 'Sheet', 'loops_num','WriteMode','overwritesheet'); % includes the numbers
    fprintf('Loops tracking done\n');
end
