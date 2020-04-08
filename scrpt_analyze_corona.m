function scrpt_analyze_corona

close all;

what_to_plot = 'total_cases'; %   'total_deaths'   'total_cases'

% get the list of countries
list_cntrs_1st_wave = {'China', 'South Korea', 'Japan', 'Iran'};
list_cntrs_2nd_wave = {'Italy', 'Spain', 'France'};
list_cntrs_3rd_wave = {'United States', 'United Kingdom', 'Israel'};
list_cntrs_forgotten = {'Germany', 'Austria', 'Belgium', 'Netherlands', 'Denmark', 'Switzerland', 'Sweden', 'Norway'};
list_cntrs_east_europe = {'Poland', 'Belarus', 'Czech Republic', 'Romania'};
list_cntrs_arabic = {'Egypt', 'United Arab Emirates', 'Algeria', 'Morocco', 'Tunisia', 'Bahrain', 'Saudi Arabia'};
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
    list_countries_to_plot, what_to_plot);
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
  list_countries_to_plot, what_to_plot)

% determine which column to used, i.e., which data to plot
idx_data_to_plot = str_to_idx_data_to_plot(what_to_plot);

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
plot_all(dates_all, data_cases, data_deaths, pop_all, ...
  list_countries_to_plot, what_to_plot);

end


function [data_country, dates] = filter_data_by_country(str_country, textdata, data)
idxs = strcmp(textdata(:, 2), str_country);
dates = textdata(idxs, 1);
data_country = data(idxs, :);
end


function plot_all(dates_all, data_cases, data_deaths, pop_all, ...
  list_countries_to_plot, what_to_plot)

n_vectors = length(dates_all);
fig = figure('name', what_to_plot, ...
  'Position', [50, 50, 1400, 700]);
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
  min_ratio_to_display = get_min_ratio_to_display(what_to_plot);
  idx_tmp = find(data_cases_norm > min_ratio_to_display, 1);
  if ~isempty(idx_tmp), first_date_to_plot(idx) = dates(idx_tmp); end
  plot(dates, data_cases_norm, 'linewidth', 2, 'color', vec_color{idx});
  plot(dates, data_deaths_norm, 'linewidth', 2, 'linestyle', ':', 'color', vec_color{idx});
end

date_first = min(first_date_to_plot);
date_last = dates(end);
set_plot_parameters(list_countries_to_plot, date_first, date_last, what_to_plot);

filename_fig = cell2mat(list_countries_to_plot);
filename_fig = strrep(filename_fig, ' ', '');
filename_fig = [filename_fig, '.png'];
saveas(fig, filename_fig);

end


function set_plot_parameters(...
  list_countries_to_plot, date_first, date_last, what_to_plot)

% parameters
vector_magnitude_db = get_vector_magnitude_db(what_to_plot);
vector_magnitude = 10 .^ (-vector_magnitude_db ./ 10);

yticks(vector_magnitude_db);
yticklabels(vector_magnitude);
grid on;
vec_legend = repmat(list_countries_to_plot, [2,1]);
for idx = 1: size(vec_legend, 2)
  vec_legend{1, idx} = [vec_legend{1, idx}, ' (cases)'];
  vec_legend{2, idx} = [vec_legend{2, idx}, ' (deaths)'];
end
vec_legend = vec_legend(:);
legend(vec_legend, 'Location', 'northwest');
ylabel(get_str_ylabel(what_to_plot));

vec_xticks = (date_first: 3: date_last);
vec_xtick_labels = datestr(vec_xticks, 'mmm-dd');
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


function idx_data_to_plot = str_to_idx_data_to_plot(what_to_plot)
if strcmp(what_to_plot, 'total_cases')
  idx_data_to_plot = 3;
elseif strcmp(what_to_plot, 'total_deaths')
  idx_data_to_plot = 4;
else
  disp(['data to plot not found in table! what_to_plot = ',...
    what_to_plot]);
end
end


function vec_mag_db = get_vector_magnitude_db(what_to_plot)
if strcmp(what_to_plot, 'total_cases')
  vec_mag_db = -65:5:-20;
elseif strcmp(what_to_plot, 'total_deaths')
  vec_mag_db = -65:5:-30;
else
  disp(['data to plot not found in table! what_to_plot = ',...
    what_to_plot]);
end
end


function min_ratio_to_display = get_min_ratio_to_display(what_to_plot)
vector_magnitude_db = get_vector_magnitude_db(what_to_plot);
min_ratio_to_display = vector_magnitude_db(1);
end


function str_ylabel = get_str_ylabel(what_to_plot)
if strcmp(what_to_plot, 'total_cases')
  str_ylabel = 'one (sick/dead) out of...';
elseif strcmp(what_to_plot, 'total_deaths')
  str_ylabel = 'one death out of...';
else
  disp(['data to plot not found in table! what_to_plot = ',...
    what_to_plot]);
end
end


function vec_color = get_cell_color()
vec_color = {[0,0,0], [0,0,1], [0,0.5,0.5], [0,0.5,0], [0,1,0], [0.5,1,0], [0.5,0.5,0], [0.5,0,0], [1,0,0]};
end
