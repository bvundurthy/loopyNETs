close all
% clear variables
clearvars -except conds num_conds curr_cond
clc

% delete 'Track_Cells.xlsx'
try
    movefile('Track_Cells.xlsx', 'Track_Cells_Old.xlsx', 'f');
catch
    disp('First run with this replicate. File does not exist');
end

[total_wells, ignored_wells, dead_begin_wells] = track_wells_initial_only();
[total_loops, ignored_loops, dead_begin_loops] = track_loops_initial_only();
[total_bulbs, ignored_bulbs, dead_begin_bulbs] = track_bulbs_initial_only();
