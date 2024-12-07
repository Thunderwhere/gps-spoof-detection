function generateSpoofedNMEA(numSentences, outputFile)
    % Generate spoofed NMEA data
    % numSentences: Number of NMEA sentences to generate
    % outputFile: File to save the generated NMEA data

    % Open the output file
    fid = fopen(outputFile, 'w');
    if fid == -1
        error('Cannot open output file.');
    end

    % Generate random NMEA sentences
    for i = 1:numSentences
        % Generate random latitude and longitude
        lat_deg = randi([0, 89]);
        lat_min = rand() * 60;
        lon_deg = randi([0, 179]);
        lon_min = rand() * 60;

        % Randomly decide if the latitude is North or South
        if rand() > 0.5
            lat_dir = 'N';
        else
            lat_dir = 'S';
        end

        % Randomly decide if the longitude is East or West
        if rand() > 0.5
            lon_dir = 'E';
        else
            lon_dir = 'W';
        end

        % Format the latitude and longitude as strings
        lat_str = sprintf('%02d%07.4f', lat_deg, lat_min);
        lon_str = sprintf('%03d%07.4f', lon_deg, lon_min);

        % Create a spoofed $GNGGA sentence
        gnggaSentence = sprintf('NMEA,$GNGGA,191722.00,%s,%s,%s,%s,1,12,0.4,185.6,M,-35.1,M,,*4F,1731957441996', lat_str, lat_dir, lon_str, lon_dir);
        fprintf(fid, '%s\n', gnggaSentence);

        % Create a spoofed $GPGSV sentence with random SNR values
        numSatellites = randi([1, 12]); % Random number of satellites
        numMessages = ceil(numSatellites / 4);
        for msgIdx = 1:numMessages
            gpgsvSentence = sprintf('NMEA,$GPGSV,%d,%d,%02d', numMessages, msgIdx, numSatellites);
            for satIdx = 1:min(4, numSatellites - (msgIdx - 1) * 4)
                prn = randi([1, 32]); % Satellite PRN number
                elevation = randi([0, 90]); % Elevation in degrees
                azimuth = randi([0, 359]); % Azimuth in degrees
                snr = randi([0, 50]); % SNR in dB
                gpgsvSentence = sprintf('%s,%02d,%02d,%03d,%02d', gpgsvSentence, prn, elevation, azimuth, snr);
            end
            checksum = mod(sum(double(gpgsvSentence(6:end))), 256);
            gpgsvSentence = sprintf('%s*%02X,1731957441996', gpgsvSentence, checksum);
            fprintf(fid, '%s\n', gpgsvSentence);
        end
    end

    % Close the output file
    fclose(fid);
end

% Example usage:
generateSpoofedNMEA(100, 'spoofed_nmea_data.nmea');