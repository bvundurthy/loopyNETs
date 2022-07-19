%% Step 1c Well displacement 
% Variable img_wells comes from Step 1 and contains all the wells with numbers
% Variable num_wells (also from Step 1) contains the total number of wells 
% Variable img_brgt contains the bright field source image from Step 1
close all
clearvars -except conds num_conds curr_cond
clc

tstart = tic; 
run('Step0_change_directory.m'); % cd into the condition folder
run('parameters.m'); % import all necessary parameters for all Steps
load 'Step1_wells'; % load all data from Step 1

%need to fix this to handle antibody data as well
wells_disp_all = cell(num_times, 1);         
wells_outliers_all = cell(num_times, 1); 
wells_mapping_all = cell(num_times, 1); 

for each_time = 1:num_times
    fprintf('\n Getting Started: Iteration %d \n', each_time);
    if (fbrgt_num(each_time)~=fbrgt_base_num) %when we are not dealing with base fbrgt
        %% Recomputing edges for current brightfield image
        fbrgt = fbrgt_all{each_time}; % Taking each bright image file
        img_brgt_src = imread(fbrgt);
        disp('Image loading done...');      

        img_brgt_bw = rgb2gray(im2single(img_brgt_src)); % Converting to grayscale

        %% Identifying the optimal morphed image
        wells_comp = zeros(50,3); count = 0; 
        for i = 2:1:4
            for j = 1:0.25:(i-0.5)
                img_brgt_morph = i*img_brgt_bw - j*imdilate(img_brgt_bw, strel('square',5)); % Applying the current morph
                img_brgt_binary = imbinarize(img_brgt_morph); % Converting to binary
                brgt_bulb_Image = img_brgt_binary(3000:6000,3000:6000); % Considering only a small part to speed up comparison
                img_brgt_edge_log = edge(brgt_bulb_Image, 'log',0);  % Using LoG for edge detection
                img_brgt_fill_log = imfill(img_brgt_edge_log,'holes'); % Fill all holes to create wells
                img_brgt_area_log = bwareafilt(img_brgt_fill_log,[18000 30000]); % Filter areas that fit the areas size for wells
                wells_temp = regionprops(img_brgt_area_log); % Determining regions and obtaining their properties
                wells_num_test = length(cat(1,wells_temp.Area)); % Obtaining the number of wells
                count = count + 1; wells_comp(count,:) = [i, j, wells_num_test]; % Saving the number and parameters for comparison
            end
        end

        wells_comp(wells_comp(:,1)==0,:) = []; % Remove excess parameter entries
        idx = find(wells_comp(:,3)==max(wells_comp(:,3))); % Identify parameters with highest wells
        max_wells = wells_comp(idx(1),:); % Identify the first parameter with highest wells
        % % Print the parameter with highest wells
        pri = ['i = ', num2str(max_wells(1)), '; j = ',num2str(max_wells(2)), ';num = ',num2str(max_wells(3))]; 
        fprintf(['Maximum number of wells occur with ',pri,' (>=90 is excellent).\n']);

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
        

        base_centroid = cat(1,wells.Centroid);
        base_BB = cat(1,wells.BoundingBox);

        % Identifying closest wells
        idx = knnsearch(brgt_BB(:,1:2), base_BB(:,1:2));
        % Identifying deviations in well location and well sizes
        wells_disp = brgt_BB(idx,1:2) - base_BB(:,1:2);
        wells_size = brgt_BB(idx,3:4) - base_BB(:,3:4);
        % Identifying outliers using such deviations
        outliers_disp = isoutlier(abs(wells_disp), 'mean'); 
        %outliers_size = isoutlier(abs(wells_size), 'mean'); 
        
        wells_outliers = [find(outliers_disp(:,1)); find(outliers_disp(:,2))];%; find(outliers_size(:,1)); find(outliers_size(:,2))];
        wells_outliers = unique(wells_outliers); 
        
        wells_disp_all{each_time} = wells_disp; 
        wells_outliers_all{each_time} = wells_outliers; 
        wells_mapping_all{each_time} = idx; 
        fprintf('Identified displacements. The current iteration %i has %d outliers. \n', each_time, length(wells_outliers)); 
        
        %% Run once for plotting figures
        img_base = imread(fbrgt_base); 
        img_blob_src = imread(fcell_all{each_time}); 
        %% Figure to check
        figure(each_time)
        num_fig = 5; 
%         rand_fig = 360; 
        rand_fig = randperm(num_wells,num_fig);
        check_outlier = ismember(rand_fig, wells_outliers); 
        
        for i = 1:num_fig
            j = rand_fig(i); 
            cmin = ceil(base_BB(j,1)+wells_disp(j,1)); 
            cmax = cmin + base_BB(j,3) - 1;
            rmin = ceil(base_BB(j,2)+wells_disp(j,2));
            rmax = rmin + base_BB(j,4) - 1;
            subplot(2,num_fig,i)
            imshow(0.7*img_brgt_src(rmin:rmax, cmin:cmax) + 0.3*img_blob_src(rmin:rmax, cmin:cmax,:));
            hold on;
            visboundaries(wells(j).Image); 
            if check_outlier(i)
                title(sprintf('Translated base image. Well %d (outlier)',j));
            else
                title(sprintf('Translated base image. Well %d',j));
            end

            cmin = ceil(brgt_BB(idx(j),1)); 
            cmax = cmin + brgt_BB(idx(j),3) - 1;
            rmin = ceil(brgt_BB(idx(j),2));
            rmax = rmin + brgt_BB(idx(j),4) - 1;
            subplot(2,num_fig,i+num_fig)
            imshow(0.7*img_brgt_src(rmin:rmax, cmin:cmax) + 0.3*img_blob_src(rmin:rmax, cmin:cmax,:));
            hold on;
            visboundaries(wells_brgt(idx(j)).Image); 
            if check_outlier(i)
                title(sprintf('Current brgt image. Well %d (outlier)',j));
            else
                title(sprintf('Current brgt image. Well %d',j));
            end
            sgtitle('5 random wells for quick view');
        end
    else
        disp('Same bright field image as base. Zero displacement and outliers. '); 
        wells_disp_all{each_time} = zeros(num_wells, 2); 
%         wells_outliers_all{each_time} = wells_outliers; 
        wells_mapping_all{each_time} = (1:num_wells)'; 
    end
end

disp('Saving wells variable for future steps...');
save('Step1_wells', 'wells', 'num_wells', 'wells_disp_all', 'wells_mapping_all', 'wells_outliers_all'); 
toc(tstart);         