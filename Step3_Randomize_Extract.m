close all
clearvars -except conds num_conds curr_cond
clc

run('Step0_change_directory.m'); % cd into the condition folder
run('parameters.m'); % import all necessary parameters for all Steps

bulbs_num_reps = num_replicates; 
loops_num_reps = num_replicates; 
%% Creates new files and folders for replicates
for i = 1:num_replicates
    if isfile(append('replicate',num2str(i),'\Cells_Wells.xlsx'))
        fprintf('Replicate %d folder already exists. Deleting and recreating new folder. \n', i);
        rmdir(strcat('replicate',num2str(i)), 's');
    end
    newfile = strcat('replicate',num2str(i)); 
    mkdir(newfile);
    copyfile('Cells_Bulbs.xlsx', newfile);
    copyfile('Cells_Loops.xlsx', newfile);
    copyfile('Cells_Wells.xlsx', newfile); 
%         copyfile('Step4_PostProcessing.m', newfile); 
%         copyfile('track_bulbs_initial_only.m', newfile); 
%         copyfile('track_loops_initial_only.m', newfile); 
%         copyfile('track_wells_initial_only.m', newfile); 
    fprintf('Replicate %d folder created\n', i); 
end
%% Extract <num_replicates> sets of <num_bulbs> bulbs

bulbs = readmatrix('Cells_Bulbs.xlsx', 'Sheet', 'live01');
bulbs_num = length(bulbs(:,1)); 

array_bulbs = 1:bulbs_num; 
replicate = cell(num_replicates,1);
bulbs_replicate = cell(num_replicates,1);
for i = 1:num_replicates
    if (length(array_bulbs)<num_bulbs)
        bulbs_num_reps = i-1; 
        break;
    end
    replicate{i} = randsample(array_bulbs,num_bulbs);
    idx_rep = ismember(array_bulbs, replicate{i});
    array_bulbs(idx_rep) = [];
    
    bulbs_replicate{i} = bulbs(replicate{i}',:); 
    writematrix(bulbs_replicate{i}, strcat('replicate',num2str(i),'\Cells_Bulbs.xlsx'), 'Sheet', 'live01','WriteMode','overwritesheet');
end
%% Extract <num_replicates> sets of <num_loops> loops

loops = readmatrix('Cells_Loops.xlsx', 'Sheet', 'live01');
loops_num = length(loops(:,1)); 

array_loops = 1:loops_num; 
replicate = cell(num_replicates,1);
loops_replicate = cell(num_replicates,1);
wells_replicate = cell(num_replicates,1); 
for i = 1:num_replicates
    if (length(array_loops) < num_loops || i > bulbs_num_reps)
        loops_num_reps = i-1; 
        break;
    end
    replicate{i} = randsample(array_loops,num_loops);
    idx_rep = ismember(array_loops, replicate{i});
    array_loops(idx_rep) = [];
    
    loops_replicate{i} = loops(replicate{i}',:); 
    writematrix(loops_replicate{i}, strcat('replicate',num2str(i),'\Cells_Loops.xlsx'), 'Sheet', 'live01','WriteMode','overwritesheet');
    
    wells_replicate{i} = [bulbs_replicate{i}; loops_replicate{i}]; 
    writematrix(wells_replicate{i}, strcat('replicate',num2str(i),'\Cells_Wells.xlsx'), 'Sheet', 'live01','WriteMode','overwritesheet');
end

correct_reps = min(bulbs_num_reps, loops_num_reps); 
if (correct_reps == 1)
    rmdir('replicate2', 's');    
    rmdir('replicate3', 's');
    fprintf('Replicates 2 and 3 folders removed \n');
elseif (correct_reps == 2)
    rmdir('replicate3', 's');
    fprintf('Replicate 3 folder removed \n');
end

%% Change the current directory to inside each replicate folder and run Step 4
for i = 1:correct_reps
    fprintf('Working on Replicate %d \n',i); 
    replicate_path_name = strcat(path_name, 'replicate', num2str(i),'\');
    run(strcat(git_path_name,'Step4_PostProcessing.m')); 
    cd ..\
end
