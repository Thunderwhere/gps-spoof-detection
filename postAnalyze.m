% FILE: postAnalyze.m

% Read the spoofed NMEA data from the text file
fileID = fopen('spoofedNMEA.txt', 'r');
nmeaData = textscan(fileID, '%s', 'Delimiter', '\n');
fclose(fileID);

% Initialize variables for previous values
prevLat = NaN;
prevLon = NaN;
prevTimestamp = NaN;
prevAlt = NaN;
prevSpeed = NaN;
prevCourse = NaN;

% Initialize plots for anomalies
figure;
hold on;
speedAnomalyPlot = plot(NaN, NaN, 'r-', 'DisplayName', 'Speed Anomaly');
altitudeAnomalyPlot = plot(NaN, NaN, 'g-', 'DisplayName', 'Altitude Anomaly');
timeAnomalyPlot = plot(NaN, NaN, 'b-', 'DisplayName', 'Time Interval Anomaly');
headingAnomalyPlot = plot(NaN, NaN, 'm-', 'DisplayName', 'Heading Change Anomaly');

% Base thresholds for anomalies
baseSpeedThreshold = 15;
baseAltitudeThreshold = 20;
baseTimeIntervalThreshold = 5;
baseHeadingChangeThreshold = 45;

% Process each NMEA sentence
for i = 1:length(nmeaData{1})
    nmeaSentence = nmeaData{1}{i};
    
    % Parse the NMEA sentence
    parts = strsplit(nmeaSentence, ',');
    if strcmp(parts{1}, '$GPGGA')
        timestamp = parts{2};
        lat = str2double(parts{3});
        lon = str2double(parts{5});
        altitude = str2double(parts{10});
        
        % Calculate speed, heading, and time difference if previous values exist
        if ~isnan(prevLat)
            distance = haversine([prevLat, lat], [prevLon, lon]);
            timeDiff = etime(datevec(timestamp, 'HHMMSS'), datevec(prevTimestamp, 'HHMMSS'));
            speed = distance / timeDiff;
            heading = atan2d(sind(lon - prevLon) * cosd(lat), cosd(prevLat) * sind(lat) - sind(prevLat) * cosd(lat) * cosd(lon - prevLon));
            headingChange = abs(heading - prevCourse);
            altitudeChange = abs(altitude - prevAlt);
            
            % Detect anomalies
            if speed > baseSpeedThreshold
                set(speedAnomalyPlot, 'XData', [get(speedAnomalyPlot, 'XData'), lon], 'YData', [get(speedAnomalyPlot, 'YData'), lat]);
                disp(['Speed anomaly detected at latitude: ', num2str(lat), ', longitude: ', num2str(lon), ', speed: ', num2str(speed), ' m/s']);
            end
            if altitudeChange > baseAltitudeThreshold
                set(altitudeAnomalyPlot, 'XData', [get(altitudeAnomalyPlot, 'XData'), lon], 'YData', [get(altitudeAnomalyPlot, 'YData'), lat]);
                disp(['Altitude anomaly detected at latitude: ', num2str(lat), ', longitude: ', num2str(lon), ', altitude change: ', num2str(altitudeChange), ' meters']);
            end
            if timeDiff > baseTimeIntervalThreshold
                set(timeAnomalyPlot, 'XData', [get(timeAnomalyPlot, 'XData'), lon], 'YData', [get(timeAnomalyPlot, 'YData'), lat]);
                disp(['Time interval anomaly detected at latitude: ', num2str(lat), ', longitude: ', num2str(lon), ', time interval: ', num2str(timeDiff), ' seconds']);
            end
            if headingChange > baseHeadingChangeThreshold
                set(headingAnomalyPlot, 'XData', [get(headingAnomalyPlot, 'XData'), lon], 'YData', [get(headingAnomalyPlot, 'YData'), lat]);
                disp(['Heading change anomaly detected at latitude: ', num2str(lat), ', longitude: ', num2str(lon), ', heading change: ', num2str(headingChange), ' degrees']);
            end
        end
        
        % Update previous values
        prevLat = lat;
        prevLon = lon;
        prevTimestamp = timestamp;
        prevAlt = altitude;
        prevSpeed = speed;
        prevCourse = heading;
    end
end

% Display legend
legend('show');

% Function to calculate the Haversine distance between two points
function d = haversine(lat, lon)
    R = 6371000; % Radius of the Earth in meters
    dlat = deg2rad(diff(lat));
    dlon = deg2rad(diff(lon));
    a = sin(dlat/2).^2 + cos(deg2rad(lat(1))) * cos(deg2rad(lat(2))) * sin(dlon/2).^2;
    c = 2 * atan2(sqrt(a), sqrt(1-a));
    d = R * c;
end