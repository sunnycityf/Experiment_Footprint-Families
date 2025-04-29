%% 绘制热力图
% 定义坐标标签
county_names = {'涪城区', '游仙区', '安州区', '江油市', '三台县', '北川县', '梓潼县', '盐亭县', '平武县'};
years = 2014:2021;

light = [210 227 243]/255;
dark = [16 92 164]/255;

% 正向映射：浅绿 -> 深绿
custom_cmap_forward = [linspace(light(1),dark(1),256)',...
                       linspace(light(2),dark(2),256)',...
                       linspace(light(3),dark(3),256)'];
% 反向映射：深绿 -> 浅绿
custom_cmap_reversed = flipud(custom_cmap_forward);

% 创建图形窗口
figure('Position', [100, 100, 1600, 500], 'Color','w')
% 通用参数设置
textOptions = {
    'HorizontalAlignment', 'center',...  % 水平居中
    'VerticalAlignment', 'middle',...    % 垂直居中
    'FontSize', 9,...                    % 适当增大字号
    'FontName', 'Microsoft YaHei',...    % 中文字体
    'Color', 'w'...                      % 固定文本颜色为黑色
};

% 绘制EFND（反向色系）
ax1 = subplot(1,3,1);
imagesc(EFND)
set(gca, 'XTick', 1:8, 'XTickLabel', years,...
         'YTick', 1:9, 'YTickLabel', county_names)
title('人均生态足迹（hm²/人）')
colormap(ax1, custom_cmap_reversed)
colorbar('Location','eastoutside')

% 添加数值标签
[rows, cols] = size(EFND);
for i = 1:rows
    for j = 1:cols
        text(j, i, sprintf('%.2f', EFND(i,j)), textOptions{:});
    end
end

% 绘制ECND（正向色系）
ax2 = subplot(1,3,2);
imagesc(ECND)
set(gca, 'XTick', 1:8, 'XTickLabel', years,...
         'YTick', [], 'YTickLabel', '')
title('人均生态承载力（hm²/人）')
colormap(ax2, custom_cmap_forward)
colorbar('Location','eastoutside')

% 添加数值标签
[rows, cols] = size(ECND);
for i = 1:rows
    for j = 1:cols
        text(j, i, sprintf('%.2f', ECND(i,j)), textOptions{:});
    end
end

% 绘制EBND（反向色系）
ax3 = subplot(1,3,3);
imagesc(EBND)
set(gca, 'XTick', 1:8, 'XTickLabel', years,...
         'YTick', [], 'YTickLabel', '')
title('生态盈亏')
colormap(ax3, custom_cmap_reversed)
colorbar('Location','eastoutside')

% 添加数值标签
[rows, cols] = size(EBND);
for i = 1:rows
    for j = 1:cols
        text(j, i, sprintf('%.2f', EBND(i,j)), textOptions{:});
    end
end

% 调整子图间距
set(ax1, 'Position', [0.06 0.15 0.25 0.75])
set(ax2, 'Position', [0.37 0.15 0.25 0.75])
set(ax3, 'Position', [0.68 0.15 0.25 0.75])

%% 绘制人均生态足迹图
figure('Position', [0 0 1400 900], 'Color', 'w', 'Name', '各区县人均生态足迹趋势分析')

% 设置统一参数
years = 2014:2021;
lineColor = [0.2 0.4 0.8]; % 统一使用深绿色
county_names = {'涪城区', '游仙区', '安州区', '江油市', '三台县',...
               '北川县', '梓潼县', '盐亭县', '平武县'};

% 使用tiledlayout进行自动布局
t = tiledlayout(3,3);
t.Padding = 'compact';       % 减少周边空白
t.TileSpacing = 'compact';   % 减少子图间距

% 循环绘制每个区县
for i = 1:9
    nexttile % 自动定位子图
    
    % 绘制趋势线（带数据点标记）
    plot(years, EFND(i,:),...
        'Color', lineColor,...
        'LineWidth', 1.8,...
        'Marker', 'o',...
        'MarkerSize', 6,...
        'MarkerFaceColor', lineColor)
    
    % 坐标轴设置
    set(gca, 'XTick', years,...
             'XTickLabelRotation', 30,...
             'FontSize', 9,...
             'FontName', 'Microsoft YaHei',...
             'Box', 'off')
    grid on
    set(gca, 'GridAlpha', 0.2, 'GridLineStyle', '--')
    
    % 标题设置（减小标题下边距）
    title(county_names{i}, 'FontSize', 11, 'FontWeight', 'bold',...
        'Margin', 0.5, 'VerticalAlignment', 'bottom')
    
    % 仅底部子图显示x轴标签
    if i < 7
        set(gca, 'XTickLabel', [])
    else
        xlabel('年份', 'FontSize', 10)
    end
    % 仅左侧子图显示y轴标签
    if mod(i,3) ~= 1
        set(gca, 'YTickLabel', [])
    else
        ylabel('人均生态足迹（hm²/人）', 'FontSize', 10)
    end
    % 统一Y轴范围（可选）
    ylim([floor(min(EFND(:))*10)/10, ceil(max(EFND(:))*10)/10])
end
% 添加整体标题
title(t, '各区县人均生态足迹指标年度变化趋势（2014-2021）',...
    'FontSize', 14, 'FontWeight', 'bold')
