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
s.barSeparation = .5;         % how far apart to separate bars // expressed as fraction of width of single bar
s.barWidth = 1;
s.lineThickness = 3;          % thickness of bar border
s.constantEdgeColor = [];     % if provided, the edges of all bars have the same color (only if showBars set to false for now)

% axis settings
s.YLim = [];
s.axisColor = [];
s.YTick = [];
s.edgeLabelsOnly = false;     % if true, y tick labels are only applied to the first and last tick
s.tickWidth = .015;           % expressed as fraction of x axis range
s.sideBuffer = .75;           % how much to add to the left and right of the first and last bars
s.lineAtZero = [];            % whether x axis is always at zero, or stays at the lower y limit // if empty this is automatically determined

% scatter settings
s.scatterCondColor = false;   % whether to use the same color for all scatter points within a condition
s.connectDots = false;        % if samples are repeated measures (i.e. within subjects design), scatter points representing the same sample across conditions can be conneceted with lines
s.showScatter = true;         % scatter the values of individual samples
s.scatterColors = 'hsv';      % if single color, all scatters will have that colors // if a matlab color space (e.g. 'hsv') OR (number of samples per condition) X 3 matrix where each row is the color of a particular sample (appropriate for repeated measure designs)
s.scatterSize = 40;
s.scatterAlpha = .2;          % transparency of scatter points
s.lineAlpha = .2;             % transparency of lines connecting scatter points

% labels
s.levelNames = {};            % names of levels for each factor // cell array of cell arrays where each nested array contains names of the levels for a particular factor, e.g. {{'male', 'female'}, {'tall', 'short'}}
s.ylabel = [];
s.labelSizePerFactor = .15;   % how much space to add to the bottom of the figure per factor, expressed as a fraction of y range

% stats
s.comparisons = [];               % (n X 2) matrix of conditions that should be compared to one another // indices are with respect to their ordering in the bar graph, e.g. [1 5] compares the 1st and the 5th bar in the plot
s.test = 'ttest';                 % 'ttest' or 'signrank'
s.pThresh = [.05 .01 .001];       % !!! CURRENTLY MUST BE ORDERED FROM LARGEST TO SMALLEST!
s.symbols = {'*', '**', '***'};   % symbols associated with the pThresh values above (they will appear above the brackets connecting the conditions to be compared)
s.bracketSz = .02;                % size of the vertical ticks in the brackets // expressed as fraction of y axis range
s.notSigText = '';                % text to appear above brackets for not groups that do not significanctly differ
s.showBracketTicks = true;        % whether to show brackets (with vertical ticks) or just horizontal lines connecting conditions
s.sigColor = [1 .2 .2]*.9;        % brackets become this color for a significant difference


% INITIALIZATIONS

figColor = get(gcf, 'color'); % get figure background color

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
labelVertSize = s.labelSizePerFactor*length(s.levelNames);  % size of space below figure to give to to axis labels, expressed as fraction of y range
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
xPositions = xPositions - 1 + s.sideBuffer;


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
        
%         keyboard
        line(xPositions+xJitters(i), smpData, 'linewidth', 1, 'color', [0 0 0 s.lineAlpha]);
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
        fill([p -fliplr(p)]+xPositions(i), [y fliplr(y)], figColor, ...
            'FaceColor', s.colors(i,:), 'FaceAlpha', s.violinAlpha, 'EdgeColor', s.colors(i,:))
    end
    
    % scatter raw data
    if s.showScatter
        if s.scatterCondColor; c = s.colors(i,:); else; c = s.scatterColors; end
        scatter(xJitters + xPositions(i), condData, ...
            s.scatterSize, c, 'filled', 'MarkerFaceAlpha', s.scatterAlpha); hold on
    end
    
    % add error bars
    if s.showErrorBars
        err = s.errorFunction(condData);
        line([xPositions(i) xPositions(i)], [err -err] + s.summaryFunction(condData), ...
            'color', s.colors(i,:), 'linewidth', s.lineThickness)
    end
    
    % add mean
    if ~s.showBars
        if s.constantEdgeColor; c = s.constantEdgeColor; else; c = s.colors(i,:); end
        line([-.5 .5]*s.barWidth + xPositions(i), repmat(s.summaryFunction(condData),1,2), ...
            'color', c, 'linewidth', s.lineThickness)
    end
end

% add bars
if s.showBars
    for i = 1:numConditions
        
        x = [-.5 .5]*s.barWidth + xPositions(i);  % left edges of bar
        y = [0, s.summaryFunction(allData{i})];   % right edges of bar
            
        % add bar outline
        if s.barAlpha<1
            plot([x(1) x(1) x(2) x(2)], [y(1) y(2) y(2) y(1)], ...
                'LineWidth', s.lineThickness, 'Color', s.colors(i,:));
        end
        
        % fill in bar
        if s.barAlpha>0
            patch([x(1) x(1) x(2) x(2) x(1)], [y(1) y(2) y(2) y(1) y(1)], [s.colors(i,:)], ...
                'EdgeColor', 'none', 'FaceAlpha', s.barAlpha)
        end
    end
end



% SET Y LIMITS
if isempty(s.YLim)
    s.YLim = get(gca, 'YLim');
    
    if s.showBars  % bar plot will always start at zero // otherwise, use the automatically determined y limits
        
        % collect all data included in plot to determine range
        summaries = cellfun(s.summaryFunction, allData)';
        errors = cellfun(s.errorFunction, allData)';
        ys = summaries;  % ys contains all data to be included in range, which depends on elements are to be included in plot
        if s.showScatter; ys = [ys; data(:)]; end
        if s.showErrorBars; ys = [ys; summaries+errors; summaries-errors]; end
        
        if min(ys)>0  % if all data are positive, lower y limit is 0
            s.YLim(1) = 0;
        elseif max(ys)<0  % if all data are negative, upper y limit is zero
            s.YLim(2) = 0;
        end
    end
end
set(gca, 'YLim', s.YLim);
if isempty(s.YTick)
    s.YTick = get(gca, 'YTick');
    yTickLabels = get(gca, 'YTickLabels');
else
    yTickLabels = strsplit(num2str(s.YTick));
end




% ADD AXIS LABELS

% get current axis color
if isempty(s.axisColor); s.axisColor=get(gca, 'XColor'); end

% add labels
for i = 1:length(s.levelNames)
    
    parentConditions = unique(conditionsMat(1:i-1,:)','rows');
    
    for j = 1:size(parentConditions,1)
        
        if i==1; bins=true(1,numConditions)'; else; bins = ismember(conditionsMat(1:i-1,:)', parentConditions(j,:), 'rows'); end
        
        for k = 1:numLevels(i)
            inds = find(conditionsMat(i,:)==k & bins');
            xPos = mean(xPositions(inds));
%             yPos = s.YLim(1)-labelVertSize*range(s.YLim) + ((labelVertSize*range(s.YLim))/length(dataDims)*i);
            yPos = s.YLim(1)-labelVertSize*range(s.YLim) + ((labelVertSize*range(s.YLim))/(length(s.levelNames)+1)*i);
            if i==numFactors; rotation = 25; else; rotation = 0; end
            if ~isempty(s.levelNames)
                condText = text(xPos, yPos, s.levelNames{i}(k), 'rotation', rotation, ...
                    'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'color', s.axisColor);
            end
            
            % add lines on the side of condition name
            if i<length(s.levelNames)
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




% ADD X AND Y AXES
set(gca, 'XColor', 'none', 'YColor', 'none');


if isempty(s.lineAtZero)
    s.lineAtZero = prod(s.YLim)<0 && s.showBars;  % if the y axis does not contain zero, horizontal line is at bottom of figure
end

if ~s.lineAtZero
	plot([0 0 xPositions(end)+s.sideBuffer], ...
        [s.YLim(2) s.YLim(1) s.YLim(1)], ...
        'color', s.axisColor)  % add line at y=0 zero
else
    plot([0 0], [s.YLim(2) s.YLim(1)], 'color', s.axisColor)
    plot([0 xPositions(end)+s.sideBuffer], [0 0], 'color', s.axisColor)
end

% y ticks
yLabelX = 0;  % this stores the right-most edge of the ylabel // it is updated below such that it hugs the widest ylabel that occurs
tickSz = s.tickWidth*range(xPositions);
plot([tickSz, 0], repmat(s.YTick,2,1), 'Color', s.axisColor)

if s.edgeLabelsOnly; ticks = [1 length(s.YTick)]; else; ticks = 1:length(s.YTick); end
for i = ticks
    tickText = text(-tickSz, s.YTick(i), yTickLabels{i}, ...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');
    textPos = get(tickText, 'Extent');
    if textPos(1)<yLabelX; yLabelX = textPos(1); end
end

% add y axis label
if ~isempty(s.ylabel)
    y = mean(s.YLim);
    text(yLabelX, y, s.ylabel, 'Rotation', 90, ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'Interpreter', 'none')
end

% add room below figure for labels
if ~isempty(s.levelNames)
    yMin = s.YLim(1)-labelVertSize*range(s.YLim);
    s.YLim = [yMin, s.YLim(2)];
end

% reset axis ticks and limits
set(gca, 'YLim', s.YLim, 'XLim', [0 xPositions(end)+s.sideBuffer], 'Color', figColor)




% ADD STATS
if s.comparisons
    
    fprintf('\n%s comparisons\n----------------------\n', s.test)
    notOccupied = true(size(s.comparisons,1), length(xPositions));
    tickSz = s.bracketSz*range(s.YLim);
    maxHgt = 1;  % keep track of how many vertical 'stacks' of brackets there are above the plot
    if isempty(s.sigColor); s.sigColor = s.axisColor; end
    
    for i = 1:size(s.comparisons,1)
        
        x = s.comparisons(i,:);  % x inds of conditions to be compared
        
        % run statistical test
        switch s.test
            case 'ttest'
                [~, p] = ttest(allData{x(1)}, allData{x(2)});
            case 'signrank'
                p = signrank(allData{x(1)}, allData{x(2)});
        end
        
        % determine whether significance is reached
        pInd = find(p<s.pThresh, 1, 'last');
        isSig = ~isempty(pInd);
        
        % set significance dependent parameters
        if isSig
            t = s.symbols{pInd};
            props = {'VerticalAlignment', 'middle', 'FontSize', 10};
            offset = .25*tickSz;
            c = s.sigColor;
        else
            t = s.notSigText;
            props = {'VerticalAlignment', 'bottom', 'FontSize', 10};
            offset = 0;
            c = s.axisColor;
        end
        
        % print results
        fprintf('%2i->%2i, p = %.2d = %.5f %s\n', x(1), x(2), p, p, t)
        
        % determine how high the bracket will be
        hgt = 1;
        while ~all(notOccupied(hgt, x(1):x(2)))
            hgt = hgt + 1;
            maxHgt = max(maxHgt, hgt);
        end
        notOccupied(hgt, x(1):x(2)) = false;
        y = s.YLim(2) + hgt*tickSz*1.5;
        
        % add bracket
        if s.showBracketTicks
            plot(xPositions([x(1) x(1) x(2) x(2)]), [y-tickSz y y y-tickSz], 'Color', c)
        else
            plot(xPositions([x(1) x(2)]), [y y], 'Color', c)
        end
        
        % add text above bracket
        text(mean(xPositions(x)), y+offset, t, 'HorizontalAlignment', 'center', props{:}, 'Color', c)
    end
    fprintf('\n')
    
    set(gca, 'YLim', [s.YLim(1) s.YLim(2)+maxHgt*tickSz*1.5])
end









