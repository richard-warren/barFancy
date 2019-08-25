%% barFancy demo

% Here is a quick demo of the types of plots you can make with barFancy. I
% start by generating some fake hierarchical data and then show some fancy,
% fancy plots.

%% generate grumpiness data

% model how gumpy people are in different seasons, days, and times
levels = {{'summer', 'winter'}, ...
           {'weekday', 'weedend'}, ...
           {'morning', 'noon', 'night'}};  % 3 factors with 2, 2, and 3 levels
samples = 10;  % number of samples in each condition

% generate 2 (season) X 2 (day) X 3 (time) X samples matrix
mood = normrnd(0, 1, [2,2,3,samples]);
mood(2,:,:,:) = mood(2,:,:,:)+4; % grumpy in the winter       :(
mood(:,1,1,:) = mood(:,1,1,:)+4; % grumpy weekday mornings    :(
mood(:,2,:,:) = mood(:,2,:,:)-2; % less grumpy on weekends    :)

% make kick ass color scheme
colors = [hot(3); hot(3); winter(3); winter(3)] * .75;

%% bar plot
figure('Color', 'white', 'Position', [100 100, 800 400], 'MenuBar', 'none')
barFancy(mood, 'levelNames', levels, 'ylabel', 'grumpiness', 'colors', colors)

%% violin plot
figure('Color', 'white', 'Position', [100 100, 800 400], 'MenuBar', 'none')
barFancy(mood, 'levelNames', levels, 'ylabel', 'grumpiness', 'colors', colors, ...
    'showBars', false', 'showViolins', true)

%% plot with no bars, median instead of mean, and connected scatter points
figure('Color', 'white', 'Position', [100 100, 800 400], 'MenuBar', 'none')
barFancy(mood, 'levelNames', levels, 'ylabel', 'grumpiness', 'colors', colors, ...
    'showBars', false', 'summaryFunction', @median, 'connectDots', true)

%% bar plot with solid bars, no scatter points, and no error bars
figure('Color', 'white', 'Position', [100 100, 800 400], 'MenuBar', 'none')
barFancy(mood, 'levelNames', levels, 'ylabel', 'grumpiness', 'colors', colors, ...
    'barAlpha', 1, 'showScatter', false, 'showErrorBars', false)

%% reshuffle factor hierarchy

moodShuffled = permute(mood, [3,1,2,4]);
levelsShuffled = levels([3,1,2]);

figure('Color', 'white', 'Position', [100 100, 800 400], 'MenuBar', 'none')
barFancy(moodShuffled, 'levelNames', levelsShuffled, 'ylabel', 'grumpiness', 'colors', 'jet')

%% collapse across factor

moodCollapsed = squeeze(mean(mood, 1));  % collapse across seasons
levelsCollapsed = levels(2:end);

figure('Color', 'white', 'Position', [100 100, 400 400], 'MenuBar', 'none')
barFancy(moodCollapsed, 'levelNames', levelsCollapsed, 'ylabel', 'grumpiness', 'colors', 'jet')





