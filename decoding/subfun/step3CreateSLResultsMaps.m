function step3CreateSLResultsMaps(conditionName, maps, funcFWHM2Level, opt)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Step 2 was smoothing the SL result maps
% Here Step 3 is producing mean classification accuracy
% and standard deviation map
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% maps = 'beta'% 't_maps';
% funcFWHM = 0 %  2;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin == 0

    maps = opt.mvpa.map4D{2};

    funcFWHM2Level = 8;

end

% get the smoothing of 4D images
funcFWHM = funcFWHM2Level;

% make the prefix for SL output files
prefixSmooth = [spm_get_defaults('smooth.prefix'), num2str(funcFWHM2Level), '_'];

% dummy call for ffxDir
ffxDir = getFFXdir(opt.subjects{1}, opt);
[~, folderName] = fileparts(ffxDir);

% get the folder name to pick files from
resultFolder = fullfile(opt.dir.searchlightout, ...
    [folderName, '_', opt.mask, ...
    '_', opt.mvpa.sphereType, ...
    '-', num2str(opt.mvpa.searchlightVoxelNb), ...
    '_classifier-', opt.mvpa.className]);

for con = 1:length(conditionName)

    for iSub = 1:numel(opt.subjects)


        midFilePattern = [prefixSmooth, 'sub-', opt.subjects{iSub}, '_4D-', maps, ...
            '_', conditionName{con}, '_', ...
            '*.nii'];

        slNiiFile = dir(fullfile(resultFolder, [midFilePattern]));
        slNiiFile([slNiiFile.isdir]) = [];

        % prepare subject full file for spm input
        FullPath = fullfile(slNiiFile(1).folder, ...
            slNiiFile(1).name);

        % save the path +nii files for spm smoothing
        subjFullfile{iSub} = FullPath; %#ok<AGROW>

    end

    disp('Files:');
    for iFile = 1:length(slNiiFile)
        disp([slNiiFile(iFile).name]);
    end

    numSubjects = numel(opt.subjects);
    fprintf('NumSubjects: %i \n', numSubjects);

    % Empty matrix of 4 dimensions (first 3 dimensions are the brain image,
    % the fourth dimention is the subject number)
    z = [];

    % first subject Number
    subjectNb = 1;

    % loop for each subject
    while subjectNb <= numSubjects

        % load the searchlight map
        temp = load_nii(subjFullfile{subjectNb});
        fprintf('Loading of Map %.0f finished. \n', subjectNb);

        % multiply by 100 to get number in percent
        k = temp.img * 100;

        % concatenate each subject to the 4th dimension
        z = cat(4, z, k);

        % increase the counter
        subjectNb = subjectNb + 1;
    end

    %% Mean Accuracy
    % calcuate mean accuracy maps
    % copy structure of one map
    meanMap = temp;

    % erase the values in the image
    meanMap.img = [];

    means = [];

    % Calculate mean of each voxel across subjects (4th dimension)
    means = mean(z, 4);

    meanMap.img = means;

    % save mean accuracy map as nifti map
    save_nii(meanMap, ...
        fullfile(resultFolder, ...
        ['AverageAcc_', ...
        prefixSmooth, ...
        midFilePattern(1:end-5), ...
        '_subNb-', num2str(numSubjects), ...
        '.nii']));

    %% Standard deviation maps
    % copy structure of one map
    stdMap = temp;

    % Calculate standard deviation of each voxel across subjects
    stds = std(z, [], 4);

    stdMap.img = stds;

    % save standard deviation map as nifti map
    save_nii(stdMap, fullfile(resultFolder, ...
        ['StdAcc_', ...
        prefixSmooth, ...
        midFilePattern(1:end-5), ...
        '_subNb-', num2str(numSubjects), ...
        '.nii']));
end
end
