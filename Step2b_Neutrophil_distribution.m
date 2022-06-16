close all
clearvars -except conds num_conds curr_cond
clc

run('Step0_change_directory.m'); % cd into the condition folder
run('parameters.m'); % import all necessary parameters for all Steps

% Read information about the wells from the excel file created in Step 1
wells = readmatrix('wells_list.xlsx');
num_wells = length(wells(:,1)); 
% Read information of all the cells from the unfiltered excel file created in Step 2
cells_wells = readmatrix('Cells_Wells_unfiltered.xlsx', 'Sheet', 'live01');

% Count the repititions in well numbers
[wells_counts,~] = groupcounts(cells_wells(:,1)); 
% Count the repititions in wells_counts - this will give the number of wells with 1, 2, 3, etc. cells in them
[category_counts, category] = groupcounts(wells_counts); 

num_wells_valid = length(unique(cells_wells(:,1))); % wells with at least one cell
num_cells = length(cells_wells(:,1)); % total number of cells
fprintf('The total number of detected wells is %d. \n', num_wells);
fprintf('There are a total of %d cells spread across %d wells. \n', num_cells, num_wells_valid); 

fprintf('%2.2f%% of wells have NO cell/s in them. \n', (((num_wells-num_wells_valid)/num_wells)*100)); 
for i = 1:length(category)
    fprintf('%2.2f%% (%d) of wells have only %d cell/s in them. \n', ((category_counts(i)/num_wells)*100),category_counts(i), category(i)); 
end
