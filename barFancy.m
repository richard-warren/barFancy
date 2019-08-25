function barFancy(data, varargin)

% OVERVIEW:
% Make fancy bar plots for multi-factor, multi-level data. Find full
% documentation at https://github.com/rwarren2163/fancyPlots
%
% Generates bat plots for data with >=1 FACTORS (gender, hair color),
% each with >=2 LEVELS (e.g. {male, female}, {red, blone, 
% brown}. Each bar is a CONDITION (male, black hair), and the hierarchical
% relationship between condition iis automatically preserved.
%
% EXAMPLES:
% barFancy(data, 'showViolins', true, 'levelNames', {{'male', 'female'}, {'red', 'blonde', 'brown'}})
% Run barFancy_demo to see examples of usage
%
% INPUTS:
% data (required): Matrix where each dimension is a FACTOR, and the final
% dimension contains data for each sample. The size of each dimension is
% the number of levels for each factor. For example, to plot data grouped
% by gender (male, female) and hair color (black, brown, blonde), data
% would be a 2 X 3 X number of sample matrix
%
% optional inputs: Name value pairs can be passed to overwrite thhe default
% values in the structure 's'. See the comments in 'settings' below for a
% full list of the many options available.

% todo: return manipulable object so things can be adjusted posthoc


% SETTINGS

% bar settings
s.showBars = true;            % add vertical bars instead of just horizontal line at mean for each condition
s.barAlpha = .2;
s.showErrorBars = true;
s.summaryFunction = @nanmean; % statistic to use for bar height (can use median instead of mean, for example)
s.errorFunction = @nanstd;    % can change to custom error function, e.g. standard error instead of standard deviation
s.colors = [.2 .2 .2];        % bar colors // can be name of matlab color space (e.g. 'hsv') OR nX3 matrix of colors where each row is the color of a specific condition
s.showViolins = false;        % add vertical probability density estimates, creating a 'violin plot'
s.violinAlpha = .2;
s.barSeparation = 1;          % how far apart to separate bars // expressed as fraction of width of single bar
s.barWidth = 1;
s.lineThickness = 3;          % thickness of bar border

% scatter settings
s.connectDots = false;        % if samples are repeated measures (i.e. within subjects design), scatter points representing the same sample across conditions can be conneceted with lines
s.showScatter = true;         % scatter the values of individual samples
s.scatterColors = 'hsv';      % if single color, all scatters will have that colors // if a matlab color space (e.g. 'hsv') OR (number of samples per condition) X 3 matrix where each row is the color of a particular sample (appropriate for repeated measure designs)
s.scatterSize = 40;
s.scatterAlpha = .2;

% labels
s.levelNames = {};            % names of levels for each factor // cell array of cell arrays where each nested array contains names of the levels for a particular factor, e.g. {{'male', 'female'}, {'tall', 'short'}}
s.ylabel = [];




% INITIALIZATIONS

% reassign settings passed in varargin
if exist('varargin', 'var'); for i = 1:2:length(varargin); s.(varargin{i}) = varargin{i+1}; end; end

% determine number of factors, levels, and conditions
numFactors = length(size(data))-1;
numLevels = size(data); numLevels = numLevels(1:end-1); % number of levels for each variable
numConditions = prod(numLevels);
dataDims = size(data);

% set bar colors if color is specified as a string
if ischar(s.colors)
    s.colors = eval([s.colors '(numConditions)']);
elseif isequal(size(s.colors), [1 3]) % if specified as a single rbg value, replicate into a matrix
    s.colors = repmat(s.colors,numConditions,1);
end

% set scatter colors if color is specified as a string
if ischar(s.scatterColors); s.scatterColors = eval([s.scatterColors '(dataDims(end))']); end

% determine various spatial parameters
labelVertSize = .15*numFactors;  % size of space below figure to give to to axis labels, expressed as fraction of y range
xJitters = linspace(-.25*s.barWidth, .25*s.barWidth, dataDims(end));  % jitters for scatter points
xJitters = xJitters(randperm(length(xJitters)));

% create matrix where each row is a factor, each entry is a level for a
% given factor, and each column is a condition (i.e.a unique combination
% of factor levels)
conditionsMat = nan(numFactors, numConditions);
xPositions = 1:numConditions;
for i = 1:numFactors
    repeats = prod(numLevels(i+1:end));
    copies = numConditions / (repeats*numLevels(i));
    conditionsMat(i,:) = repmat(repelem(1:numLevels(i), repeats), 1, copies);
    xPositions = xPositions + (repelem(1:copies*numLevels(i), repeats)-1) * s.barSeparation;
end
line([0 xPositions(end)+s.barWidth/2], [0 0], 'color', get(gca, 'YColor'))  % add line at y=0 zero





% GENERATE PLOT
hold on

% add lines connecting same sample across conditions
if s.connectDots && dataDims(end)<100  % latter term prevents drawing lines with there are a large number of samples
    for i = 1:dataDims(end)  % loop across samples
        
        % get data for sample in all conditions
        smpData = nan(1,numConditions);
        for j = 1:numConditions
            inds = num2cell([conditionsMat(:,j); i]);
            smpData(j) = squeeze(data(inds{:}));
        end

        line(xPositions+xJitters(i), smpData, 'linewidth', 1, 'color', 1-[1 1 1]*s.scatterAlpha);
    end
end

% make bars, etc
allData = cell(1,numConditions);  % each entry contains a vector of values for all samples within a condition
for i = 1:numConditions
    
    inds = cat(1, num2cell(conditionsMat(:,i)), {1:size(data,ndims(data))});  % inds for this condition within data matrix
    condData = squeeze(data(inds{:}));
    allData{i} = condData;
    
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
            s.scatterSize, s.scatterColors, 'filled', 'MarkerFaceAlpha', s.scatterAlpha); hold on
    end
    
    % add error bars
    if s.showErrorBars
        err = s.errorFunction(condData);
        line([xPositions(i) xPositions(i)], [err -err] + s.summaryFunction(condData), ...
            'color', s.colors(i,:), 'linewidth', s.lineThickness*.5)
    end
    
    % add mean
    if ~s.showBars
        line([-.5 .5]*s.barWidth + xPositions(i), repmat(s.summaryFunction(condData),1,2), ...
            'color', s.colors(i,:), 'linewidth', s.lineThickness)
    end
end

% add bars
if s.showBars
    for i = 1:numConditions
        
        % add bar outline
        x = [-.5 .5]*s.barWidth + xPositions(i);
        y = [0, s.summaryFunction(allData{i})];
        plot([x(1) x(1) x(2) x(2)], [y(1) y(2) y(2) y(1)], ...
            'LineWidth', s.lineThickness, 'Color', s.colors(i,:));
        
        % fill in bar
        if s.barAlpha>0
            if ~isnan(s.summaryFunction(allData{i}))
                height = s.summaryFunction(allData{i});
                x = xPositions(i)-.5*s.barWidth;  % bottom left corner of bar
                y = min(height, 0);               % bottom left corner of bar
                rectangle('Position', [x, y, s.barWidth, abs(height)], 'LineWidth', s.lineThickness, ...
                    'EdgeColor', 'none', 'FaceColor', [s.colors(i,:) s.barAlpha]);
            end
        end
    end
end




% ADD AXIS LABELS

% get initial y ticks and y limitis (will be subsequently adjusted)
yLims = get(gca, 'ylim');
yTicks = get(gca, 'ytick');


% add labels
for i = 1:length(s.levelNames)
    
    parentConditions = unique(conditionsMat(1:i-1,:)','rows');
    
    for j = 1:size(parentConditions,1)
        
        if i==1; bins=true(1,numConditions)'; else; bins = ismember(conditionsMat(1:i-1,:)', parentConditions(j,:), 'rows'); end
        
        for k = 1:numLevels(i)
            inds = find(conditionsMat(i,:)==k & bins');
            xPos = mean(xPositions(inds));
            yPos = yLims(1)-labelVertSize*range(yLims) + ((labelVertSize*range(yLims))/length(dataDims)*i);
            if i==numFactors; rotation = 25; else; rotation = 0; end
            if ~isempty(s.levelNames)
                condText = text(xPos, yPos, s.levelNames{i}(k), 'rotation', rotation, ...
                    'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
            end
            
            % add lines on the side of condition name
            if i<numFactors
                if ~isempty(s.levelNames)
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

% add y axis label
if ~isempty(s.ylabel)
    lab = ylabel(s.ylabel);
    labPos = get(lab, 'position');
    labPos(2) = mean(yLims);
    set(lab, 'position', labPos);
end

% add room below figure for labels
figColor = get(gcf, 'color');
if ~isempty(s.levelNames)
    yMin = yLims(1)-labelVertSize*range(yLims);
    lineObj = line([0 0], [yMin, yLims(1)], 'color', figColor, 'linewidth', 3); % cover bottom of y axis with white line
    uistack(lineObj, 'bottom')
    yLims = [yMin, yLims(2)];
end

% reset axis ticks and limits
set(gca, 'YLim', yLims, 'yTick', yTicks, 'XLim', [0 xPositions(end)+1], ...
    'XColor', 'none', 'Color', figColor)


