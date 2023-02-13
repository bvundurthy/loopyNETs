% This code is only to identify the specific condition that we are testing

% Path name for the specific condition we intend to investigate
folder_name = 'E:\Udaya\06_16_2022\tiff_files\';
cond_num = 4; 
path_name = strcat(folder_name, 'Cond_', num2str(cond_num), '\');
% Path name for git files
git_path_name = 'E:\Udaya\z_git_repo\loopyNETs\'; 

cd(path_name); 