% This file contains all parameters to remove any need to copy codes into
% each condition. Edit this file alone to make sure what all tiff files go
% into the analysis

%% Step 1 and 2 
% Consolidated list of all the bright field images 
fbrgt_cons = {
        'dicc1t1xy1.tif'; % 1
        'dicc1t2xy1.tif'; % 2
        'dicc1t3xy1.tif'; % 3
        'dicc1t4xy1.tif'; % 4
        'dicc1t5xy1.tif'; % 5
        'dicc1t6xy1.tif'; % 6
        'ab_dicc1xy1.tif'}; %7

% Number of cell images
num_times = 9; % Number of live (e.g. 1) + dead (e.g. 6) + antibody (e.g. 2) time points

% Consolidated list of all the cell images (live, dead and antibody) 
fcell_all = {
        'dapic1t1xy1.tif';  % 1 - 1  
        'tritcc1t1xy1.tif'; % 2 - 1
        'tritcc1t2xy1.tif'; % 3 - 2
        'tritcc1t3xy1.tif'; % 4 - 3
        'tritcc1t4xy1.tif'; % 5 - 4
        'tritcc1t5xy1.tif'; % 6 - 5
        'tritcc1t6xy1.tif'; % 7 - 6
        'ab_dapic1xy1.tif'; % 8 - 7
        'ab_cy5c1xy1.tif';}; % 9 - 7
        

% Base bright field image:     
fbrgt_base_num = 1; % <- Change this if you want to change the base image
fbrgt_base = fbrgt_cons{fbrgt_base_num}; % Do not touch this

% Bright field image associations to cells images
fbrgt_num = [1 1 2 3 4 5 6 7 7]; %<- change this
fbrgt_all = fbrgt_cons(fbrgt_num); % Do not touch this

% Sheet labels for all live, dead and antibody timsheet points
sheet_names = {
        'live01';
        'dead01';
        'dead02';
        'dead03';
        'dead04';
        'dead05';
        'dead06';
        'ab_dapi';
        'ab_cy5';};

% Loads bubble coordinates if available
bbl_box = [];
if isfile('bubbles_coords.mat')
    load('bubbles_coords.mat');
end

% Auto illumination settings (note: 0 is not auto)
% Note: num_times + 2 (Extra 2 values are for antibody staining 
% - mandatory only if you have antibody staining (not needed otherwise)
auto_illum = [0.2 0.3 0.3 0.3 0.3 0.3 0.3 0.3 0.3];  

%% Step 3 - Randomize existing data to create (ideally) 3 replicates 
num_replicates = 3; % Number of technical replicates
num_bulbs_rep = 100; % Number of cells in bulbs in each replicate
num_loops_rep = 100; % Number of cells in loops in each replicate

%% Step 4 - Identify live and dead sheets to perform tracking analysis
live_times = 1; % Number of live cell data time points
dead_times = 6; % Number of dead cell data time points (Do not include antibody files)
% List of sheet names for reading
live_sheets = sheet_names(1);
dead_sheets = sheet_names(2:1+dead_times);

%% Step 4a - Antibody staining
Ab_switch = false; 
Ab_sheets = {
        'ab_dapi';
        'ab_cy5';};
num_Ab_sheets = 2;
