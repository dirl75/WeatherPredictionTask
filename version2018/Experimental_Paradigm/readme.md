# Weather Prediction Task (Psychtoolbox)

This task is based on the WPT version in Kumaran et al., Neuropsychologia 2007 (https://doi.org/10.1016/j.neuropsychologia.2007.04.007)

his repository contains MATLAB scripts to run an experimental **Weather Prediction Task** integrated with **Psychtoolbox-3** and eye-tracking functionality (Eyelink).

---

## 📌 Requirements & Prerequisites

* **MATLAB** (R2018a or newer recommended)
* **Psychtoolbox-3** installed and configured
* **Eyelink Toolbox** (if running with active Eye-Tracking calibration)
* **Operating Directory:** The active working directory in MATLAB **must** be named `WeatherPredictionTask_UDP`.

---

## Repository Structure

```
WeatherPredictionTask_UDP/
│
├── WeatherPredictionTask_Aspe.m    # Main execution function
├── settings_WeatherPredictionTask_ASPE.m # Task parameters & setup
├── GetSubjectInfo_Weather.m        # GUI dialog for participant metadata
├── saveBehavData_Weather.m         # Saves performance data (.mat and .txt)
├── GenRandomString.m               # Generates randomized participant IDs
├── GetCurrDateTime.m               # Helper utility to format timestamps
│
├── images/                         # Stimulus visual assets
│   ├── rain_bw.png
│   ├── sun_bw.png
│   ├── Triangle.png
│   ├── Star.png
│   ├── Ellipse.png
│   └── Square.png
│
└── data/                           # Output directory for session logs

```


How to run the experiment:

1. Launch the experiment by calling the main function in Matlab command window:
WeatherPredictionTask_Aspe
2. 
3. A GUI dialog box will prompt you for participant details:
Participant ID / Name  Gender (F or M)  Age (years)  Experimenter in charge
4.  
