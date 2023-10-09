close all
clear variables
clc

folder_name = 'E:\Udaya\07_08_2022\tiff_files\Cond_2\replicate1\'; 
intensitiesOld = readmatrix(strcat(folder_name, 'intensitiesNET.xlsx'), 'Sheet', 'Sheet1');
% figNames = dir(fullfile(folder_name, '*.png'));
numCells = nnz(intensitiesOld(:,2)); % figNames, 1); 
numFigs = ceil(numCells/3); 
lastFigCells = numCells - (numFigs-1)*3; 


bbl_dapi = zeros(numCells,4); 
bbl_cy5 = zeros(numCells,4); 
roi_dapi = zeros(numCells,4); 
roi_cy5 = zeros(numCells,4);
intensitiesROI = [(1:numCells)' zeros(numCells,5) nonzeros(intensitiesOld(:,end))]; 
for i = 1 : numFigs
    
    figName = strcat(folder_name, 'figureNET', num2str(i), '.png'); 
    imgCurr = imread(figName);
    disp('Opening image...');  
    figure (1)
    imshow(imgCurr); 
    
    for j = 1:3
        currCell = 3*(i-1) + j; 
        if (i==numFigs && j>lastFigCells)
            break;
        end
        
        roi = drawrectangle; 
        roi_dapi(currCell,:) = roi.Position; 
        roi_cy5(currCell,:) = roi_dapi(currCell,:) + [618 0 0 0]; 
        bbl_dapi(currCell,:) = round([roi.Position(2), roi.Position(2)+roi.Position(4), roi.Position(1), roi.Position(1)+roi.Position(3)]);        
        bbl_cy5(currCell,:) = bbl_dapi(currCell,:) + [0 0 618 618]; 
        
        img_dapi = imgCurr(bbl_dapi(currCell,1):bbl_dapi(currCell,2), bbl_dapi(currCell,3):bbl_dapi(currCell,4), :);
        img_cy5 = imgCurr(bbl_cy5(currCell,1):bbl_cy5(currCell,2), bbl_cy5(currCell,3):bbl_cy5(currCell,4), :);
        img_area = size(img_dapi,1) * size(img_dapi,2); 
        % [cell number, total intensity dapi, total intensity cy5, area, avg intesity dapi, avg intensity cy5, ratios]
        intensitiesROI(currCell,2:6) = [sum(rgb2gray(img_dapi), 'all') sum(rgb2gray(img_cy5), 'all') img_area sum(rgb2gray(img_dapi), 'all')/img_area sum(rgb2gray(img_cy5), 'all')/img_area];
        fprintf('Intensities: dapi = %d, cy5 = %d \n', intensitiesROI(currCell,2), intensitiesROI(currCell,3)); 
        
%         figure (2)
%         imshow(img_dapi);
%         figure (3)
%         imshow(img_cy5);
        
%         pause (1); 
    
    end
    close all; 
    fig = figure (1);
    imshow(imgCurr); 
    hold on; 
    for j = 1:3
        currCell = 3*(i-1) + j; 
        if (i==numFigs && j>lastFigCells)
            break;
        end        
        rectangle('Position',roi_dapi(currCell,:), 'EdgeColor','r', 'LineWidth',3); 
        text(roi_dapi(currCell,1)-20,roi_dapi(currCell,2)-50,num2str(intensitiesROI(currCell,2)), 'Color','red','FontSize',14); 
        text(roi_dapi(currCell,1)-20,roi_dapi(currCell,2)-20,num2str(intensitiesROI(currCell,5)), 'Color','red','FontSize',14); 
%         fig = insertText(fig, roi_dapi(currCell,1:2), intensitiesROI(currCell,2),'AnchorPoint','LeftBottom');
        rectangle('Position',roi_cy5(currCell,:), 'EdgeColor','r', 'LineWidth', 3); 
        text(roi_cy5(currCell,1)-20,roi_cy5(currCell,2)-50,num2str(intensitiesROI(currCell,3)), 'Color','red','FontSize',14); 
        text(roi_cy5(currCell,1)-20,roi_cy5(currCell,2)-20,num2str(intensitiesROI(currCell,6)), 'Color','red','FontSize',14); 
%         fig = insertText(fig, roi_cy5(currCell,1:2), intensitiesROI(currCell,3),'AnchorPoint','LeftBottom');
    end
    
    fig.WindowState = 'maximized'; 
    pause(0.5); 
    saveas(gcf, strcat(folder_name, 'ROI_figureNET',num2str(i), '.tif'));
    close all;
    
end

write_name = strcat(folder_name,'/ROI_intensitiesNET.xlsx');
writematrix(intensitiesROI, write_name,'WriteMode','overwritesheet'); 


disp('Saving ROIs future steps...');
save(strcat(folder_name, 'ROI_info'), 'roi_dapi', 'roi_cy5', 'bbl_dapi', 'bbl_cy5');

% add 618 in columns