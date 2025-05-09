clear
clc

load( ...
    '/Users/yiyang/DATA/numMVPA_bids/code/mvpa/rsa/rsa_model_exploration/form_num_Model_05.mat'); % get seq_Model
load( ...
    '/Users/yiyang/DATA/numMVPA_bids/code/mvpa/rsa/rsa_model_exploration/cond_num_Model_05.mat'); % get cond_Model
load( ...
    '/Users/yiyang/DATA/numMVPA_bids/code/mvpa/rsa/rsa_model_exploration/mod_num_Model_05.mat'); % get num_Model
load( ...
    '/Users/yiyang/DATA/numMVPA_fmriprep/outputs/derivatives/rsa_mreyenew/corrMatDTD_new.mat');

cond_num = squareform(cond_num_Model_05)';
form_num = squareform(form_num_Model_05)';
mod_num = squareform(mod_num_Model_05)';

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
maskLabel = {'LhIP4', 'LhIP8', ...
            'LV3A', 'Rprecentral', 'RhIP2', ...
            'RhIP3', 'RhIP4'};

%% do partial correlation
for iRoi = 61:size(corrMat, 1)
    for sub = 1:size(corrMat, 2)
        mtrx_fmri = 1 - corrMat{iRoi, sub}; % vector
        [r_cond(sub, iRoi), p_cond(sub, iRoi)] = partialcorr(mtrx_fmri, cond_num, [form_num, mod_num]);
        [r_form(sub, iRoi), p_form(sub, iRoi)] = partialcorr(mtrx_fmri, form_num, [cond_num, mod_num]);
        [r_mod(sub, iRoi), p_mod(sub, iRoi)] = partialcorr(mtrx_fmri, mod_num, [cond_num, form_num]);
    end

    % get median
    conNumModel_corr_median(iRoi) = median(r_cond(:, iRoi));
    formNumModel_corr_median(iRoi) = median(r_form(:, iRoi));
    modNumModel_corr_median(iRoi) = median(r_mod(:, iRoi));
    % test corr coef against zero
    [p(1, iRoi), h(1, iRoi), stats1] = signrank(r_cond(:, iRoi), 0);
    [p(2, iRoi), h(2, iRoi), stats2] = signrank(r_form(:, iRoi), 0);
    [p(3, iRoi), h(3, iRoi), stats3] = signrank(r_mod(:, iRoi), 0);
    p_corr(:, iRoi) = mafdr(p(:, iRoi), 'BHFDR', 'true');
    % test corr coef diff
    [p_diff(1, iRoi), h_diff(1, iRoi), stats1_diff] = signrank(r_cond(:, iRoi), r_form(:, iRoi));
    [p_diff(2, iRoi), h_diff(2, iRoi), stats2_diff] = signrank(r_cond(:, iRoi), r_mod(:, iRoi));
    [p_diff(3, iRoi), h_diff(3, iRoi), stats3_diff] = signrank(r_form(:, iRoi), r_mod(:, iRoi));
    p_groupdiff(:, iRoi) = mafdr(p_diff(:, iRoi), 'BHFDR', 'true');

    figure();

    fig = bar([median(r_cond(:, iRoi)); median(r_form(:, iRoi)); median(r_mod(:, iRoi))], 'grouped', ...
        'FaceColor', 'none', ...
        'EdgeColor', 'flat', 'BarWidth', 0.8, 'LineWidth', 3.5);

    fig.CData(1, :) = blueC;
    fig.CData(2, :) = orangeC;
    fig.CData(3, :) = purpleC;
    fig.ShowBaseLine = 'off';
    hold on

    %plot scatter
    scatter(1, r_cond(:, iRoi), sz, lightB, shape, ...
        'LineWidth', LineWidthMarkers, 'jitter', 'on', 'jitterAmount', jitterAmount, 'MarkerEdgeAlpha', 1);
    scatter(2, r_form(:, iRoi), sz, lightO, shape, ...
        'LineWidth', LineWidthMarkers, 'jitter', 'on', 'jitterAmount', jitterAmount, 'MarkerEdgeAlpha', 1);
    scatter(3, r_mod(:, iRoi), sz, lightP, shape, ...
        'LineWidth', LineWidthMarkers, 'jitter', 'on', 'jitterAmount', jitterAmount, 'MarkerEdgeAlpha', 1);

    f = gca;
    f.YAxis.FontSize = 30;
    f.XAxis.Visible = 'off';
    f.YAxis.TickLength = [0, 0];
    box off;
    set(gca, 'ylim', [-0.4, 0.9]); set(gca, 'ytick', -0.4:0.4:0.8)
    %add asterisks
    xPosition = [0.90, 1.90, 2.90];
    myColor = [darkB; darkO; darkP];
    set(gca, 'linewidth', 6)
    for ROIsig = 1:3
        if p_corr(ROIsig, iRoi) < 0.05
            text(xPosition(ROIsig), 0, '*', FontSize = 60, Color = myColor(ROIsig, :));
        end
    end
    % add line between bars
    ycoords = [0.83, 0.83; 0.86, 0.86; 0.89, 0.89];
    xcoords = [1, 2; 1, 3; 2, 3];
    for ROIdiffsig = 1:3
        if p_groupdiff(ROIdiffsig, iRoi) < 0.05 && p_groupdiff(ROIdiffsig, iRoi) > 0.001
            line(xcoords(ROIdiffsig, :), ycoords(ROIdiffsig, :), 'color', darkGray, 'LineWidth', 2.7, 'LineStyle', "--");
        else
            if p_groupdiff(ROIdiffsig, iRoi) < 0.001
                line(xcoords(ROIdiffsig, :), ycoords(ROIdiffsig, :), 'color', darkGray, 'LineWidth', 2.7);
            end
        end
    end

    set(gca, 'FontName', "avenir")
    exportgraphics(gca, ...
        ['/Users/yiyang/DATA/numMVPA_bids/code/mvpa/rsa/final_figure/partial_corr_median/4slidesvss/', ...
        'median', maskLabel{iRoi}, 'withsigstar_final_model_partialcorr.png'], ...
        'Resolution', 300)

end

%% do stats
% for wilcoxon signed-rank test, W rbc and p value should be report
for iRoi = 1:10

    conNum = r_cond(:, iRoi);
    formNum = r_form(:, iRoi);
    modNum = r_mod(:, iRoi);
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
