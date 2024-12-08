% Specify the file path
filePath = 'gnss_log_2024_10_27_11_47_14.nmea'; % Update with your file name

% Open the file and read the contents
fileID = fopen(filePath, 'r');
rawData = textscan(fileID, '%s', 'Delimiter', '\n'); % Read all lines
fclose(fileID);
rawData = rawData{1}; % Store the lines in a cell array

% Filter for $GNRMC sentences
gnrmcData = rawData(contains(rawData, '$GNRMC'));

% Initialize arrays to store Doppler shifts
dopplerShifts = [];

% Extract Doppler shifts from $GNRMC sentences
for i = 1:length(gnrmcData)
    fields = split(gnrmcData{i}, ','); % Split the sentence into fields
    if length(fields) >= 8
        dopplerShifts = [dopplerShifts, str2double(fields{8})]; % Convert Doppler shift to numeric and store
    end
end

% Calculate the Doppler effect using known satellite orbital data and compare it to received signals
% For simplicity, let's assume we have a trusted Doppler shift array
trustedDopplerShifts = dopplerShifts + randn(size(dopplerShifts)) * 0.1; % Simulate trusted Doppler shifts with small random noise

% Calculate Doppler shift anomalies
dopplerAnomalies = dopplerShifts - trustedDopplerShifts;

% Detect anomalies
threshold = 0.1; % in Hz
anomalies = abs(dopplerAnomalies) > threshold;

% Display results
disp('Doppler Shift Values:');
disp(dopplerShifts);
disp('Anomalous Doppler Shift Values:');
disp(dopplerShifts(anomalies));

% Plot the results
figure;
plot(dopplerShifts, 'o-'); % Plot all Doppler shift values
hold on;
plot(find(anomalies), dopplerShifts(anomalies), 'rx', 'LineWidth', 2); % Highlight anomalies
title('Doppler Shift Analysis');
xlabel('Observation Index');
ylabel('Doppler Shift (Hz)');
legend('Doppler Shift Values', 'Anomalies');