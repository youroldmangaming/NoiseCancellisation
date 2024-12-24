# List of required packages
required_packages <- c("seewave", "tuneR", "tidyverse", "audio", "plotly", "fftw", "cowplot", "tuneR", "sonicscrewdriver")

# Function to install and load packages
install_and_load <- function(packages) {
  for (package in packages) {
    if (!require(package, character.only = TRUE)) {
      install.packages(package, dependencies = TRUE)
      library(package, character.only = TRUE)
    }
  }
}

# Suppress messages while loading and installing
suppressMessages({
  install_and_load(required_packages)
})




# Sound Suppression

library(sonicscrewdriver)
library(audio)
library(ggplot2)  # For plotting
library(pracma)   # For FFT and sine wave generation
library(signal)    # For FIR filter design


#The above will be dependant on your current install but it's all there.



# Set parameters for recording
sample_rate <- 44100  # Sampling rate in Hz
duration <- 1          # Duration for each recording cycle
buffer_size <- 0.1     # Buffer size in seconds to account for lag
noise_threshold <- 0.05 # Threshold for noise detection (adjust as necessary)
average_factor <- 0.1   # Smoothing factor for averaging
spike_threshold <- 0.1   # Threshold for ignoring spikes (adjust as necessary)

# Calculate the number of samples for the buffer size
buffer_samples <- round(buffer_size * sample_rate)

# Create a circular buffer to hold the last few seconds of audio
audio_buffer <- numeric(buffer_samples)

# Function to calculate RMS
calculate_rms <- function(signal) {
    sqrt(mean(signal^2))
}

# Function to detect the fundamental frequency using FFT
detect_frequency <- function(signal) {
    fft_result <- fft(signal)
    freq <- seq(0, length(fft_result) - 1) * (sample_rate / length(fft_result))
    magnitude <- Mod(fft_result)
    peak_freq <- freq[which.max(magnitude[1:(length(magnitude)/2)])]  # Only consider positive frequencies
    return(peak_freq)
}

# Function to apply a simple low-pass filter
low_pass_filter <- function(signal, cutoff_freq) {
    b <- fir1(128, cutoff_freq / (sample_rate / 2))  # Design a low-pass FIR filter
    filtered_signal <- filter(b, 1, signal)
    return(filtered_signal)
}

# Initialize variables for averaging
previous_noise_level <- 0
average_frequency <- 0
volume_factor <- 1.0

# Start a loop for real-time audio processing
cat("Type 'plot' to see the graphs and 'exit' to exit the program.\n")

while (TRUE) {
    audio_data <- numeric(duration * sample_rate)
    cat("Recording audio... Please speak into the microphone.\n")
    record(audio_data, rate = sample_rate)

    if (inherits(audio_data, "audioSample")) {
        audio_data <- as.numeric(audio_data)
    }

    # Apply low-pass filter to reduce keyboard noise
    filtered_audio_data <- low_pass_filter(audio_data, cutoff_freq = 1000)  # Adjust cutoff frequency as needed

    audio_buffer <- c(audio_buffer, filtered_audio_data)
    audio_buffer <- tail(audio_buffer, buffer_samples)

    noise_level <- calculate_rms(audio_buffer)
    cat(sprintf("Current noise level: %.4f\n", noise_level))  # Output the noise level

    # Ignore sudden spikes in noise
    if (noise_level < spike_threshold) {
        # Detect the fundamental frequency of the noise
        fundamental_freq <- detect_frequency(audio_buffer)
        cat(sprintf("Detected fundamental frequency: %.2f Hz\n", fundamental_freq))

        # Update the average frequency using a simple exponential moving average
        average_frequency <- average_frequency * (1 - average_factor) + fundamental_freq * average_factor

        # Generate a cyclic cancellation wave (sine wave)
        time_axis <- seq(0, duration, by = 1/sample_rate)
        cancellation_wave <- sin(2 * pi * average_frequency * time_axis + pi)  # 180 degrees out of phase

        # Adjust volume based on the noise level
        volume_factor <- ifelse(noise_level > previous_noise_level, 
                                1 + (noise_level - previous_noise_level) * 2, 
                                max(1, volume_factor - 0.1))

        adjusted_audio_data <- cancellation_wave * volume_factor

        # Play the cancellation wave
        play(adjusted_audio_data, rate = sample_rate)
    }

    previous_noise_level <- noise_level

    # Check for user input
    if (interactive()) {
        if (readline("Type 'plot' to see the graphs or 'exit' to stop the program: ") == "plot") {
            cat("Displaying graphs...\n")
            # Plot the waves
            time_axis <- seq(1, length(audio_data)) / sample_rate

            noise_df <- data.frame(time = time_axis, amplitude = audio_data)
            cancellation_df <- data.frame(time = time_axis, amplitude = cancellation_wave)

            # Plot Noise Wave
            ggplot(noise_df, aes(x = time, y = amplitude)) +
                geom_line(color = "blue") +
                labs(title = "Noise Wave", x = "Time (s)", y = "Amplitude") +
                theme_minimal()

            # Plot Cancellation Wave
            ggplot(cancellation_df, aes(x = time, y = amplitude)) +
                geom_line(color = "red") +
                labs(title = "Cancellation Wave", x = "Time (s)", y = "Amplitude") +
                theme_minimal()

            # Plot the Effect of Cancellation
            combined_wave <- audio_data + cancellation_wave
            combined_df <- data.frame(time = time_axis, amplitude = combined_wave)

            ggplot(combined_df, aes(x = time, y = amplitude)) +
                geom_line(color = "green") +
                labs(title = "Combined Effect of Noise and Cancellation", x = "Time (s)", y = "Amplitude") +
                theme_minimal()

            Sys.sleep(5)  # Pause to allow viewing the plots
        }
    }
}
