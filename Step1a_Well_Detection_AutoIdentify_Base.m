%% 0. Getting Started
close all
clearvars -except conds num_conds curr_cond
clc
disp('Getting Started...');
tstart = tic;

run('Step0_change_directory.m'); % cd into the condition folder
run('parameters.m'); % import all necessary parameters for all Steps

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
        img_temp = img_binary(3000:6000,3000:6000); % Considering only a small part to speed up comparison
        img_edge_log = edge(img_temp, 'log',0);  % Using LoG for edge detection
        img_fill_log = imfill(img_edge_log,'holes'); % Fill all holes to create wells
        img_area_log = bwareafilt(img_fill_log,[18000 30000]); % Filter areas that fit the areas size for wells
        regs = regionprops(img_area_log); % Determining regions and obtaining their properties
        bb = cat(1,regs.Area); wells_num = length(bb); % Obtaining the number of wells
        count = count + 1; wells_comp(count,:) = [i, j, wells_num]; % Saving the number and parameters for comparison

% %         Use this for debugging: prints number of wells for each parameter
%         pri = ['i = ', num2str(i), '; j = ',num2str(j), ';num = ',num2str(wells_num)];
%         fprintf([pri, '\n']);
 
% %         Displays a figure for quick debugging
%         figure(iter)     
%         title(pri);
%         hold on;
%         subplot(3,2,1)
%         imshow(img_src(6000:9000,6000:9000,:));
%         subplot(3,2,2)
%         imshow(img_temp);            
%         subplot(3,2,3)
%         imshow(img_edge_log);
%         subplot(3,2,4)
%         imshow(img_fill_log);
%         subplot(3,2,5)
%         imshow(img_area_log);
    end
end

wells_comp(wells_comp(:,1)==0,:) = []; % Remove excess parameter entries
idx = find(wells_comp(:,3)==max(wells_comp(:,3))); % Identify parameters with highest wells
max_wells = wells_comp(idx(1),:); % Identify the last parameter with highest wells
% % Print the parameter with highest wells
pri = ['i = ', num2str(max_wells(1)), '; j = ',num2str(max_wells(2)), ';num = ',num2str(max_wells(3))]; 
fprintf(['Maximum number of wells occur with ',pri,' (>=90 is excellent).\n']);

%% Morphological calculations and binary conversion using optimal values
img_morph = max_wells(1)*img_bw - max_wells(2)*imdilate(img_bw, strel('square',5));
img_binary = imbinarize(img_morph);
disp('Image conversion to binary done...');  

%% 2. Removing air bubble areas from the binary image
for i = 1:size(bbl_box(:,1),1)
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
regs = regionprops(img_area_log,'Area','BoundingBox','Centroid','Image'); % Determining regions
disp('Wells identification done...'); 

wells_list = [cat(1,regs.Area) cat(1,regs.Centroid) cat(1,regs.BoundingBox)];
num_wells = size(wells_list,1);
fprintf('No. of Wells = %d \n',num_wells); 

% % Displays a Figure for quick debugging
%     figure(iter) 
%     hold on;
%     subplot(3,2,1)
%     imshow(img_src(6000:9000,6000:9000,:));
%     subplot(3,2,2)
%     imshow(img_binary(6000:9000,6000:9000));            
%     subplot(3,2,3)
%     imshow(img_edge_log(6000:9000,6000:9000));
%     subplot(3,2,4)
%     imshow(img_fill_log(6000:9000,6000:9000));
%     subplot(3,2,5)
%     imshow(img_area_log(6000:9000,6000:9000));

%% 4. Separating regions and enumeration
bb = wells_list(:,end-3:end); % Obtaining wells' bounding boxes
img_size = size(img_area_log);
img_wells = zeros(img_size(1), img_size(2)); % Creating wells image
img_bulbs = zeros(img_size(1), img_size(2)); % Creating bulbs image
invalid_wells = zeros(num_wells,1); count = 0; 
for i = 1:num_wells
    fprintf('Iteration: %d\n',i); 
    % Identifying bounding box for each well (rmin:rmax, cmin:cmax)
    cmin = ceil(bb(i,1)); 
    cmax = cmin + bb(i,3) - 1;
    rmin = ceil(bb(i,2));
    rmax = rmin + bb(i,4) - 1;    
    img_here = regs(i).Image; %img_area_log(rowmin:rowmax, colmin:colmax);
    
    % Creating image for bulbs with the well number
    img_temp = zeros(bb(i,4), bb(i,3));
    img_temp_size = size(img_temp); count_bulb = 0; 
    for j = 0.85:0.01:1
        [cen, rad] = imfindcircles(img_here, [37 47], 'Sensitivity', j);
        if isempty(rad)
            count_bulb = count_bulb + 1; 
            continue;
        elseif (length(rad)>1)
            fprintf('Found multiple bulbs in iteration %d. Selecting the right most bulb and moving on. \n',i);
%             figure
%             imshow(img_here);
%             viscircles(cen, rad);
%             % Circles that reach outside the BB are removed
%             cen_rmin = cen(:,2)-rad; idx_rmin = find(cen_rmin<0);
%             cen_rmax = cen(:,2)+rad; idx_rmax = find(cen_rmax>bb(i,4)); 
%             cen_cmin = cen(:,1)-rad; idx_cmin = find(cen_cmin<0);
%             cen_cmax = cen(:,1)+rad; idx_cmax = find(cen_cmax>bb(i,3)); 
%             idx = [idx_rmin; idx_rmax; idx_cmin; idx_cmax]; 
%             cen(idx,:) = []; rad(idx) = []; 
%             figure
%             imshow(img_here);
%             viscircles(cen, rad);     
        end
        [~, pos] = max(cen(:,1)); % Identifying the farthest circle as bulb
        cen = cen(pos,:); rad = rad(pos); % Removing all other bulbs
        bulb_rmin = floor(cen(2)-rad);
        bulb_cmin = floor(cen(1)-rad);
        bulb_rmax = min(img_temp_size(1), ceil(cen(2)+rad)); 
        bulb_cmax = min(img_temp_size(2), ceil(cen(1)+rad));
        for row = bulb_rmin:bulb_rmax
            for col = bulb_cmin:bulb_cmax
                if norm([col row]-cen)<rad
                    img_temp(row,col) = i;
                end
            end
        end
        break;
    end
    if (count_bulb == 16)
        fprintf('Found no bulbs in iteration %d. This well will be discarded. If you plan to debug, note that the order will change. \n',i);
        count = count + 1; invalid_wells(count) = i; 
    else
        img_bulbs(rmin:rmax, cmin:cmax) = img_temp; 
%         figure
%         imshow(img_temp);
        % Creating image for wells with the well number
        img_temp = zeros(bb(i,4), bb(i,3));
        img_temp(img_here == 1) = i;
        img_wells(rmin:rmax, cmin:cmax) = img_temp;   
%         figure
%         imshow(img_temp);
    end
%     close all
%     rectangle('Position',[bb(i,1) bb(i,2) bb(i,3) bb(i,4)],'EdgeColor','green');
end

invalid_wells(invalid_wells == 0) = []; 
wells_list(invalid_wells,:) = []; 
disp ('Image encoding done...');      

%% 5. Writing to Excel
write_name = 'wells_list.xlsx';
writematrix(wells_list, write_name,'WriteMode','overwritesheet');

%% 6. Drawing Figures for analysis
toc(tstart);
img_orgl = img_src;
% figure (1)
% imshow(img_src);
% title('src')
% 
figure
imshow(img_orgl(7000:8500, 7000:8500));
% imshow(img_orgl);
hold on
visboundaries(img_area_log(7000:8500, 7000:8500),'color','r');
visboundaries(img_bulbs(7000:8500, 7000:8500),'color','b');
% visboundaries(img_area_log,'color','r');
% savefig('Figure_wells_list'); 

% title('log')
save('Step1_data', 'img_wells', 'num_wells', 'img_orgl', 'img_bulbs', 'img_area_log', 'regs', 'max_wells');

cd(git_path_name); 
disp('End of code...');