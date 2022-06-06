%% 0. Getting Started
close all
clearvars -except conds num_conds curr_cond
clc
disp('Getting Started...');
tstart = tic;

run('Step0_change_directory.m'); % cd into the condition folder
run('parameters.m'); % import all necessary parameters for all Steps

%% 1. Reading the image and converting it to binary
% fbrgt_base = 'dicc1t2xy2.tif'; 
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
fprintf(['Maximum number of wells occur with ',pri,'\n']);

%% Morphological calculations and binary conversion using optimal values
img_morph = max_wells(1)*img_bw - max_wells(2)*imdilate(img_bw, strel('square',5));
img_binary = imbinarize(img_morph);
disp('Image conversion to binary done...');  

%% 2. Removing air bubble areas from the binary image
% 
% % The bubble boxes are given by [rowmin, rowmax, colmin, colmax]
% % Each line represents a different bubble
% % Note that when using markers on the figure: x -> columns, y -> rows
% bbl_box = [3553, 7685, 3525, 7647]; 
% for i = 1:length(bbl_box(:,1))
%     img_binary(bbl_box(i,1):bbl_box(i,2), bbl_box(i,3):bbl_box(i,4)) = 0;
% end
% disp ('Air bubbles removed from the binary figure...');

%% 3. Identifying and separating the wells 

% Detecting Edges, Filling Holes, Detecting areas with specific interval
img_edge_log = edge(img_binary, 'log',0);
img_fill_log = imfill(img_edge_log,'holes');
img_area_log = bwareafilt(img_fill_log,[18000 30000]); 
regs = regionprops(img_area_log); % Determining regions
disp('Wells identification done...'); 

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

bb = cat(1,regs.Area); wells_num = length(bb);
fprintf('No. of Wells = %d \n',wells_num); 

%% 4. Separating regions and enumeration
bb = cat(1,regs.BoundingBox); % Obtaining wells' bounding boxes
img_size = size(img_area_log);
img_wells = zeros(img_size(1), img_size(2)); % Creating wells image
img_bulbs = zeros(img_size(1), img_size(2)); % Creating bulbs image
num_wells = length(bb(:,1));
for i = 1:length(bb(:,1))
    % Identifying bounding box for each well
    colmin = bb(i,1) - 0.5; 
    colmax = bb(i,1) + 0.5 + bb(i,3);
    rowmin = bb(i,2) - 0.5; 
    rowmax = bb(i,2) + 0.5 + bb(i,4);
    img_here = img_area_log(rowmin:rowmax, colmin:colmax);
    
    % Creating image for wells with the well number
    img_temp = zeros(bb(i,4)+2, bb(i,3)+2);
    img_temp(img_here == 1) = i;
    img_wells(rowmin:rowmax, colmin:colmax) = img_temp;            
    
    % Creating image for bulbs with the well number
    img_temp = zeros(bb(i,4)+2, bb(i,3)+2);
    img_temp_size = size(img_temp);
    count = 0; 
    for j = 0.85:0.1:1
        [cen, rad] = imfindcircles(img_here, [37 47], 'Sensitivity', j);
        if isempty(rad)
            count = count + 1; 
            continue; 
        elseif (length(rad)>1)
            fprintf('Found multiple bulbs. Pause and Debug iteration %d \n',i);
%             imshow(img_here);
%             viscircles(cen, rad);
        end
        [~, pos] = max(cen(:,1)); % Identifying the farthest circle as bulb
        cen = cen(pos,:); rad = rad(pos); % Removing all other bulbs
        bulb_colmin = floor(cen(1)-rad);
        bulb_rowmin = floor(cen(2)-rad);
        bulb_colmax = min(img_temp_size(2), ceil(cen(1)+rad));
        bulb_rowmax = min(img_temp_size(1), ceil(cen(2)+rad)); 
        for row = bulb_rowmin:bulb_rowmax
            for col = bulb_colmin:bulb_colmax
                if norm([row col]-cen)<rad
                    img_temp(row,col) = i;
                end
            end
        end
%         viscircles(cen, rad);
        break;
    end
    if (count == 16)
        fprintf('Found no bulbs. Pause and Debug iteration %d \n',i);
    end
    img_bulbs(rowmin:rowmax, colmin:colmax) = img_temp;            
    
% rectangle('Position',[bb(i,1) bb(i,2) bb(i,3) bb(i,4)],'EdgeColor','green');
end

disp ('Image encoding done...');      

%% 5. Writing to Excel
write_name = 'wells_list.xlsx';
wells_list = [cat(1,regs.Area) cat(1,regs.Centroid) cat(1,regs.BoundingBox)];
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
% visboundaries(img_area_log,'color','r');
% savefig('Figure_wells_list'); 

% title('log')
save('Step1_data', 'img_wells', 'num_wells', 'img_orgl', 'img_bulbs', 'img_area_log', 'regs', 'max_wells');

cd(git_path_name); 
disp('End of code...');