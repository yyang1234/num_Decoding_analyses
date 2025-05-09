% (C) Copyright 2019 CPP BIDS SPM-pipeline developpers

function opt = getOptionMvpa()
  % returns a structure that contains the options chosen by the user to run
  % decoding with cosmo-mvpa.

  if nargin < 1
    opt = [];
  end

  % suject to run in each group
  opt.subjects = {'02','03','04','05','06','07','08','09','10','11','12','14',...
    '15','16','17','18','19','20','21','22','23'};%'02',

  % we stay in native space (that of the T1)
  opt.space = 'MNI152NLin2009cAsym'; % 'individual', 'MNI'
  opt.desc = 'MVPA';

  % The directory where the data are located
  this_dir = fileparts(mfilename('fullpath'));
  root_dir = fullfile(this_dir, '..', '..');
  opt.dir.raw = fullfile(root_dir, 'input', 'raw');
  output_dir = '/Volumes/ssd/num_output';
  opt.dir.derivatives = fullfile(output_dir, 'derivatives');
  opt.dir.preproc = '/Users/yiyang/DATA/numMVPA_fmriprep/outputs/derivatives/bidspm-preproc';
  opt.dir.input = opt.dir.preproc;
  opt.dir.rois = fullfile(output_dir, 'derivatives','bidspm-rois');
  opt.dir.stats = fullfile(output_dir, 'derivatives','bidspm-stats');
  opt.dir.cosmo =  fullfile(output_dir, 'derivatives','CoSMoMVPA');
  opt.model.file = '/Users/yiyang/DATA/numMVPA_fmriprep/code/models/model_nummvpa_eyemovement_smdl.json';
  % task to analyze
  opt.taskName = 'numMVPA';
  opt.pipeline.type = 'stats';

  opt.parallelize.do = false;
  opt.parallelize.nbWorkers = 1;
  opt.parallelize.killOnExit = true;

  %% DO NOT TOUCH
  opt = checkOptions(opt);
  saveOptions(opt);
  % we cannot save opt with opt.mvpa, it crashes

  %% mvpa options

  % set which type of ffx results you want to use
  opt.mvpa.map4D = {'beta'}; %, 'tmap'

  % design info
  opt.mvpa.nbRun = [20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,...
      20,20,20,20,20,20,20,20,20,20]; %14(13) 15  10  sub001:16  sub003:22  sub005:26  sub006:22
  opt.mvpa.nbTrialRepetition = 1;%???1:one beta for each condition per run 2: two beta (I want 1 beta each condition per run though I have repetition)

  % cosmo options
  opt.mvpa.tool = 'cosmo';
%   opt.mvpa.normalization = 'zscore';
  opt.mvpa.child_classifier = @cosmo_classify_libsvm; %@cosmo_classify_libsvm;
  opt.mvpa.feature_selector = @cosmo_anova_feature_selector;

  % permute the accuracies ?
  opt.mvpa.permutate = 1;

end