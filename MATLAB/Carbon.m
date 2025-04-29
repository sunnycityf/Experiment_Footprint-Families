clc
clear
%% 输入文件
[Data_File_Carbon,Data_FilePath_Carbon] = uigetfile('*.xlsx','选择能源数据',"MultiSelect","off");
if Data_File_Carbon == 0
    disp("未选择文件，程序停止运行");
    return
end
cd(Data_FilePath_Carbon);
Data_Carbon = readmatrix(Data_File_Carbon);
Data_Carbon = Data_Carbon(2:10,2:9);

[Data_File_Person,Data_FilePath_Person] = uigetfile('*.xlsx','选择人口数据',"MultiSelect","off");
if Data_File_Person == 0
    disp("未选择文件，程序停止运行");
    return
end
cd(Data_FilePath_Person);
Data_Person = readmatrix(Data_File_Person);
Data_Person = Data_Person(2:10,2:9)*10000;

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
Pf = 0.5233;
Pg = 0.0957;
Pc = 0.381;

NEPf = 3.8096;
NEPg = 0.9482;
NEPc = 8.9946;

CO2C = 44/12;

CS = cell(length(Data),1);
CC = cell(length(Data),1);
CCN = cell(length(Data),1);
for i = 1:length(Data)
    CropArea = Data{i}(:,2) * 0.0001;
    ForestArea = Data{i}(:,3) * 0.0001;
    GrassArea = Data{i}(:,5) * 0.0001;
    CS{i} = ForestArea * NEPf + GrassArea * NEPg + CropArea * NEPc;
    CC{i} = CS{i} * (Pf / NEPf + Pg / NEPg + Pc / NEPc);
    CCN{i} = CC{i} ./ Data_Person(:,i);
end

Dei = 0.67;
CE = cell(length(Data),1);
CF = cell(length(Data),1);
CFN = cell(length(Data),1);
for i = 1:length(Data)
    Qei = Data_Carbon(:,i);
    CE{i} = Qei * Dei * CO2C;
    CF{i} = CE{i} * (Pf / NEPf + Pg / NEPg + Pc / NEPc);
    CFN{i} = CF{i} ./ Data_Person(:,i);
end

CBN = cell(length(Data_Person),1);
for i = 1:length(Data)
    CBN{i} = CFN{i} - CCN{i};
end

CFND = [CFN{1},CFN{2},CFN{3},CFN{4},CFN{5},CFN{6},CFN{7},CFN{8}];
CCND = [CCN{1},CCN{2},CCN{3},CCN{4},CCN{5},CCN{6},CCN{7},CCN{8}];
CBND = [CBN{1},CBN{2},CBN{3},CBN{4},CBN{5},CBN{6},CBN{7},CBN{8}];

%% 绘制热力图
% 定义坐标标签
county_names = {'涪城区', '游仙区', '安州区', '江油市', '三台县', '北川县', '梓潼县', '盐亭县', '平武县'};
years = 2014:2021;

light = [235 215 165]/255;
dark = [89 46 30]/255;

% 正向映射：浅棕 -> 深棕
custom_cmap_forward = [linspace(light(1),dark(1),256)',...
                       linspace(light(2),dark(2),256)',...
                       linspace(light(3),dark(3),256)'];
% 反向映射：深棕 -> 浅棕
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

% 绘制CFND（反向色系）
ax1 = subplot(1,3,1);
imagesc(CFND)
set(gca, 'XTick', 1:8, 'XTickLabel', years,...
         'YTick', 1:9, 'YTickLabel', county_names)
title('人均碳足迹（hm²/人）')
colormap(ax1, custom_cmap_reversed)
colorbar('Location','eastoutside')

% 添加数值标签
[rows, cols] = size(CFND);
for i = 1:rows
    for j = 1:cols
        text(j, i, sprintf('%.2f', CFND(i,j)), textOptions{:});
    end
end

% 绘制CCND（正向色系）
ax2 = subplot(1,3,2);
imagesc(CCND)
set(gca, 'XTick', 1:8, 'XTickLabel', years,...
         'YTick', [], 'YTickLabel', '')
title('人均区域碳承载力（hm²/人）')
colormap(ax2, custom_cmap_forward)
colorbar('Location','eastoutside')

% 添加数值标签
[rows, cols] = size(CCND);
for i = 1:rows
    for j = 1:cols
        text(j, i, sprintf('%.2f', CCND(i,j)), textOptions{:});
    end
end

% 绘制CBND（反向色系）
ax3 = subplot(1,3,3);
imagesc(CBND)
set(gca, 'XTick', 1:8, 'XTickLabel', years,...
         'YTick', [], 'YTickLabel', '')
title('碳盈亏')
colormap(ax3, custom_cmap_reversed)
colorbar('Location','eastoutside')

% 添加数值标签
[rows, cols] = size(CBND);
for i = 1:rows
    for j = 1:cols
        text(j, i, sprintf('%.2f', CBND(i,j)), textOptions{:});
    end
end

% 调整子图间距
set(ax1, 'Position', [0.06 0.15 0.25 0.75])
set(ax2, 'Position', [0.37 0.15 0.25 0.75])
set(ax3, 'Position', [0.68 0.15 0.25 0.75])

%% 绘制人均碳足迹图
figure('Position', [0 0 1400 900], 'Color', 'w', 'Name', '各区县人均碳足迹趋势分析')

% 设置统一参数
years = 2014:2021;
lineColor = [0.349 0.1804 0.1176]; % 统一使用深棕色
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
    plot(years, CFND(i,:),...
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
        ylabel('人均碳足迹（hm²/人）', 'FontSize', 10)
    end
    % 统一Y轴范围（可选）
    ylim([floor(min(CFND(:))*10)/10, ceil(max(CFND(:))*10)/10])
end
% 添加整体标题
title(t, '各区县人均碳足迹指标年度变化趋势（2014-2021）',...
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