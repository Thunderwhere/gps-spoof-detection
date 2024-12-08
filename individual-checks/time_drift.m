% Specify the file path
filePath = 'gnss_log_2024_10_27_11_47_14.nmea'; % Update with your file name

% Open the file and read the contents
fileID = fopen(filePath, 'r');
rawData = textscan(fileID, '%s', 'Delimiter', '\n'); % Read all lines
fclose(fileID);
rawData = rawData{1}; % Store the lines in a cell array

% Filter for $GPRMC sentences
gprmcData = rawData(contains(rawData, '$GPRMC'));

% Initialize arrays to store times
times = [];

% Extract times from $GPRMC sentences
for i = 1:length(gprmcData)
    fields = split(gprmcData{i}, ','); % Split the sentence into fields
    if length(fields) >= 2
        times = [times, str2double(fields{2})]; % Convert time to numeric and store
    end
end

% Compare the GPS-reported time to a trusted source (e.g., a local atomic clock or network time)
% For simplicity, let's assume we have a trusted time array
trustedTimes = times + randn(size(times)) * 0.001; % Simulate trusted times with small random noise

% Calculate time drift
timeDrift = times - trustedTimes;

% Detect anomalies
threshold = 0.001; % in seconds (1 millisecond)
anomalies = abs(timeDrift) > threshold;

% Display results
disp('Time Drift Values:');
disp(timeDrift);
disp('Anomalous Time Drift Values:');
disp(timeDrift(anomalies));

% Plot the results
figure;
plot(timeDrift, 'o-'); % Plot all time drift values
hold on;
plot(find(anomalies), timeDrift(anomalies), 'rx', 'LineWidth', 2); % Highlight anomalies
title('Time Drift Analysis');
xlabel('Observation Index');
ylabel('Time Drift (seconds)');
legend('Time Drift Values', 'Anomalies');