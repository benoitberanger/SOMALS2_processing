switch char(mdl)
    
    case 'PNEU'
        
        Rest   = [1 0 0];
        Bone   = [0 1 0];
        Tendon = [0 0 1];
        
        
        contrast_T.names = {
            
        'Rest'
        'Bone'
        'Tendon'
        'Bone   - Rest'
        'Tendon - Rest'
        'Bone   - Tendon'
        'Tendon - Bone'
        
        }';
    
    contrast_T.values = {
        
    Rest
    Bone
    Tendon
    Bone   - Rest
    Tendon - Rest
    Bone   - Tendon
    Tendon - Bone
    
    }';

    case 'ELEC'
        
        Rest  = [1 0 0];
        Nerve = [0 1 0];
        Skin  = [0 0 1];
        
        
        contrast_T.names = {
            
        'Rest'
        'Nerve'
        'Skin'
        'Nerve - Rest'
        'Skin  - Rest'
        'Skin  - Nerve'
        'Nerve - Skin'
        
        }';
    
    contrast_T.values = {
        
    Rest
    Nerve
    Skin
    Nerve - Rest
    Skin  - Rest
    Skin  - Nerve
    Nerve - Skin
    
    }';

end

contrast_T.types = cat(1,repmat({'T'},[1 length(contrast_T.names)]));

contrast_F.names  = {'F-all'};
contrast_F.values = {eye(3)};
contrast_F.types  = cat(1,repmat({'F'},[1 length(contrast_F.names)]));

contrast.names   = [contrast_F.names  contrast_T.names ];
contrast.values = [contrast_F.values contrast_T.values];
contrast.types  = [contrast_F.types  contrast_T.types ];


%% Contrast : write

par.run = 1;
par.display = 0;

par.sessrep = 'none';

par.delete_previous = 1;
par.report=0;
job_first_level_contrast(fspm,contrast,par);
