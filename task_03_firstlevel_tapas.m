clear
clc

load e_stim.mat

model_name_baze = 'model_tapas';


%% Prepare paths and regexp

mainPath = fullfile(pwd,'nii');
stimPath = fullfile(pwd,'stim');

par.display=0;
par.run=1;
par.pct = 1;
par.verbose = 2;


%% dirs & files


for mdl = {'PNEU', 'ELEC'}
    
    model_name = [model_name_baze '_' char(mdl)];
    
    dirStats = e.mkdir(model_name);
%     do_delete(dirStats,0)
%     continue
    
    dirFonc = e.getSerie(['run_' char(mdl) '_nm']).toJob;
    onsetFile = e.getSerie(['run_' char(mdl) '_nm']).addStim(stimPath, [ char(mdl) '_run\d{2}.mat$'], char(mdl), 1 );
    
    %% Specify
    
    par.rp = 1;
    par.rp_regex = 'multiple_regressors.txt';
    par.file_reg  = '^s.*nii'; %le nom generique du volume pour les fonctionel
    job_first_level_specify(dirFonc,dirStats,onsetFile,par);
    
    
    %% Estimate
    
    fspm = e.addModel(model_name,model_name);
    save('e_stim','e') % work on this one
    
    job_first_level_estimate(fspm,par);
    
    
    %% Contrast : definition
    
    task_routine_contrasts
    
    
    %% Display
    
%     e.getModel(model_name).show
    
    
end
