%% This code allows you to select the bubbles (if any) 

%%0. Getting Started
close all
clearvars -except conds num_conds curr_cond
clc
tstart = tic;

run('Step0_change_directory.m'); % cd into the condition folder
run('parameters.m'); % import all necessary parameters for all Steps

fprintf('Starting Step 1a to detect bubbles in this folder "%s" \n', path_name);

img_src = imread(fbrgt_base);
imshow(img_src);

num_bubbles = input("How many bubbles do you want to deselect (enter 0 if NO bubbles)? \n");
if (num_bubbles>0)
    bbl_box = NaN(num_bubbles,4); 
    for i = 1:num_bubbles
        roi = drawrectangle; 
        bbl_box(i,:) = round([roi.Position(2), roi.Position(2)+roi.Position(4), roi.Position(1), roi.Position(1)+roi.Position(3)]);
    end

    for i = 1:num_bubbles
        figure
        imshow(img_src(bbl_box(i,1):bbl_box(i,2), bbl_box(i,3):bbl_box(i,4), :)); 
    end
    fprintf('Bubbles marked and saved. Go to Step 1. \n');
    clearvars -except bbl_box git_path_name
    save('bubbles_coords');
else
    fprintf('No bubbles in this figure! Good job, Dr. Datla. \n');
end
cd(git_path_name); 
% The bubble boxes are given by [rowmin, rowmax, colmin, colmax]
% Each line represents a different bubble
% Note that when using markers on the figure: x -> columns, y -> rows
% e.g. bbl_box = [3553, 7685, 3525, 7647]; 