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


write_name_ratio = 'Statistics_Ratio_(2-15)_unequal.xlsx'; % Writing into the excel file   
write_name_times = 'Statistics_Times_(2-15)_unequal.xlsx'; % Writing into the excel file   

ratio_min = 2;
ratio_max = 15; 
time_min = 0.5; 
time_max = 7.5; 
% x_bins = ratio_min:1:ratio_max; 
x_bins = [2 3 5 10 15]; 
x_bins_labels = strcat(num2str(x_bins(1:end-1)'),'-',num2str(x_bins(2:end)'));
x_bins_times = time_min:1:time_max;  
x_times_labels = strcat('0000',num2str((x_bins_times(1:end-1)+0.5)'));

% ratio_perc_wells = cell(3,1); ratio_perc_loops = cell(3,1); ratio_perc_bulbs = cell(3,1); 
% cum_ratio_wells_times = cell(3,1); cum_ratio_loops_times = cell(3,1); cum_ratio_bulbs_times = cell(3,1); 

for i = 1:num_conds
    ratios_len = length(x_bins)-1; ratio_perc_wells = NaN(3,ratios_len); ratio_perc_loops = NaN(3,ratios_len); ratio_perc_bulbs = NaN(3,ratios_len);
    times_len = length(x_bins_times)-1; cum_ratio_wells_times = NaN(3,times_len); cum_ratio_loops_times = NaN(3,times_len); cum_ratio_bulbs_times = NaN(3,times_len);
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
        %% Computation for wells
        idx_wells = (cells_track_wells(:,end)<=ratio_max & cells_track_wells(:,end)>=ratio_min); 
        ratio_restrict_wells = cells_track_wells(idx_wells,:); 

        den_wells = (wells_num(1) - wells_num(3)); 
        ratio_hist_wells = histcounts(ratio_restrict_wells(:,end),x_bins);

        ratio_perc_wells(j,:) = (ratio_hist_wells/den_wells)*100;
        cum_ratio_wells_times(j,:) = cumsum(histcounts(ratio_restrict_wells(:,7),x_bins_times))/den_wells*100;

    %% Computation for loops        
        idx_loops = (cells_track_loops(:,end)<=ratio_max & cells_track_loops(:,end)>=ratio_min); 
        ratio_restrict_loops = cells_track_loops(idx_loops,:); 

        den_loops = (loops_num(1) - loops_num(3)); 
        ratio_hist_loops = histcounts(ratio_restrict_loops(:,end),x_bins);
        
        ratio_perc_loops(j,:) = (ratio_hist_loops/den_loops)*100;
        cum_ratio_loops_times(j,:) = cumsum(histcounts(ratio_restrict_loops(:,7),x_bins_times))/den_loops*100;

    %% Computation for bulbs        
        idx_bulbs = (cells_track_bulbs(:,end)<=ratio_max & cells_track_bulbs(:,end)>=ratio_min); 
        ratio_restrict_bulbs = cells_track_bulbs(idx_bulbs,:); 

        den_bulbs = (bulbs_num(1) - bulbs_num(3)); 
        ratio_hist_bulbs = histcounts(ratio_restrict_bulbs(:,end),x_bins);
        
        ratio_perc_bulbs(j,:) = (ratio_hist_bulbs/den_bulbs)*100;
        cum_ratio_bulbs_times(j,:) = cumsum(histcounts(ratio_restrict_bulbs(:,7),x_bins_times))/den_bulbs*100;

    end
    writematrix([ratio_perc_wells; ratio_perc_loops; ratio_perc_bulbs], strcat(folder_name, write_name_ratio), 'Sheet', strcat('dead','_cond_',num2str(conds(i))),'WriteMode','overwritesheet'); 
    writematrix([cum_ratio_wells_times; cum_ratio_loops_times; cum_ratio_bulbs_times], strcat(folder_name, write_name_times), 'Sheet', strcat('time','_cond_',num2str(conds(i))),'WriteMode','overwritesheet'); 

end


%% In case you want to debug using plots
    %     figure(1)
    %     subplot(2,3,i)
    %     histogram('BinEdges',x_bins_wells,'BinCounts',ratio_perc_wells);
    %     xticks(x_bins_wells);
    %     yticks(0:5:100);
    %     ylim([0 50]);
    %     fprintf('The total percentage of nets released in wells in cond %f= %f\n',i,sum(ratio_perc_wells));
    %     figure(2)
    %     hold on
    %     plot(0:4, cum_ratio_wells_times); 

