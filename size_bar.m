close all
clear variables
clc

folder_name = 'E:\Udaya\Figures\IHC panel\Cond1\';
cd (folder_name);
img = imread(strcat(folder_name, 'cond1_crop_RGB_Cy5.tif')); 

figure (1)

imshow(img); 
hold on
line([35 217], [1366 1366], 'color', 'w', 'LineWidth', 3);
text(27, 1320,'100 \mum','Color','w','FontWeight','bold', 'FontSize', 12);
ax = gca;
exportgraphics(ax,'fig2.tif');

