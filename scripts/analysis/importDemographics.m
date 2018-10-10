%% Import data from text file.
% Script for importing data from the following text file:
%
%    /data/joy/BBL/studies/pnc/n2416_dataFreeze/clinical/n2416_demographics_20170310.csv
%
% To extend the code to different selected data or a different text file,
% generate a function instead of a script.

% Auto-generated by MATLAB on 2018/09/25 12:04:07

%% Initialize variables.
filename = '/data/joy/BBL/studies/pnc/n2416_dataFreeze/clinical/n2416_demographics_20170310.csv';
delimiter = ',';
startRow = 2;

%% Read columns of data as text:
% For more information, see the TEXTSCAN documentation.
formatSpec = '%s%s%s%s%s%s%s%s%s%[^\n\r]';

%% Open the text file.
fileID = fopen(filename,'r');

%% Read columns of data according to the format.
% This call is based on the structure of the file used to generate this
% code. If an error occurs for a different file, try regenerating the code
% from the Import Tool.
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'TextType', 'string', 'HeaderLines' ,startRow-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');

%% Close the text file.
fclose(fileID);

%% Convert the contents of columns containing numeric text to numbers.
% Replace non-numeric text with NaN.
raw = repmat({''},length(dataArray{1}),length(dataArray)-1);
for col=1:length(dataArray)-1
    raw(1:length(dataArray{col}),col) = mat2cell(dataArray{col}, ones(length(dataArray{col}), 1));
end
numericData = NaN(size(dataArray{1},1),size(dataArray,2));

for col=[1,2,4,5,6,8,9]
    % Converts text in the input cell array to numbers. Replaced non-numeric
    % text with NaN.
    rawData = dataArray{col};
    for row=1:size(rawData, 1)
        % Create a regular expression to detect and remove non-numeric prefixes and
        % suffixes.
        regexstr = '(?<prefix>.*?)(?<numbers>([-]*(\d+[\,]*)+[\.]{0,1}\d*[eEdD]{0,1}[-+]*\d*[i]{0,1})|([-]*(\d+[\,]*)*[\.]{1,1}\d+[eEdD]{0,1}[-+]*\d*[i]{0,1}))(?<suffix>.*)';
        try
            result = regexp(rawData(row), regexstr, 'names');
            numbers = result.numbers;
            
            % Detected commas in non-thousand locations.
            invalidThousandsSeparator = false;
            if numbers.contains(',')
                thousandsRegExp = '^[-/+]*\d+?(\,\d{3})*\.{0,1}\d*$';
                if isempty(regexp(numbers, thousandsRegExp, 'once'))
                    numbers = NaN;
                    invalidThousandsSeparator = true;
                end
            end
            % Convert numeric text to numbers.
            if ~invalidThousandsSeparator
                numbers = textscan(char(strrep(numbers, ',', '')), '%f');
                numericData(row, col) = numbers{1};
                raw{row, col} = numbers{1};
            end
        catch
            raw{row, col} = rawData{row};
        end
    end
end

dateFormatIndex = 1;
blankDates = cell(1,size(raw,2));
anyBlankDates = false(size(raw,1),1);
invalidDates = cell(1,size(raw,2));
anyInvalidDates = false(size(raw,1),1);
for col=[3,7]% Convert the contents of columns with dates to MATLAB datetimes using the specified date format.
    try
        dates{col} = datetime(dataArray{col}, 'Format', 'MM/dd/yyyy', 'InputFormat', 'MM/dd/yy'); %#ok<SAGROW>
    catch
        try
            % Handle dates surrounded by quotes
            dataArray{col} = cellfun(@(x) x(2:end-1), dataArray{col}, 'UniformOutput', false);
            dates{col} = datetime(dataArray{col}, 'Format', 'MM/dd/yyyy', 'InputFormat', 'MM/dd/yyyy'); %#ok<SAGROW>
        catch
            dates{col} = repmat(datetime([NaN NaN NaN]), size(dataArray{col})); %#ok<SAGROW>
        end
    end
    
    dateFormatIndex = dateFormatIndex + 1;
    blankDates{col} = dataArray{col} == '';
    anyBlankDates = blankDates{col} | anyBlankDates;
    invalidDates{col} = isnan(dates{col}.Hour) - blankDates{col};
    anyInvalidDates = invalidDates{col} | anyInvalidDates;
end
dates = dates(:,[3,7]);
blankDates = blankDates(:,[3,7]);
invalidDates = invalidDates(:,[3,7]);

%% Split data into numeric and string columns.
rawNumericColumns = raw(:, [1,2,4,5,6,8,9]);

%% Replace non-numeric cells with NaN
R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),rawNumericColumns); % Find non-numeric cells
rawNumericColumns(R) = {NaN}; % Replace non-numeric cells

%% Create output variable
demographics = table;
demographics.bblid = cell2mat(rawNumericColumns(:, 1));
demographics.scanid = cell2mat(rawNumericColumns(:, 2));
demographics.DOSCAN = dates{:, 1};
demographics.sex = cell2mat(rawNumericColumns(:, 3));
demographics.race = cell2mat(rawNumericColumns(:, 4));
demographics.ethnicity = cell2mat(rawNumericColumns(:, 5));
demographics.dob = dates{:, 2};
demographics.scanageMonths = cell2mat(rawNumericColumns(:, 6));
demographics.scanageYrs = cell2mat(rawNumericColumns(:, 7));

% For code requiring serial dates (datenum) instead of datetime, uncomment
% the following line(s) below to return the imported dates as datenum(s).

% n2416demographics1.DOSCAN=datenum(n2416demographics1.DOSCAN);
% n2416demographics1.dob=datenum(n2416demographics1.dob);

%% Clear temporary variables
clearvars filename delimiter startRow formatSpec fileID dataArray ans raw col numericData rawData row regexstr result numbers invalidThousandsSeparator thousandsRegExp dateFormatIndex dates blankDates anyBlankDates invalidDates anyInvalidDates rawNumericColumns R;