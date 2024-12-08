% Enable GNSS sensor and Logging
m.PositionSensorEnabled = 1;
m.Logging = 1;

% Initialize variables for real-time plotting
figure;
h = plot(NaN, NaN, 'bo-');
xlabel('Longitude');
ylabel('Latitude');
title('Real-Time GNSS Data with Anomaly Detection');
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

% Thresholds for detecting anomalies
jumpThreshold = 15; % Positional jump threshold in meters
speedThreshold = 30; % Speed threshold in m/s (e.g., 108 km/h)
altitudeThreshold = 50; % Altitude change threshold in meters
timeIntervalThreshold = 2; % Time interval threshold in seconds
headingChangeThreshold = 45; % Heading change threshold in degrees

% Main loop for real-time data processing
try
    while true
        % Get the latest GNSS data
        [lat, lon, alt, time] = poslog(m); % Assuming poslog also returns altitude and time
        
        % Check if there is enough data to process
        if length(lat) > 1
            % Calculate the distance between consecutive points
            distances = haversine(lat(end-1:end), lon(end-1:end));
            
            % Calculate the time difference between consecutive points
            timeDiff = diff(time(end-1:end));
            
            % Calculate the speed between consecutive points
            speed = distances(end) / timeDiff;
            
            % Calculate the altitude change between consecutive points
            altitudeChange = abs(diff(alt(end-1:end)));
            
            % Calculate the heading change between consecutive points
            headingChange = abs(atan2d(sind(lon(end) - lon(end-1)) * cosd(lat(end)), cosd(lat(end-1)) * sind(lat(end)) - sind(lat(end-1)) * cosd(lat(end)) * cosd(lon(end) - lon(end-1))));
            
            % Detect positional jumps
            if distances(end) > jumpThreshold
                % Update anomaly plot
                set(jumpAnomalyPlot, 'XData', [get(jumpAnomalyPlot, 'XData'), lon(end)], 'YData', [get(jumpAnomalyPlot, 'YData'), lat(end)]);
                % Log a message indicating an anomaly
                disp(['Anomaly detected at latitude: ', num2str(lat(end)), ', longitude: ', num2str(lon(end))]);
            end
            
            % Detect unrealistic speeds
            if speed > speedThreshold
                % Update anomaly plot
                set(speedAnomalyPlot, 'XData', [get(speedAnomalyPlot, 'XData'), lon(end)], 'YData', [get(speedAnomalyPlot, 'YData'), lat(end)]);
                % Log a message indicating an anomaly
                disp(['Speed anomaly detected at latitude: ', num2str(lat(end)), ', longitude: ', num2str(lon(end)), ', speed: ', num2str(speed), ' m/s']);
            end
            
            % Detect sudden altitude changes
            if altitudeChange > altitudeThreshold
                % Update anomaly plot
                set(altitudeAnomalyPlot, 'XData', [get(altitudeAnomalyPlot, 'XData'), lon(end)], 'YData', [get(altitudeAnomalyPlot, 'YData'), lat(end)]);
                % Log a message indicating an anomaly
                disp(['Altitude anomaly detected at latitude: ', num2str(lat(end)), ', longitude: ', num2str(lon(end)), ', altitude change: ', num2str(altitudeChange), ' meters']);
            end
            
            % Detect inconsistent time intervals
            if timeDiff > timeIntervalThreshold
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
        
        % Pause for a short time to allow for real-time updates
        pause(1);
    end
catch ME
    % Turn off logging and sensors when stopping the script
    m.Logging = 0;
    m.PositionSensorEnabled = 0;
    rethrow(ME);
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