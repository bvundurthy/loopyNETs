%% 0. Getting Started
close all
clearvars -except conds num_conds curr_cond
clc
tstart = tic;

run('Step0_change_directory.m'); % cd into the condition folder
run('parameters.m'); % import all necessary parameters for all Steps

fprintf('Starting Step 1b to detect wells in the base bright field image. Folder name: "%s" \n', path_name);

%% 1. Reading the image and converting it to binary
img_src = imread(fbrgt_base);
% imshow(img_src);
disp('Image loading done...');        
img_bw = rgb2gray(im2single(img_src)); % Converting to grayscale 

%% Identifying the optimal morphed image
wells_comp = zeros(50,3); count = 0; 
for i = 2:1:4
    for j = 1:0.25:(i-0.5)
        img_morph = i*img_bw - j*imdilate(img_bw, strel('square',5)); % Applying the current morph
        img_binary = imbinarize(img_morph); % Converting to binary
        bulb_Image = img_binary(3000:6000,3000:6000); % Considering only a small part to speed up comparison
        img_edge_log = edge(bulb_Image, 'log',0);  % Using LoG for edge detection
        img_fill_log = imfill(img_edge_log,'holes'); % Fill all holes to create wells
        img_area_log = bwareafilt(img_fill_log,[18000 30000]); % Filter areas that fit the areas size for wells
        wells = regionprops(img_area_log); % Determining regions and obtaining their properties
        wells_num_test = length(cat(1,wells.Area)); % Obtaining the number of wells
        count = count + 1; wells_comp(count,:) = [i, j, wells_num_test]; % Saving the number and parameters for comparison
    end
end

wells_comp(wells_comp(:,1)==0,:) = []; % Remove excess parameter entries
idx = find(wells_comp(:,3)==max(wells_comp(:,3))); % Identify parameters with highest wells
max_wells = wells_comp(idx(1),:); % Identify the first parameter with highest wells
% % Print the parameter with highest wells
pri = ['i = ', num2str(max_wells(1)), '; j = ',num2str(max_wells(2)), ';num = ',num2str(max_wells(3))]; 
fprintf(['Maximum number of wells occur with ',pri,' (>=90 is excellent).\n']);

%% Morphological calculations and binary conversion using optimal values
img_morph = max_wells(1)*img_bw - max_wells(2)*imdilate(img_bw, strel('square',5));
img_binary = imbinarize(img_morph);
disp('Image conversion to binary done...');  

%% 2. Removing air bubble areas from the binary image
for i = 1:size(bbl_box,1)
    img_binary(bbl_box(i,1):bbl_box(i,2), bbl_box(i,3):bbl_box(i,4)) = 0;
    if (i==1)
        disp('Air bubbles are present in this condition. Removing them from the binary figure...');
    end
end

%% 3. Identifying and separating the wells 

% Detecting Edges, Filling Holes, Detecting areas with specific interval
img_edge_log = edge(img_binary, 'log',0);
img_fill_log = imfill(img_edge_log,'holes');
img_area_log = bwareafilt(img_fill_log,[18000 30000]); 
wells = regionprops(img_area_log,'Area','BoundingBox','Centroid','Image'); % Determining regions
[wells.Bulb_Image] = wells(:).Image; % Creating a new field for bulbs
disp('Wells identification done...'); 
num_wells = length(cat(1, wells.Area)); % Get the number of wells
fprintf('No. of Wells = %d \n',num_wells); 

%% 4. Separating regions and enumeration
wells_BB = cat(1,wells.BoundingBox); % Obtaining wells' bounding boxes
invalid_wells = zeros(num_wells,1); count_invalid = 0; % Variables to handle inaccurate bulb detection
fprintf('A few wells will be discarded to eliminate incorrect identification. If you plan to debug, note that the number will go down.\n'); 
figure; 
for i = 1:num_wells
    % Identifying bounding box for each well - (rmin:rmax, cmin:cmax)
    cmin = ceil(wells_BB(i,1)); 
    cmax = cmin + wells_BB(i,3) - 1;
    rmin = ceil(wells_BB(i,2));
    rmax = rmin + wells_BB(i,4) - 1;    
    img_curr = wells(i).Image; %img_area_log(rowmin:rowmax, colmin:colmax);
    
    % Creating temporary image for bulbs with the well number
    % wells_BB(i,4) and wells_BB(i,3) are used for the size of each wells.Image
    bulb_Image = zeros(wells_BB(i,4), wells_BB(i,3),'logical'); count_bulb = 0; 
    for j = 0.85:0.01:1 % exploring with changing sensitivities to identify the best bulb
        [cen, rad] = imfindcircles(img_curr, [37 47], 'Sensitivity', j);
        if (length(rad)>1)
            idx = knnsearch(cen,[227 222]); idx = idx(1); % Identifying one circle closest to actual location
            cen = cen(idx,:); rad = rad(idx); % Removing all other bulbs 
        end
        
        if (isempty(rad) || ~img_curr(round(cen(2)), round(cen(1)))) 
%            go to next sensitivity if 1. no circle is detected or if 2. hollow circles are detected
           count_bulb = count_bulb + 1; 
           continue;
        end
         
        bulb_rmin = max(1, floor(cen(2)-rad)); 
        bulb_rmax = min(wells_BB(i,4), ceil(cen(2)+rad));
        bulb_cmin = max(1, floor(cen(1)-rad));
        bulb_cmax = min(wells_BB(i,3), ceil(cen(1)+rad));
        for row = bulb_rmin:bulb_rmax
            for col = bulb_cmin:bulb_cmax
                if norm([col row]-cen)<=rad
                    bulb_Image(row,col) = true; % logical 1 where there's a bulb
                end
            end
        end            
        break; % if you found a bulb, go to the next well
    end
    if (count_bulb == 16) % if you did not find a suitable bulb
        count_invalid = count_invalid + 1; invalid_wells(count_invalid) = i; % this well is invalid
        fprintf('Discarding well %d for lack of good bulbs. Total discarded = %d\n',i, count_invalid);
        % comment till else if you do not need figures
        subplot (2,5,(rem(count_invalid-1,10)+1)) % plot the discarded well for verification
        imshow(img_curr);
        viscircles(cen, rad); 
        title(sprintf('iteration %d',i)); 
        if (rem(count_invalid,10)==0)
            figure; 
        end
    else
        wells(i).Bulb_Image = bulb_Image; % add the current bulb image to wells structure
    end
end

%% 5. Handling modified wells data for downstream steps
invalid_wells(invalid_wells == 0) = []; 
wells(invalid_wells) = []; % remove invalid wells from the wells structure

num_wells = length(cat(1, wells.Area)); % recompute the number of wells
fprintf('Well and bulb encoding done. We now have %d wells. \n',num_wells); 

disp('Saving wells variable for future steps...');
save('Step1_wells', 'max_wells', 'wells', 'num_wells');
toc(tstart);

%% 6. Drawing Figures for analysis
figure

rand_fig = randperm(num_wells,10);
for i = 1:10
    j = rand_fig(i);
    subplot(2,5,i)
    imshow(wells(j).Image);
    hold on
    visboundaries(wells(j).Bulb_Image); 
    
    title(sprintf('well no. %d',j));
end

cd(git_path_name); 
disp('End of code...');