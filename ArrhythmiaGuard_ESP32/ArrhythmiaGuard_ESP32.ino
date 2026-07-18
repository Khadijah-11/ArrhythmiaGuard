#include "config.h"
#include "signal_processing.h"
#include "ml_inference.h"
#include "ble_service.h"
#include <Wire.h>
#include "MAX30105.h"
unsigned long lastRpeakMs = 0;
int currentBPM = 0;

const char* CLASS_NAMES[NUM_CLASSES] = {"N","S","V","F","Q"};

MAX30105       ppgSensor;
EcgFilter      ecgFilter;
PpgFilter      ppgFilter;
RPeakDetector  rpeak;
MLInference    ml;
BLEService_AG  ble;

volatile float ecgRing[RING_SIZE];
volatile float ppgRing[RING_SIZE];
volatile int   ringHead = 0;
volatile bool  newSample = false;
volatile float latestEcgRaw = 0;
volatile float latestPpgRaw = 0;
volatile int   samplesSinceRPeak = -1;
volatile int   rpeakRingIndex = 0;

hw_timer_t* timer = nullptr;
portMUX_TYPE timerMux = portMUX_INITIALIZER_UNLOCKED;

void IRAM_ATTR onTimer() {
  portENTER_CRITICAL_ISR(&timerMux);
  newSample = true;
  portEXIT_CRITICAL_ISR(&timerMux);
}

void setup() {
  Serial.begin(115200);
  delay(500);
  Serial.println("\n=== ArrhythmiaGuard ESP32 ===");

  pinMode(ECG_LO_PLUS, INPUT);
  pinMode(ECG_LO_MINUS, INPUT);
  pinMode(VIBRATION_PIN, OUTPUT);
  digitalWrite(VIBRATION_PIN, LOW);

  analogReadResolution(12);
  analogSetPinAttenuation(ECG_PIN, ADC_11db);

  Wire.begin(8, 9);
  if (!ppgSensor.begin(Wire, I2C_SPEED_FAST)) {
    Serial.println("ERROR: MAX30102 not found");
    while (1) delay(1000);
  }
  ppgSensor.setup(0x1F, 4, 2, 125, 411, 4096);
  ppgSensor.setPulseAmplitudeRed(0x0A);
  ppgSensor.setPulseAmplitudeIR(0x1F);

  if (!ml.begin()) { Serial.println("ML init failed - halt"); while(1) delay(1000); }
  ble.begin();

  timer = timerBegin(0, 80, true);
  timerAttachInterrupt(timer, &onTimer, true);
  timerAlarmWrite(timer, SAMPLE_PERIOD_US, true);
  timerAlarmEnable(timer);

  Serial.println("Setup complete. Sampling at 125Hz.");
  // TEMP vibration test — buzz 3 times at startup
  /* for (int i = 0; i < 3; i++) {
    digitalWrite(VIBRATION_PIN, HIGH);
    delay(300);
    digitalWrite(VIBRATION_PIN, LOW);
    delay(300);
  } */
}

float ecgWin[WINDOW_SIZE], ppgWin[WINDOW_SIZE];
float ecgNorm[WINDOW_SIZE], ppgNorm[WINDOW_SIZE];

void loop() {
  latestEcgRaw = (float) analogRead(ECG_PIN);   // bypass leads-off for testing
  latestPpgRaw = (float) ppgSensor.getIR();

  if (newSample) {
    portENTER_CRITICAL(&timerMux);
    newSample = false;
    portEXIT_CRITICAL(&timerMux);

    // Filter here (NOT in ISR — FPU math in ISR crashes on ESP32)
    float e = ecgFilter.process(latestEcgRaw);
    float p = ppgFilter.process(latestPpgRaw);
    ringHead = (ringHead + 1) % RING_SIZE;
    ecgRing[ringHead] = e;
    ppgRing[ringHead] = p;
    if (samplesSinceRPeak >= 0) samplesSinceRPeak++;

    static unsigned long lastStream = 0;
    if (millis() - lastStream > 50) {
      lastStream = millis();
      int ecgByte = (int)((e + 2000.0f) / 4000.0f * 255.0f);
      ecgByte = ecgByte < 0 ? 0 : (ecgByte > 255 ? 255 : ecgByte);
      int ppgByte = (int)(p / 120000.0f * 255.0f);
      ppgByte = ppgByte < 0 ? 0 : (ppgByte > 255 ? 255 : ppgByte);
      ble.sendStream((uint8_t)ecgByte, (uint8_t)ppgByte, 97);
    }  

    int head = ringHead;
    float ecgNow = ecgRing[head];

    if (rpeak.detect(ecgNow, millis())) {
      samplesSinceRPeak = 0;
      rpeakRingIndex = head;

      unsigned long now = millis();
      if (lastRpeakMs > 0) {
        unsigned long rr = now - lastRpeakMs;        // ms between beats
        if (rr > 250 && rr < 2500) {                 // valid range 24–240 bpm
          int instantBpm = 60000 / rr;
          currentBPM = rpeak.getSmoothedBPM(instantBpm);
        }
      }
      lastRpeakMs = now;
    }

    // Debug: print raw sensor values once per second
    static unsigned long lastDbg = 0;
    if (millis() - lastDbg > 1000) {
      lastDbg = millis();
      Serial.printf("ECG raw: %.0f  PPG(IR): %.0f  filtered ECG: %.2f\n",
                    latestEcgRaw, latestPpgRaw, ecgNow);
    }

    if (samplesSinceRPeak >= NOMINAL_BEAT_LEN) {
      int start = (rpeakRingIndex - R_PEAK_OFFSET + RING_SIZE) % RING_SIZE;
      for (int i = 0; i < WINDOW_SIZE; i++) {
        if (i < NOMINAL_BEAT_LEN) {
          int idx = (start + i) % RING_SIZE;
          ecgWin[i] = ecgRing[idx];
          ppgWin[i] = ppgRing[idx];
        } else {
          ecgWin[i] = 0.0f;
          ppgWin[i] = 0.0f;
        }
      }
      samplesSinceRPeak = -1;

      normalizeWindow(ecgWin, ecgNorm, WINDOW_SIZE);
      normalizeWindow(ppgWin, ppgNorm, WINDOW_SIZE);

      float probs[NUM_CLASSES];
      int cls = ml.predict(ecgNorm, ppgNorm, probs);
      if (cls >= 0) {
        Serial.printf("Beat -> %s (%.2f)\n", CLASS_NAMES[cls], probs[cls]);
        ble.sendResult(cls, probs[cls], currentBPM);

        if (VIBRATION_ENABLED && isArrhythmia(cls)) {
          digitalWrite(VIBRATION_PIN, HIGH);
          delay(200);
          digitalWrite(VIBRATION_PIN, LOW);
        }
      }
    }
  }
}