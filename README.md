# Real-Time Noise Cancellation System

This project implements a real-time noise cancellation system in R that captures ambient noise and generates a cancellation sound to minimize unwanted noise, such as keyboard sounds. The system uses cyclic analysis and averaging to produce an inverse wave that maximizes overall sound suppression.

## Features

- Continuous recording of ambient noise.
- Detection of the fundamental frequency of the noise using Fast Fourier Transform (FFT).
- Generation of a cyclic cancellation wave that is 180 degrees out of phase with the detected noise.
- Application of a low-pass filter to reduce high-frequency noise, such as keyboard sounds.
- Dynamic volume adjustment of the cancellation wave based on the noise level.
- Visualization of the noise wave, cancellation wave, and their combined effect using `ggplot2`.

## Requirements

- R (version 4.0 or higher)
- Required R packages:
  - `sonicscrewdriver`
  - `audio`
  - `ggplot2`
  - `pracma`
  - `signal`

Run and tested with Juypter Notebook running R.


You can install the required packages using the following commands in R:

```R
install.packages(c("sonicscrewdriver", "audio", "ggplot2", "pracma", "signal"))
