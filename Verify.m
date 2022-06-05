close all
clear variables
clc

load 'primary_edges_workspace.mat';

num_files = 7;
fcell_all = {
        'dapic1t1xy1.tif';
        'tritcc1t1xy1.tif';
        'tritcc1t2xy1.tif';
        'tritcc1t3xy1.tif';
        'tritcc1t4xy1.tif';
        'tritcc1t5xy1.tif';
        'tritcc1t6xy1.tif';
        };
sheet_names = {
        'live01';
        'dead01';
        'dead02';
        'dead03';
        'dead04';
        'dead05';
        'dead06';
                };
    
regs = readmatrix('wells_list.xlsx');
bb = regs(:,4:7);
well_no=525;

%Creating a buffer of 15 on both sides to accomodate displacement
colmin = bb(well_no,1) - 0.5 - 15; 
colmax = bb(well_no,1) + 0.5 + bb(well_no,3) + 15;
rowmin = bb(well_no,2) - 0.5 - 15; 
rowmax = bb(well_no,2) + 0.5 + bb(well_no,4) + 15;

figure(1)
hold on

for i = 1:num_files    
    subplot(2,4,i)
    img_test = imread(fcell_all{i});
    wells_all = readmatrix('Cells_Wells','sheet',sheet_names{i});
    wells_this = wells_all(wells_all(:,1)==well_no,:);
    if ~isempty(wells_this)
        img_test = insertText(img_test, wells_this(:,4:5), wells_this(:,3),'AnchorPoint','LeftBottom','BoxOpacity',0,'TextColor','white','FontSize',21);
        img_test = insertMarker(img_test, wells_this(:,4:5), '*', 'Color', 'white');
    end
    imshow(img_test(rowmin:rowmax, colmin:colmax,:));
    hold on; 
    title(sheet_names{i}); 
    fprintf('iteration %d \n',i);
    wells_disp = wells_disp_all(i,:);
    img_bound = img_area_log(rowmin:rowmax, colmin:colmax,:);
    size_orgl = size(img_bound);
    img_area_wells = zeros(size_orgl(1), size_orgl(2));

    % Shifting in x direction - equivalent to moving columns
    mov_col = abs(wells_disp(1)); 
    if wells_disp(1) > 0
        img_area_wells(:, mov_col+1:end) = img_bound(:, 1:end-mov_col);
    else
        img_area_wells(:, 1:end-mov_col) = img_bound(:, mov_col+1:end);    
    end

    % Shifting in y direction - equivalent to moving rows
    mov_row = abs(wells_disp(2)); 
    if wells_disp(2) > 0
        img_area_wells(mov_row+1:end, :) = img_area_wells(1:end-mov_row, :);
    else
        img_area_wells(1:end-mov_row, :) = img_area_wells(mov_row+1:end, :);    
    end
    
    visboundaries(img_area_wells, 'color', 'r'); 
    visboundaries(img_blob_area_all{i}(rowmin:rowmax, colmin:colmax,:), 'color', 'c');
    
%     rectangle('Position',[bb(well_no,1) bb(well_no,2) bb(well_no,3) bb(well_no,4)],'EdgeColor','green');
end
