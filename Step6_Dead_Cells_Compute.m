%% Note that this creates two excel files - one for backup folder and for the other folder

close all
clearvars -except conds num_conds curr_cond
clc

run('Step0_change_directory.m'); % cd into the condition folder
cd ..\

conds = [1 2 3 4 5 6 7 8 9]; 
num_conds = length(conds);


write_name = 'Statistics_deadcells.xlsx'; % Writing into the excel file   

count_conds = 0; 
% count_conds_bkp = 0; 
deadCells = NaN(100,6); 
% deadCells_bkp = NaN(50,6); 
count_avg = 0; 
dead_cells_avg = NaN(num_conds,4); 

for i = 1:num_conds
    for j = 1:3
        %% running some tests to see if this replicate is invalid (does not exist or has 0 cells in wells, bulbs or loops)
        curr_file = strcat(folder_name, 'Cond_', num2str(conds(i)), '\replicate', num2str(j), '\Track_Cells.xlsx'); 
        if ~isfile(curr_file)
            fprintf('In condition %d, replicates beyond %d do not exist. Moving to next condition. \n',i,j);
            break;
        end
        wells_num = readmatrix(curr_file,'sheet','wells_num');
        dead_wells = ((wells_num(1)-wells_num(2))*100)/(wells_num(1) - wells_num(3)); 
        loops_num = readmatrix(curr_file,'sheet','loops_num');
        dead_loops = ((loops_num(1)-loops_num(2))*100)/(loops_num(1) - loops_num(3));  
        bulbs_num = readmatrix(curr_file,'sheet','bulbs_num');
        dead_bulbs = ((bulbs_num(1)-bulbs_num(2))*100)/(bulbs_num(1) - bulbs_num(3)); 

        count_conds = count_conds + 1; 
        deadCells (count_conds,:) = [i 1 j dead_wells dead_loops dead_bulbs]; 

    end
    
    for j = 1:3
        %% running some tests to see if this replicate is invalid (does not exist or has 0 cells in wells, bulbs or loops)
        curr_file = strcat(folder_name, 'Cond_', num2str(conds(i)), '\Backup\replicate', num2str(j), '\Track_Cells.xlsx'); 
        if ~isfile(curr_file)
            fprintf('In condition %d, backup replicates beyond %d do not exist. Moving to next condition. \n',i,j);
            break;
        end
        wells_num = readmatrix(curr_file,'sheet','wells_num');
        dead_wells = ((wells_num(1)-wells_num(2))*100)/(wells_num(1) - wells_num(3)); 
        loops_num = readmatrix(curr_file,'sheet','loops_num');
        dead_loops = ((loops_num(1)-loops_num(2))*100)/(loops_num(1) - loops_num(3));  
        bulbs_num = readmatrix(curr_file,'sheet','bulbs_num');
        dead_bulbs = ((bulbs_num(1)-bulbs_num(2))*100)/(bulbs_num(1) - bulbs_num(3)); 

        count_conds = count_conds + 1; 
        deadCells (count_conds,:) = [i 2 j dead_wells dead_loops dead_bulbs]; 

    end
    count_avg = count_avg + 1; 
    idx = find(deadCells(:,1)==i); 
    dead_cells_avg(count_avg,:) = [i mean(deadCells(idx,4:6))]; 
end
deadCells(count_conds+1,:) = []; 
% deadCells_bkp(count_conds_bkp+1, :) = []; 
writematrix(deadCells, strcat(folder_name, write_name), 'Sheet', 'dead cells','WriteMode','overwritesheet'); 
writematrix(dead_cells_avg, strcat(folder_name, write_name), 'Sheet', 'dead cells avg','WriteMode','overwritesheet');  
