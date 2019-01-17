clear
clc

%% Prepare paths and regexp

cwd = '/mnt/data/benoit/protocol/SOMALS2/fmri';
cd(cwd)
mainPath = fullfile(pwd,'nii');

%for the preprocessing : Volume selection
par.anat_file_reg  = '^s.*nii'; %le nom generique du volume pour l'anat
par.file_reg  = '^f.*nii'; %le nom generique du volume pour les fonctionel

par.display=0;
par.run=1;
par.verbose = 2;
par.pct = 0;


%% Get files paths

% dfonc = get_subdir_regex_multi(suj,par.dfonc_reg) % ; char(dfonc{:})
% dfonc_op = get_subdir_regex_multi(suj,par.dfonc_reg_oposit_phase)% ; char(dfonc_op{:})
% dfoncall = get_subdir_regex_multi(suj,{par.dfonc_reg,par.dfonc_reg_oposit_phase })% ; char(dfoncall{:})
% anat = get_subdir_regex_one(suj,par.danat_reg)% ; char(anat) %should be no warning

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

e = exam(mainPath,'SOM_ALS2');

% anat_T1
e.addSerie('3DT1_mprage_1iso_ipat2_ND$','anat',1)
e.addVolume('anat','^s.*nii','s',1)

% func
e.addSerie('Run_PNEU$'        , 'run_PNEU_nm'  ,1)
e.addSerie('Run_PNEU_refBLIP$', 'run_PNEU_blip',1) % refAP
e.addSerie('Run_ELEC$'        , 'run_ELEC_nm'  ,1)
e.addSerie('Run_ELEC_refBLIP$', 'run_ELEC_blip',1) % refAP

% All func volumes
e.getSerie('run').addVolume('^f.*nii','f',1)

% Unzip if necessary
e.unzipVolume(par)

e.reorderSeries('name'); % mostly useful for topup, that requires pairs of (AP,PA)/(PA,AP) scans

e.explore

subjectDirs = e.toJob
regex_dfonc_np = 'run_\w+_nm$'  ;
regex_dfonc_op = 'run_\w+_blip$';
regex_dfonc    = 'run' ;
regex_anat     = 'anat';
dfonc    = e.getSerie(regex_dfonc_np).toJob
dfonc_op = e.getSerie(regex_dfonc_op).toJob
dfoncall = e.getSerie(regex_dfonc   ).toJob
anat     = e.getSerie(regex_anat    ).toJob(0)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

t0 = tic;


%% Segment anat

%anat segment
par.doSurface = 0;
par.doROI     = 0;
par.GM   = [1 1 1 1]; % Unmodulated / modulated / native_space / dartel import
%first one not possible, but keep for compatibility with spm12 job_segment
par.WM   = [1 1 1 1];
par.CSF  = [1 1 1 1];

j_segment = job_do_segmentCAT12(e.getSerie('anat').getVolume('^s'),par);  


%% Preprocess fMRI runs

% slice timing
par.use_JSON = 1;
ffonc_all = e.getSerie('run').getVolume('f');
j_stc = job_slice_timing(ffonc_all,par);

%realign and reslice
par.type = 'estimate_and_reslice';
ffonc_nm = e.getSerie(regex_dfonc_np).getVolume('af');
ffonc_bp = e.getSerie(regex_dfonc_op).getVolume('af');
j_realign_reslice    = job_realign(ffonc_nm,par);
j_realign_reslice_op = job_realign(ffonc_bp,par);

%topup and unwarp
par.sge=0;
ffonc_all = e.getSerie('run').getVolume('raf');
do_topup_unwarp_4D(ffonc_all,par)

%coregister mean fonc on brain_anat
fanat = e.getSerie('anat').getVolume('^ms');
par.type = 'estimate';
fmean = e.getSerie(regex_dfonc_np);
fmean = fmean(:,1).getVolume('^utmeanaf'); % first acquired run (time)
fo = e.getSerie(regex_dfonc_np).getVolume('^utraf');
j_coregister=job_coregister(fmean,fanat,fo,par);

%apply normalize
fy = e.getSerie(regex_anat).getVolume('^y');
j_apply_normalize=job_apply_normalize(fy,fo,par);
fo = fmean;
job_apply_normalize(fy,fo,par); % apply normalize on the utmean also

%smooth the data
ffonc = e.getSerie(regex_dfonc_np).getVolume('^wutraf');
par.smooth = [4 4 4];
par.prefix = sprintf('s%d',par.smooth(1));
j_smooth=job_smooth(ffonc,par);

% coregister WM & CSF on functionnal (using the warped mean)
if isfield(par,'prefix'), par = rmfield(par,'prefix'); end
ref = e.getSerie(regex_dfonc_np);
ref = ref(:,1).getVolume('^wutmeanaf'); % first acquired run (time)
src = e.getSerie(regex_anat).getVolume('^wp2');
oth = e.getSerie(regex_anat).getVolume('^wp3');
par.type = 'estimate_and_write';
job_coregister(src,ref,oth,par);

toc(t0)

% save('e_orig','e') % always keep the original
% save('e_stim','e') % work on this one
