function step2SmoothSLMaps(subID, maps, funcFWHM2Level, opt)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Step 1 was running searchlight analysis
% Here is Step 2, smoothing the SL result maps

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% maps = 'beta'% 't_maps';
% funcFWHM = 0 %  2;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 2

    maps = opt.mvpa.map4D{2};
    funcFWHM2Level = 8;

end

% make the prefix for SL output files
prefixSmooth = [spm_get_defaults('smooth.prefix'), num2str(funcFWHM2Level), '_'];

opt.dir.pathData = fullfile(opt.dir.stats, ...
    ['sub-', subID], ...
    opt.dir.statsTask);
% get the folder name to pick files from
resultFolder = fullfile(opt.dir.searchlightout, ...
    [opt.dir.statsTask, '_', opt.mask, ...
    '_', opt.mvpa.sphereType, ...
    '-', num2str(opt.mvpa.searchlightVoxelNb), ...
    '_classifier-', opt.mvpa.className]);

midFilePattern = ['sub-', subID, '_4D-', maps, ...
    '*.nii'];

slNiiFile = dir(fullfile(resultFolder, [midFilePattern]));
slNiiFile([slNiiFile.isdir]) = [];
searchLightNiftis = cell(size(slNiiFile, 1), 1);

for iFile = 1:size(slNiiFile, 1)

    searchLightNiftis{iFile} = fullfile(resultFolder, slNiiFile(iFile).name);

end

% get rid of the nans
fprintf('Converting zero values to nans\n\n');

for iFile = 1:size(searchLightNiftis, 1)

    % convert 0 to nan in .nii files
    tmp = load_nii(searchLightNiftis{iFile});
    tmp.img(tmp.img == 0) = nan;
    save_nii(tmp, searchLightNiftis{iFile});

end

%% spm batch for smoothing

spm('defaults', 'fmri');
spm_jobman('initcfg');

matlabbatch = [];
matlabbatch{1}.spm.spatial.smooth.data = searchLightNiftis(:); %subjFullfile;
matlabbatch{1}.spm.spatial.smooth.fwhm = [funcFWHM2Level, funcFWHM2Level, funcFWHM2Level];
matlabbatch{1}.spm.spatial.smooth.dtype = 0;
matlabbatch{1}.spm.spatial.smooth.im = 1;
matlabbatch{1}.spm.spatial.smooth.prefix = prefixSmooth;

spm_jobman('run', matlabbatch);

end
