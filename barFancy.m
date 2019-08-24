function barFancy(data, varargin)

% todo: replace my hacky code with combve

% SETTINGS

% bar settings
s.showBars = false;  % add vertical bars instead of just horizontal line at mean
s.barAlpha = .2;
s.showErrorBars = true;
s.colors = [.2 .2 .2]; % !!!
s.showViolins = false;
s.violinAlpha = .2; % alpha for violin plot fill
s.barSeparation = 1;
s.barWidth = 1;
s.lineThickness = 3;

% scatter settings
s.showScatter = true;
s.scatColors = 'hsv'; % can be a single rgb value, a name of a color space, or a matrix of colors
s.circSize = 40;
s.scatAlpha = .6;

% labels
s.conditionNames = {}; % nested cell array, where each cell array contains names of the levels of each variable
s.ylabel = [];

% stats settings
s.showStats = true;
s.compareToFirstOnly = true; % only run stats between first and all other conditions
s.isWithinSubs = true; % are the conditions within subjects
s.pThresh = .05;



% reassign settings passed in varargin
if exist('varargin', 'var'); for i = 1:2:length(varargin); s.(varargin{i}) = varargin{i+1}; end; end

% initializations
numVariables = length(size(data))-1;
varLevelNum = size(data); varLevelNum = varLevelNum(1:end-1); % number of levels for each variable
totalConditions = prod(varLevelNum);
dataDims = size(data);

if ischar(s.colors) % set bar colors if color is specified as a string
    s.colors = eval([s.colors '(totalConditions)']);
elseif isequal(size(s.colors), [1 3]) % if specified as a single rbg value, replicate into a matrix
    s.colors = repmat(s.colors,totalConditions,1);
end

if ischar(s.scatColors) % set bar colors if color is specified as a string
    if s.isWithinSubs
        s.scatColors = eval([s.scatColors '(dataDims(end))']);
    else
        s.scatColors = [.5 .5 .5];
    end
end

conditionsMat = nan(numVariables, totalConditions);
labelVertSize = .15*numVariables; % size of space below figure to give to to axis labels, expressed as fraction of y range
statsVertSpacing = .02; % vertical spacing of stat comparison lines, expressed as fraction of y range
xJitters = linspace(-.5*s.barWidth, .5*s.barWidth, dataDims(end));
xJitters = xJitters(randperm(length(xJitters)));
hold on


% create matrix where each column is an interection of conditions
xPositions = 1:totalConditions;
for i = 1:numVariables
    repeats = prod(varLevelNum(i+1:end));
    copies = totalConditions / (repeats*varLevelNum(i));
    conditionsMat(i,:) = repmat(repelem(1:varLevelNum(i), repeats), 1, copies);
    xPositions = xPositions + (repelem(1:copies*varLevelNum(i), repeats)-1) * s.barSeparation;
end

% add lines connecting same sample across conditions
if s.isWithinSubs && dataDims(end)<40 
    [~,~,condInds] = unique(conditionsMat(1:end-1,:)', 'rows'); % only draw lines connecting data across last condition
    
    for i = 1:dataDims(end) % for each subject        
        
        % get data in all conditions
        smpData = nan(1,totalConditions);
        for j = 1:totalConditions
            inds = num2cell([conditionsMat(:,j); i]);
            smpData(j) = squeeze(data(inds{:}));
        end
        
        % draw lines connecting data only across levels of last condition
        for j = unique(condInds)'
            line(xPositions(condInds==j)+xJitters(i), smpData(condInds==j), ...
                'linewidth', 1, 'color', [.8 .8 .8 s.scatAlpha]);
        end
    end
end


% plot data
allData = cell(1,totalConditions);
for i = 1:totalConditions
    inds = cat(1, num2cell(conditionsMat(:,i)), {1:size(data,length(dataDims))});
    condData = squeeze(data(inds{:}));
    allData{i} = condData;
    if s.isWithinSubs; lineColor = [0 0 0]; else; lineColor = scatColors(conditionsMat(end,i),:); end
    
    % add probability density estimate
    if s.showViolins
        [p,y] = ksdensity(condData);
        p = p / max(p) * s.barWidth*.5; % normalize range
        fill([p -fliplr(p)]+xPositions(i), [y fliplr(y)], [.8 .8 .8], ...
            'FaceColor', s.colors(i,:), 'FaceAlpha', s.violinAlpha, 'EdgeColor', s.colors(i,:))
    end
    
    % scatter raw data
    if s.showScatter
        scatter(xJitters + xPositions(i), condData, ...
            s.circSize, s.scatColors, 'filled', 'MarkerFaceAlpha', s.scatAlpha); hold on
    end
    
    if s.showErrorBars
        err = nanstd(condData);
        line([xPositions(i) xPositions(i)], [err -err] + nanmean(condData), ...
            'color', s.colors(i,:), 'linewidth', s.lineThickness*.5)
    end
    
    % add mean
    if ~s.showBars
        line([-.5 .5]*s.barWidth + xPositions(i), repmat(nanmean(condData),1,2), ...
            'color', s.colors(i,:), 'linewidth', s.lineThickness)
    end
end


% get y limit information
yLims = get(gca, 'ylim');

% add pairwise stats
if s.showStats
    [~,~,condInds] = unique(conditionsMat(1:end-1,:)', 'rows'); % only draw lines connecting data across last condition
    
    for i = unique(condInds)'
        dimPairs = nchoosek(1:length(find(condInds==i)), 2); % wrt data dimensions
        condPairs = nchoosek(find(condInds==i), 2); % wrt columns in plot
        
        % sort s.t. more distant comparisons are last
        [~, sortInds] = sort(diff(dimPairs,[],2));
        dimPairs = dimPairs(sortInds,:); condPairs = condPairs(sortInds,:);
        
        % only keep comparisons between first and all other conditions
        if s.compareToFirstOnly
            bins = any(dimPairs==1,2);
            dimPairs = dimPairs(bins,:);
            condPairs = condPairs(bins,:);
        end
        
        % vertical position of each line, expressed as fraction of y range
        yMax = yLims(2) + statsVertSpacing*range(yLims)*size(dimPairs,1);
        yPosits = linspace(yLims(2), yMax, size(dimPairs,1)); 
        inds = conditionsMat(1:end-1, find(condInds==i,1,'first'))'; % matrix inds for conditions higher up in the hierarchy
        
        for j = 1:size(dimPairs,1)
            
            [inds1, inds2] = deal(cat(2,num2cell([inds dimPairs(j,1)]), {1:size(data,length(dataDims))}));
            inds2{numVariables} = dimPairs(j,2);
            
            if s.isWithinSubs
                [~,p] = ttest(data(inds1{:}), data(inds2{:}));
            else
                [~,p] = ttest2(data(inds1{:}), data(inds2{:}));
            end
            if p<s.pThresh; lineColor = 'red'; else; lineColor = [.5 .5 .5]; end
            line(xPositions(condPairs(j,:)), [yPosits(j) yPosits(j)], ...
                'color', lineColor, 'linewidth', 1.0);
        end
    end
end


% add bars
if s.showBars
    for i = 1:totalConditions
        x = [-.5 .5]*s.barWidth + xPositions(i);
        y = [yLims(1), nanmean(allData{i})];
        plot([x(1) x(1) x(2) x(2)], [y(1) y(2) y(2) y(1)], ...
            'LineWidth', s.lineThickness, 'Color', s.colors(i,:));
        
        if s.barAlpha>0
            if ~isnan(nanmean(allData{i}))
                rectangle('Position', [xPositions(i)-.5*s.barWidth, yLims(1), s.barWidth, nanmean(allData{i})-yLims(1)], ...
                    'LineWidth', s.lineThickness, 'EdgeColor', 'none', 'FaceColor', [s.colors(i,:) s.barAlpha]);
            end
        end
    end
end



% add labels
for i = 1:length(s.conditionNames)
    
    parentConditions = unique(conditionsMat(1:i-1,:)','rows');
    
    for j = 1:size(parentConditions,1)
        
        if i==1; bins=true(1,totalConditions)'; else; bins = ismember(conditionsMat(1:i-1,:)', parentConditions(j,:), 'rows'); end
        
        for k = 1:varLevelNum(i)
            inds = find(conditionsMat(i,:)==k & bins');
            xPos = mean(xPositions(inds));
            yPos = yLims(1)-labelVertSize*range(yLims) + ((labelVertSize*range(yLims))/length(dataDims)*i);
            if i==numVariables; rotation = 25; else; rotation = 0; end
            if ~isempty(s.conditionNames)
                condText = text(xPos, yPos, s.conditionNames{i}(k), 'rotation', rotation, ...
                    'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
            end
            
            % add lines on the side of condition name
            if i<numVariables
                if ~isempty(s.conditionNames)
                    textPos = get(condText, 'Extent');
                    line([xPositions(inds(1)) textPos(1)], [yPos yPos], 'color', [.5 .5 .5]) % left side of text
                    line([textPos(1)+textPos(3) xPositions(inds(end))], [yPos yPos], 'color', [.5 .5 .5]) % right side of text
                else
                    line([xPositions(inds(1)) xPositions(inds(end))], [yPos yPos], 'color', [.5 .5 .5]) % line spanning variable
                end
            end
        end
    end
end


% add room above figure for stat lines
figColor = get(gcf, 'color');
if s.showStats
    line([0 0], [yLims(2), yMax], 'color', figColor, 'linewidth', 3) % cover top of y axis with white line
    yLims = [yLims(1), yMax];
end


% add room below figure for labels
if ~isempty(s.conditionNames)
    yMin = yLims(1)-labelVertSize*range(yLims);
    line([0 0], [yMin, yLims(1)], 'color', figColor, 'linewidth', 3) % cover bottom of y axis with white line
    yLims = [yMin, yLims(2)];
end

set(gca, 'YLim', yLims, 'XLim', [0 xPositions(end)+1], ...
    'XColor', 'none', 'Color', figColor)

% add y axis label
if ~isempty(s.ylabel)
    lab = ylabel(s.ylabel);
    labPos = get(lab, 'position');
    labPos(2) = mean(yLims);
    set(lab, 'position', labPos);
end

pause(.001) % when doing many subplots, this makes sure they pop up one by one



