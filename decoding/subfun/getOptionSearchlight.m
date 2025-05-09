% (C) Copyright 2019 CPP BIDS SPM-pipeline developpers

function opt = getOptionSearchlight()
% returns a structure that contains the options chosen by the user to run
% searchlight.

if nargin < 1
    opt = [];
end

% suject to run 
opt.subjects = {'02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12', '14', ...
    '15', '16', '17', '18', '19', '20', '21', '22', '23'}; % '02','03','04','05','06','07','08','09','11','12'
% mask choose to use
opt.mask = 'wholebrain'; 

opt.space = 'MNI152NLin2009cAsym'; 
opt.desc = 'MVPA';

% The directory where the data are located
this_dir = fileparts(mfilename('fullpath'));
root_dir = fullfile(this_dir, '..', '..');
output_dir = '/Volumes/ssd/num_output'; 
opt.dir.raw = fullfile(root_dir, 'input', 'raw');
opt.dir.derivatives = fullfile(output_dir, 'derivatives');
opt.dir.preproc = '/Users/yiyang/DATA/numMVPA_fmriprep/outputs/derivatives/bidspm-preproc';
opt.dir.input = opt.dir.preproc;
opt.dir.rois = fullfile(output_dir, 'derivatives', 'bidspm-rois');
opt.dir.stats = fullfile(output_dir, 'derivatives', 'bidspm-stats');
opt.dir.cosmo = fullfile(output_dir, 'derivatives', 'CoSMoMVPA');
opt.dir.searchlightout = fullfile(output_dir, 'derivatives', 'Searchlight', 'results');
opt.dir.searchlightin = fullfile(output_dir, 'derivatives', 'Searchlight', 'derivatives');
opt.dir.sl_ac = fullfile(output_dir, 'derivatives', 'Searchlight', 'aboveChance');

% multivariate
opt.model.file = '/Users/yiyang/DATA/numMVPA_bids/code/models/model_nummvpa_eyemovement_smdl.json';
% task to analyze
opt.taskName = 'numMVPA';
opt.pipeline.type = 'stats';

opt.parallelize.do = false;
opt.parallelize.nbWorkers = 1; %???
opt.parallelize.killOnExit = true;
%% DO NOT TOUCH
opt = checkOptions(opt);
saveOptions(opt);
% we cannot save opt with opt.mvpa, it crashes
%% mvpa options

% opt.decodingCondition = {'within_format'};
opt.decodingCondition = {'within_format'};

% define the 4D maps to be used
opt.fwhm.func = 2;

% Define a neighborhood with approximately 100 voxels in each searchlight.
opt.mvpa.searchlightVoxelNb = 3; % 100 150 'count', or 3 - 5 with 'radius'
opt.mvpa.sphereType = 'radius'; % 'radius' or 'count'

% set which type of ffx results you want to use
opt.mvpa.map4D = {'beta'}; %, 'tmap'};

% design info
opt.mvpa.nbRun = [20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, ...
    20, 20, 20, 20, 20, 20, 20, 20, 20, 20];
opt.mvpa.nbTrialRepetition = 1;

% cosmo options
opt.mvpa.tool = 'cosmo';

% Use the cosmo_cross_validation_measure and set its parameters
% (classifier and partitions) in a measure_args struct.
opt.mvpa.measure = @cosmo_crossvalidation_measure;

% Define which classifier to use, using a function handle.
% Alternatives are @cosmo_classify_{svm,matlabsvm,libsvm,nn,naive_bayes}
opt.mvpa.classifier = @cosmo_classify_libsvm;
opt.mvpa.className = 'libsvm';

end
