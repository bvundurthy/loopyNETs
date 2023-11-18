%% This code should create a panel of images for antibody quantification
% In any given row of an image panel, here is what each figure signifies:
% 1 - live cell at first time point
% 2 - dead cell at its time of death
% 3 - ab_dapi cell to see if there was a dead cell to begin with
% 4 - ab_cy5 cell to see if the antibody is stained

% Step7_Antibody_Quantification.m handles creating files that are exclusive to NETs. More specifically, this code creates 'figureNET<>.png' file with 3X4  image where the rows represent three cells and columns represent live, dead, Ab blue and Ab pink stains. This can later be used to measure antibody intensities. Please note that this code assumes the date, condition number and replicate number come from Step0 code and thus calls the same. However, this requires the user to run this code for every condition and every replicate.

close all
clearvars -except conds num_conds cond_num replicate curr_rep replicate_list
clc

run('Step0_change_directory.m'); % cd into the condition folder
run('parameters.m'); % import all necessary parameters for all Steps

load 'Step1_wells.mat'; % load all data from Step 1
% Read information of all the cells from the unfiltered excel file created in Step 2
load 'Step2_cells.mat'; 

wells_disp_all(end+1:end+2, :) = zeros(2, 2);   

%% Recomputing edges for current brightfield image
fbrgt = strcat('ab_dicc1xy', num2str(cond_num), '.tif'); % Taking each bright image file
img_brgt_src = imread(fbrgt);
disp('Image loading done...');      

img_brgt_bw = rgb2gray(im2single(img_brgt_src)); % Converting to grayscale
img_brgt_morph = max_wells(1)*img_brgt_bw - max_wells(2)*imdilate(img_brgt_bw, strel('square',5));
img_brgt_binary = imbinarize(img_brgt_morph);
disp('Image conversion to binary done...');  

%% 2. Removing air bubble areas from the binary image
for i = 1:size(bbl_box,1)
    img_brgt_binary(bbl_box(i,1):bbl_box(i,2), bbl_box(i,3):bbl_box(i,4)) = 0;
    if (i==1)
        disp ('Air bubbles are being removed from the binary figure...');
    end
end

%% Identifying and separating the wells 

% Detecting Edges, Filling Holes, Detecting areas with specific interval
img_brgt_edge_log = edge(img_brgt_binary, 'log',0);
img_brgt_fill_log = imfill(img_brgt_edge_log,'holes');
img_brgt_area_log = bwareafilt(img_brgt_fill_log,[18000 30000]); 
wells_brgt = regionprops(img_brgt_area_log,'Area','BoundingBox','Centroid','Image'); % Determining regions
disp('Wells identification done...'); 

brgt_centroid = cat(1,wells_brgt.Centroid);
brgt_BB = cat(1,wells_brgt.BoundingBox);  
fprintf('Number of wells in this iteration is %d. \n', size(brgt_centroid,1)); 

%% Fixing the centroids and bounding boxes to match with the full image
base_BB = cat(1,wells.BoundingBox);
% Identifying closest wells
idx = knnsearch(brgt_BB(:,1:2), base_BB(:,1:2));
% Identifying deviations in well location and well sizes
wells_disp_temp = brgt_BB(idx,1:2) - base_BB(:,1:2);
[~,~,~,wells_disp] = isoutlier(wells_disp_temp); 
wells_disp_all(end-1:end,:) = repmat(wells_disp,2,1); 
fprintf('Antibody image displaced by (%d, %d). \n', wells_disp(1), wells_disp(2)); 

fcell_all{end+1} = strcat('ab_dapic1xy', num2str(cond_num), '.tif'); 
fcell_all{end+1} = strcat('ab_cy5c1xy', num2str(cond_num), '.tif');
fbrgt_all{end+1} = fbrgt;
fbrgt_all{end+1} = fbrgt;

for i = 1:9
    img_read{i} = imread(fcell_all{i}); %#ok<SAGROW> 
    fprintf('Loaded image %d \n', i); 
end

%% Load the following figure once if you are debugging

dead_cells = readmatrix(strcat(replicate, '\Track_Cells.xlsx'), 'Sheet', 'wells');
num_dead_cells = size(dead_cells,1); 
intensities = zeros(num_dead_cells,6); 
intensities(:,1) = (1:num_dead_cells)'; 
cellNum = 0; 
for i = 1:num_dead_cells
    if ((dead_cells(i,end)<2) || (dead_cells(i,end)>15))
        continue;
    end
    j = dead_cells(i,2); % well number
    time_point = [1 dead_cells(i,7)+1 8 9]; 
    cellNum = cellNum + 1; 
    fig = figure (ceil(cellNum/3));
    fig.WindowState = 'maximized'; 
    row = rem((cellNum-1),3) + 1; 
% Commented from here to     
    cells_temp = cells_wells{time_point(2)};
    idx = find(cells_temp(:,2) == dead_cells(i,9));
    centroid_temp = round(cat(1,cells{time_point(2), j}.Centroid)); 
    cell_idx = find(centroid_temp(:,1) == cells_temp(idx,4) & centroid_temp(:,2) == cells_temp(idx,5));
    bb_cell = cells{time_point(2), j}(cell_idx).BoundingBox;
    area_cell = cells{time_point(2), j}(cell_idx).Area;
    cell_cmin = ceil(bb_cell(1)); 
    cell_cmax = cell_cmin + bb_cell(3) - 1;
    cell_rmin = ceil(bb_cell(2));
    cell_rmax = cell_rmin + bb_cell(4) - 1;
%   here  
    for k = 1:4 % time_point
        fig_label = {{'dapi'}, {strcat('tritc@',num2str(time_point(2)-1))}, {'ab-dapi'}, {'ab-cy5'}}; 
        img_blob = img_read{time_point(k)}; % imread(fcell_all{time_point(k)}); 
        
        cmin = ceil(base_BB(j,1)+wells_disp_all(time_point(k), 1)); 
        cmax = cmin + base_BB(j,3) - 1;
        rmin = ceil(base_BB(j,2)+wells_disp_all(time_point(k), 2));
        rmax = rmin + base_BB(j,4) - 1;
%         Commented from here to 
        img_temp = img_blob(rmin:rmax, cmin:cmax,:); 
        img_temp_gray = rgb2gray(img_temp); 
        
        img_cell_temp = cells_wells_image{time_point(2),j}; 
        img_cell_temp(1:cell_rmin-1,:) = 0; 
        img_cell_temp(cell_rmax+1:end,:) = 0; 
        img_cell_temp(:,1:cell_cmin-1) = 0;
        img_cell_temp(:,cell_cmax+1:end) = 0; 
        
        intensities(i,k+1) = sum(sum(double(img_temp_gray).*double(img_cell_temp)))/(area_cell*2^16); 
        
        if (cmin<0 || rmin<0 || cmax>size(img_brgt_src,2) || rmax>size(img_brgt_src,1))
            continue;
        end
%             here
        subplot(3,4,4*(row-1)+k)
        imshow(img_blob(rmin:rmax, cmin:cmax,:)); % img_brgt(rmin:rmax, cmin:cmax) + 2 *
        hold on;
%         visboundaries(wells(j).Image); 
%         visboundaries(img_cell_temp, 'Color', 'w'); 
        
        switch (k)
            case 1
%                 visboundaries(cells_wells_image{time_point(k),dead_cells(i,3)}, 'Color', 'w');
                cells_temp = cells_wells{time_point(k)};
                idx = find(cells_temp(:,2) == dead_cells(i,3));
                plot(cells_temp(idx,4), cells_temp(idx,5), '*', 'Color', 'r'); 
            case 2
%                 visboundaries(cells_wells_image{time_point(k),dead_cells(i,9)});
                cells_temp = cells_wells{time_point(k)};
                idx = find(cells_temp(:,2) == dead_cells(i,9));
                plot(cells_temp(idx,4), cells_temp(idx,5), '*', 'Color', 'r'); 
        end
                
        
        title(strcat('Cell:', num2str(i), '|| Well:', num2str(j), ' || Image:', fig_label{k}, ' || Ratio:', num2str(dead_cells(i,end))));
        
    end
    intensities(i,end) = dead_cells(i,end); 
    if ceil((cellNum+1)/3)~=ceil(cellNum/3)
        pause(0.5); 
        saveas(gcf, strcat(replicate,'/figureNET',num2str(ceil(cellNum/3)), '.png'));
        close all;
    end
end
if (ceil(cellNum/3) ~= floor(cellNum/3))
    saveas(gcf, strcat(replicate,'/figureNET',num2str(ceil(cellNum/3)), '.png'));
end

write_name = strcat(replicate,'/intensitiesNET.xlsx');
writematrix(intensities, write_name,'WriteMode','overwritesheet');

close all;
cd(git_path_name); 

