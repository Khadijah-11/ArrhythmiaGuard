# ArrhythmiaGuard

**Real-Time Cardiac Arrhythmia Detection via ECG+PPG Fusion on ESP32**

![Python](https://img.shields.io/badge/Python-3.11-blue)
![TensorFlow](https://img.shields.io/badge/TensorFlow-2.x-orange)
![Flutter](https://img.shields.io/badge/Flutter-3.x-blue)
![ESP32-S3](https://img.shields.io/badge/ESP32--S3-TFLite_Micro-green)
![License](https://img.shields.io/badge/License-MIT-lightgrey)

Final Year Project (PFE) — Master in Embedded Artificial Intelligence
Faculté des Sciences Appliquées, Université Ibn Zohr, Aït Melloul

**Author:** Khadija TAGUI
**Supervisor:** Pr. Aimad KARKOUCH

---

## Overview

ArrhythmiaGuard is an end-to-end embedded system for real-time cardiac arrhythmia detection. It fuses ECG and PPG signals using a lightweight dual-stream deep learning model with a custom cross-modal attention mechanism (ChannelGate), deployed on an ESP32-S3 microcontroller via TensorFlow Lite Micro. A Flutter mobile app communicates with the device over BLE for live monitoring and haptic alerts.

The main contribution is the **ChannelGate** mechanism — a cross-modal attention layer built exclusively with TFLite Micro-compatible operators (MEAN, MUL, ADD), enabling ECG+PPG fusion on resource-constrained embedded hardware without requiring unsupported ops like BATCH_MATMUL or EXPAND_DIMS.

---

## System Architecture

```
AD8232 (ECG) ──┐
               ├──► ESP32-S3 N16R8 ──► TFLite Micro Inference ──► BLE ──► Flutter App
MAX30102 (PPG) ┘              │
                       Vibration Motor
                       (haptic alert for S/V/F classes)
```

---

## Results

| Model | Accuracy | Macro F1 | Size | Deployed on ESP32-S3 |
|-------|----------|----------|------|----------------------|
| CNN 1D Baseline (ECG only) | 97.49% | 0.8725 | — | No |
| ChannelGate Fusion (ECG+PPG) | 97.55% | 0.8607 | 229.9 KB (float32) | Yes |

**Per-class F1 — ChannelGate Fusion model:**

| Class | N Normal | S Supra | V Ventricular | F Fusion | Q Unknown |
|-------|----------|---------|---------------|----------|-----------|
| F1 | 0.987 | 0.669 | 0.941 | 0.725 | 0.982 |

---

## Datasets

- **MIT-BIH Arrhythmia Database** — 87,554 annotated beats, 5 AAMI classes
  [Kaggle version](https://www.kaggle.com/datasets/shayanfazeli/heartbeat)

- **BIDMC PPG+ECG Dataset** — 53 simultaneous ECG+PPG recordings at 125 Hz
  [PhysioNet](https://physionet.org/content/bidmc/1.0.0/)

> Datasets are not included in this repo due to size constraints.
> Download both and place them in the `data/` directory before running notebooks.

---

## Repository Structure

```
ArrhythmiaGuard/
├── 01_explore_mitbih.ipynb       # Data exploration and EDA
├── 02_preprocess.ipynb           # MIT-BIH preprocessing pipeline
├── 03_train.ipynb                # CNN 1D baseline training
├── 04_evaluate.ipynb             # Model evaluation and metrics
├── 05_bidmc_download.ipynb       # BIDMC dataset download
├── 06_preprocess_bidmc.ipynb     # BIDMC preprocessing and quality filter
├── 07_fusion_model.ipynb         # ChannelGate fusion model training
├── 08_quantize.ipynb             # TFLite conversion and format comparison
├── figures/                      # Generated plots and visualizations
├── .gitignore
└── README.md
```

---

## Hardware

| Component | Model |
|-----------|-------|
| Microcontroller | ESP32-S3 N16R8 (240 MHz, 8 MB PSRAM) |
| ECG Sensor | AD8232 |
| PPG Sensor | MAX30102 |
| Vibration Motor | Moussasoft 3-pin module |
| Power Module | HW-131 (3.3V stabilized rail) |

Total hardware cost: approximately 482 MAD (~44 EUR)

---

## Setup

### ML Pipeline

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/ArrhythmiaGuard.git
cd ArrhythmiaGuard

# Create and activate virtual environment
python -m venv pfe_env
pfe_env\Scripts\activate      # Windows
# source pfe_env/bin/activate  # Linux/Mac

# Install dependencies
pip install tensorflow numpy pandas scikit-learn imbalanced-learn wfdb scipy matplotlib seaborn

# Download datasets into data/ then run notebooks in order:
# 01 → 02 → 03 → 04 → 05 → 06 → 07 → 08
```

### ESP32-S3 Firmware

- Arduino IDE with ESP32 core 2.0.17 (not 3.x)
- Library: TFLite Micro by tanakamasayuki
- Partition scheme: Huge APP (3MB No OTA)
- Flash the main `.ino` file from the firmware folder

### Flutter App

```bash
cd ArrhythmiaGuard_app
flutter pub get
flutter run
```

Tested on Samsung Galaxy Tab SM-X510 (Android 16).

---

## Key Technical Notes

- **Why float32 and not INT8:** INT8 dynamic-range quantization generates `hybrid CONV_2D` ops not supported by the TFLite Micro library used. Float16 requires a missing `DEQUANTIZE` kernel. Float32 TFLite is the only format that runs on this library/hardware combination.

- **Why ChannelGate instead of MultiHeadAttention:** standard attention generates `BATCH_MATMUL` and `EXPAND_DIMS` ops unsupported by TFLite Micro. ChannelGate achieves cross-modal modulation using only `MEAN`, `MUL`, and `ADD`.

- **PPG proxy:** since no public dataset combines AAMI arrhythmia labels and simultaneous PPG recordings, MIT-BIH ECG beats are paired with BIDMC PPG beats via 1-NN matching on ECG morphology. This is a methodological approximation discussed in the report.

---

## License

MIT License — free to use for research and educational purposes.

---

## Citation

```
Tagui, K. (2026). ArrhythmiaGuard: Real-Time Cardiac Arrhythmia Detection
via ECG+PPG Fusion with TinyML on ESP32-S3.
PFE Report, Faculté des Sciences Appliquées, Université Ibn Zohr, Aït Melloul.
```
