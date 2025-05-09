% Variance partitioning. Look for word 'edit' to edit the lines below. Also
% find %%%%% to read comments

clear
clc

%%%%% load all models here - edit

load( ...
    '/Users/yiyang/DATA/numMVPA_bids/code/mvpa/rsa/rsa_model_exploration/form_num_Model_05.mat'); % get seq_Model
load( ...
    '/Users/yiyang/DATA/numMVPA_bids/code/mvpa/rsa/rsa_model_exploration/cond_num_Model_05.mat'); % get cond_Model
load( ...
    '/Users/yiyang/DATA/numMVPA_bids/code/mvpa/rsa/rsa_model_exploration/mod_num_Model_05.mat'); % get num_Model
load( ...
    '/Users/yiyang/DATA/numMVPA_fmriprep/outputs/derivatives/rsa_mreyenew/corrMatDTD_new.mat');

%% Calculate Rsquared at each timepoint

% condition model
vect_cond = squareform(cond_num_Model_05)';

% % sequential model
vect_form = squareform(form_num_Model_05)';

% % visual model
vect_mod = squareform(mod_num_Model_05)';

% combination of predictors to calculate Rsq - edit if dont have 3 models
vect = {vect_cond, vect_form, vect_mod}; % all predictors
combn = {1, 2, 3, [1, 2], [1, 3], [2, 3], [1, 2, 3]};
% begin loop
nsub = 21;
for cc = 1:length(combn)

    for iRoi = 1:size(corrMat, 1)
        for sub = 1:size(corrMat, 2)

            vect_fmri = 1 - corrMat{iRoi, sub};

            mdl = fitglm(zscore([vect{combn{cc}}]), zscore(vect_fmri));

            var.r2_adj(cc, sub, iRoi) = mdl.Rsquared.Adjusted;
            var.r2_ord(cc, sub, iRoi) = mdl.Rsquared.Ordinary;
        end

    end

    cc
end

var.r2_adj = squeeze(nanmean(var.r2_adj, 2)); % mean rsq across subj
var.r2_ord = squeeze(nanmean(var.r2_ord, 2)); % mean rsq across subj

%% Commonality analysis
c = [];
for iRoi = 1:size(corrMat, 1)

    c(7, iRoi) = var.r2_ord(1, iRoi) + var.r2_ord(2, iRoi) + var.r2_ord(3, iRoi) ...
        -var.r2_ord(4, iRoi) - var.r2_ord(5, iRoi) - var.r2_ord(6, iRoi) ...
        +var.r2_ord(7, iRoi);

    c(4, iRoi) = var.r2_ord(5, iRoi) + var.r2_ord(6, iRoi) - var.r2_ord(3, iRoi) - var.r2_ord(7, iRoi); 
    c(5, iRoi) = var.r2_ord(4, iRoi) + var.r2_ord(6, iRoi) - var.r2_ord(2, iRoi) - var.r2_ord(7, iRoi);
    c(6, iRoi) = var.r2_ord(4, iRoi) + var.r2_ord(5, iRoi) - var.r2_ord(1, iRoi) - var.r2_ord(7, iRoi);

    c(1, iRoi) = var.r2_ord(7, iRoi) - var.r2_ord(6, iRoi); % U1
    c(2, iRoi) = var.r2_ord(7, iRoi) - var.r2_ord(5, iRoi); % U2
    c(3, iRoi) = var.r2_ord(7, iRoi) - var.r2_ord(4, iRoi); % U3

    c_tot(iRoi) = c(1, iRoi) + c(2, iRoi) + c(3, iRoi);
end
