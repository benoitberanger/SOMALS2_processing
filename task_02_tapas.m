clear
clc

load e_orig.mat

dirFunc = e.getSerie('run_\w+_nm$').toJob

%% Fetch noise ROI dirs

dirNoiseROI = e.getSerie('anat').toJob(0)


%%

par.file_reg = '^f.*nii'; % to fetch volume info (nrVolumes, nrSlices, TR, ...)
par.noiseROI_files_regex  = '^wutraf.*nii';  % usually use normalied files, NOT the smoothed data
par.noiseROI_mask_regex   = '^rwp[23].*nii'; % 2 = WM, 3 = CSF

par.rp_threshold = 1.0;

par.run = 1;
par.display = 0;
par.print_figures = 0;

par.redo=0;
par.usePhysio = 0;
par.noiseROI=1;

par.pct = 1;

par

job_physio_tapas( dirFunc, [], dirNoiseROI, par);
