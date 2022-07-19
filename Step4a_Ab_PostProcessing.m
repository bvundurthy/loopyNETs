close all
% clearvars -except conds num_conds curr_cond
% clc

run('Step0_change_directory.m'); % cd into the condition folder
run('parameters.m'); % import all necessary parameters for all Steps

cd(replicate_path_name); 

% delete 'Track_Cells.xlsx'
% if isfile('Track_Cells.xlsx')
%     movefile('Track_Cells.xlsx', 'Track_Cells_Old.xlsx', 'f');
% end

addpath(git_path_name); 
track_Ab_wells_initial_only(1, num_Ab_sheets, {'wells'}, Ab_sheets, replicate_path_name);
% 1 indicates 1 sheet from tracking and 1 Ab sheet

