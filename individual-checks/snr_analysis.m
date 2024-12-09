% Specify the file path
filePath = 'gnss_log_2024_10_27_11_47_14.nmea'; % Update with your file name

% Open the file and read the contents
fileID = fopen(filePath, 'r');
if fileID == -1
    error('Failed to open file: %s', filePath);
end
rawData = textscan(fileID, '%s', 'Delimiter', '\n'); % Read all lines
fclose(fileID);
rawData = rawData{1}; % Store the lines in a cell array

% Filter for $GPGSV sentences
gpgsvData = rawData(contains(rawData, '$GPGSV'));

% Initialize an array to store SNR values
snrValues = [];

% Extract SNR values from $GPGSV sentences
for i = 1:length(gpgsvData)
    fields = split(gpgsvData{i}, ','); % Split the sentence into fields
    for j = 8:4:length(fields) % SNR values start at the 8th field and repeat every 4 fields
        if j <= length(fields) && ~isempty(fields{j})
            snrValues = [snrValues, str2double(fields{j})]; % Convert SNR to numeric and store
        end
    end
end

% Analyze SNR anomalies
meanSNR = mean(snrValues, 'omitnan');
stdSNR = std(snrValues, 'omitnan');
highThreshold = meanSNR + 2 * stdSNR;
lowThreshold = meanSNR - 2 * stdSNR;

% Detect anomalies
anomalies = snrValues > highThreshold | snrValues < lowThreshold;

% Display results
disp('Extracted SNR Values:');
disp(snrValues);
disp('Anomalous SNR Values:');
disp(snrValues(anomalies));

% Plot the results
figure;
plot(snrValues, 'o-'); % Plot all SNR values
hold on;
plot(find(anomalies), snrValues(anomalies), 'rx', 'LineWidth', 2); % Highlight anomalies
title('Signal-to-Noise Ratio (SNR) Analysis');
xlabel('Observation Index');
ylabel('SNR (dB)');
legend('SNR Values', 'Anomalies');
