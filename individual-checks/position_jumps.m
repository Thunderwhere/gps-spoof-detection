% Specify the file path
%filePath = 'gnss_log_2024_11_18_13_21_59.nmea';
filePath = 'gnss_log_2024_11_18_14_17_21.nmea';
%filePath = 'spoofed_nmea_data.txt';

% Open the file
fileID = fopen(filePath, 'r'); % 'r' means read mode
rawData = textscan(fileID, '%s', 'Delimiter', '\n'); % Read all lines
fclose(fileID); % Close the file

% Extract the data
rawData = rawData{1}; % Store the lines in a cell array
disp('File loaded successfully!');

% Filter for $GNGGA sentences
gnggaData = rawData(contains(rawData, '$GNGGA')); % GPGGA for multi GNSS
disp('Extracted $GNGGA sentences.');

% Parse fields for latitude and longitude
parsedGNGGA = cellfun(@(line) split(line, ','), gnggaData, 'UniformOutput', false);

% Initialize arrays to store latitudes and longitudes
latitudes = zeros(length(parsedGNGGA), 1);
longitudes = zeros(length(parsedGNGGA), 1);

% Populate latitudes and longitudes arrays
for i = 1:length(parsedGNGGA)
    if length(parsedGNGGA{i}) < 6
        % Skip this entry if it does not have enough fields
        continue;
    end
    % Extract latitude and longitude from the correct parsed positions
    lat_str = parsedGNGGA{i}{4}; % Latitude (Degrees and Minutes)
    lon_str = parsedGNGGA{i}{6}; % Longitude (Degrees and Minutes)

    try
        % Latitude conversion (assuming the format is Degrees.Minutes)
        lat_deg = str2double(lat_str(1:2)); % Degrees part
        lat_min = str2double(lat_str(3:end)); % Minutes part
        lat = lat_deg + lat_min / 60; % Convert to decimal degrees

        % Adjust for South Latitude (if applicable)
        if contains(parsedGNGGA{i}{5}, 'S')
            lat = -lat;
        end

        % Longitude conversion (assuming the format is Degrees.Minutes)
        lon_deg = str2double(lon_str(1:3)); % Degrees part
        lon_min = str2double(lon_str(4:end)); % Minutes part
        lon = lon_deg + lon_min / 60; % Convert to decimal degrees

        % Adjust for West Longitude (if applicable)
        if contains(parsedGNGGA{i}{7}, 'W')
            lon = -lon;
        end

        % Store values in latitudes and longitudes arrays
        latitudes(i) = lat;
        longitudes(i) = lon;
    catch
        % If there's any issue with the data, skip the current iteration
        fprintf('Error processing line %d\n', i);
        continue;
    end
end

% Now apply the anomaly detection code
R = 6371; % Radius of the Earth in km
haversineDist = @(lat1, lon1, lat2, lon2) R * acos(sin(deg2rad(lat1)) * sin(deg2rad(lat2)) + cos(deg2rad(lat1)) * cos(deg2rad(lat2)) * cos(deg2rad(lon2) - deg2rad(lon1)));

threshold = 0.1; % in km (100 meters)

for i = 2:length(latitudes) % Start from the second data point
    dist = haversineDist(latitudes(i-1), longitudes(i-1), latitudes(i), longitudes(i)); % Calculate distance between consecutive points
    if dist > threshold
        fprintf('Anomaly detected between point %d and point %d. Distance: %.2f km\n', i-1, i, dist);
    end
end

% Plot the coordinates on a 2D scatter plot
figure;
scatter(longitudes, latitudes, 'filled');
title('GNSS Data Points');