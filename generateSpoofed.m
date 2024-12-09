% FILE: generateSpoofedNMEA.m

% Number of data points to generate
numPoints = 100;

% Base values for spoofed data
baseLat = 42.3223; % Example latitude
baseLon = -83.1763; % Example longitude
baseSpeed = 3; % Speed in m/s
baseAltitude = 130; % Altitude in meters
baseHeading = 90; % Heading in degrees

% Thresholds for anomalies
baseSpeedThreshold = 15;
baseAltitudeThreshold = 20;
baseTimeIntervalThreshold = 5;
baseHeadingChangeThreshold = 45;
baseSNRThreshold = 30; % SNR threshold for anomalies
positionalAnomalyThreshold = 0.001; % Positional anomaly threshold in degrees

% Generate spoofed NMEA data
nmeaData = cell(numPoints * 2, 1); % Allocate space for both GPGGA and GPGSV sentences
for i = 1:numPoints
    % Simulate movement in one direction (eastward)
    lat = baseLat + (i - 1) * 0.0001; % Increment latitude slightly
    lon = baseLon + (i - 1) * 0.0001; % Increment longitude slightly
    speed = baseSpeed + (rand - 0.5) * 2; % Small random variation in speed
    altitude = baseAltitude + (rand - 0.5) * 5; % Small random variation in altitude
    heading = baseHeading + (rand - 0.5) * 10; % Small random variation in heading
    timestamp = datestr(now + (i-1)/1440, 'HHMMSS'); % Increment time by 1 minute

    % Introduce anomalies based on thresholds
    if rand < 0.1 % 10% chance to introduce a speed anomaly
        speed = baseSpeedThreshold + (rand * 10);
    end
    if rand < 0.1 % 10% chance to introduce an altitude anomaly
        altitude = baseAltitude + baseAltitudeThreshold + (rand * 10);
    end
    if rand < 0.1 % 10% chance to introduce a heading change anomaly
        heading = baseHeading + baseHeadingChangeThreshold + (rand * 20);
    end
    if rand < 0.1 % 10% chance to introduce a positional anomaly
        lat = lat + (rand - 0.5) * positionalAnomalyThreshold;
        lon = lon + (rand - 0.5) * positionalAnomalyThreshold;
    end

    % Create GPGGA sentence
    gpggaSentence = sprintf('$GPGGA,%s,%02.5f,N,%03.5f,W,1,08,0.9,%0.1f,M,0.0,M,,*47', ...
        timestamp, lat, lon, altitude);
    nmeaData{2*i-1} = gpggaSentence;

    % Generate GPGSV sentence
    numSatellites = 8; % Example number of satellites
    gpgsvSentence = sprintf('$GPGSV,3,%d,%02d', ceil(numSatellites/4), numSatellites);
    for j = 1:numSatellites
        elevation = randi([0, 90]); % Random elevation angle
        azimuth = randi([0, 359]); % Random azimuth angle
        snr = randi([20, 50]); % Random SNR value
        if rand < 0.1 % 10% chance to introduce an SNR anomaly
            snr = baseSNRThreshold + randi([10, 20]);
        end
        gpgsvSentence = sprintf('%s,%02d,%03d,%03d,%02d', gpgsvSentence, j, elevation, azimuth, snr);
    end
    gpgsvSentence = sprintf('%s*%02X', gpgsvSentence, mod(sum(double(gpgsvSentence(2:end))), 256)); % Add checksum
    nmeaData{2*i} = gpgsvSentence;
end

% Save the spoofed NMEA data to a text file
fileID = fopen('spoofedNMEA.txt', 'w');
for i = 1:length(nmeaData)
    fprintf(fileID, '%s\n', nmeaData{i});
end
fclose(fileID);

disp('Spoofed NMEA data generated and saved to spoofedNMEA.txt');