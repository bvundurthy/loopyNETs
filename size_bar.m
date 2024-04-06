close all
clear variables
clc

folder_name = 'C:\Users\bvund\Documents\Image panel new figure\F. PAO1 + IL-6\';
cd (folder_name);

for i = 1:6
    img = imread(strcat(folder_name, 'cond8t', num2str(i), '.tif')); 
    figure (i)    
    imshow(img); 
    hold on
    line([22 204], [1366 1366], 'color', 'w', 'LineWidth', 3);
    text(2, 1310,'100 \mum','Color','w', 'FontSize', 26);
    text(1400, 60,[num2str(i) ' hr.'],'Color','w', 'FontSize', 30);
    ax = gca;
    exportgraphics(ax,['scalebar_cond8t', num2str(i),'.tif']);
end
