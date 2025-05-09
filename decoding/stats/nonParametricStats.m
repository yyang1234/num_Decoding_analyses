%% statistical significance in mvpa
% non-parametric technique by combining permutations and bootstrapping

% step1:
% For each subject, the labels of the different conditions (eg. motion_vertical and motion_horizontal) were permuted,
% and the same decoding analysis was performed.
% The previous step was repeated 100 times for each subject.

% DONE in our decoding scripts

% step2:
% A bootstrap procedure was applied in order to obtain a group-level null distribution
% that was representative of the whole group.
% From each subject a null distribution, one value was randomly chosen (with replacement)
% and averaged across all participants.
% This step was repeated 100,000 times resulting in a group-level null distribution of 100,000 values.

% step3:
% The statistical significance of the MVPA results was estimated by comparing the observed result
% to the group-level null distribution. This was done by calculating the proportion of observations
% in the null distribution that had a classification accuracy higher than the one obtained in the real test.

% step4:
% To account for the multiple comparisons, all p values were corrected using false discovery rate (FDR) correction
%% set which file, condition and roi label are we testing

clear all;

roiList = {'LhIP4', 'LhIP8', ...
    'LV3A', 'Rprecentral', 'RhIP2', ...
    'RhIP3', 'RhIP4'};

subList = {'02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12', ...
    '14', '15', '16', '17', '18', '19', '20', '21', '22', '23'}; %,
% load the .mat file with decoding accuracies
% to do: laod and merge the .mat file get from parfor loop
filePath = '/Volumes/ssd/num_output/derivatives/CoSMoMVPA/SLeyemove_new/withcorrectedROIs';
filePath = '/Volumes/ssd/num_output/derivatives/CoSMoMVPA/S2_SLeyemove_pseudoruns/S2';
filePattern = '*_numMVPA_cross_formatpseudo-Decoding_SLpTFCE_eyemove_newnew_s2_ratio150_*.mat';
matFiles = dir(fullfile(filePath, filePattern));

for iFile = 22:length(matFiles)
    load(fullfile(matFiles(iFile).folder, matFiles(iFile).name)); %get accu
    eval(['sub', char(subList(iFile-21)), ' = struct2table(accu);']);
end

merge_accu = [sub02; sub03; sub04; sub05; sub06; sub07; sub08; sub09; sub10; ...
    sub11; sub12; sub14; sub15; sub16; sub17; sub18; sub19; sub20; sub21; sub22; sub23];
merge_accu_s = table2struct(merge_accu);
clear sub02 sub03 sub04 sub05 sub06 sub07 sub08 sub09 sub10 ...
    sub11 sub12 sub14 sub15 sub16 sub17 sub18 sub19 sub20 sub21 sub22 sub23

decodTitle = 'aseq_vseq';
decodingConditionList = {'trainvseq_testaseq', 'trainaseq_testvseq', 'aud_seq_vs_vis-seq'};
% decodingConditionList = {'trainvsim_testaseq','trainaseq_testvsim','aud_seq_vs_vis_sim'};
% decodingConditionList = {'trainvsim_testvseq','trainvseq_testvsim','vis-seq_vs_vis_sim'};
%%%% !!IMPORTANT!!MODIFY
decodingCondition = 'trainaseq_testvseq';

decodingType = 'cross_modal';
maskName = 'SLpTFCE_eyemove_new';
im = 'beta';
smooth = '2';
chooseVoxNb = '150';

% number of iterations for group level null distribution
nbIter = 100000; 

groupNullDistr = zeros(length(roiList), nbIter);
subAccu = zeros(length(subList), length(roiList));

for iRoi = 1:length(roiList)
    roiLabel = roiList(iRoi);
    disp(roiList(iRoi))
    %% STEP 1: DONE
    %% STEP 2: create group null distribution
    timeStart = datestr(now, 'HH:MM:DD')
    subSamp = zeros(length(subList), nbIter);
    for iIter = 1:nbIter
        %     disp(iIter)
        for iAccu = 1:length(merge_accu_s)

            for iSub = 1:length(subList)
                subID = subList(iSub);
                if strcmp(char({merge_accu_s(iAccu).subID}.'), char(subID)) == 1
                    %check if all the parameters and conditions match
                    if strcmp(char({merge_accu_s(iAccu).image}.'), im) == 1 && ...
                            strcmp(num2str([merge_accu_s(iAccu).ffxSmooth].'), smooth) == 1 ...
                            && strcmp(num2str([merge_accu_s(iAccu).choosenVoxNb].'), chooseVoxNb) == 1
                        if strcmp(string({merge_accu_s(iAccu).decodingCondition}.'), decodingCondition) == 1
                            if strcmp(string({merge_accu_s(iAccu).mask}.'), roiLabel) == 1

                                %read the subject level permutations = accu(iAccu).permutation;
                                %pick one decoding accuracy randomly with replacement
                                subSamp(iSub, iIter) = datasample(merge_accu_s(iAccu).permutation, 1);

                            end

                        end
                    end
                end
            end
        end
        if iIter == 20000 || iIter == 40000 || iIter == 60000 || iIter == 80000
            disp('1/4 milestone')
        end
    end
    disp(decodingCondition)
    timeEnd = datestr(now, 'HH:MM')
    groupNullDistr(iRoi, :) = mean(subSamp);
    %% STEP 3: check where does the avg accu of the group falls in the group level null ditribution
    % calculate the proportion of values in the group null ditribution which are above the actual decoding
    % accuracy for a one-tailed test. accordingly change for two-tailed test.
    % p = sum(accuracy < acc0) / nbIter; %from Ceren
    % pValue = (sum(Pooled_Perm>accuracy)+1)/(1+NrPermutations); % from Mohamed

    for iAccu = 1:length(merge_accu_s)
        for iSub = 1:length(subList)
            subID = subList(iSub);
            if strcmp(char({merge_accu_s(iAccu).subID}.'), char(subID)) == 1
                %check if all the parameters and conditions match
                if strcmp(char({merge_accu_s(iAccu).image}.'), im) == 1 && ...
                        strcmp(num2str([merge_accu_s(iAccu).ffxSmooth].'), smooth) == 1 ...
                        && strcmp(num2str([merge_accu_s(iAccu).choosenVoxNb].'), chooseVoxNb) == 1
                    if strcmp(string({merge_accu_s(iAccu).decodingCondition}.'), decodingCondition) == 1
                        if strcmp(string({merge_accu_s(iAccu).mask}.'), roiLabel) == 1

                            %read the actual decoding accuracy
                            subAccu(iSub, iRoi) = [merge_accu_s(iAccu).accuracy].';

                        end
                    end
                end
            end
        end
    end

    subObsPVal(iRoi) = sum(mean(subAccu(:, iRoi)) < groupNullDistr(iRoi, :)) / nbIter;
    disp(subObsPVal(iRoi))
end
%% STEP 4: correct the obtained p-value

% function mafdr([vector of pvalues], BHFDR, 'true') % from Stefania
fdrCorrPVal = mafdr(subObsPVal, 'BHFDR', 'true');
% fdrCorrPValBasic=mafdr(subObsPVal);
%% save the outout

% set output folder/name
pathOutput = '/Volumes/ssd/num_output/derivatives/CoSMoMVPA/stats';
savefileMat = fullfile(pathOutput, ...
    [decodingType, '_', 'stats', '_', maskName, '_', decodingCondition, '_', ...
    'vox', chooseVoxNb, '_', im, ...
    '_', datestr(now, 'yyyymmddHHMM'), '.mat']);

%store output
mvpaStats.decodTitle = decodTitle;
mvpaStats.decodCondition = decodingCondition;
mvpaStats.imageType = im;
mvpaStats.roiList = roiList; % this tells the order of corresponding p-values
mvpaStats.groupNullDistr = groupNullDistr; % the rows are in the order of Roi list
mvpaStats.subAccu = subAccu;
mvpaStats.obsPVal = subObsPVal; % in the order of roi list
mvpaStats.fdrCorPVal = fdrCorrPVal;

% mat file
save(savefileMat, 'mvpaStats');