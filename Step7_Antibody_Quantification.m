%% This code should create a panel of images for antibody quantification
% In any given row of an image panel, here is what each figure signifies:
% 1 - dead cell at its time of death
% 2 - ab_dapi cell to see if there was a dead cell to begin with
% 3 - ab_cy5 cell to see if the antibody is stained


close all
clearvars -except conds num_conds curr_cond
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
    img_read{i} = imread(fcell_all{i});
    fprintf('Loaded image %d \n', i); 
end

%% Load the following figure once if you are debugging

dead_cells = readmatrix('replicate1\Track_Cells.xlsx', 'Sheet', 'wells');
% fig_label = {{'dapi'}, {'tritc'}, {'ab_dapi'}, {'ab_cy5'}}; 

for i = 1:size(dead_cells,1)
    j = dead_cells(i,2);
    time_point = [1 dead_cells(i,7)+1 8 9]; 
    fig = figure (ceil(i/3));
    fig.WindowState = 'maximized'; 
    row = rem((i-1),3) + 1; 
    
    for k = 1:4 % time_point
        fig_label = {{'dapi'}, {strcat('tritc@',num2str(time_point(2)-1))}, {'ab-dapi'}, {'ab-cy5'}}; 
        img_blob = img_read{time_point(k)}; % imread(fcell_all{time_point(k)}); 
        
        cmin = ceil(base_BB(j,1)+wells_disp_all(time_point(k), 1)); 
        cmax = cmin + base_BB(j,3) - 1;
        rmin = ceil(base_BB(j,2)+wells_disp_all(time_point(k), 2));
        rmax = rmin + base_BB(j,4) - 1;
%         if (cmin<0 || rmin<0 || cmax>size(img_brgt,2) || rmax>size(img_brgt,1))
%             continue;
%         end

        subplot(3,4,4*(row-1)+k)
        imshow(img_blob(rmin:rmax, cmin:cmax,:)); % img_brgt(rmin:rmax, cmin:cmax) + 2 *
        hold on;
        visboundaries(wells(j).Image); 
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
                
        
        title(strcat('Well:', num2str(j), ' || Image:', fig_label{k}, ' || Ratio:', num2str(dead_cells(i,end))));
        
    end
    if ceil((i+1)/3)~=ceil(i/3)
        pause(0.5);
        saveas(gcf, strcat('replicate1/figure',num2str(ceil(i/3)), '.png'));
        close all;
    end
end
saveas(gcf, strcat('replicate1/figure',num2str(ceil(i/3)), '.png'));

