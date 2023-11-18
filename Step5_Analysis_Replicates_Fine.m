%% Note that this creates two excel files
% the data in these excel files is wells, loops and bulbs for each
% replicate. so if you have 9 rows, rows 1-3 are wells (three
% replicates), rows 4-6 are loops (three replicates) and rows 7-9 are bulbs
% (three replicates). if you have only three rows in total, row 1 is wells,
% row 2 is loops and row 3 is bulbs - indicates only 1 replicate

close all
clearvars -except conds num_conds curr_cond
clc

run('Step0_change_directory.m'); % cd into the condition folder
cd ..\

conds = [1 2 3 4 5 6 7 8 9]; 
num_conds = length(conds);


write_name_ratio = 'Statistics_Ratio.xlsx'; % Writing into the excel file   
write_name_times = 'Statistics_Times.xlsx'; % Writing into the excel file   

ratio_min = 2;
ratio_max = 15; 
time_min = 0.5; 
time_max = 6.5; 
% x_bins = ratio_min:1:ratio_max; 
x_bins = [2 5 10 15]; 
x_bins_labels = strcat(num2str(x_bins(1:end-1)'),'-',num2str(x_bins(2:end)'));
x_bins_times = time_min:1:time_max;  
x_times_labels = strcat('0000',num2str((x_bins_times(1:end-1)+0.5)'));

% ratio_perc_wells = cell(3,1); ratio_perc_loops = cell(3,1); ratio_perc_bulbs = cell(3,1); 
% cum_ratio_wells_times = cell(3,1); cum_ratio_loops_times = cell(3,1); cum_ratio_bulbs_times = cell(3,1); 

count_wells = 0; count_loops = 0; count_bulbs = 0; 
ratios_len = length(x_bins)-1; ratio_perc_wells = NaN(300,5); ratio_perc_loops = NaN(300,5); ratio_perc_bulbs = NaN(300,5);
times_len = length(x_bins_times)-1; cum_ratio_wells_times = NaN(300,times_len+4); cum_ratio_loops_times = NaN(300,times_len+4); cum_ratio_bulbs_times = NaN(300,times_len+4);

count_wells_avg = 0; count_loops_avg = 0; count_bulbs_avg = 0; 
ratio_wells_avg = NaN(300,5); ratio_loops_avg = NaN(300,5); ratio_bulbs_avg = NaN(300,5); 
times_wells_avg = NaN(300,times_len+4);  times_loops_avg = NaN(300,times_len+4);  times_bulbs_avg = NaN(300,times_len+4); 


for i = 1:num_conds
    for j = 1:3
        %% running some tests to see if this replicate is invalid (does not exist or has 0 cells in wells, bulbs or loops)
        curr_file = strcat(folder_name, 'Cond_', num2str(conds(i)), '\replicate', num2str(j), '\Track_Cells.xlsx'); 
        if ~isfile(curr_file)
            fprintf('In condition %d, replicates beyond %d do not exist. Moving to next condition. \n',i,j);
            break;
        end
        cells_track_wells = readmatrix(curr_file,'sheet','wells');
        wells_num = readmatrix(curr_file,'sheet','wells_num');
        
        cells_track_loops = readmatrix(curr_file,'sheet','loops');
        loops_num = readmatrix(curr_file,'sheet','loops_num');
        
        cells_track_bulbs = readmatrix(curr_file,'sheet','bulbs');
        bulbs_num = readmatrix(curr_file,'sheet','bulbs_num');

        if (isempty(cells_track_wells) || isempty(cells_track_bulbs) || isempty(cells_track_loops))
            fprintf('In condition %d and replicate %d there are no cells in either wells, bulbs or loops. Moving to next replicate. \n',i,j);
            continue;
        end
        for k = 1:ratios_len
            %% Computation for wells
            idx_wells = find(cells_track_wells(:,end)>=x_bins(k) & cells_track_wells(:,end)<=x_bins(k+1)); 
            ratio_restrict_wells = cells_track_wells(idx_wells,:); 

            den_wells = (wells_num(1) - wells_num(3)); 
%             ratio_hist_wells = histcounts(ratio_restrict_wells(:,end),x_bins);
            
            count_wells = count_wells+1; 
            ratio_perc_wells(count_wells,:) = [i 1 j k (length(idx_wells)/den_wells)*100];
            cum_ratio_wells_times(count_wells,:) = [i 1 j k cumsum(histcounts(ratio_restrict_wells(:,7),x_bins_times))/den_wells*100];

            %% Computation for loops
            idx_loops = find(cells_track_loops(:,end)>=x_bins(k) & cells_track_loops(:,end)<=x_bins(k+1)); 
            ratio_restrict_loops = cells_track_loops(idx_loops,:); 

            den_loops = (loops_num(1) - loops_num(3)); 
%             ratio_hist_loops = histcounts(ratio_restrict_loops(:,end),x_bins);
            
            count_loops = count_loops+1; 
            ratio_perc_loops(count_loops,:) = [i 1 j k (length(idx_loops)/den_loops)*100];
            cum_ratio_loops_times(count_loops,:) = [i 1 j k cumsum(histcounts(ratio_restrict_loops(:,7),x_bins_times))/den_loops*100];

            %% Computation for bulbs
            idx_bulbs = find(cells_track_bulbs(:,end)>=x_bins(k) & cells_track_bulbs(:,end)<=x_bins(k+1)); 
            ratio_restrict_bulbs = cells_track_bulbs(idx_bulbs,:); 

            den_bulbs = (bulbs_num(1) - bulbs_num(3)); 
%             ratio_hist_bulbs = histcounts(ratio_restrict_bulbs(:,end),x_bins);
            
            count_bulbs = count_bulbs+1; 
            ratio_perc_bulbs(count_bulbs,:) = [i 1 j k (length(idx_bulbs)/den_bulbs)*100];
            cum_ratio_bulbs_times(count_bulbs,:) = [i 1 j k cumsum(histcounts(ratio_restrict_bulbs(:,7),x_bins_times))/den_bulbs*100];

            
        end
    end

    
    for j = 1:3
        %% running some tests to see if this replicate is invalid (does not exist or has 0 cells in wells, bulbs or loops)
        curr_file = strcat(folder_name, 'Cond_', num2str(conds(i)), '\Backup\replicate', num2str(j), '\Track_Cells.xlsx'); 
        if ~isfile(curr_file)
            fprintf('In condition %d, backup replicates beyond %d do not exist. Moving to next condition. \n',i,j);
            break;
        end
        cells_track_wells = readmatrix(curr_file,'sheet','wells');
        wells_num = readmatrix(curr_file,'sheet','wells_num');
        
        cells_track_loops = readmatrix(curr_file,'sheet','loops');
        loops_num = readmatrix(curr_file,'sheet','loops_num');
        
        cells_track_bulbs = readmatrix(curr_file,'sheet','bulbs');
        bulbs_num = readmatrix(curr_file,'sheet','bulbs_num');

        if (isempty(cells_track_wells) || isempty(cells_track_bulbs) || isempty(cells_track_loops))
            fprintf('In condition %d and replicate %d there are no cells in either wells, bulbs or loops. Moving to next replicate. \n',i,j);
            continue;
        end
        for k = 1:ratios_len
            %% Computation for wells
            idx_wells = find(cells_track_wells(:,end)>=x_bins(k) & cells_track_wells(:,end)<=x_bins(k+1)); 
            ratio_restrict_wells = cells_track_wells(idx_wells,:); 

            den_wells = (wells_num(1) - wells_num(3)); 
%             ratio_hist_wells = histcounts(ratio_restrict_wells(:,end),x_bins);
            
            count_wells = count_wells+1; 
            ratio_perc_wells(count_wells,:) = [i 2 j k (length(idx_wells)/den_wells)*100];
            cum_ratio_wells_times(count_wells,:) = [i 2 j k cumsum(histcounts(ratio_restrict_wells(:,7),x_bins_times))/den_wells*100];

            %% Computation for loops
            idx_loops = find(cells_track_loops(:,end)>=x_bins(k) & cells_track_loops(:,end)<=x_bins(k+1)); 
            ratio_restrict_loops = cells_track_loops(idx_loops,:); 

            den_loops = (loops_num(1) - loops_num(3)); 
%             ratio_hist_loops = histcounts(ratio_restrict_loops(:,end),x_bins);
            
            count_loops = count_loops+1; 
            ratio_perc_loops(count_loops,:) = [i 2 j k (length(idx_loops)/den_loops)*100];
            cum_ratio_loops_times(count_loops,:) = [i 2 j k cumsum(histcounts(ratio_restrict_loops(:,7),x_bins_times))/den_loops*100];

            %% Computation for bulbs
            idx_bulbs = find(cells_track_bulbs(:,end)>=x_bins(k) & cells_track_bulbs(:,end)<=x_bins(k+1)); 
            ratio_restrict_bulbs = cells_track_bulbs(idx_bulbs,:); 

            den_bulbs = (bulbs_num(1) - bulbs_num(3)); 
%             ratio_hist_bulbs = histcounts(ratio_restrict_bulbs(:,end),x_bins);
            
            count_bulbs = count_bulbs+1; 
            ratio_perc_bulbs(count_bulbs,:) = [i 2 j k (length(idx_bulbs)/den_bulbs)*100];
            cum_ratio_bulbs_times(count_bulbs,:) = [i 2 j k cumsum(histcounts(ratio_restrict_bulbs(:,7),x_bins_times))/den_bulbs*100];

            
        end
    end
    
    
    %% Averaging for every condition and every bin
    for k = 1:ratios_len
        
        %% Averaging wells
        count_wells_avg = count_wells_avg + 1; 
        idx = ratio_perc_wells(:,1)==i & ratio_perc_wells(:,4)==k; 
        ratio_wells_avg(count_wells_avg,:) = [i NaN NaN k mean(ratio_perc_wells(idx,5))];
        
        idx = cum_ratio_wells_times(:,1)==i & cum_ratio_wells_times(:,4)==k;
        times_wells_avg(count_wells_avg,:) = [i NaN NaN k mean(cum_ratio_wells_times(idx,5:10))]; 
        
        %% Averaging loops
        count_loops_avg = count_loops_avg + 1; 
        idx = ratio_perc_loops(:,1)==i & ratio_perc_loops(:,4)==k; 
        ratio_loops_avg(count_loops_avg,:) = [i NaN NaN k mean(ratio_perc_loops(idx,5))];
        
        idx = cum_ratio_loops_times(:,1)==i & cum_ratio_loops_times(:,4)==k;
        times_loops_avg(count_loops_avg,:) = [i NaN NaN k mean(cum_ratio_loops_times(idx,5:10))]; 
        
         %% Averaging bulbs
        count_bulbs_avg = count_bulbs_avg + 1; 
        idx = ratio_perc_bulbs(:,1)==i & ratio_perc_bulbs(:,4)==k; 
        ratio_bulbs_avg(count_bulbs_avg,:) = [i NaN NaN k mean(ratio_perc_bulbs(idx,5))];
        
        idx = cum_ratio_bulbs_times(:,1)==i & cum_ratio_bulbs_times(:,4)==k;
        times_bulbs_avg(count_bulbs_avg,:) = [i NaN NaN k mean(cum_ratio_bulbs_times(idx,5:10))]; 
        
    end
    
    
    
end

writematrix(ratio_perc_wells, strcat(folder_name, write_name_ratio), 'Sheet', 'wells', 'WriteMode','overwritesheet'); 
writematrix(ratio_perc_loops, strcat(folder_name, write_name_ratio), 'Sheet', 'loops', 'WriteMode','overwritesheet'); 
writematrix(ratio_perc_bulbs, strcat(folder_name, write_name_ratio), 'Sheet', 'bulbs', 'WriteMode','overwritesheet'); 

writematrix(ratio_wells_avg, strcat(folder_name, write_name_ratio), 'Sheet', 'wells_avg', 'WriteMode','overwritesheet'); 
writematrix(ratio_loops_avg, strcat(folder_name, write_name_ratio), 'Sheet', 'loops_avg', 'WriteMode','overwritesheet'); 
writematrix(ratio_bulbs_avg, strcat(folder_name, write_name_ratio), 'Sheet', 'bulbs_avg', 'WriteMode','overwritesheet'); 

writematrix(cum_ratio_wells_times, strcat(folder_name, write_name_times), 'Sheet', 'wells', 'WriteMode','overwritesheet'); 
writematrix(cum_ratio_loops_times, strcat(folder_name, write_name_times), 'Sheet', 'loops', 'WriteMode','overwritesheet'); 
writematrix(cum_ratio_bulbs_times, strcat(folder_name, write_name_times), 'Sheet', 'bulbs', 'WriteMode','overwritesheet'); 

writematrix(times_wells_avg, strcat(folder_name, write_name_times), 'Sheet', 'wells_avg', 'WriteMode','overwritesheet'); 
writematrix(times_loops_avg, strcat(folder_name, write_name_times), 'Sheet', 'loops_avg', 'WriteMode','overwritesheet'); 
writematrix(times_bulbs_avg, strcat(folder_name, write_name_times), 'Sheet', 'bulbs_avg', 'WriteMode','overwritesheet'); 
