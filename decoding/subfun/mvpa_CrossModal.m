function accu = mvpa_CrossModal(opt, subID, iSub)

% main function which loops through masks and subjects to calculate the
% decoding accuracies for given conditions.
% dependant on SPM + CPP_SPM and CosMoMvpa toolboxes
% the output is compatible for R visualisation, it gives .csv file as well
% as .mat file

% get the smoothing parameter for 4D map
funcFWHM = opt.fwhm.func;
opt.decodingCondition = {'cross-modal'};

% choose masks to be used
opt = mvpa_chooseMask(opt);

for i = 1:length(opt.featuresele_vx)

    opt.mvpa.ratioToKeep = opt.featuresele_vx(i);

    % set output folder/name
    savefileMat = fullfile(opt.dir.cosmo, ...
        [char(subID), '_', ...
        char(opt.taskName), '_', ...
        char(opt.decodingCondition), ...
        'Decoding_', ...
        opt.mask, ...
        '_s', num2str(funcFWHM), ...
        '_ratio', num2str(opt.mvpa.ratioToKeep), ...
        '_', datestr(now, 'yyyymmddHHMM'), '.mat']);

    savefileCsv = fullfile(opt.dir.cosmo, ...
        [char(subID), '_', ...
        char(opt.taskName), '_', ...
        char(opt.decodingCondition), ...
        'Decoding_', ...
        opt.mask, ...
        '_s', num2str(funcFWHM), ...
        '_ratio', num2str(opt.mvpa.ratioToKeep), ...
        '_', datestr(now, 'yyyymmddHHMM'), '.csv']);
    %% MVPA options

    % set cosmo mvpa structure
    condLabelNb = [1, 2, 3, 4];
    condLabelName = {'2', '3', '4', '5'};
    modalityLabelName = {'aud_num', 'aud_seq', 'vis_num', 'vis_seq', 'vis_sim'};
    modalityLabelNb = [1, 2, 3, 4, 5];
    modalityPairs = [2, 4; 2, 5; 4, 5];
    labels = {'aud_num', 'aud_seq', 'vis_num', 'vis-seq', ...
        'vis_sim'};
    decodingConditionList = {'trainvseq_testaseq', 'trainaseq_testvseq'; ...
        'trainvsim_testaseq', 'trainaseq_testvsim'; ...
        'trainvsim_testvseq', 'trainvseq_testvsim'};
    %% let's get going!

    % set structure array for keeping the results
    accu = struct( ...
        'subID', [], ...
        'mask', [], ...
        'accuracy', [], ...
        'prediction', [], ...
        'maskVoxNb', [], ...
        'choosenVoxNb', [], ...
        'image', [], ...
        'ffxSmooth', [], ...
        'roiSource', [], ...
        'decodingCondition', [], ...
        'permutation', [], ...
        'imagePath', []);

    count = 1;


    opt.dir.pathData = fullfile(opt.dir.stats, ...
        ['sub-', subID], ...
        opt.dir.statsTask);

    % get subject folder name
    subFolder = ['sub-', subID];

    for iImage = 1:length(opt.mvpa.map4D)

        %             subMasks = opt.maskName(startsWith(opt.maskName,...
        %                    strcat('sub-', subID)));

        for iMask = 1:length(opt.maskName)

            mask = fullfile(opt.dir.rois, opt.maskName{iMask});

            if isfile(mask)

                % display the used mask
                disp(opt.maskName{iMask});

                % 4D image
                imageName = ['sub-', num2str(subID), ...
                    '_task-', char(opt.taskName), ...
                    '_space-', char(opt.space), '_desc-4D_', ...
                    opt.mvpa.map4D{iImage}, '.nii'];
                image = fullfile(opt.dir.pathData, imageName);

                for iModality = 1:length(modalityPairs) % see the types in decoding conditionlist

                    for iTest = 1:3 %1: train first test second 2: train second test first 3: do both and get average results

                        if iTest == 1 || iTest == 2
                            test = modalityPairs(iModality, iTest);
                            decodingCondition = decodingConditionList{iModality, iTest};
                        else
                            test = [];
                            decodingCondition = [labels{modalityPairs(iModality, 1)}, '_vs_', ...
                                labels{modalityPairs(iModality, 2)}];
                        end

                        % load cosmo input
                        ds = cosmo_fmri_dataset(image, 'mask', mask);

                        % Getting rid off zeros
                        zeroMask = all(ds.samples == 0, 1);
                        ds = cosmo_slice(ds, ~zeroMask, 2);

                        % set cosmo structure
                        ds = c_setCosmoStructure(opt, ds, condLabelNb, condLabelName, ...
                            modalityLabelNb, modalityLabelName, iSub);

                        % Demean  every pattern to remove univariate effect differences
                        meanPattern = nanmean(ds.samples, 2); % get the mean for every pattern
                        meanPattern = repmat(meanPattern, 1, size(ds.samples, 2)); % make a matrix with repmat
                        ds.samples = ds.samples - meanPattern; % remove the mean from every every point in each pattern

                        % Slice the dataset accroding to modality
                        ds = cosmo_slice(ds, ds.sa.modality == modalityPairs(iModality, 1) | ...
                            ds.sa.modality == modalityPairs(iModality, 2));

                        ds = cosmo_slice(ds, strcmp(ds.sa.labels, '2') | strcmp(ds.sa.labels, '3') ...
                            | strcmp(ds.sa.labels, '4') | strcmp(ds.sa.labels, '5'));

                        % remove constant features
                        ds = cosmo_remove_useless_data(ds);

                        % calculate the mask size
                        maskVoxel = size(ds.samples, 2);

                        % partitioning, for test and training : cross validation
                        partitions = cosmo_nchoosek_partitioner(ds, 1, 'modality', test);

                        % use the ratios, instead of the voxel number:
                        opt.mvpa.feature_selection_ratio_to_keep = opt.mvpa.ratioToKeep;

                        % ROI mvpa analysis
                        [pred, accuracy] = cosmo_crossvalidate(ds, ...
                            @cosmo_classify_meta_feature_selection, ...
                            partitions, opt.mvpa);

                        %% store output
                        accu(count).subID = subID;
                        accu(count).mask = opt.maskLabel{iMask};
                        accu(count).maskVoxNb = maskVoxel;
                        accu(count).choosenVoxNb = opt.mvpa.feature_selection_ratio_to_keep;
                        % accu(count).choosenVoxNb = round(maskVoxel * maxRatio);
                        % accu(count).maxRatio = maxRatio;
                        accu(count).image = opt.mvpa.map4D{iImage};
                        accu(count).ffxSmooth = funcFWHM;
                        accu(count).accuracy = accuracy;
                        accu(count).prediction = pred;
                        accu(count).imagePath = image;
                        %         accu(count).roiSource = roiSource;
                        accu(count).decodingCondition = decodingCondition;

                        %% PERMUTATION PART
                        if opt.mvpa.permutate == 1
                            % number of iterations
                            nbIter = 100;

                            % allocate space for permuted accuracies
                            acc0 = zeros(nbIter, 1);

                            % make a copy of the dataset
                            ds0 = ds;

                            % for _niter_ iterations, reshuffle the labels and compute accuracy
                            % Use the helper function cosmo_randomize_targets
                            for k = 1:nbIter
                                % manaully randomize the targets (because of cross-modal error)
                                % In every modality seperatly and in every chunk,
                                % randomize the directions

                                for iChunk = 1:length(unique(ds.sa.chunks))
                                    for iTestModality = 1:length(unique(ds.sa.modality))
                                        indMod = unique(ds.sa.modality);
                                        ds0.sa.targets(ds.sa.chunks == iChunk & ...
                                            ds.sa.modality == indMod(iTestModality)) = ...
                                            Shuffle(ds.sa.targets(ds.sa.chunks == iChunk & ...
                                            ds.sa.modality == indMod(iTestModality)));
                                    end
                                end

                                [~, acc0(k)] = cosmo_crossvalidate(ds0, ...
                                    @cosmo_classify_meta_feature_selection, ...
                                    partitions, opt.mvpa);
                            end

                            p = sum(accuracy < acc0) / nbIter;
                            fprintf('%d permutations: accuracy=%.3f, p=%.4f\n', nbIter, accuracy, p);

                            % save permuted accuracies
                            accu(count).permutation = acc0';
                        end

                        % increase the counter and allons y!
                        count = count + 1;

                        fprintf(['Sub', subID, ' - area: ', opt.maskLabel{iMask}, ...
                            ', accuracy: ', num2str(accuracy), ',', decodingCondition, '\n\n\n']);

                    end
                end
            else
                disp('dont exist skip')
            end
        end
    end

    %% save output

    % mat file
    save(savefileMat, 'accu');

    % csv but with important info for plotting
    csvAccu = rmfield(accu, 'permutation');
    csvAccu = rmfield(csvAccu, 'prediction');
    csvAccu = rmfield(csvAccu, 'imagePath');
    writetable(struct2table(csvAccu), savefileCsv);

end
end