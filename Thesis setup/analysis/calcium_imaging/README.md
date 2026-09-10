# Calcium imaging analysis

This folder documents the Excel workbook used as a calcium-imaging analysis example/template.

## File to upload

Upload the existing workbook here:

```text
Results_darktowhite1518.csv.xlsx
```

This is the Excel file generated from the ImageJ/Fiji `Results` table for the dark-to-white two-photon recording. It is not a newly generated workbook; it is the working spreadsheet you used and want to keep in the repository as a template/example for future calcium-imaging analysis.

## Purpose

The workbook shows how ROI fluorescence values exported from ImageJ/Fiji were organized and processed for a dark-to-white calcium-imaging experiment.

It can be used as a template for similar recordings by replacing the raw ImageJ/Fiji results with a new export and adapting the formulas, baseline frames, and stimulus frames as needed.

## Data structure

The workbook contains one sheet:

```text
Results_darktowhite1518
```

The first columns contain the ImageJ/Fiji ROI measurements:

```text
Frame / index
Label
Area1, Mean1, MinThr1, MaxThr1
Area2, Mean2, MinThr2, MaxThr2
Area3, Mean3, MinThr3, MaxThr3
Area4, Mean4, MinThr4, MaxThr4
Area5, Mean5, MinThr5, MaxThr5
```

The workbook therefore supports five ROIs in its current form.

## Analysis columns

Additional columns to the right of the ImageJ/Fiji export contain spreadsheet formulas used to process the ROI fluorescence traces.

In the current file, these formulas include subtraction of one ROI trace from other ROI traces and baseline-normalized percentage-change calculations. For example, some columns calculate differences between ROI mean intensities, and later columns calculate percentage change relative to a baseline value.

## General analysis logic

The spreadsheet follows this general workflow:

1. Export ROI intensity values from ImageJ/Fiji.
2. Keep one row per imaging frame.
3. Use the `Mean` columns as fluorescence traces for each ROI.
4. Use formula columns to calculate corrected or relative fluorescence values.
5. Define a baseline period from the pre-stimulus frames.
6. Calculate response values relative to the baseline.
7. Use the resulting traces or summary values for plotting and statistics.

## Important notes for reuse

- Keep a copy of the original workbook before editing.
- Do not overwrite the original formulas unless you are making a new analysis version.
- When reusing the workbook, replace the ImageJ/Fiji raw results carefully and check that formulas still refer to the correct columns.
- Record the baseline frame range used for each experiment.
- Record the stimulus timing, for example dark-to-white onset frame and offset frame.
- Save each experiment-specific copy with a descriptive file name, such as `Results_darktowhite1518_fly01.xlsx`.

## Missing information to add later

Add the following details once finalized:

- exact baseline frame range
- exact stimulus onset and offset frames
- imaging frame rate
- ROI-selection criteria
- whether any ROI was used as background or reference signal
- final formula definitions for each calculated column

## Data policy

This folder should contain analysis templates, example spreadsheets, and scripts. Raw two-photon imaging files should be stored separately unless a data-release plan is approved.
