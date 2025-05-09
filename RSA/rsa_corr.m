%% model summation
clear
clc

load( ...
    '/Users/yiyang/DATA/numMVPA_fmriprep/outputs/derivatives/rsa_mreyenew/corrMatDTD_new.mat');
load( ...
    '/Users/yiyang/DATA/numMVPA_bids/code/mvpa/rsa/rsa_model_exploration/cond_num_Model_05.mat'); % get seq_Model
load( ...
    '/Users/yiyang/DATA/numMVPA_bids/code/mvpa/rsa/rsa_model_exploration/form_num_Model_05.mat'); % get seq_Model
load( ...
    '/Users/yiyang/DATA/numMVPA_bids/code/mvpa/rsa/rsa_model_exploration/mod_num_Model_05.mat'); % get vis_Model

cond_num = squareform(cond_num_Model_05)';
form_num = squareform(form_num_Model_05)';
mod_num = squareform(mod_num_Model_05)';

for iRoi = 1:size(corrMat, 1) 
    for sub = 1:size(corrMat, 2) 

        vect_fmri = 1 - corrMat{iRoi, sub}; 

        conNumModel_corr(sub, :) = corr(vect_fmri, cond_num, 'type', 'Spearman');
        formNumModel_corr(sub, :) = corr(vect_fmri, form_num, 'type', 'Spearman');
        modNumModel_corr(sub, :) = corr(vect_fmri, mod_num, 'type', 'Spearman');

        % noise ceiling
        % 1. z-transform single subject RDMs
        ztrans_vect = zscore(vect_fmri);
        ztrans_vect_group = zscore(1-cell2mat(corrMat(iRoi, :)), [], 1); %zscore(X,flag,dim)) 66*20
        %upperbound
        upperBound(sub) = corr(ztrans_vect, mean(ztrans_vect_group, 2), 'type', 'Spearman');

        %lowerbound
        %get rid of dsm from current sub
        groupDsm_zscored_leftout = ztrans_vect_group;
        groupDsm_zscored_leftout(:, sub) = [];
        groupDsm_zscored_leftout_mean = mean(groupDsm_zscored_leftout, 2);
        lowerBound(sub) = corr(ztrans_vect, groupDsm_zscored_leftout_mean, 'type', 'Spearman');

    end

    conNumModel_corr_median(iRoi) = median(conNumModel_corr);
    formNumModel_corr_median(iRoi) = median(formNumModel_corr);
    modNumModel_corr_median(iRoi) = median(modNumModel_corr);

    conNumModel_corr_group(:, iRoi) = conNumModel_corr;
    formNumModel_corr_group(:, iRoi) = formNumModel_corr;
    modNumModel_corr_group(:, iRoi) = modNumModel_corr;

    upperBound_mean(iRoi) = mean(upperBound);
    lowerBound_mean(iRoi) = mean(lowerBound);

end
%% do stats
% for each ROI, test significance of three models
% for wilcoxon signed-rank test, W rbc and p value should be report
for iRoi = 1:10

    conNum = conNumModel_corr_group(:, iRoi);
    formNum = formNumModel_corr_group(:, iRoi);
    modNum = modNumModel_corr_group(:, iRoi);
    % calculate difference
    diff_conNum = conNum - 0;
    diff_formNum = formNum - 0;
    diff_modNum = modNum - 0;
    diff_con_form = conNum - formNum;
    diff_con_mod = conNum - modNum;
    diff_form_mod = formNum - modNum;
    %absolute value of difference
    abs_diff_conNum = abs(diff_conNum);
    abs_diff_formNum = abs(diff_formNum);
    abs_diff_modNum = abs(diff_modNum);
    abs_diff_con_form = abs(diff_con_form);
    abs_diff_con_mod = abs(diff_con_mod);
    abs_diff_form_mod = abs(diff_form_mod);
    %rank the abs value in ascending order
    [~, rank1] = sort(abs_diff_conNum, 'ascend');
    [~, rank2] = sort(abs_diff_formNum, 'ascend');
    [~, rank3] = sort(abs_diff_modNum, 'ascend');
    [~, rank4] = sort(abs_diff_con_form, 'ascend');
    [~, rank5] = sort(abs_diff_con_mod, 'ascend');
    [~, rank6] = sort(abs_diff_form_mod, 'ascend');
    % sum rank based on sign and w is the smaller value
    WValue(1, iRoi) = min(sum(rank1(diff_conNum > 0)), sum(rank1(diff_conNum < 0)));
    WValue(2, iRoi) = min(sum(rank2(diff_formNum > 0)), sum(rank2(diff_formNum < 0)));
    WValue(3, iRoi) = min(sum(rank3(diff_modNum > 0)), sum(rank3(diff_modNum < 0)));
    WValue(4, iRoi) = min(sum(rank4(diff_con_form > 0)), sum(rank4(diff_con_form < 0)));
    WValue(5, iRoi) = min(sum(rank5(diff_con_mod > 0)), sum(rank5(diff_con_mod < 0)));
    WValue(6, iRoi) = min(sum(rank6(diff_form_mod > 0)), sum(rank6(diff_form_mod < 0)));

    % 1. test correlation against 0
    [p(1, iRoi), h(1, iRoi), stats1] = signrank(conNum, 0);
    [p(2, iRoi), h(2, iRoi), stats2] = signrank(formNum, 0);
    [p(3, iRoi), h(3, iRoi), stats3] = signrank(modNum, 0);

    % 2. test between models
    [p(4, iRoi), h(4, iRoi), stats4] = signrank(conNum, formNum);
    [p(5, iRoi), h(5, iRoi), stats5] = signrank(conNum, modNum);
    [p(6, iRoi), h(6, iRoi), stats6] = signrank(formNum, modNum);

    p(1:3, iRoi) = mafdr(p(1:3, iRoi), 'BHFDR', 'true');
    p(4:6, iRoi) = mafdr(p(4:6, iRoi), 'BHFDR', 'true');

    zval(1, iRoi) = stats1.zval;
    zval(2, iRoi) = stats2.zval;
    zval(3, iRoi) = stats3.zval;
    zval(4, iRoi) = stats4.zval;
    zval(5, iRoi) = stats5.zval;
    zval(6, iRoi) = stats6.zval;

    signedrank(1, iRoi) = stats1.signedrank;
    signedrank(2, iRoi) = stats2.signedrank;
    signedrank(3, iRoi) = stats3.signedrank;
    signedrank(4, iRoi) = stats4.signedrank;
    signedrank(5, iRoi) = stats5.signedrank;
    signedrank(6, iRoi) = stats6.signedrank;

    Rbc(1, iRoi) = WValue(1, iRoi) / (21 * 22 / 2); %rbc=(w/n*(n+1)/2)
    Rbc(2, iRoi) = WValue(2, iRoi) / (21 * 22 / 2); %rbc=(w/n*(n+1)/2)
    Rbc(3, iRoi) = WValue(3, iRoi) / (21 * 22 / 2); %rbc=(w/n*(n+1)/2)
    Rbc(4, iRoi) = WValue(4, iRoi) / (21 * 22 / 2); %rbc=(w/n*(n+1)/2)
    Rbc(5, iRoi) = WValue(5, iRoi) / (21 * 22 / 2); %rbc=(w/n*(n+1)/2)
    Rbc(6, iRoi) = WValue(6, iRoi) / (21 * 22 / 2); %rbc=(w/n*(n+1)/2)

end

%%% bar plor model correlation
maskLabel = {'LhIP4', 'LhIP8', ...
            'LV3A', 'Rprecentral', 'RhIP2', ...
            'RhIP3', 'RhIP4'};
orangeC = [220, 118, 51] / 255; % RGB value for orange
lightO = [225, 178, 102] / 255;
darkO = [204, 102, 0] / 255;
blueC = [93, 173, 226] / 255;
lightB = [102, 178, 255] / 255;
darkB = [0, 102, 204] / 255;
greenC = [82, 190, 128] / 255;
purpleC = [175, 122, 197] / 255;
lightP = [178, 102, 255] / 255;
darkP = [102, 0, 204] / 255;
darkGray = [86, 101, 115] / 255;

jitterAmount = 0.2;
%settings for plots
shape = 'o';
%%set the size of the shape
sz = 90;
%%set the width of the edge of the markers
LineWidthMarkers = 1.5;

for i = 1:length(maskLabel)
    figure();

    fig = bar([conNumModel_corr_median(i), formNumModel_corr_median(i), ...
        modNumModel_corr_median(i)], 'grouped', ...
        'FaceColor', 'none', ...
        'EdgeColor', 'flat', 'BarWidth', 0.8, 'LineWidth', 3.5);

    fig.CData(1, :) = blueC;
    fig.CData(2, :) = orangeC;
    fig.CData(3, :) = purpleC;
    fig.ShowBaseLine = 'off';
    hold on

    rectangle(Position = [0, lowerBound_mean(i), 4, upperBound_mean(i) - lowerBound_mean(i)], ...
        FaceColor = [0.9, 0.9, 0.9], EdgeColor = [0.9, 0.9, 0.9])
    hold on

    %plot scatter
    scatter(1, conNumModel_corr_group(:, i), sz, lightB, shape, ...
        'LineWidth', LineWidthMarkers, 'jitter', 'on', 'jitterAmount', jitterAmount, 'MarkerEdgeAlpha', 1);
    scatter(2, formNumModel_corr_group(:, i), sz, lightO, shape, ...
        'LineWidth', LineWidthMarkers, 'jitter', 'on', 'jitterAmount', jitterAmount, 'MarkerEdgeAlpha', 1);
    scatter(3, modNumModel_corr_group(:, i), sz, lightP, shape, ...
        'LineWidth', LineWidthMarkers, 'jitter', 'on', 'jitterAmount', jitterAmount, 'MarkerEdgeAlpha', 1);

    h = gca;
    h.YAxis.FontSize = 30;
    h.XAxis.Visible = 'off';
    h.YAxis.TickLength = [0, 0];
    box off;
    set(gca, 'ylim', [-0.1, 0.9]); set(gca, 'ytick', -0:0.4:0.9)
    xPosition = [0.90, 1.90, 2.90];
    myColor = [darkB; darkO; darkP];
    set(gca, 'linewidth', 6)
    for ROIsig = 1:3
        if p(ROIsig, i) < 0.05
            text(xPosition(ROIsig), 0, '*', FontSize = 60, Color = myColor(ROIsig, :));
        end
    end

    % add line between bars
    ycoords = [0.83, 0.83; 0.86, 0.86; 0.89, 0.89];
    xcoords = [1, 2; 1, 3; 2, 3];
    for ROIdiffsig = 4:6
        if p(ROIdiffsig, i) < 0.05 && p(ROIdiffsig, i) > 0.001
            line(xcoords(ROIdiffsig-3, :), ycoords(ROIdiffsig-3, :), 'color', darkGray, 'LineWidth', 2.7, 'LineStyle', "--");
        else
            if p(ROIdiffsig, i) < 0.001
                line(xcoords(ROIdiffsig-3, :), ycoords(ROIdiffsig-3, :), 'color', darkGray, 'LineWidth', 2.7);
            end
        end
    end

        exportgraphics(gca,...
        ['/Users/yiyang/DATA/numMVPA_bids/code/mvpa/rsa/final_figure/correlation_final/' maskLabel{i} 'withsigstar_final_corr_median.png'],...
        'Resolution',300)
end
