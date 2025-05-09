clear all;
clc;

warning('off');
addpath(fullfile(pwd, '..', '..', '..', 'numMVPA_analysis', 'code', 'lib', 'bidspm'));
addpath(fullfile(pwd, '..', '..', '..', 'numMVPA_analysis', 'code', 'src', 'mvpa'));
bidspm();

% cosmo
cosmo = '/Applications/CoSMoMVPA';
addpath(genpath(cosmo));
cosmo_warning('once');

% libsvm
libsvm = '/Applications/libsvm';
addpath(genpath(libsvm));
% verify it worked.
cosmo_check_external('libsvm'); % should not give an error

%   % add cpp repo 
%   run ../lib/bidspm/initCppSpm.m;

% get options
opt = getOptionSearchlight();

opt.dir.statsTask = ['task-numMVPA_space-MNI152NLin2009cAsym_FWHM-', ...
    num2str(opt.fwhm.func), '_node-eyeMovementsGLM'];

%% perform the searchlight
parfor iSub = 1:length(opt.subjects)

    info = Searchlight(opt, opt.subjects{iSub}, iSub);

end
% % smoothing
funcFWHM2Level = 8;
maps = 'beta';
conditionName = {'aud_num', 'aud_seq', 'vis_num', 'vis_seq', 'vis_sim'};

parfor iSub = 1:length(opt.subjects)
    step2SmoothSLMaps(opt.subjects{iSub}, maps, funcFWHM2Level, opt);
end
%% average across subjects
step3CreateSLResultsMaps(conditionName, maps, funcFWHM2Level, opt);

step4CreateContrastMaps(conditionName, maps, funcFWHM2Level);

step5RunRFX(conditionName, maps, funcFWHM2Level);