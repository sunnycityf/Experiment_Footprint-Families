clc
clear
%% 选择数据
[Data_File_Person,Data_FilePath_Person] = uigetfile('*.xlsx','选择人口数据',"MultiSelect","off");
if Data_File_Person == 0
    disp("未选择文件，程序停止运行");
    return
end
cd(Data_FilePath_Person);
Data_Person = readmatrix(Data_File_Person);
Data_Person = Data_Person(2:10,2:9)*10000;

[Data_File_Electricity,Data_FilePath_Electricity] = uigetfile('*.xlsx','选择用电量数据',"MultiSelect","off");
if Data_File_Electricity == 0
    disp("未选择文件，程序停止运行");
    return
end
cd(Data_FilePath_Electricity);
Data_Electricity = readmatrix(Data_File_Electricity);
Data_Electricity = Data_Electricity(2:10,2:9);

DataFilePath_Environment = uigetdir('','选择产品产量数据所在的文件夹');
if DataFilePath_Environment == 0
    disp("未选择文件夹，程序停止运行!");
    return
end
cd(DataFilePath_Environment)
DataFile_Environment = FindFilesRecursive(DataFilePath_Environment,'.xlsx');

DataFilePath_Landuse = uigetdir('','选择土地利用数据所在的文件夹');
if DataFilePath_Landuse == 0
    disp("未选择文件夹，程序停止运行!");
    return
end
cd(DataFilePath_Landuse)
DataFile_Landuse = FindFilesRecursive(DataFilePath_Landuse,'.xlsx');

%% 读取数据
Data_Environment = cell(length(DataFile_Environment),1);
for i = 1:length(DataFile_Environment)
    Data_Environment{i} = readmatrix(DataFile_Environment{i});
end

Data_Landuse = cell(length(DataFile_Landuse),1);
for i = 1:length(DataFile_Landuse)
    Data_Landuse{i} = readmatrix(DataFile_Landuse{i});
end

%% 计算
% 均衡因子
rCropland = 1.02;
rForest = 0.74;
rGrassland = 0.62;
rWater = 0.49;
rImprevious = 1.02;

% 产量因子
yCropland = 0.6723;
yForest = 0.8084;
yGrassland = 5.4690;
yWater = 1.7983;
yImprevious = 0.6723;

% 世界平均产量
aveCrop = 2.744;
aveOil = 1.856;
aveSurge = 65.08282;
aveTea = 1.30162;
aveFruit = 18;
aveVegetable = 18;
avePork = 0.074;
aveBeef = 0.033;
aveWaterProduct = 0.029;

Alphae = 0.0036; % 电力能源折算系数
Ee = 1000; % 全球平均能源足迹
% 生态足迹计算
EFe = cell(length(Data_Environment),1);
EFb = cell(length(Data_Environment),1);
EF = cell(length(Data_Environment),1);
EFN = cell(length(Data_Environment),1);
for i = 1:length(Data_Environment)
    Crop = Data_Environment{i}(:,2);
    Oil = Data_Environment{i}(:,3);
    Surge = Data_Environment{i}(:,4);
    Tea = Data_Environment{i}(:,5);
    Fruit = Data_Environment{i}(:,6);
    Vegetable = Data_Environment{i}(:,7);
    Pork = Data_Environment{i}(:,8);
    Beef = Data_Environment{i}(:,9);
    WaterProduct = Data_Environment{i}(:,10);
    Ce = Data_Electricity(:,i);
    EFe{i} = (Ce * rImprevious * Alphae) / Ee;
    EFb_Crop = rCropland * (Crop / aveCrop);
    EFb_Oil = rCropland * (Oil / aveOil);
    EFb_Surge = rCropland * (Surge / aveSurge);
    EFb_Tea = rCropland * (Tea / aveTea);
    EFb_Fruit = rForest * (Fruit / aveFruit);
    EFb_Vegetable = rCropland * (Vegetable / aveVegetable);
    EFb_Pork = rCropland * (Pork / avePork);
    EFb_Beef = rGrassland * (Beef / aveBeef);
    EFb_WaterProduct = rWater * (WaterProduct / aveWaterProduct);
    EFb{i} = EFb_Crop + EFb_Oil + EFb_Surge + EFb_Tea + EFb_Fruit ...
        + EFb_Vegetable + EFb_Pork + EFb_Beef + EFb_WaterProduct;
    EF{i} = EFb{i} + EFe{i};
    EFN{i} = EF{i} ./ Data_Person(:,i);
end
% 生态承载力计算
EC = cell(length(Data_Landuse),1);
ECN = cell(length(Data_Landuse),1);
for i = 1:length(Data_Landuse)
    Cropland = Data_Landuse{i}(:,2) * 0.0001;
    Forest = Data_Landuse{i}(:,3) * 0.0001;
    Grassland = Data_Landuse{i}(:,5) * 0.0001;
    Water = Data_Landuse{i}(:,6) * 0.0001;
    Imprevious = Data_Landuse{i}(:,9) * 0.0001;
    EC_Cropland = Cropland * rCropland * yCropland * 0.88;
    EC_Forest = Forest * rForest * yForest * 0.88;
    EC_Grassland = Grassland * rGrassland * yGrassland * 0.88;
    EC_Water = Water * rWater * yWater * 0.88;
    EC_Impervious = Imprevious * rImprevious * yImprevious * 0.88;
    EC{i} = EC_Cropland + EC_Forest + EC_Grassland + EC_Water + EC_Impervious;
    ECN{i} = EC{i} ./ Data_Person(:,i);
end
% 生态盈余计算
EBN = cell(length(Data_Environment),1);
for i = 1:length(Data_Environment)
    EBN{i} = EFN{i} - ECN{i};
end
clearvars -except ECN EFN EBN

EFND = [EFN{1},EFN{2},EFN{3},EFN{4},EFN{5},EFN{6},EFN{7},EFN{8}];
ECND = [ECN{1},ECN{2},ECN{3},ECN{4},ECN{5},ECN{6},ECN{7},ECN{8}];
EBND = [EBN{1},EBN{2},EBN{3},EBN{4},EBN{5},EBN{6},EBN{7},EBN{8}];

%% 绘制热力图
% 定义坐标标签
county_names = {'涪城区', '游仙区', '安州区', '江油市', '三台县', '北川县', '梓潼县', '盐亭县', '平武县'};
years = 2014:2021;

light = [224 239 220]/255;
dark = [117 185 86]/255;

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
    'Color', 'k'...                      % 固定文本颜色为黑色
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
lineColor = [0.4588 0.7255 0.3373]; % 统一使用深绿色
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