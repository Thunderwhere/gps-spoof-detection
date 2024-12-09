function analyzeGNSSData(m)
    % Enable GNSS sensor and Logging
    m.PositionSensorEnabled = 1;
    m.Logging = 1;

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
        while true
            % Get the latest GNSS data
            [lat, lon, timestamp, speed, course, alt, horizacc] = poslog(m);
            processGNSSData(lat, lon, alt, timestamp, speed, course, horizacc, h, jumpAnomalyPlot, speedAnomalyPlot, altitudeAnomalyPlot, timeAnomalyPlot, headingAnomalyPlot, ...
                baseJumpThreshold, baseSpeedThreshold, baseAltitudeThreshold, baseTimeIntervalThreshold, baseHeadingChangeThreshold);
            pause(1); % Pause for a short time to allow for real-time updates
        end
    catch ME
        disp(['Error: ', ME.message]);
    end
end

function processGNSSData(lat, lon, alt, timestamp, speed, course, horizacc, h, jumpAnomalyPlot, speedAnomalyPlot, altitudeAnomalyPlot, timeAnomalyPlot, headingAnomalyPlot, ...
    baseJumpThreshold, baseSpeedThreshold, baseAltitudeThreshold, baseTimeIntervalThreshold, baseHeadingChangeThreshold)

    persistent prevLat prevLon prevTimestamp prevAlt prevSpeed prevCourse distances

    if isempty(prevLat)
        prevLat = lat;
        prevLon = lon;
        prevTimestamp = timestamp;
        prevAlt = alt;
        prevSpeed = speed;
        prevCourse = course;
        distances = [];
    end

    % Calculate the Haversine distance between the current and previous points
    distance = haversine([prevLat, lat], [prevLon, lon]);
    distances = [distances, distance];

    % Update the main plot with the new data point
    set(h, 'XData', [get(h, 'XData'), lon], 'YData', [get(h, 'YData'), lat]);

    % Calculate the time difference between consecutive points
    if length(prevTimestamp) > 1
        timeDiff = diff([prevTimestamp, timestamp]);
    else
        timeDiff = 0;
    end

    % Calculate the altitude change between consecutive points
    if length(prevAlt) > 1
        altitudeChange = abs(diff([prevAlt, alt]));
    else
        altitudeChange = 0;
    end

    % Calculate the heading change between consecutive points if distance is above the threshold
    minDistance = 0.1; % Define a minimum distance threshold
    if distance > minDistance
        headingChange = abs(atan2d(sind(lon - prevLon) * cosd(lat), cosd(prevLat) * sind(lat) - sind(prevLat) * cosd(lat) * cosd(lon - prevLon)));
    else
        headingChange = 0;
    end

    % Scale thresholds based on speed and horizontal accuracy
    jumpThreshold = baseJumpThreshold * (1 + speed / baseSpeedThreshold) * (1 + horizacc / 10);
    headingChangeThreshold = baseHeadingChangeThreshold * (1 + speed / baseSpeedThreshold) * (1 + horizacc / 10);
    dynamicSpeedThreshold = baseSpeedThreshold * (1 + speed / baseSpeedThreshold) * (1 + horizacc / 10);

    % Detect positional jumps
    if distance > jumpThreshold
        % Update anomaly plot
        set(jumpAnomalyPlot, 'XData', [get(jumpAnomalyPlot, 'XData'), lon], 'YData', [get(jumpAnomalyPlot, 'YData'), lat]);
        % Log a message indicating an anomaly
        disp(['Positional anomaly detected at latitude: ', num2str(lat), ', longitude: ', num2str(lon)]);
    end

    % Detect unrealistic speeds
    if speed > dynamicSpeedThreshold
        % Update anomaly plot
        set(speedAnomalyPlot, 'XData', [get(speedAnomalyPlot, 'XData'), lon], 'YData', [get(speedAnomalyPlot, 'YData'), lat]);
        % Log a message indicating an anomaly
        disp(['Speed anomaly detected at latitude: ', num2str(lat), ', longitude: ', num2str(lon), ', speed: ', num2str(speed), ' m/s']);
    end

    % Detect sudden altitude changes
    if altitudeChange > baseAltitudeThreshold
        % Update anomaly plot
        set(altitudeAnomalyPlot, 'XData', [get(altitudeAnomalyPlot, 'XData'), lon], 'YData', [get(altitudeAnomalyPlot, 'YData'), lat]);
        % Log a message indicating an anomaly
        disp(['Altitude anomaly detected at latitude: ', num2str(lat), ', longitude: ', num2str(lon), ', altitude change: ', num2str(altitudeChange), ' meters']);
    end

    % Detect inconsistent time intervals
    if timeDiff > baseTimeIntervalThreshold
        % Update anomaly plot
        set(timeAnomalyPlot, 'XData', [get(timeAnomalyPlot, 'XData'), lon], 'YData', [get(timeAnomalyPlot, 'YData'), lat]);
        % Log a message indicating an anomaly
        disp(['Time interval anomaly detected at latitude: ', num2str(lat), ', longitude: ', num2str(lon), ', time interval: ', num2str(timeDiff), ' seconds']);
    end

    % Detect unrealistic heading changes
    if headingChange > headingChangeThreshold
        % Validate heading change with course data
        if abs(headingChange - prevCourse) > headingChangeThreshold
            % Update anomaly plot
            set(headingAnomalyPlot, 'XData', [get(headingAnomalyPlot, 'XData'), lon], 'YData', [get(headingAnomalyPlot, 'YData'), lat]);
            % Log a message indicating an anomaly
            disp(['Heading change anomaly detected at latitude: ', num2str(lat), ', longitude: ', num2str(lon), ', heading change: ', num2str(headingChange), ' degrees']);
        end
    end

    % Update previous values
    prevLat = lat;
    prevLon = lon;
    prevTimestamp = timestamp;
    prevAlt = alt;
    prevSpeed = speed;
    prevCourse = course;
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