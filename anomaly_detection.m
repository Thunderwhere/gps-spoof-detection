%tuning
threshold = 0.03; % in km (100 meters)


% Specify the file path
filePath = 'gnss-data/gnss_log_2024_11_18_14_17_21.nmea'; % Update with your file name
%filePath = 'spoofed_nmea_data.nmea';


% Open the file and read the contents
fileID = fopen(filePath, 'r');
rawData = textscan(fileID, '%s', 'Delimiter', '\n'); % Read all lines
fclose(fileID);
rawData = rawData{1}; % Store the lines in a cell array

% Filter for $GNGGA sentences
gnggaData = rawData(contains(rawData, '$GNGGA'));

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

% Now apply the anomaly detection code for position jumps
R = 6371; % Radius of the Earth in km
haversineDist = @(lat1, lon1, lat2, lon2) R * acos(sin(deg2rad(lat1)) * sin(deg2rad(lat2)) + cos(deg2rad(lat1)) * cos(deg2rad(lat2)) * cos(deg2rad(lon2) - deg2rad(lon1)));

% Initialize an array to store anomaly indices
anomalyIndices = [];

for i = 2:length(latitudes) % Start from the second data point
    dist = haversineDist(latitudes(i-1), longitudes(i-1), latitudes(i), longitudes(i)); % Calculate distance between consecutive points
    if dist > threshold
        fprintf('Anomaly detected between point %d and point %d. Distance: %.2f km\n', i-1, i, dist);
        anomalyIndices = [anomalyIndices, i]; % Store the index of the anomaly
    end
end

% Filter for $GPGSV sentences
gpgsvData = rawData(contains(rawData, '$GPGSV'));

% Initialize an array to store SNR values
snrValues = [];

% Extract SNR values from $GPGSV sentences
for i = 1:length(gpgsvData)
    fields = split(gpgsvData{i}, ','); % Split the sentence into fields
    for j = 8:4:length(fields) % SNR values start at the 8th field and repeat every 4 fields
        if j <= length(fields) && ~isempty(fields{j})
            snrValue = str2double(fields{j}); % Convert SNR to numeric
            allSnrValues = [snrValues, snrValue];
            if snrValue >= 0 && snrValue <= 50 % Filter out unreasonable SNR values
                snrValues = [snrValues, snrValue]; % Store valid SNR values
            end
        end
    end
end

% Analyze SNR anomalies
meanSNR = mean(snrValues, 'omitnan');
stdSNR = std(snrValues, 'omitnan');
highThreshold = meanSNR + 2 * stdSNR;
lowThreshold = meanSNR - 2 * stdSNR;

% Display the calculated values
    fprintf('Mean SNR: %.2f\n', meanSNR);
    fprintf('Standard Deviation of SNR: %.2f\n', stdSNR);
    fprintf('High Threshold: %.2f\n', highThreshold);
    fprintf('Low Threshold: %.2f\n', lowThreshold);

% Detect anomalies
anomalies = allSnrValues > highThreshold | allSnrValues < lowThreshold;

% Display results
disp('Anomalous SNR Values:');
disp(allSnrValues(anomalies));

% Plot the results
figure;
subplot(2, 1, 1);
scatter(longitudes, latitudes, 'filled');
hold on;
scatter(longitudes(anomalyIndices), latitudes(anomalyIndices), 'rx', 'LineWidth', 2); % Highlight positional anomalies
title('GNSS Data Points');
xlabel('Longitude');
ylabel('Latitude');

% Mark SNR anomalies on the scatter plot
snrAnomalyIndices = find(anomalies);
scatter(longitudes(snrAnomalyIndices), latitudes(snrAnomalyIndices), 'go', 'LineWidth', 2); % Highlight SNR anomalies

legend({'Data Points', 'Positional Anomalies', 'SNR Anomalies'});
hold off;

subplot(2, 1, 2);
scatter(1:length(allSnrValues), allSnrValues, 'b'); % Plot SNR values
hold on;
scatter(snrAnomalyIndices, allSnrValues(anomalies), 'r', 'filled'); % Highlight SNR anomalies
title('Signal-to-Noise Ratio (SNR) Analysis');
xlabel('Data Point Index');
ylabel('SNR (dB)');
legend({'SNR Values', 'Anomalies'});
hold off;