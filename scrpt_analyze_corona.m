function scrpt_analyze_corona

close all;

% get the list of countries
list_cntrs_1st_wave = {'China', 'South Korea', 'Japan', 'Iran'};
list_cntrs_2nd_wave = {'Italy', 'Spain', 'France'};
list_cntrs_3rd_wave = {'United States', 'United Kingdom', 'Israel'};
list_cntrs_forgotten = {'Germany', 'Austria', 'Belgium', 'Netherlands', 'Denmark', 'Switzerland', 'Sweden', 'Norway'};
list_cntrs_east_europe = {'Poland', 'Belarus', 'Czech Republic', 'Romania'};
list_cntrs_arabic = {'Egypt', 'Algeria', 'Morocco', 'Tunisia', 'Saudi Arabia'};
list_list_countries_to_plot = {...
  list_cntrs_1st_wave, ...
  list_cntrs_2nd_wave, ...
  list_cntrs_3rd_wave, ...
  list_cntrs_forgotten, ...
  list_cntrs_east_europe, ...
  list_cntrs_arabic};

% load information from csv table
[crn_txt, crn_data] = import_current_corona_status();
[pop_txt, pop_data] = import_population_data();

% just for manual searching
list_countries_all = get_list_countries(crn_txt);

for idx = 1: length(list_list_countries_to_plot)
  list_countries_to_plot = list_list_countries_to_plot{idx};
  % plot a graph for a specific list of countries
  plot_graph_list_of_countries(...
    crn_txt, crn_data, pop_txt, pop_data, ...
    list_countries_to_plot);
end

end


function [textdata, data] = import_current_corona_status()

tmp = importdata('table_corona.csv');
textdata = tmp.textdata;
data = tmp.data;

end


function [textdata, data] = import_population_data()

load('table_population.mat', 'textdata', 'data');

end



function plot_graph_list_of_countries(...
  crn_txt, crn_data, pop_txt, pop_data, ...
  list_countries_to_plot)

% allocate variables
n_countries = length(list_countries_to_plot);
data_cases = cell(1, n_countries);
data_deaths = cell(1, n_countries);
dates_all = cell(1, n_countries);
pop_all = zeros(1, n_countries);

for idx_country = 1: length(list_countries_to_plot)
  % get the data for this country
  str_country = list_countries_to_plot{idx_country};
  [data_country, dates] = filter_data_by_country(str_country, crn_txt, crn_data);
  % collect the data to arrays
  data_cases{idx_country} = data_country(:, 3);
  data_deaths{idx_country} = data_country(:, 4);
  dates_all{idx_country} = dates;
  % find the total population of this country
  idx_pop_country = find(strcmp(pop_txt(:, 3), str_country)) - 1;
  pop_all(idx_country) = pop_data(idx_pop_country, end);
end

% plot the data
plot_all(dates_all, data_cases, data_deaths, pop_all, list_countries_to_plot);

end


function [data_country, dates] = filter_data_by_country(str_country, textdata, data)
idxs = strcmp(textdata(:, 2), str_country);
dates = textdata(idxs, 1);
data_country = data(idxs, :);
end


function plot_all(dates_all, data_cases, data_deaths, pop_all, list_countries_to_plot)

n_vectors = length(dates_all);
fig = figure('Position', [50, 50, 1800, 900]);
first_date_to_plot = 1e9 * ones(1, n_vectors);
vec_color = get_cell_color();
hold on;
for idx = 1: n_vectors
  % get the corona data to plot
  dates = datenum(dates_all{idx});
  data_cases_norm = data_cases{idx} / (1e3 * pop_all(idx));
  data_cases_norm = 10 * log10(data_cases_norm);
  data_deaths_norm = data_deaths{idx} / (1e3 * pop_all(idx));
  data_deaths_norm = 10 * log10(data_deaths_norm);
  min_ratio_to_display = get_min_ratio_to_display();
  idx_tmp = find(data_cases_norm > min_ratio_to_display, 1);
  if ~isempty(idx_tmp), first_date_to_plot(idx) = dates(idx_tmp); end
  plot(dates, data_cases_norm, 'linewidth', 2, 'color', vec_color{idx});
  plot(dates, data_deaths_norm, 'linewidth', 2, 'linestyle', ':', 'color', vec_color{idx});
end

date_first = min(first_date_to_plot);
date_last = dates(end);
set_plot_parameters(list_countries_to_plot, date_first, date_last);

filename_fig = cell2mat(list_countries_to_plot);
filename_fig = strrep(filename_fig, ' ', '');
filename_fig = [filename_fig, '.png'];
saveas(fig, filename_fig);

end


function set_plot_parameters(list_countries_to_plot, date_first, date_last)

% parameters
vector_magnitude = get_vector_magnitude();
vector_magnitude_ticklabels = 1e6 * vector_magnitude;
vector_magnitude_db = 10 * log10(vector_magnitude);
% vector_magnitude_db = get_vector_magnitude_db();
% vector_magnitude = 1e6 * 10 .^ (vector_magnitude_db ./ 10);

yticks(vector_magnitude_db);
yticklabels(vector_magnitude_ticklabels);
grid on;
vec_legend = repmat(list_countries_to_plot, [2,1]);
for idx = 1: size(vec_legend, 2)
  vec_legend{1, idx} = [vec_legend{1, idx}, ' (cases)'];
  vec_legend{2, idx} = [vec_legend{2, idx}, ' (deaths)'];
end
vec_legend = vec_legend(:);
legend(vec_legend, 'Location', 'northwest');
ylabel(get_str_ylabel());

vec_xticks = (date_first: 3: date_last);
vec_xtick_labels = datestr(vec_xticks, 'mm-dd');
xticks(vec_xticks);
xticklabels(vec_xtick_labels);

ylim([vector_magnitude_db(1), vector_magnitude_db(end)]);
xlim([date_first, date_last - 1]);

set(gca, 'fontsize', 14);
set(gca, 'fontname', 'times');

end


function [list_countries, list_dates] = get_list_countries(textdata)
list_countries = unique(textdata(2: end, 2));
list_dates = unique(textdata(2: end, 1));
end


function vector_magnitude = get_vector_magnitude()
vector_magnitude = [3e-7, 1e-6, 3e-6, 1e-5, 3e-5, 1e-4, 3e-4, 1e-3, 3e-3];
end

function vec_mag_db = get_vector_magnitude_db()
vec_mag_db = -65:5:-25;
end


function min_ratio_to_display = get_min_ratio_to_display()
vector_magnitude_db = get_vector_magnitude_db();
min_ratio_to_display = vector_magnitude_db(1);
end


function str_ylabel = get_str_ylabel()
str_ylabel = 'number of [sick/dead] per million';
end


function vec_color = get_cell_color()
vec_color = {...
    [0,0,0], ...
    [0,0,1], ...
    [0,0.5,0], ...
    [0,1,0], ...
    [0.5,0.5,0], ...
    [0.5,0,0], ...
    [0.8,0,0], ...
    [0.8,0,0.8]};
end
