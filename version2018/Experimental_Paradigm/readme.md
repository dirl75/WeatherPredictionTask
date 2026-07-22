# Weather Prediction Task (Psychtoolbox)

This task is based originally on the WPT version in Kumaran et al., Neuropsychologia 2007 (https://doi.org/10.1016/j.neuropsychologia.2007.04.007). 

The code contained here was used in a replica of the study of Kumaran et al., conducted at the Centro de Estudios en Neurociencia Humana y Neuropsicología, Facultad de Psicología, Universidad Diego Portales, Santiago, Chile. This work was published in the International Journal of Psychophysiology (https://doi.org/10.1016/j.ijpsycho.2026.113431).

This repository contains MATLAB scripts to run an experimental **Weather Prediction Task** integrated with **Psychtoolbox-3** and eye-tracking functionality (Eyelink).

---

## Requirements & Prerequisites

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


---

## How to run the experiment:

1. Launch the experiment by calling the main function in Matlab command window:
`WeatherPredictionTask_Aspe`

2. A GUI dialog box will prompt you for participant details:
* Participant ID
* Gender (F or M)
* Age (years)
* Experimenter in charge

3. Calibrate eye-tracking (Eyelink)
4. When calibration is done, the task starts

---

## Task control and workings

The task requires a regular computer keyboard for the participant to deliver responses

* Keyboard Controls
`S`: Predict SUN
`L`: Predict RAIN
`SPACE`: Advance instructions screens / start task
`ESCAPE`: Prompts early exit confirmation screen

* Task structure

+ Blocks: Up to 6 blocks of 50 trials each (300 total maximum).
Performance Criteria: If a participant achieves 47 or more correct responses in a single block, the session terminates early upon success.
Block Breaks: Includes a 60-second break between blocks

---

## Configuration & Hardware Settings
Settings can be customized inside `settings_WeatherPredictionTask_ASPE.m`:
Eye-Tracker Integration: Set `dummyMode_Eyelink = true` to skip Eyelink calibration during testing without hardware attached.  Set `dummyMode_Eyelink = false` for active eye-tracking sessions.
Timing Parameters: `ITI_s = 2;`: Inter-trial interval (seconds).  `Wait_time_s = 2;`: Maximum response window per trial.  `Feedback_durat_s = 2;`: Duration of visual feedback.

---

## Output Data
Session data is saved automatically to the ./data/ folder in both .mat and tab-delimited .txt formats:

Output File Contents (.txt and .mat):
* Metadata: Subject ID, Age, Gender, Date/Time, Experimenter, and Task Status.
* Variables:

  Block: Current block index

  Stimulus: ID of presented shape pair

  Performance: Accuracy (1 = Correct, 0 = Incorrect)

  RT (s): Response time in seconds

* Stimulus-Outcome Association Map: Overview of shape pairs, stimulus associations, and assigned weather predictions for the session.  

---

## Functions overview

| File | Purpose |
| :--- | :--- |
| `WeatherPredictionTask_Aspe.m` | Core task loop handling Psychtoolbox rendering, inputs, and trial sequencing. |
| `settings_WeatherPredictionTask_ASPE.m` | Loads parameters, generates pseudorandom sequences, and handles key mappings. |
| `GetSubjectInfo_Weather.m` | GUI prompt collecting metadata prior to task start. |
| `saveBehavData_Weather.m` | Exports behavioral parameters to `.txt` and `.mat` formats. |
| `GenRandomString.m` | Generates a randomized alphanumeric code for participant anonymization. |
| `GetCurrDateTime.m` | Returns a formatted string (`yyyy_mm_dd_hh-min`) for timestamping saved files. |
