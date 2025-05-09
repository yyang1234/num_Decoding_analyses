% This script performs Representational Disimilarity Analysis (RSA)
% in several ROIs and subjects. The Decoding Toolbox and SPM12 must be
% added to the path. The RSA is done on beta images, so before using this
% script, you should have estimated a GLM to extract the betas of interests
% (e.g. one beta per condition and run, or one beta per trial).
%
% The final output of the script is actually a similarity matrix (r), not dissimilarity (1 - r).
% If you decide to use some other distance measure (e.g. euclidean), bear
% in mind that the output would then be already a dissimilarity matrix (so
% no need to do 1 - output afterwards).
%
% 25/01/2018 v.0.1.0: - initial commit
% 15/02/2019 v 0.2.0: - implemented crossvalidation
%                     - implemented multivariate noise normalization (see
%                     https://www.sciencedirect.com/science/article/pii/S1053811915011258)
%
% originally from Carlos González-García (carlos.gonzalezgarcia@ugent.be)
% modified by Ying Yang

clear all
clc

%subject ID
subjects = {'02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12', '14', ...
    '15', '16', '17', '18', '19', '20', '21', '22', '23'};
% some peremeters
opt.fwhm.func = 2;
% Set defaults
cfg = decoding_defaults;
cfg.plot_design = 0;
cfg.results.overwrite = 1; % check to 0 if you don't want to overwrite
cfg.analysis = 'ROI'; % for searchlight see 'RSA_searchlight.m'
cfg.results.overwrite = 1;
cfg.hrf_fitting = 0; % specify if hrf fitting betas should be used for loading the residuals
do_cv = 0; % compute cross-validated distance (please, keep in mind this will use euclidean distance instance of Pearson's r)
do_MNN = 1; % do noise normalization (using residuals from SPM.mat)
cfg.results.output = 'other_average_RDV';
cfg.decoding.train.classification.model_parameters = 'pearson';
% set dir
dir.stats = '/Volumes/ssd/num_output/derivatives/bidspm-stats';
dir.statsTask = ['task-numMVPA_space-MNI152NLin2009cAsym_FWHM-', ...
    num2str(opt.fwhm.func), '_node-eyeMovementsGLM']; % node-eyeMovementsGLM node-seqtype _node-transform
dir.rois = fullfile('/Volumes/ssd/num_output', 'derivatives', 'bidspm-rois');

% get roi mask
opt.mask = 'SLpTFCE_eyemove_new';
opt = mvpa_chooseMask(opt);

for iSub = 1:length(subjects)
    fprintf(['Starting RSA for subject', subjects{iSub}, '\t'])
    dir.pathData = fullfile(dir.stats, ...
        ['sub-', subjects{iSub}], ...
        dir.statsTask); %where beta files are

    dir.output = [ ...
        '/Users/yiyang/DATA/numMVPA_fmriprep/outputs/derivatives/rsa/sub-', subjects{iSub}]; % outputdir
    if ~exist(dir.output, 'dir')
        mkdir(dir.output)
    end
    beta_loc = dir.pathData; % beta images should be here
    cfg.files.mask = fullfile(opt.dir.rois, opt.maskName); % mask = roi in this case

    % order condition names
    condition_names = {'2aud_seq', '3aud_seq', '4aud_seq', '5aud_seq', ...
        '2vis_seq', '3vis_seq', '4vis_seq', '5vis_seq', ...
        '2vis_sim', '3vis_sim', '4vis_sim', '5vis_sim'};
    % a non-elegant hack to be able to use a different pattern_similarity_fast.m function than the one used in the TDT
    % this is necessary since the original pattern_similarity_fast.m function creates faulty results
    cd('/Users/yiyang/DATA/object_drawing_dynamics/first_level/fmri')
    labels = [1:12];
    rsa_fmri_pearson(condition_names, labels, dir.pathData, dir.output, cfg);
end
