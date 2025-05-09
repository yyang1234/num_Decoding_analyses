clear;
clc;

addpath(fullfile(pwd, '..', '..', 'numMVPA_analysis', 'code', 'lib', 'bidspm'));
bidspm();

this_dir = fileparts(mfilename('fullpath'));
root_dir = fullfile(this_dir, '..');

%% Smooth the data
%
% fmriprep data is not smoothed so we need to do that first
%
% we need to specify where the smoothed data will go
opt.dir.raw = '/Users/yiyang/DATA/numMVPA_bids/input/raw';
% opt.dir.input = fullfile(root_dir, 'inputs', 'fmriprep');
opt.dir.input = '/Users/yiyang/DATA/numMVPA_fmriprep/inputs/fmriprep'; %/Volumes/ssd/fmriprep '/Users/yiyang/DATA/numMVPA_fmriprep/inputs/fmriprep'
opt.dir.derivatives = fullfile(root_dir, 'outputs', 'derivatives');%fullfile(root_dir, 'outputs', 'derivatives'); /Volumes/ssd/num_output
opt.pipeline.type = 'preproc';
opt.dir.preproc = fullfile(opt.dir.derivatives, 'bidspm-preproc'); %fullfile(opt.dir.derivatives, 'bidspm-preproc');
opt.space = {'MNI152NLin2009cAsym'};
opt.subjects = {'12'};
opt.query.ses = '02';
opt.query.run = {'17', '18', '19', '20'};
opt.taskName = 'numMVPA';%'numMVPA';'wordLocalizer'
opt.fwhm.func = 6;%2
opt = checkOptions(opt);
% specify some filter to decide which file to copy out of the frmiprep dataset
%
% this 2 step copy should disappear in future version.
%
% See: https://github.com/cpp-lln-lab/bidspm/issues/409

% copy the actual nifti images
opt.query.desc = {'preproc', 'brain'};
opt.query.suffix = {'T1w', 'bold', 'mask'};
opt.query.space = opt.space;
bidsCopyInputFolder(opt);
% then we can smooth
bidsSmoothing(opt);


%% smooth data with new version of bidspm
% (C) Copyright 2019 Remi Gau

clear;
clc;

addpath('/Users/yiyang/DATA/smooth/bidspm')
bidspm();

%%
subject_label = {'23'};%exclude sub13

 %{'02','03','04','05','06','07','08','09','10','11','12',...
 %               '14','15','16','17','18','19','20','21','22','23'};%exclude sub13

task = {'numMVPA'};
space = {'MNI152NLin2009cAsym'};
this_dir = fileparts(mfilename('fullpath'));
root_dir = fullfile(this_dir, '..');
bids_dir = '/Users/yiyang/DATA/numMVPA_bids/input/raw';
% fmriprep_dir = fullfile(root_dir, 'inputs', 'fmriprep');
fmriprep_dir = '/Volumes/ssd/fmriprep';
% we need to specify where the smoothed data will go
output_dir = '/Volumes/ssd/num_output/derivatives';
opt.query.ses = '02';
opt.query.run = {'17', '18', '19', '20'};
%% Copy and smooth
%
% fmriprep data is not smoothed so we need to do that first

parfor i = 1:length(subject_label)
  bidspm(fmriprep_dir, output_dir, 'subject', ...
         'action', 'smooth', ...
         'participant_label', subject_label(i), ...
         'task', task, ...
         'space', space, ...
         'fwhm', 6, ...
         'options', opt, ...
         'verbosity', 3);
end