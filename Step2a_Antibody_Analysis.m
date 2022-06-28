%% 0. Getting Started
close all
clearvars -except conds num_conds curr_cond
clc
disp('Getting Started...');
tstart = tic;

run('Step0_change_directory.m'); % cd into the condition folder
run('parameters.m'); % import all necessary parameters for all Steps

load 'Step1_data.mat'; % load all data from Step 1
load 'primary_edges_workspace.mat'; % load all data from Step 2

%% Recomputing edges for current brightfield image
img_brgt_src = imread(Ab_brgt);
disp('Image loading done...');        
beep;

img_brgt_bw = rgb2gray(im2single(img_brgt_src)); 
img_brgt_morph = max_wells(1)*img_brgt_bw - max_wells(2)*imdilate(img_brgt_bw, strel('square',5));
img_brgt_binary = imbinarize(img_brgt_morph);
disp('Image conversion to binary done...');  

%% 2. Removing air bubble areas from the binary image
for i = 1:size(bbl_box(:,1),1)
    img_binary(bbl_box(i,1):bbl_box(i,2), bbl_box(i,3):bbl_box(i,4)) = 0;
    if (i==1)
        disp ('Air bubbles are being removed from the binary figure...');
    end
end

%% Identifying and separating the wells 

% Detecting Edges, Filling Holes, Detecting areas with specific interval
img_brgt_edge_log = edge(img_brgt_binary, 'log',0);
img_brgt_fill_log = imfill(img_brgt_edge_log,'holes');
img_brgt_area_log = bwareafilt(img_brgt_fill_log,[18000 30000]); 
regs_brgt = regionprops(img_brgt_area_log); % Determining regions
disp('Wells identification done...'); 

%% Identifying the displacement
centroid_orgl = cat(1,regs.Centroid);
centroid_brgt = cat(1,regs_brgt.Centroid);

loop_exit = 0; i = 1; 
while (loop_exit == 0)
    idx = knnsearch(centroid_brgt, centroid_orgl(i,:));
    wells_disp = round(centroid_brgt(idx,:)-centroid_orgl(i,:));
    if max(abs(wells_disp)) < 110        
        loop_exit = 1; 
    else
        i = i + 1;
    end
end

if (loop_exit == 0)
    fprintf('Displacement is too larger (>110 pixels). Stop and debug. \n'); 
    return;
end

fprintf('Displacement: x->%d y->%d\n',wells_disp(1), wells_disp(2));
wells_disp_all(end+1,:) = wells_disp; % For live antibody staining
wells_disp_all(end+2,:) = wells_disp; % For dead antibody staining

size_orgl = size(img_area_log);
img_brgt_wells = zeros(size_orgl(1), size_orgl(2));
img_brgt_bulbs = zeros(size_orgl(1), size_orgl(2));

% Shifting in x direction - equivalent to moving columns
mov_col = abs(wells_disp(1)); 
if wells_disp(1) > 0
    img_brgt_wells(:, mov_col+1:end) = img_wells(:, 1:end-mov_col);
    img_brgt_bulbs(:, mov_col+1:end) = img_bulbs(:, 1:end-mov_col);
else
    img_brgt_wells(:, 1:end-mov_col) = img_wells(:, mov_col+1:end);    
    img_brgt_bulbs(:, 1:end-mov_col) = img_bulbs(:, mov_col+1:end);    
end

% Shifting in y direction - equivalent to moving rows
mov_row = abs(wells_disp(2)); 
if wells_disp(2) > 0
    img_brgt_wells(mov_row+1:end, :) = img_brgt_wells(1:end-mov_row, :);
    img_brgt_bulbs(mov_row+1:end, :) = img_brgt_bulbs(1:end-mov_row, :);
else
    img_brgt_wells(1:end-mov_row, :) = img_brgt_wells(mov_row+1:end, :);    
    img_brgt_bulbs(1:end-mov_row, :) = img_brgt_bulbs(mov_row+1:end, :);    
end

% figure(1)
% imshow(img_brgt_src(4872:5512, 8968:9700))
% hold on
% visboundaries(img_wells(4872:5512, 8968:9700), 'color', 'r','LineWidth',5);
% visboundaries(img_brgt_area_log(4872:5512, 8968:9700), 'color','b','LineWidth',5);
% visboundaries(img_brgt_wells(4872:5512, 8968:9700), 'color','c','LineWidth',5);
% fprintf('Wells from the base image are in red. Wells detected in this image are in blue while the red wells after adjustment are in cyan (blue should coincide with cyan. \n'); 

fprintf('Well Displacement Computed and Operated \n'); 

%% Cell Identification and Writing Data
for each_cell = 1:2
    % Reading the image and converting it to binary
    fcell = Ab_cell{each_cell}; 
    img_blob_src = imread(fcell);
    disp('Image loading done...');        
    beep;

    img_blob_bw = rgb2gray(im2single(img_blob_src));     
    auto_thresh = graythresh(img_blob_bw);
    fprintf('Auto Gray Threshold value = %f\n',auto_thresh);
    if (auto_illum(each_cell) == 0)
        img_blob_binary = imbinarize(img_blob_bw); % Note that the default is not 0 - this does the automated version by MATLAB
    else
        img_blob_binary = imbinarize(img_blob_bw,auto_illum(end-2+each_cell)); % useful with auto-illumination
    end
    %     img_blob_binary = imbinarize(img_blob_bw,auto_illum(each_cell));
    disp('Image conversion to binary done...');  

    %% Identifying and separating the cells 

    % Detecting Edges, Filling Holes, Detecting areas with specific interval
    img_blob_edge_log = edge(img_blob_binary, 'log',0);
    img_blob_fill_log = imfill(img_blob_edge_log,'holes');
    img_blob_area_log = bwareafilt(img_blob_fill_log,[85 Inf]); 
    % img_blob_area_log = bwareafilt(imfill(edge(img_blob_binary, 'log'),'holes'),[18000 22000]); 
    regs_blob = regionprops(img_blob_area_log); % Determining regions
    disp('Cells identification done...');

    area = round(0.3025*cat(1,regs_blob.Area),1); % area in sq microns
    centroid = cat(1,regs_blob.Centroid); % centroid info
    bb = cat(1, regs_blob.BoundingBox); % bounding box info

    % [area, centroid] = step(hblob, y3);   % Calculate area and centroid
    centroid_rnd = round(centroid);
    numBlobs = size(centroid,1);  % and number of cells.
    disp('Morphological operations and cell counting done...');

    %% Creating information for wells in a matrix form
    wells = zeros(numBlobs,5);
    bulbs = zeros(numBlobs,5);
    loops = zeros(numBlobs,5);
    count_wells = 0; count_bulbs = 0; count_loops = 0; 
    for i = 1 : numBlobs
        well_num = img_brgt_wells(centroid_rnd(i,2), centroid_rnd(i,1));
        if (well_num ~=0)
            count_wells = count_wells + 1;
            wells(count_wells,:) = [well_num, i, area(i), centroid(i,:)];

            bulb_num = img_brgt_bulbs(centroid_rnd(i,2), centroid_rnd(i,1));
            if (bulb_num ~=0)
                count_bulbs = count_bulbs + 1;
                bulbs(count_bulbs,:) = [well_num, i, area(i), centroid(i,:)];
            else
                count_loops = count_loops + 1;
                loops(count_loops,:) = [well_num, i, area(i), centroid(i,:)];
            end
        else
            % remove the blob from img_blob_area_log using bounding box
            rmin = floor(bb(i,2)); cmin = floor(bb(i,1));
            rmax = rmin + bb(i,4) + 1; cmax = cmin + bb(i,3) + 1;
            img_blob_area_log(rmin:rmax, cmin:cmax) = 0;
        end
    end
    wells(count_wells+1:end,:) = []; wells = sortrows(wells);
    bulbs(count_bulbs+1:end,:) = []; bulbs = sortrows(bulbs);
    loops(count_loops+1:end,:) = []; loops = sortrows(loops); 
    img_blob_area_all{num_times+each_cell} = img_blob_area_log;  %#ok<SAGROW>
    disp('Neutrophils from within wells, bulbs and loops identified and separated...');

    %% Writing to excel
    % Dec. 5, 2021 - Writing modified files into excel
    write_name = 'Cells_Wells.xlsx';
    writematrix(wells, write_name, 'Sheet', Ab_sheets{each_cell},'WriteMode','overwritesheet');
    write_name = 'Cells_Bulbs.xlsx';
    writematrix(bulbs, write_name, 'Sheet', Ab_sheets{each_cell},'WriteMode','overwritesheet');
    write_name = 'Cells_Loops.xlsx';
    writematrix(loops, write_name, 'Sheet', Ab_sheets{each_cell},'WriteMode','overwritesheet');
    disp('Writing into excel files done...');
    toc(tstart);
    
    figure (each_cell)
    imshow(img_blob_src);
    hold on
    visboundaries(img_blob_area_log);
%     save_filename = append('Figure_',sheet_names{each_cell});
%     savefig(save_filename); 

%     figure
%     img_brgt_wells_mark = insertMarker(img_blob_src, wells(:,4:5), '*', 'Color', 'green');  
%     img_brgt_wells_bulbs_mark = insertMarker(img_brgt_wells_mark, bulbs(:,4:5), '*', 'Color', 'yellow');  
%     img_brgt_wells_bulbs_loops_mark = insertMarker(img_brgt_wells_bulbs_mark, loops(:,4:5), '*', 'Color', 'red');  
%     disp('Target marking done...');
% %         img_brgt_wells_bulbs_loops_mark = insertText(img_brgt_wells_bulbs_loops_mark, wells(:,4:5), wells(:,3),'AnchorPoint','LeftBottom','BoxOpacity',0,'TextColor','white');
%     imshow(img_brgt_wells_bulbs_loops_mark);
%     hold on
% %         visboundaries(img_wells, 'Color', 'w');
% %         visboundaries(img_brgt_wells, 'Color', 'c');
% %         visboundaries(img_brgt_area_log, 'Color', 'r');
%     visboundaries(img_blob_area_log);

end

fprintf('Saving some crucial variables in Workspace \n'); 
save('primary_edges_workspace','regs','img_area_log','img_blob_area_all','wells_disp_all','num_wells','max_wells');

%% Insert markers and Display Images

% figure (1)
% imshow(img_blob_src);

% figure (2)
% img_brgt_wells_mark = insertMarker(img_blob_src, wells(:,4:5), '*', 'Color', 'green');  
% img_brgt_wells_bulbs_mark = insertMarker(img_brgt_wells_mark, bulbs(:,4:5), '*', 'Color', 'yellow');  
% img_brgt_wells_bulbs_loops_mark = insertMarker(img_brgt_wells_bulbs_mark, loops(:,4:5), '*', 'Color', 'red');  
% disp('Target marking done...');
% img_brgt_wells_bulbs_loops_mark = insertText(img_brgt_wells_bulbs_loops_mark, wells(:,4:5), wells(:,3),'AnchorPoint','LeftBottom','BoxOpacity',0,'TextColor','white');
% imshow(img_brgt_wells_bulbs_loops_mark);
% hold on
% visboundaries(img_area_log, 'Color', 'w');
% visboundaries(img_brgt_wells, 'Color', 'c');
% visboundaries(img_blob_area_log);

% figure (1)
% imshow(img_all);

% figure(2)
% imshow(img_ext);
% hold on

% figure (3)
% imshow(y3);
cd(git_path_name); 
toc(tstart);
disp('End of code...');
