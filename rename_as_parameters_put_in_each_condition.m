% This file contains all parameters to remove any need to copy codes into
% each condition. Edit this file alone to make sure what all tiff files go
% into the analysis

%% Step 1 - Identify all the wells using this base bright field image
fbrgt_base = 'dicc1t2xy1.tif';

%% Step 2 - Identify all cells at all time points (live and dead)
% Step 2 - Then, save all the cells that are inside wells
% Step 2 - Includes the code to identify deviations in well locations

num_times = 6; % Number of live (e.g. 1) + dead (e.g. 5) time points
% List of all images for live and dead time points
fcell_all = {
        'dapic1t2xy1.tif';
        'tritcc1t2xy1.tif';
        'tritcc1t3xy1.tif';
        'tritcc1t4xy1.tif';
        'tritcc1t5xy1.tif';
        'tritcc1t6xy1.tif';};
% Sheet labels for all live and dead timsheete points
sheet_names = {
        'live01';
        'dead01';
        'dead02';
        'dead03';
        'dead04';
        'dead05';};
% Bright field images for all images of cells from above (same order)            
fbrgt_all = {
        'dicc1t2xy1.tif';
        'dicc1t2xy1.tif';
        'dicc1t3xy1.tif';
        'dicc1t4xy1.tif';
        'dicc1t5xy1.tif';
        'dicc1t6xy1.tif'};

% Auto illumination settings (note: 0 is not auto)
auto_illum = [0 0.3 0.3 0.3 0.3 0.3];%repmat(0.6,1,4)];

%% Step 3 - Randomize existing data to create (ideally) 3 replicates 
num_replicates = 3; % Number of technical replicates
num_bulbs = 100; % Number of cells in bulbs in each replicate
num_loops = 100; % Number of cells in loops in each replicate

%% Step 4 - Identify live and dead sheets to perform tracking analysis
live_times = 1; % Number of live cell data time points
dead_times = num_times - live_times; % Number of dead cell data time points
% List of sheet names for reading
live_sheets = sheet_names(1);
dead_sheets = sheet_names(live_times+1:end);
