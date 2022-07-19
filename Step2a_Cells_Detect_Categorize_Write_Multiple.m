%% Step 2 of neutrophil identification
% Variable img_wells comes from Step 1 and contains all the wells with numbers
% Variable num_wells (also from Step 1) contains the total number of wells 
% Variable img_brgt contains the bright field source image from Step 1
close all
clearvars -except conds num_conds curr_cond
clc

tstart = tic;
run('Step0_change_directory.m'); % cd into the condition folder
run('parameters.m'); % import all necessary parameters for all Steps

fprintf('Starting Step 2a to detect cells across all time points. This step also creates excel files with all the data. \n Folder name: "%s" \n', path_name);

load 'Step1_wells.mat'; % load all data from Step 1
run_times = 1:num_times; % modify this if you want to run only a single time point

% commented out to help Dr. Datla run. Uncomment later...
% if isfile('Step2_cells.mat')
%      % Load the workspace
%      load 'Step2_cells.mat';
%      disp('Workspace loaded'); 
% else
    % Creating variables that will be saved later
    cells = cell(num_times, num_wells); 
    cells_wells_image = cell(num_times, num_wells);
    cells_bulbs_image = cell(num_times, num_wells);
    cells_loops_image = cell(num_times, num_wells);
    cells_wells = cell(num_times,1); 
    cells_bulbs = cell(num_times,1); 
    cells_loops = cell(num_times,1); 
% end

for curr_time = run_times
    fprintf('Getting Started: Iteration %d/%d \n', curr_time, num_times);
    tstart = tic; 
    %% Cell Identification and Writing Data
    % Reading the bright field image for easy plotting
    fbrgt = fbrgt_all{curr_time}; % Taking each bright image file
    img_brgt_src = imread(fbrgt);
    % Reading the image and converting it to binary
    fcell = fcell_all{curr_time}; 
    img_blob_src = imread(fcell);
    disp('Image loading done...');   

    img_blob_bw = rgb2gray(im2single(img_blob_src));     
    if (auto_illum(curr_time) == 0)
        img_blob_binary = imbinarize(img_blob_bw); % Note that the default is not 0 - this does the automated version by MATLAB
    else
        img_blob_binary = imbinarize(img_blob_bw,auto_illum(curr_time)); % useful with auto-illumination
    end
%     img_blob_binary = imbinarize(img_blob_bw,auto_illum(each_time));
    disp('Image conversion to binary done...');  

    %% Identifying and separating the cells 

    % Detecting Edges, Filling Holes, Detecting areas with specific interval
    img_blob_edge_log = edge(img_blob_binary, 'log',0);
    img_blob_fill_log = imfill(img_blob_edge_log,'holes');
    
    base_BB = cat(1,wells.BoundingBox);
    wells_disp = wells_disp_all(curr_time,:); 
    %% Extracting information for the current time point for every well
    count_fig = 0; count_wells = 1; count_bulbs = 1; count_loops = 1; 
    cells_wells{curr_time} = zeros(10000,5); 
    cells_bulbs{curr_time} = zeros(10000,5); 
    cells_loops{curr_time} = zeros(10000,5); 
    for curr_well = 1:num_wells
        
        cmin = ceil(base_BB(curr_well,1)+wells_disp(1)); 
        cmax = cmin + base_BB(curr_well,3) - 1;
        rmin = ceil(base_BB(curr_well,2)+wells_disp(2));
        rmax = rmin + base_BB(curr_well,4) - 1;
        
        if (cmin<0 || rmin<0 || cmax>size(img_brgt_src,2) || rmax>size(img_brgt_src,1))
            continue;
        end
        
        img_blob_area_log = bwareafilt(img_blob_fill_log(rmin:rmax, cmin:cmax),[85 Inf]); 
        blobs = regionprops(img_blob_area_log); % Determining regions
        blobs_centroid = round(cat(1,blobs.Centroid));
        blobs_BB = cat(1,blobs.BoundingBox);
        for curr_cell = 1:size(blobs_centroid,1)
            if (wells(curr_well).Image(blobs_centroid(curr_cell,2), blobs_centroid(curr_cell,1))==0)
                cell_cmin = ceil(blobs_BB(curr_cell,1)); 
                cell_cmax = cell_cmin + blobs_BB(curr_cell,3) - 1;
                cell_rmin = ceil(blobs_BB(curr_cell,2));
                cell_rmax = cell_rmin + blobs_BB(curr_cell,4) - 1;
                img_blob_area_log(cell_rmin:cell_rmax, cell_cmin:cell_cmax) = 0;
            end
        end
        
        curr_img_wells = img_blob_area_log; 
        curr_img_bulbs = img_blob_area_log; 
        curr_img_loops = img_blob_area_log; 
        % Recomputing blobs after eliminating cells outside wells
        blobs = regionprops(curr_img_wells); % Determining regions
        blobs_centroid = round(cat(1,blobs.Centroid));
        blobs_area = round(0.3025*cat(1,blobs.Area)); % Area in sq. microns
        blobs_BB = cat(1,blobs.BoundingBox);
        blobs_num = size(blobs_area,1); 
        
        for curr_cell = 1:blobs_num
            
            cell_cmin = ceil(blobs_BB(curr_cell,1)); 
            cell_cmax = cell_cmin + blobs_BB(curr_cell,3) - 1;
            cell_rmin = ceil(blobs_BB(curr_cell,2));
            cell_rmax = cell_rmin + blobs_BB(curr_cell,4) - 1;

            if (wells(curr_well).Bulb_Image(blobs_centroid(curr_cell,2), blobs_centroid(curr_cell,1))==1)
                % Cell is in the bulb - make the corresponding loop 0
                curr_img_loops(cell_rmin:cell_rmax, cell_cmin:cell_cmax) = 0;
                % Save in the well
                cells_wells{curr_time}(count_wells,:) = [curr_well count_wells blobs_area(curr_cell) blobs_centroid(curr_cell,:)]; % blobs_BB(curr_cell,:)];
                % Save in the bulb
                cells_bulbs{curr_time}(count_bulbs,:) = cells_wells{curr_time}(count_wells,:); 
                count_wells = count_wells + 1; 
                count_bulbs = count_bulbs + 1; 
                
            else
                % Cell is in the loop - make the corresponding bulb 0
                curr_img_bulbs(cell_rmin:cell_rmax, cell_cmin:cell_cmax) = 0;
                % Save in the well
                cells_wells{curr_time}(count_wells,:) = [curr_well count_wells blobs_area(curr_cell) blobs_centroid(curr_cell,:)]; % blobs_BB(curr_cell,:)];
                % Save in the loop
                cells_loops{curr_time}(count_loops,:) = cells_wells{curr_time}(count_wells,:);
                count_wells = count_wells + 1; 
                count_loops = count_loops + 1; 
            end
        end
        
        
        cells{curr_time, curr_well} = blobs; 
        cells_wells_image{curr_time, curr_well} = curr_img_wells;
        cells_bulbs_image{curr_time, curr_well} = curr_img_bulbs;
        cells_loops_image{curr_time, curr_well} = curr_img_loops;
        
%         if (rem(count_fig,10)==0)
%             count_fig = 0; 
%             figure (ceil(curr_well/10))
%         end
%         count_fig = count_fig + 1; 
%         subplot(2,5,count_fig)
%         hold on
%         curr_img_show = 0.5*img_brgt_src(rmin:rmax, cmin:cmax) + img_blob_src(rmin:rmax, cmin:cmax,:); 
%         if ~isempty(cells{curr_time, curr_well})
%             cells_marker = insertMarker(curr_img_show, blobs_centroid, '*', 'Color', 'w');  
%             cells_marker = insertText(cells_marker, blobs_centroid, blobs_area','AnchorPoint','LeftBottom','BoxOpacity',0,'TextColor','w');
%             imshow(cells_marker);
%             hold on
%             visboundaries(cells_bulbs_image{curr_time, curr_well},'Color','r'); 
%             visboundaries(cells_loops_image{curr_time, curr_well},'Color','m'); 
%             visboundaries(wells(curr_well).Image,'Color','c'); 
%         else
%             imshow(curr_img_show);
%             visboundaries(wells(curr_well).Image,'Color','c'); 
%         end

    end
    cells_wells{curr_time}(count_wells:end,:) = [];
    cells_bulbs{curr_time}(count_bulbs:end,:) = [];
    cells_loops{curr_time}(count_loops:end,:) = [];
    disp('Cells identification done. Writing variables. ');
    
    %% Printing 10 random wells for quick peak
    figure (curr_time)
    num_fig = 10; 
    rand_fig = randperm(num_wells,num_fig); % rand_fig = 360;
    for i = 1:num_fig
        curr_well = rand_fig(i);
        
        cmin = ceil(base_BB(curr_well,1)+wells_disp(1)); 
        cmax = cmin + base_BB(curr_well,3) - 1;
        rmin = ceil(base_BB(curr_well,2)+wells_disp(2));
        rmax = rmin + base_BB(curr_well,4) - 1;
        
        subplot(2,5,i)
        hold on;
        title(sprintf('Well np. %d', curr_well)); 
        sgtitle(sprintf('%s', sheet_names{curr_time})); 
        curr_img_show = img_blob_src(rmin:rmax, cmin:cmax,:); %0.5*img_brgt_src(rmin:rmax, cmin:cmax) + 
        if ~isempty(cells{curr_time, curr_well})
            cells_marker = insertMarker(curr_img_show, cat(1, cells{curr_time, curr_well}.Centroid), '*', 'Color', 'w');  
            cells_marker = insertText(cells_marker, cat(1, cells{curr_time, curr_well}.Centroid), cat(1, cells{curr_time, curr_well}.Area),'AnchorPoint','LeftBottom','BoxOpacity',0,'TextColor','w');
            imshow(cells_marker);
            visboundaries(cells_bulbs_image{curr_time, curr_well},'Color','r'); 
            visboundaries(cells_loops_image{curr_time, curr_well},'Color','m'); 
            visboundaries(wells(curr_well).Image,'Color','c'); 
        else
            imshow(curr_img_show);
            visboundaries(wells(curr_well).Image,'Color','c'); 
        end
    end
    savefig(sheet_names{curr_time})
    disp('Image saved successfully.');
    %% Writing to excel
    % Dec. 5, 2021 - Writing modified files into excel
    write_name = 'Cells_Wells.xlsx';
    writematrix(cells_wells{curr_time}, write_name, 'Sheet', sheet_names{curr_time},'WriteMode','overwritesheet');
    write_name = 'Cells_Bulbs.xlsx';
    writematrix(cells_bulbs{curr_time}, write_name, 'Sheet', sheet_names{curr_time},'WriteMode','overwritesheet');
    write_name = 'Cells_Loops.xlsx';
    writematrix(cells_loops{curr_time}, write_name, 'Sheet', sheet_names{curr_time},'WriteMode','overwritesheet');
    disp('Writing into excel files done...');
    toc(tstart);
end

% Create copies of files and operate on older files to ensure backup
movefile('Cells_Wells.xlsx', 'Cells_Wells_backup.xlsx');
movefile('Cells_Bulbs.xlsx', 'Cells_Bulbs_backup.xlsx');
movefile('Cells_Loops.xlsx', 'Cells_Loops_backup.xlsx');

disp('Note: "cells" contains Area (in pixels), Centroid and Bounding box of all cells across all time points in a structure format. cells{3,5} gives you the 5th well in the 3rd image.');
disp('Note: "cell_image contains all the cell images for all wells across all time points. Use visboundaries to print the boundaries of wells. cells{3,5} gives you the 5th well in the 3rd image."');
disp('Note: "cells_data" contains all relevant data for downstream tasks - well number, cell number, area (in sq microns), centroid (5 columns)'); 
save('Step2_cells', 'cells', 'cells_wells_image', 'cells_bulbs_image', 'cells_loops_image', 'cells_wells', 'cells_bulbs', 'cells_loops'); 

toc(tstart);
cd(git_path_name); 
disp('End of code...');