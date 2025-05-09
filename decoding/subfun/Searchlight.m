function info = Searchlight(opt, subID, iSub)

% get the smoothing parameter for 4D map
funcFWHM = opt.fwhm.func;

% choose masks to be used
opt = mvpa_chooseMask(opt);
%get opt.maskname & opt.masklabel
%% set output folder/name
savefileMatName = ['sub-', subID, '_', ...
    char(opt.taskName), ...
    '_SL_', ...
    opt.mask, ...
    '_s', num2str(funcFWHM), ...
    '_space-', char(opt.space), ...
    '_', opt.mvpa.sphereType, ...
    '-', num2str(opt.mvpa.searchlightVoxelNb), ...
    '_classifier-', opt.mvpa.className, ...
    '_', datestr(now, 'yyyymmddHHMM'), '.mat'];
%% let's get going!

% set structure array for keeping the results
info = struct( ...
    'subID', [], ...
    'mask', [], ...
    'decodingCondition', [], ...
    'maskVoxNb', [], ...
    'searchlightVoxelNb', [], ...
    'image', [], ...
    'ffxSmooth', [], ...
    'roiSource', [], ...
    'imagePath', []);

decodingCondition = {'aud_num', 'aud_seq', 'vis_num', 'vis_seq', 'vis_sim'};

count = 1;

fprintf(['\n\n\nSub', subID, ' is  being processed ....\n']);

opt.dir.pathData = fullfile(opt.dir.stats, ...
    ['sub-', subID], ...
    opt.dir.statsTask);

% create folder for output
resultFolder = fullfile(opt.dir.searchlightout, ...
    [opt.dir.statsTask, '_', opt.mask, ...
    '_', opt.mvpa.sphereType, ...
    '-', num2str(opt.mvpa.searchlightVoxelNb), ...
    '_classifier-', opt.mvpa.className]);
if ~exist(resultFolder, 'dir')
    mkdir(resultFolder);
end

% loop through different 4D images
for iImage = 1:length(opt.mvpa.map4D)

    for iMask = 1:length(opt.maskName)

        %individual mask
        if strcmp(opt.mask, 'IPS') || strcmp(opt.mask, 'temporal')
            mask = fullfile(opt.dir.rois, subFolder, opt.mask, ['sub-', char(subID), opt.maskName{iMask}]);
        else
            if strcmp(opt.mask, 'visual') || strcmp(opt.mask, 'auditory')
                mask = fullfile(opt.dir.rois, subFolder, opt.mask, ['sub', char(subID), opt.maskName{iMask}]);
            else
                mask = fullfile(opt.dir.rois, opt.maskName{iMask}); %group mask
            end
        end

        % display the used mask
        disp(opt.maskName{iMask});

        % 4D image
        imageName = ['sub-', num2str(subID), ...
            '_task-', char(opt.taskName), ...
            '_space-', char(opt.space), '_desc-4D_', ...
            opt.mvpa.map4D{iImage}, '.nii'];
        image = fullfile(opt.dir.pathData, imageName);

        %extract decoding conditions and set stimuli
        [condLabelName, condLabelNb, decodingPairs] = mvpa_assignDecodingConditions(opt);

        for pair = 1:size(decodingPairs, 1)

            % load cosmo input
            ds = cosmo_fmri_dataset(image, 'mask', mask);

            % Getting rid off zeros
            zeroMask = all(ds.samples == 0, 1);
            ds = cosmo_slice(ds, ~zeroMask, 2);

            % calculate the mask size
            maskVoxel = size(ds.samples, 2);

            % set cosmo structure
            ds = setCosmoStructure(opt, ds, condLabelNb, condLabelName, iSub);

            ds = cosmo_slice(ds, ds.sa.targets == decodingPairs(pair, 1) | ...
                ds.sa.targets == decodingPairs(pair, 2) | ...
                ds.sa.targets == decodingPairs(pair, 3) | ...
                ds.sa.targets == decodingPairs(pair, 4));

            % remove constant features
            ds = cosmo_remove_useless_data(ds);

            maskVoxel = size(ds.samples, 2);

            % partitioning, for test and training : cross validation
            % can be different e.g. cosmo_oddeven_partitioner(ds_per_run)
            opt.mvpa.partitions = cosmo_nfold_partitioner(ds);


            % define a neightborhood
            nbrhood = cosmo_spherical_neighborhood(ds, ...
                opt.mvpa.sphereType, ...
                opt.mvpa.searchlightVoxelNb);
            %cosmo_disp(nbrhood);

            % Run the searchlight
            svm_results = cosmo_searchlight(ds, ...
                nbrhood, ...
                opt.mvpa.measure, ...
                opt.mvpa);

            % store the relevant info
            info(count).subID = subID;
            info(count).mask = opt.maskLabel{iMask};
            info(count).maskVoxNb = maskVoxel;
            info(count).searchlightVoxelNb = opt.mvpa.searchlightVoxelNb;
            info(count).image = opt.mvpa.map4D{iImage};
            info(count).ffxSmooth = funcFWHM;
            info(count).roiSource = opt.mask;
            info(count).imagePath = image;
            accu(count).decodingCondition = decodingCondition{pair};

            count = count + 1;

            % Store results to disc
            savingResultFile = fullfile(resultFolder, ...
                [['sub-', subID], ...
                '_4D-', opt.mvpa.map4D{iImage}, ...
                '_', decodingCondition{pair}, ...
                '_', opt.mvpa.sphereType, ...
                '-', num2str(opt.mvpa.searchlightVoxelNb), ...
                '_', datestr(now, 'yyyymmddHHMM'), '.nii']);

            cosmo_map2fmri(svm_results, savingResultFile);
        end
    end
end
% end

%% save output
% mat file
savefileMat = fullfile(resultFolder, savefileMatName);
save(savefileMat, 'info');

end
