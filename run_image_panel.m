close all
clear variables
clc

replicate_list{1} = 'replicate1'; 
replicate_list{2} = 'replicate2'; 
replicate_list{3} = 'Backup/replicate1';
replicate_list{4} = 'Backup/replicate2'; 

for cond_num = [1 2 4 6 8]
    for curr_rep = 1%:4
        replicate = replicate_list{curr_rep}; 
        if (cond_num==3 && (curr_rep==2 || curr_rep==4))% isfile(strcat(path_name,replicate))
             fprintf('No replicate %d in condition %d \n', curr_rep, cond_num);
        else
            run('Step7_Antibody_Quantification.m');
        end
        
    end
end

