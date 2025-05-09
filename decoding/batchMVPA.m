%% MVPA batch script for numMVPA experiment

clear all;
clc;

warning('off');
addpath(fullfile(pwd, '..', '..', '..', 'numMVPA_analysis', 'code', 'lib', 'bidspm'));
addpath(fullfile(pwd, '..', '..', '..', 'numMVPA_analysis', 'code', 'src', 'mvpa'));
bidspm();

% add bids repo
ptbPath = '/Users/yiyang/numMVPA/lib/CPP_PTB';
addpath(genpath(fullfile(ptbPath, 'src')));
addpath(genpath(fullfile(ptbPath, 'lib')));

cosmo = '/Applications/CoSMoMVPA';
addpath(genpath(cosmo));
cosmo_warning('once');

% libsvm
libsvm = '/Applications/libsvm';
addpath(genpath(libsvm));
% verify it worked
cosmo_check_external('libsvm');

%might helpful in the future
% addpath(genpath(fullfile(pwd, 'subfun')));

opt = getOptionMvpa();
opt.dir.stats = '/Volumes/ssd/num_output/derivatives/bidspm-stats';
% mask choose to use
opt.mask = 'SLpTFCE_eyemove_new';

% take the most responsive xx nb of voxels
opt.featuresele_vx = 150;

% define the 4D maps to be used
opt.fwhm.func = 2;

outputFolder = ['S', num2str(opt.fwhm.func)];
opt.dir.cosmo = '/Volumes/ssd/num_output/derivatives/CoSMoMVPA/';
opt.dir.cosmo = fullfile(opt.dir.cosmo, outputFolder);
opt.dir.statsTask = ['task-numMVPA_space-MNI152NLin2009cAsym_FWHM-', ...
    num2str(opt.fwhm.func), 'node-eyeMovementsGLM'];

if ~exist(opt.dir.cosmo, 'dir')
    mkdir(opt.dir.cosmo)
end

%% GO GET THAT ACCURACY!


% % crossmodal
parfor iSub = 1:length(subject_label)

    mvpaCross = mvpa_CrossModal(opt, subject_label{iSub}, iSub);

end
