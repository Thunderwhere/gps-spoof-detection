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
    baseJumpThreshold = 2; % Positional jump threshold in meters for walking
    baseSpeedThreshold = 1.5; % Speed threshold in m/s for walking (e.g., 5.4 km/h)
    baseAltitudeThreshold = 10; % Altitude change threshold in meters
    baseTimeIntervalThreshold = 2; % Time interval threshold in seconds
    baseHeadingChangeThreshold = 10; % Heading change threshold in degrees for walking

    % Main loop for data processing
    try
        if nargin < 2
            % Real-time mode
            while true
                % Get the latest GNSS data
                [lat, lon, timestamp, speed, course, alt, horizacc] = poslog(m);
                processGNSSData(lat, lon, alt, timestamp, speed, course, h, jumpAnomalyPlot, speedAnomalyPlot, altitudeAnomalyPlot, timeAnomalyPlot, headingAnomalyPlot, ...
                    baseJumpThreshold, baseSpeedThreshold, baseAltitudeThreshold, baseTimeIntervalThreshold, baseHeadingChangeThreshold);
                pause(1); % Pause for a short time to allow for real-time updates
            end
        else
            % Post-analysis mode
            data = load(dataFile); % Load data from file
            lat = data.lat;
            lon = data.lon;
            alt = data.alt;
            timestamp = data.timestamp;
            speed = data.speed;
            course = data.course;
            processGNSSData(lat, lon, alt, timestamp, speed, course, h, jumpAnomalyPlot, speedAnomalyPlot, altitudeAnomalyPlot, timeAnomalyPlot, headingAnomalyPlot, ...
                baseJumpThreshold, baseSpeedThreshold, baseAltitudeThreshold, baseTimeIntervalThreshold, baseHeadingChangeThreshold);
        end
    catch ME
        % Turn off logging and sensors when stopping the script
        if nargin < 2
            m.Logging = 0;
            m.PositionSensorEnabled = 0;
        end
        rethrow(ME);
    end
end

function processGNSSData(lat, lon, alt, timestamp, speed, course, h, jumpAnomalyPlot, speedAnomalyPlot, altitudeAnomalyPlot, timeAnomalyPlot, headingAnomalyPlot, ...
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

        % Scale thresholds based on speed
        jumpThreshold = baseJumpThreshold * (1 + speed(end) / baseSpeedThreshold);
        headingChangeThreshold = baseHeadingChangeThreshold * (1 + speed(end) / baseSpeedThreshold);

        % Detect positional jumps
        if distances(end) > jumpThreshold
            % Update anomaly plot
            set(jumpAnomalyPlot, 'XData', [get(jumpAnomalyPlot, 'XData'), lon(end)], 'YData', [get(jumpAnomalyPlot, 'YData'), lat(end)]);
            % Log a message indicating an anomaly
            disp(['Anomaly detected at latitude: ', num2str(lat(end)), ', longitude: ', num2str(lon(end))]);
        end

        % Detect unrealistic speeds
        if speed(end) > baseSpeedThreshold
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
            % Update anomaly plot
            set(headingAnomalyPlot, 'XData', [get(headingAnomalyPlot, 'XData'), lon(end)], 'YData', [get(headingAnomalyPlot, 'YData'), lat(end)]);
            % Log a message indicating an anomaly
            disp(['Heading change anomaly detected at latitude: ', num2str(lat(end)), ', longitude: ', num2str(lon(end)), ', heading change: ', num2str(headingChange), ' degrees']);
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