% This script calls  "Step7a_Create_figureNETx_fn.m" repeatedly 
% This script overrides the condition number in Step0 and calls a set of
% conditions and replicates sequentially.  
% Note that this requires commenting out the condition number in Step0
% and you will note that it is currently commented out. 

close all
clear variables
clc

replicate_list{1} = 'replicate1'; 
replicate_list{2} = 'replicate2'; 
replicate_list{3} = 'Backup/replicate1';
replicate_list{4} = 'Backup/replicate2'; 

for cond_num = [1 2 3 4] 
    for curr_rep = 1%:4
        replicate = replicate_list{curr_rep}; 
        run('Step7a_Create_figureNETx_fn.m');
    end
end

