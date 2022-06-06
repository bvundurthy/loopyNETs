close all
% clearvars -except conds num_conds curr_cond
% clc

run('Step0_change_directory.m'); % cd into the condition folder
run('parameters.m'); % import all necessary parameters for all Steps

cd(replicate_path); 

% delete 'Track_Cells.xlsx'
if isfile('Track_Cells.xlsx')
    movefile('Track_Cells.xlsx', 'Track_Cells_Old.xlsx', 'f');
end

addpath(git_path_name); 
[total_wells, ignored_wells, dead_begin_wells] = track_wells_initial_only(live_times, dead_times, live_sheets, dead_sheets, replicate_path);
[total_loops, ignored_loops, dead_begin_loops] = track_loops_initial_only(live_times, dead_times, live_sheets, dead_sheets, replicate_path);
[total_bulbs, ignored_bulbs, dead_begin_bulbs] = track_bulbs_initial_only(live_times, dead_times, live_sheets, dead_sheets, replicate_path);
