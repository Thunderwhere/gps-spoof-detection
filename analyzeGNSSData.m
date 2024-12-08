function analyzeGNSSData(m, dataFile)
    % Enable GNSS sensor and Logging if in real-time mode
    if nargin < 2
        m.PositionSensorEnabled = 1;
        m.Logging = 1;
    end

    % Initialize variables for plotting
    figure;
    h = plot(NaN, NaN, 'bo-');
    xlabel('Longitude');
    ylabel('Latitude');
    title('GNSS Data with Anomaly Detection');
    hold on;

    % Initialize anomaly plots with different colors
    jumpAnomalyPlot = plot(NaN, NaN, 'ro', 'MarkerFaceColor', 'r'); % Red for positional jumps
    speedAnomalyPlot = plot(NaN, NaN, 'go', 'MarkerFaceColor', 'g'); % Green for speed anomalies
    altitudeAnomalyPlot = plot(NaN, NaN, 'mo', 'MarkerFaceColor', 'm'); % Magenta for altitude anomalies
    timeAnomalyPlot = plot(NaN, NaN, 'co', 'MarkerFaceColor', 'c'); % Cyan for time interval anomalies
    headingAnomalyPlot = plot(NaN, NaN, 'yo', 'MarkerFaceColor', 'y'); % Yellow for heading change anomalies

    % Add legend
    legend([h, jumpAnomalyPlot, speedAnomalyPlot, altitudeAnomalyPlot, timeAnomalyPlot, headingAnomalyPlot], ...
        {'GNSS Data', 'Positional Jump', 'Speed Anomaly', 'Altitude Anomaly', 'Time Interval Anomaly', 'Heading Change Anomaly'});

    % Base thresholds for detecting anomalies
    baseJumpThreshold = 2; % Positional jump threshold in meters
    baseSpeedThreshold = 1.5; % Speed threshold in m/s for walking
    baseAltitudeThreshold = 18; % Altitude change threshold in meters
    baseTimeIntervalThreshold = 4; % Time interval threshold in seconds
    baseHeadingChangeThreshold = 45; % Heading change threshold in degrees

    % Main loop for data processing
    try
        if nargin < 2
            % Real-time mode
            while true
                % Get the latest GNSS data
                [lat, lon, timestamp, speed, course, alt, horizacc] = poslog(m);
                processGNSSData(lat, lon, alt, timestamp, speed, course, horizacc, h, jumpAnomalyPlot, speedAnomalyPlot, altitudeAnomalyPlot, timeAnomalyPlot, headingAnomalyPlot, ...
                    baseJumpThreshold, baseSpeedThreshold, baseAltitudeThreshold, baseTimeIntervalThreshold, baseHeadingChangeThreshold);
                pause(1); % Pause for a short time to allow for real-time updates
            end
        else
            % Post-analysis mode
            nmeaData = fileread(dataFile); % Load NMEA data from file
            nmeaSentences = strsplit(nmeaData, '\n'); % Split data into sentences

            for i = 1:length(nmeaSentences)
                sentence = nmeaSentences{i};
                if startsWith(sentence, 'NMEA,$GPGGA') || startsWith(sentence, 'NMEA,$GNRMC')
                    disp(['Parsing sentence: ', sentence]); % Log the sentence being parsed
                    [lat, lon, timestamp, speed, course, alt, horizacc] = parseNMEASentence(sentence);
                    disp(['Parsed data - Lat: ', num2str(lat), ', Lon: ', num2str(lon), ', Timestamp: ', timestamp, ...
                          ', Speed: ', num2str(speed), ', Course: ', num2str(course), ', Altitude: ', num2str(alt), ...
                          ', Horizontal Accuracy: ', num2str(horizacc)]); % Log the parsed data
                    processGNSSData(lat, lon, alt, timestamp, speed, course, horizacc, h, jumpAnomalyPlot, speedAnomalyPlot, altitudeAnomalyPlot, timeAnomalyPlot, headingAnomalyPlot, ...
                        baseJumpThreshold, baseSpeedThreshold, baseAltitudeThreshold, baseTimeIntervalThreshold, baseHeadingChangeThreshold);
                end
            end
        end
    catch ME
        disp(['Error: ', ME.message]);
    end
end

function processGNSSData(lat, lon, alt, timestamp, speed, course, horizacc, h, jumpAnomalyPlot, speedAnomalyPlot, altitudeAnomalyPlot, timeAnomalyPlot, headingAnomalyPlot, ...
    baseJumpThreshold, baseSpeedThreshold, baseAltitudeThreshold, baseTimeIntervalThreshold, baseHeadingChangeThreshold)
    % Parameters for smoothing
    windowSize = 5; % Adjust the window size as needed
    minDistance = 5; % Minimum distance in meters to consider for heading change

    % Smooth the latitude and longitude data
    lat = movingAverage(lat, windowSize);
    lon = movingAverage(lon, windowSize);

    % Check if there is enough data to process
    if length(lat) > 1
        % Calculate the distance between consecutive points
        distances = haversine(lat(end-1:end), lon(end-1:end));

        % Calculate the time difference between consecutive points
        timeDiff = diff(timestamp(end-1:end));

        % Calculate the altitude change between consecutive points
        altitudeChange = abs(diff(alt(end-1:end)));

        % Calculate the heading change between consecutive points if distance is above the threshold
        if distances(end) > minDistance
            headingChange = abs(atan2d(sind(lon(end) - lon(end-1)) * cosd(lat(end)), cosd(lat(end-1)) * sind(lat(end)) - sind(lat(end-1)) * cosd(lat(end)) * cosd(lon(end) - lon(end-1))));
        else
            headingChange = 0;
        end

        % Scale thresholds based on speed and horizontal accuracy
        jumpThreshold = baseJumpThreshold * (1 + speed(end) / baseSpeedThreshold) * (1 + horizacc(end) / 10);
        headingChangeThreshold = baseHeadingChangeThreshold * (1 + speed(end) / baseSpeedThreshold) * (1 + horizacc(end) / 10);
        dynamicSpeedThreshold = baseSpeedThreshold * (1 + speed(end) / baseSpeedThreshold) * (1 + horizacc(end) / 10);

        % Detect positional jumps
        if distances(end) > jumpThreshold
            % Update anomaly plot
            set(jumpAnomalyPlot, 'XData', [get(jumpAnomalyPlot, 'XData'), lon(end)], 'YData', [get(jumpAnomalyPlot, 'YData'), lat(end)]);
            % Log a message indicating an anomaly
            disp(['Positional anomaly detected at latitude: ', num2str(lat(end)), ', longitude: ', num2str(lon(end))]);
        end

        % Detect unrealistic speeds
        if speed(end) > dynamicSpeedThreshold
            % Update anomaly plot
            set(speedAnomalyPlot, 'XData', [get(speedAnomalyPlot, 'XData'), lon(end)], 'YData', [get(speedAnomalyPlot, 'YData'), lat(end)]);
            % Log a message indicating an anomaly
            disp(['Speed anomaly detected at latitude: ', num2str(lat(end)), ', longitude: ', num2str(lon(end)), ', speed: ', num2str(speed(end)), ' m/s']);
        end

        % Detect sudden altitude changes
        if altitudeChange > baseAltitudeThreshold
            % Update anomaly plot
            set(altitudeAnomalyPlot, 'XData', [get(altitudeAnomalyPlot, 'XData'), lon(end)], 'YData', [get(altitudeAnomalyPlot, 'YData'), lat(end)]);
            % Log a message indicating an anomaly
            disp(['Altitude anomaly detected at latitude: ', num2str(lat(end)), ', longitude: ', num2str(lon(end)), ', altitude change: ', num2str(altitudeChange), ' meters']);
        end

        % Detect inconsistent time intervals
        if timeDiff > baseTimeIntervalThreshold
            % Update anomaly plot
            set(timeAnomalyPlot, 'XData', [get(timeAnomalyPlot, 'XData'), lon(end)], 'YData', [get(timeAnomalyPlot, 'YData'), lat(end)]);
            % Log a message indicating an anomaly
            disp(['Time interval anomaly detected at latitude: ', num2str(lat(end)), ', longitude: ', num2str(lon(end)), ', time interval: ', num2str(timeDiff), ' seconds']);
        end

        % Detect unrealistic heading changes
        if headingChange > headingChangeThreshold
            % Validate heading change with course data
            if abs(headingChange - course(end)) > headingChangeThreshold
                % Update anomaly plot
                set(headingAnomalyPlot, 'XData', [get(headingAnomalyPlot, 'XData'), lon(end)], 'YData', [get(headingAnomalyPlot, 'YData'), lat(end)]);
                % Log a message indicating an anomaly
                disp(['Heading change anomaly detected at latitude: ', num2str(lat(end)), ', longitude: ', num2str(lon(end)), ', heading change: ', num2str(headingChange), ' degrees']);
            end
        end

        % Update the plot with new data
        set(h, 'XData', [get(h, 'XData'), lon(end)], 'YData', [get(h, 'YData'), lat(end)]);
        drawnow;
    end
end

% Function to calculate the Haversine distance between two points
function d = haversine(lat, lon)
    R = 6371000; % Radius of the Earth in meters
    dlat = deg2rad(diff(lat));
    dlon = deg2rad(diff(lon));
    a = sin(dlat/2).^2 + cos(deg2rad(lat(1:end-1))) .* cos(deg2rad(lat(2:end))) .* sin(dlon/2).^2;
    c = 2 * atan2(sqrt(a), sqrt(1-a));
    d = R * c;
end

% Function to apply a moving average to data
function smoothedData = movingAverage(data, windowSize)
    smoothedData = filter(ones(1, windowSize) / windowSize, 1, data);
end

function [lat, lon, timestamp, speed, course, alt, horizacc] = parseNMEASentence(sentence)
    % Remove the "NMEA," prefix
    sentence = strrep(sentence, 'NMEA,', '');

    % Parse NMEA sentence and extract relevant data
    if startsWith(sentence, '$GPGGA')
        % Example parsing for GPGGA sentence
        parts = strsplit(sentence, ',');
        lat = nmeaToDecimal(parts{3}, parts{4});
        lon = nmeaToDecimal(parts{5}, parts{6});
        alt = str2double(parts{10});
        timestamp = parts{2};
        horizacc = str2double(parts{9});
        speed = NaN;
        course = NaN;
    elseif startsWith(sentence, '$GNRMC')
        % Example parsing for GNRMC sentence
        parts = strsplit(sentence, ',');
        lat = nmeaToDecimal(parts{4}, parts{5});
        lon = nmeaToDecimal(parts{6}, parts{7});
        speed = str2double(parts{8}) * 0.514444; % Convert knots to m/s
        course = str2double(parts{9});
        timestamp = parts{2};
        alt = NaN;
        horizacc = NaN;
    else
        lat = NaN;
        lon = NaN;
        timestamp = NaN;
        speed = NaN;
        course = NaN;
        alt = NaN;
        horizacc = NaN;
    end
end

function decimal = nmeaToDecimal(coord, direction)
    % Convert NMEA coordinate format to decimal degrees
    degrees = floor(str2double(coord) / 100);
    minutes = mod(str2double(coord), 100);
    decimal = degrees + minutes / 60;
    if direction == 'S' || direction == 'W'
        decimal = -decimal;
    end
end