% This code filters all the wells that have a maximum of three cells and then removes all the live cells that have an area greater than 177 sq microns. 
% This is helpful in avoiding cluttering. 

close all
clear variables
clc

if ~isfile('Cells_Wells_Old.xlsx')
    movefile('Cells_Wells.xlsx', 'Cells_Wells_Old.xlsx');
    movefile('Cells_Bulbs.xlsx', 'Cells_Bulbs_Old.xlsx');
    movefile('Cells_Loops.xlsx', 'Cells_Loops_Old.xlsx');
end

num_times = 6;
sheet_names = {
        'live01';
        'dead01';
        'dead02';
        'dead03';
        'dead04';
        'dead05';
                };

for each_time = 1:num_times
    % Removing all wells that have greater than 3 cells. 
    % Removing corresponding bulbs and loops too. 
    % Note: Handling sorted data
    
    wells = readmatrix('Cells_Wells_Old.xlsx', 'Sheet', sheet_names{each_time});
    bulbs = readmatrix('Cells_Bulbs_Old.xlsx', 'Sheet', sheet_names{each_time});
    loops = readmatrix('Cells_Loops_Old.xlsx', 'Sheet', sheet_names{each_time});
    
    wells_stats = unique(wells(:,1)); % unique well numbers
    wells_stats(:,2) = groupcounts(wells(:,1)); % Repetitions
    wells_excld = wells_stats((wells_stats(:,2)>3),1); % Greater than 3 (all time points live and dead)
    wells_check = ~ismember(wells(:,1),wells_excld); % Identify in wells
    wells_mdfd = wells(wells_check,:); % Keep only those that not in excld
    bulbs_check = ~ismember(bulbs(:,1),wells_excld); % Identify in bulbs
    bulbs_mdfd = bulbs(bulbs_check,:); % Keep only those that not in excld
    loops_check = ~ismember(loops(:,1),wells_excld); % Identify in loops
    loops_mdfd = loops(loops_check,:); % Keep only those that not in excld
    
    % removing all live cells only that have an area greater than 177 sq microns
    if (each_time == 1)
        cells_wells_excld = find(wells_mdfd(:,3) > 177); wells_mdfd(cells_wells_excld,:) = [];
        cells_bulbs_excld = find(bulbs_mdfd(:,3) > 177); bulbs_mdfd(cells_bulbs_excld,:) = [];
        cells_loops_excld = find(loops_mdfd(:,3) > 177); loops_mdfd(cells_loops_excld,:) = [];
    end
    
    writematrix(wells_mdfd, 'Cells_Wells.xlsx', 'Sheet', sheet_names{each_time},'WriteMode','overwritesheet');
    writematrix(bulbs_mdfd, 'Cells_Bulbs.xlsx', 'Sheet', sheet_names{each_time},'WriteMode','overwritesheet');
    writematrix(loops_mdfd, 'Cells_Loops.xlsx', 'Sheet', sheet_names{each_time},'WriteMode','overwritesheet');
    
end
%     
%     % add condition for iteration == 1
%     % randsample([1 3 5 7 9],3); - this will randomize 3 numbers within
%     % this array



