close all
clearvars -except conds num_conds curr_cond
clc

run('Step0_change_directory.m'); % cd into the condition folder
run('parameters.m'); % import all necessary parameters for all Steps

load 'Step1_wells.mat'; 
load 'Step2_cells.mat'; 

run_times = 1:num_times; 
run_wells = 280; % 1:num_wells; 

img_brgt_src = cell(length(run_times),1); 
img_blob_src = cell(length(run_times),1); 
disp('Reading files...');
for curr_time = run_times%1:num_times
    fprintf('Iteration %d/%d \n',curr_time, length(num_times)); 
    % Reading the bright field image for easy plotting
    fbrgt = fbrgt_all{curr_time}; % Taking each bright image file
    img_brgt_src{curr_time} = imread(fbrgt);
    % Reading the image and converting it to binary
    fcell = fcell_all{curr_time}; 
    img_blob_src{curr_time} = imread(fcell);
end
disp('Finished reading all files');
%% Creating the image panel - can run this section repeatedly

for curr_time = run_times %1:num_times
    for curr_well = run_wells
    curr_well_BB = wells(curr_well).BoundingBox;
    cmin = ceil(curr_well_BB(1)+wells_disp_all(curr_time,1)); 
    cmax = cmin + curr_well_BB(3) - 1;
    rmin = ceil(curr_well_BB(2)+wells_disp_all(curr_time,2));
    rmax = rmin + curr_well_BB(4) - 1;
    
    subplot(2,5,curr_time)
    hold on; 
    curr_img_show = 0.5*img_brgt_src{curr_time}(rmin:rmax, cmin:cmax) + 2*img_blob_src{curr_time}(rmin:rmax, cmin:cmax,:);
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
    title(sprintf('%s',sheet_names{curr_time}));
    sgtitle(sprintf('Well number %d', curr_well)); 
    end
end

%% Transfer control back to git folder and end the code
cd(git_path_name); 
disp('End of code...');