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

fprintf('Starting Step 1x to verify wells displacement. Folder name: "%s" \n', path_name);

load 'Step1_wells.mat'; % load all data from Step 1

%need to fix this to handle antibody data as well

verify_times = [6 7]; 



for each_time = verify_times
    fprintf('Iteration %d/%d\n', each_time, length(verify_times));
    curr_brgt_num = fbrgt_num(each_time); 
    
    fbrgt = fbrgt_all{each_time}; % Taking each bright image file
    img_brgt_src = imread(fbrgt);
    
    %% Load the following figure once if you are debugging
    img_blob_src = imread(fcell_all{each_time}); 
%         Figure to check - run this section repeatedly for analysis
    figure(each_time)
    %%
    base_BB = cat(1,wells.BoundingBox);
    
    imshow(0.7*img_brgt_src + 0.3*img_blob_src);
    hold on; 
    for j = 1:num_wells
        cmin = ceil(base_BB(j,1)+wells_disp_all(j,1)); 
        cmax = cmin + base_BB(j,3) - 1;
        rmin = ceil(base_BB(j,2)+wells_disp_all(j,2));
        rmax = rmin + base_BB(j,4) - 1;
        if (cmin<0 || rmin<0 || cmax>size(img_brgt_src,2) || rmax>size(img_brgt_src,1))
            continue;
        end
%         h = axes('Position', [rmin cmin base_BB(j,4) base_BB(j,3)]);
        visboundaries(wells(j).Image);
%         visboundaries(wells(j).Image); 
%         title(sprintf('Translated base image. Well %d',j));
    end
    
    
%     num_fig = 5; 
%     rand_fig = randperm(num_wells,num_fig); % rand_fig = 360; 
% 
%     for i = 1:num_fig
%         j = rand_fig(i); 
%         cmin = ceil(base_BB(j,1)+wells_disp(1)); 
%         cmax = cmin + base_BB(j,3) - 1;
%         rmin = ceil(base_BB(j,2)+wells_disp(2));
%         rmax = rmin + base_BB(j,4) - 1;
%         if (cmin<0 || rmin<0 || cmax>size(img_brgt_src,2) || rmax>size(img_brgt_src,1))
%             continue;
%         end
%         subplot(2,num_fig,i)
%         imshow(0.7*img_brgt_src(rmin:rmax, cmin:cmax) + 0.3*img_blob_src(rmin:rmax, cmin:cmax,:));
%         hold on;
%         visboundaries(wells(j).Image); 
%         title(sprintf('Translated base image. Well %d',j));
% 
%         cmin = ceil(brgt_BB(idx(j),1)); 
%         cmax = cmin + brgt_BB(idx(j),3) - 1;
%         rmin = ceil(brgt_BB(idx(j),2));
%         rmax = rmin + brgt_BB(idx(j),4) - 1;
%         subplot(2,num_fig,i+num_fig)
%         imshow(0.7*img_brgt_src(rmin:rmax, cmin:cmax) + 0.3*img_blob_src(rmin:rmax, cmin:cmax,:));
%         hold on;
%         visboundaries(wells_brgt(idx(j)).Image); 
%         title(sprintf('Current brgt image. Well %d',j));
%         sgtitle('5 random wells for quick view');
%     end
end
    
    
    
%     %% Recomputing edges for current brightfield image
%     fbrgt = fbrgt_all{each_time}; % Taking each bright image file
%     img_brgt_src = imread(fbrgt);
%     disp('Image loading done...');      
% 
%     img_brgt_bw = rgb2gray(im2single(img_brgt_src)); % Converting to grayscale
%     img_brgt_morph = max_wells(1)*img_brgt_bw - max_wells(2)*imdilate(img_brgt_bw, strel('square',5));
%     img_brgt_binary = imbinarize(img_brgt_morph);
%     disp('Image conversion to binary done...');  
% 
%     %% 2. Removing air bubble areas from the binary image
%     for i = 1:size(bbl_box,1)
%         img_brgt_binary(bbl_box(i,1):bbl_box(i,2), bbl_box(i,3):bbl_box(i,4)) = 0;
%         if (i==1)
%             disp ('Air bubbles are being removed from the binary figure...');
%         end
%     end
% 
%     %% Identifying and separating the wells 
% 
%     % Detecting Edges, Filling Holes, Detecting areas with specific interval
%     img_brgt_edge_log = edge(img_brgt_binary, 'log',0);
%     img_brgt_fill_log = imfill(img_brgt_edge_log,'holes');
%     img_brgt_area_log = bwareafilt(img_brgt_fill_log,[18000 30000]); 
%     wells_brgt = regionprops(img_brgt_area_log,'Area','BoundingBox','Centroid','Image'); % Determining regions
%     disp('Wells identification done...'); 
% 
%     brgt_centroid = cat(1,wells_brgt.Centroid);
%     brgt_BB = cat(1,wells_brgt.BoundingBox);  
%     fprintf('Number of wells in this iteration is %d. \n', size(brgt_centroid,1)); 
% 
%     %% Fixing the centroids and bounding boxes to match with the full image
%     base_BB = cat(1,wells.BoundingBox);
%     % Identifying closest wells
%     idx = knnsearch(brgt_BB(:,1:2), base_BB(:,1:2));
%     % Identifying deviations in well location and well sizes
%     wells_disp_temp = brgt_BB(idx,1:2) - base_BB(:,1:2);
%     [~,~,~,wells_disp] = isoutlier(wells_disp_temp); 
%     wells_disp_all(each_time,:) = wells_disp; 
% 
%     %% Load the following figure once if you are debugging
%     img_blob_src = imread(fcell_all{each_time}); 
% %         Figure to check - run this section repeatedly for analysis
%     figure(each_time)
%     num_fig = 5; 
%     rand_fig = randperm(num_wells,num_fig); % rand_fig = 360; 
% 
%     for i = 1:num_fig
%         j = rand_fig(i); 
%         cmin = ceil(base_BB(j,1)+wells_disp(1)); 
%         cmax = cmin + base_BB(j,3) - 1;
%         rmin = ceil(base_BB(j,2)+wells_disp(2));
%         rmax = rmin + base_BB(j,4) - 1;
%         if (cmin<0 || rmin<0 || cmax>size(img_brgt_src,2) || rmax>size(img_brgt_src,1))
%             continue;
%         end
%         subplot(2,num_fig,i)
%         imshow(0.7*img_brgt_src(rmin:rmax, cmin:cmax) + 0.3*img_blob_src(rmin:rmax, cmin:cmax,:));
%         hold on;
%         visboundaries(wells(j).Image); 
%         title(sprintf('Translated base image. Well %d',j));
% 
%         cmin = ceil(brgt_BB(idx(j),1)); 
%         cmax = cmin + brgt_BB(idx(j),3) - 1;
%         rmin = ceil(brgt_BB(idx(j),2));
%         rmax = rmin + brgt_BB(idx(j),4) - 1;
%         subplot(2,num_fig,i+num_fig)
%         imshow(0.7*img_brgt_src(rmin:rmax, cmin:cmax) + 0.3*img_blob_src(rmin:rmax, cmin:cmax,:));
%         hold on;
%         visboundaries(wells_brgt(idx(j)).Image); 
%         title(sprintf('Current brgt image. Well %d',j));
%         sgtitle('5 random wells for quick view');
%     end
% end
% 
% disp('Saving wells variable for future steps...');
% save('Step1_wells', 'max_wells', 'wells', 'num_wells', 'wells_disp_all'); 
% toc(tstart);         
% cd(git_path_name); 
% disp('End of code...');