# gps-spoof-detection

### What are Simple Propagation Anomaly Checks?

Propagation anomalies occur when GPS signals behave in ways inconsistent with their expected behavior, often due to spoofing. Basic anomaly detection involves identifying deviations in signal properties or calculated positions. Examples of simple checks include:

1. *Signal Strength Anomalies*: GPS spoofing signals often have stronger or less variable signal strength compared to genuine satellite signals because they originate from a nearby transmitter.
   - *How to Detect*: Monitor signal-to-noise ratio (SNR) or received signal strength indicator (RSSI) values over time. Unexpectedly high or stable values can indicate spoofing.

2. *Position Jumps*: A sudden, unrealistic change in the reported GPS position, velocity, or time can signal spoofing.
   - *How to Detect*: Calculate the distance between consecutive positions. If this "jump" exceeds a certain threshold (e.g., a car suddenly appearing 10 km away within a second), it may indicate spoofing.

3. *Time Drift*: GPS spoofers might cause inconsistencies in the receiver’s clock.
   - *How to Detect*: Compare the GPS-reported time to a trusted source (e.g., a local atomic clock or network time).

4. *Doppler Shift Anomalies*: Spoofed signals often have Doppler shifts inconsistent with the satellite's expected trajectory.
   - *How to Detect*: Calculate the Doppler effect using known satellite orbital data and compare it to received signals.

---

### *Steps to Implement a Basic Anomaly Detection System*

1. *Data Collection*:
   - Collect genuine GPS data using your receiver in normal conditions (baseline data).
   - Optionally use MATLAB simulations to generate spoofing scenarios (e.g., simulate a sudden position jump or constant high SNR).

2. *Define Thresholds*:
   - Analyze your baseline data to set thresholds for anomalies. For instance:
     - Position jump > 100 meters per second.
     - SNR deviation from average > 10 dB.
     - Time drift > 1 microsecond.

3. *Implementation*:
   - In MATLAB (or Python if preferred), write code to analyze incoming GPS data in real time or post-process logs. Start with these steps:
     - *Input Data*: Parse GPS NMEA sentences or equivalent raw data.
     - *Calculate Metrics*: Compute metrics like position change, SNR, Doppler shifts.
     - *Check Against Thresholds*: Flag data points or time intervals where metrics exceed thresholds.

4. *Visualize Results*:
   - Use MATLAB to create plots showing normal and anomalous behavior for clarity.
   - Examples:
     - A scatterplot of position changes showing large jumps.
     - A time series of SNR highlighting sudden spikes.
