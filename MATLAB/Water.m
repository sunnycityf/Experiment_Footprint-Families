clc
clear
%% 输入文件
DataFilePath = uigetdir('','选择数据所在的文件夹');
if DataFilePath == 0
    disp("未选择文件夹，程序停止运行!");
    return
end
cd(DataFilePath)
DataFile = FindFilesRecursive(DataFilePath,'.xlsx');

%% 读取数据
Data = cell(length(DataFile),1);
for i = 1:length(DataFile)
    Data{i} = readmatrix(DataFile{i});
end

%% 计算
RW = 5.19;
PW = 3140;
WF = cell(length(Data),1);
WC = cell(length(Data),1);
WFN = cell(length(Data),1);
WCN = cell(length(Data),1);
WBN = cell(length(Data),1);
for i = 1:length(Data)
    W = Data{i}(:,5) * 100000000;
    N = Data{i}(:,7) * 10000;
    Q = Data{i}(:,6) * 100000000;
    beta = Data{i}(:,9) * 10000 * 0.01 / PW;
    WF{i} = RW * (W/PW);
    WC{i} = 0.4 .* beta .* RW .* (Q/PW);
    WFN{i} = WF{i} ./ N;
    WCN{i} = WC{i} ./ N;
    WBN{i} = WFN{i} - WCN{i};
end
WFND = [WFN{1},WFN{2},WFN{3},WFN{4},WFN{5},WFN{6},WFN{7},WFN{8}];
WCND = [WCN{1},WCN{2},WCN{3},WCN{4},WCN{5},WCN{6},WCN{7},WCN{8}];
WBND = [WBN{1},WBN{2},WBN{3},WBN{4},WBN{5},WBN{6},WBN{7},WBN{8}];

%% 绘制热力图
% 定义坐标标签
county_names = {'涪城区', '游仙区', '安州区', '江油市', '三台县', '北川县', '梓潼县', '盐亭县', '平武县'};
years = 2014:2021;

light_blue = [210 227 243]/255;
dark_blue = [16 92 164]/255;

% 正向映射：浅蓝 -> 深蓝
custom_cmap_forward = [linspace(light_blue(1),dark_blue(1),256)',...
                       linspace(light_blue(2),dark_blue(2),256)',...
                       linspace(light_blue(3),dark_blue(3),256)'];
% 反向映射：深蓝 -> 浅蓝
custom_cmap_reversed = flipud(custom_cmap_forward);

% 创建图形窗口
figure('Position', [100, 100, 1600, 500], 'Color','w')
% 通用参数设置
textOptions = {
    'HorizontalAlignment', 'center',...  % 水平居中
    'VerticalAlignment', 'middle',...    % 垂直居中
    'FontSize', 9,...                    % 适当增大字号
    'FontName', 'Microsoft YaHei',...    % 中文字体
    'Color', 'k'...                      % 固定文本颜色为黑色
};

% 绘制WFND（反向色系）
ax1 = subplot(1,3,1);
imagesc(WFND)
set(gca, 'XTick', 1:8, 'XTickLabel', years,...
         'YTick', 1:9, 'YTickLabel', county_names)
title('人均水足迹（hm²/人）')
colormap(ax1, custom_cmap_reversed)
colorbar('Location','eastoutside')

% 添加数值标签
[rows, cols] = size(WFND);
for i = 1:rows
    for j = 1:cols
        text(j, i, sprintf('%.2f', WFND(i,j)), textOptions{:});
    end
end

% 绘制WCND（正向色系）
ax2 = subplot(1,3,2);
imagesc(WCND)
set(gca, 'XTick', 1:8, 'XTickLabel', years,...
         'YTick', [], 'YTickLabel', '')
title('人均水资源承载力（hm²/人）')
colormap(ax2, custom_cmap_forward)
colorbar('Location','eastoutside')

% 添加数值标签
[rows, cols] = size(WCND);
for i = 1:rows
    for j = 1:cols
        text(j, i, sprintf('%.2f', WCND(i,j)), textOptions{:});
    end
end

% 绘制WBND（反向色系）
ax3 = subplot(1,3,3);
imagesc(WBND)
set(gca, 'XTick', 1:8, 'XTickLabel', years,...
         'YTick', [], 'YTickLabel', '')
title('水资源盈亏')
colormap(ax3, custom_cmap_reversed)
colorbar('Location','eastoutside')

% 添加数值标签
[rows, cols] = size(WBND);
for i = 1:rows
    for j = 1:cols
        text(j, i, sprintf('%.2f', WBND(i,j)), textOptions{:});
    end
end

% 调整子图间距
set(ax1, 'Position', [0.06 0.15 0.25 0.75])
set(ax2, 'Position', [0.37 0.15 0.25 0.75])
set(ax3, 'Position', [0.68 0.15 0.25 0.75])

%% 绘制人均水足迹图
figure('Position', [0 0 1400 900], 'Color', 'w', 'Name', '各区县人均水足迹趋势分析')

% 设置统一参数
years = 2014:2021;
lineColor = [0.2 0.4 0.8]; % 统一使用深蓝色
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
    plot(years, WFND(i,:),...
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
        ylabel('人均水足迹（hm²/人）', 'FontSize', 10)
    end
    % 统一Y轴范围（可选）
    ylim([floor(min(WFND(:))*10)/10, ceil(max(WFND(:))*10)/10])
end
% 添加整体标题
title(t, '各区县人均水足迹指标年度变化趋势（2014-2021）',...
    'FontSize', 14, 'FontWeight', 'bold')

%% [Function]文件批量读取
function files = FindFilesRecursive(folder, fileExt)
    contents = dir(folder);
    numFiles = sum(~[contents.isdir]); 
    files = cell(numFiles, 1); 
    idx = 1; 
    for i = 1:numel(contents)
        if strcmp(contents(i).name, '.') || strcmp(contents(i).name, '..')
            continue;
        end
        currentPath = fullfile(folder, contents(i).name);
        if contents(i).isdir
            nestedFiles = FindFilesRecursive(currentPath, fileExt);
            files(idx:idx+numel(nestedFiles)-1) = nestedFiles;
            idx = idx + numel(nestedFiles);
        else
            [~, ~, ext] = fileparts(contents(i).name);
            if strcmpi(ext, fileExt)
                files{idx} = currentPath;
                idx = idx + 1;
            end
        end
    end
end