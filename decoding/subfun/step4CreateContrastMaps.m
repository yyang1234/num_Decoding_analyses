function step4CreateContrastMaps(condition, maps, funcFWHM2Level)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Step 3 was producing mean classification accuracy
% and standard deviation map
% Here Step 4 is omitting the change level from the maps and make
% contrast maps
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% maps = 'beta'% 't_maps';
% funcFWHM = 0 %  2;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

opt = getOptionSearchlight();
modalityLabelName = {'aud_num', 'aud_seq', 'vis_num', 'vis_seq', 'vis_sim'};

if nargin == 0

    maps = opt.mvpa.map4D{2};

    funcFWHM2Level = 8;

end

% get the smoothing of 4D images
funcFWHM = opt.fwhm.func;

% make the prefix for SL output files
prefixSmooth = [spm_get_defaults('smooth.prefix'), num2str(funcFWHM2Level), '_'];

%   % define where the sl files are
%   pathInput = fullfile(opt.pathOutput, 'derivatives');

% we do binary decoding, so the chance is 50%
chanceLevel = 25;

% dummy call for ffxDir
ffxDir = getFFXdir(opt.subjects{1}, opt);
[~, folderName] = fileparts(ffxDir);

% get the folder name to pick files from
resultFolder = fullfile(opt.dir.searchlightout, ...
    [folderName, '_', opt.mask, ...
    '_', opt.mvpa.sphereType, ...
    '-', num2str(opt.mvpa.searchlightVoxelNb), ...
    '_classifier-', opt.mvpa.className]);

for i = 1:length(modalityLabelName)

    %   midFilePattern = ['4D-', maps, ...
    %                     '_', modalityLabelName{i}, '_', ...
    %                     'radius-', num2str(opt.mvpa.searchlightVoxelNb), '*.nii'];
    %
    %
    %   % read smoothed files only
    %   slNiiFile = dir(fullfile(resultFolder, [prefixSmooth, '*_', midFilePattern]));
    %   slNiiFile([slNiiFile.isdir]) = [];


    % load the files to create contrast maps
    for iSub = 1:numel(opt.subjects)

        midFilePattern = ['sub-', opt.subjects{iSub}, '_4D-', maps, ...
            '_', modalityLabelName{i}, '_', ...
            '*.nii'];

        slNiiFile = dir(fullfile(resultFolder, [prefixSmooth, midFilePattern]));
        slNiiFile([slNiiFile.isdir]) = [];

        % prepare subject full file for spm input
        FullPath = fullfile(slNiiFile(1).folder, ...
            slNiiFile(1).name);

        % save the path +nii files for creating contrast maps
        subjFullfile{iSub} = FullPath; %#ok<AGROW>

    end

    disp('Files:');
    for iFile = 1:length(slNiiFile)
        disp([slNiiFile(iFile).name]);
    end

    % extract total subject number
    totalSubNb = numel(opt.subjects);
    fprintf('NumSubjects: %i \n', totalSubNb);

    % load individual accuracy maps from each subject
    iSub = 1;

    % loop for each subject
    while iSub <= totalSubNb

        % get subject label
        subLabel = opt.subjects{iSub};

        % load the searchlight map
        temp = load_nii(subjFullfile{iSub});

        % calculate accuracies (max 100)
        accuracies = temp.img * 100;

        % extract the chance level
        accuracies(accuracies > 0) = accuracies(accuracies > 0) - chanceLevel;

        %     % omit the zeros don't use this scripts otherwise there are lots of
        %     holes
        accuracies(accuracies == 0) = nan;

        % assign accuracies into new map
        con = accuracies;

        % init a dummy .nii skeleton
        con_map = temp;

        % delete the .img values
        con_map.img = [];

        % assign con values into .img
        con_map.img = con;

        % save mean accuracy map as nifti map
        save_nii(con_map, ...
            fullfile(resultFolder, ...
            ['conMap_', ...
            prefixSmooth, ...
            ['sub-', subLabel, '_'], ...
            midFilePattern(8:end-6), ...
            '.nii']));

        % increase subject the counter
        iSub = iSub + 1;

    end

    % cd(WD);

end
