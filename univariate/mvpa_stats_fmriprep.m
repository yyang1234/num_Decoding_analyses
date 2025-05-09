clear;
clc;

addpath(fullfile(pwd, '..', '..', 'numMVPA_analysis', 'code', 'lib', 'bidspm'));
bidspm();

this_dir = fileparts(mfilename('fullpath'));
root_dir = fullfile(this_dir, '..');

% bids_dir = fullfile(root_dir, 'inputs', 'raw');
bids_dir = '/Users/yiyang/DATA/numMVPA_bids/input/trialtype';%raw correctonly
fmriprep_dir = '/Volumes/ssd/fmriprep';%'/Volumes/ssd/fmriprep'; fullfile(root_dir, 'inputs', 'fmriprep');
% output_dir = fullfile(root_dir, 'outputs', 'derivatives');
output_dir = '/Volumes/ssd/num_output/derivatives';
% model_file = '/Users/yiyang/DATA/numMVPA_fmriprep/code/models/model_nummvpa_eyemovement_smdl.json';
model_file = '/Users/yiyang/DATA/numMVPA_fmriprep/code/models/model-NumMVPA01seqtype_smdl.json';
% model_file = '/Users/yiyang/DATA/numMVPA_fmriprep/code/models/model_nummvpa_eyemovement_excludefalseresp_smdl.json';
%model-defaultNumMVPA01_smdl.json';
preproc_dir = '/Users/yiyang/DATA/numMVPA_fmriprep/outputs/derivatives/bidspm-preproc';
subject_label = {'10','11'};%,'05','06','07','08','09','10','11','12','14',...
    %'15','16','17','18','19','20','21','22','23'};
                %exclude sub13 % 03 11
% subject_label = {'23'};%'09','12','10'
task = {'numMVPA'}; %'wordLocalizer'
space = {'MNI152NLin2009cAsym'};

%% subject level

% run the stats at subject-level
% where the smooth data is
% preproc_dir = fullfile(output_dir, 'bidspm-preproc');
parfor i = 1:length(subject_label)
    bidspm(bids_dir, output_dir, 'subject', ...
           'participant_label', subject_label(i), ...
           'action', 'stats', ...
           'task', task,...
           'preproc_dir', preproc_dir, ...
           'model_file', model_file,...
           'space', space, ...
           'fwhm', 2,...
           'verbosity', 3,...
           'concatenate', true);
end
