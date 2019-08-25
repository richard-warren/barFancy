# fancy bar plots!
I'm sick and tired of plots that aren't fancy! `barFancy` allows you to make beautiful bar plots for simple data, as well as datasets with arbitrarily complex factor hierarchies.

Imagine you are trying to figure out when people are most grumpy. You guess that grumpiness varies with certain **factors**, such as the season, the day of the week, and the time of day. Each of these factors has multiple **levels** (summer/winter, weekday/weekend, morning/noon/night). With `barFancy` you can quickly generate bar plots that show the hierarchical relationships between your factors:

![](exampleImages/bar2.png)


`barFancy` takes as input a *number of factors + 1* dimensional data matrix, where each dimension is a factor, and the last dimension contains data from all of your samples. There are tons of visualization options that can be passed in as Name-Value pairs (see below).

## example
Let's start by generating some fake grumpiness data:
```Matlab
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
```

Let's check out the default plot:
```
% default settings
barFancy(mood, 'levelNames', levels, 'ylabel', 'grumpiness', 'colors', colors)
```
![](exampleImages/bar1.png)


It's super trivial to reorder the factor hierarchy. Simply change the order of the dimensions in your matrix, and you're done!
```
% reshuffled factor hierarchy
moodShuffled = permute(mood, [3,1,2,4]);
levelsShuffled = levels([3,1,2]);
barFancy(moodShuffled, 'levelNames', levelsShuffled, 'ylabel', 'grumpiness', 'colors', 'jet')

```
![](exampleImages/bar5.png)


There are tons of visualization options. Here are some examples of what you can play around with:
```
% violin plot
barFancy(mood, 'levelNames', levels, 'ylabel', 'grumpiness', 'colors', colors, ...
    'showBars', false', 'showViolins', true)
```
![](exampleImages/bar2.png)

```
% plot with no bars, median instead of mean, and connected scatter points
barFancy(mood, 'levelNames', levels, 'ylabel', 'grumpiness', 'colors', colors, ...
    'showBars', false', 'summaryFunction', @median, 'connectDots', true)
```
![](exampleImages/bar3.png)

```
% bar plot with solid bars, no scatter points, and no error bars
barFancy(mood, 'levelNames', levels, 'ylabel', 'grumpiness', 'colors', colors, ...
    'barAlpha', 1, 'showScatter', false)
```
![](exampleImages/bar4.png)

## options
