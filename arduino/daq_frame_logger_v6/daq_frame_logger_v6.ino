/*
  daq_frame_logger_v6.ino
  ------------------------------------------------------------------
  Arduino Uno R3  -  DAQ frame logger with RTC, DHT22 and IR illuminator

  Pin map (as wired)
    DAQ frame trigger   D2   INT0, BNC centre; shield -> Arduino GND
    IR LED array        D5   -> WPM411 (IRF520) SIG   [PWM capable]
                             V- = switching leg, V+ unused
    DHT22 DATA          D7   +10k pull-up to 5V if bare 4-pin sensor
    DS3231              A4 SDA / A5 SCL
    DAQ analog in       A0, A1

  Serial commands (Serial Monitor at 115200, or from MATLAB)
    S  start streaming        X  stop streaming
    Z  zero frame counter     R  print statistics now
    1  LEDs full on           0  LEDs off
    B<n>  LED brightness 0-255 (e.g. B128)
    T  DHT self-test: 5 reads with the trigger interrupt detached
    H  toggle 1 Hz heartbeat  ?  print header block

  Output, one line per DAQ trigger:
    D,seq,epoch_s,ms,micros,a0,a1,tempC,rh,missed

  v6 fix: the DHT22 needs 2 s of dead time between samples. v4/v5
  forced BOTH readTemperature() and readHumidity(), so the humidity
  call hit the sensor milliseconds after the temperature call and
  always returned NaN. Now one call forces a fresh sample and the
  other reads the same packet from cache. The 60 ms retry loop had
  the same fault and is gone; a failed read is simply retried on the
  next 2 s cycle, which also keeps the loop non-blocking.
  ------------------------------------------------------------------
*/

#include <Wire.h>
#include <RTClib.h>
#include <DHT.h>

// ------------------------- pin map -------------------------------
const uint8_t PIN_TRIG     = 2;
const uint8_t PIN_LED_GATE = 5;
const uint8_t PIN_DHT      = 7;
const uint8_t CH_A         = A0;
const uint8_t CH_B         = A1;

#define DHTTYPE DHT22              // change to DHT11 if that's the part

// ------------------------- config --------------------------------
const uint32_t BAUD           = 115200;
const uint16_t DHT_PERIOD_MS  = 2200;   // >= 2000; sensor dead time
const uint16_t DHT_FORCE_MS   = 6000;   // read regardless once this stale
const uint16_t DHT_GUARD_MS   = 150;    // prefer to read between bursts
const uint16_t RTC_PERIOD_MS  = 1000;
const uint16_t STAT_PERIOD_MS = 1000;
const uint16_t MIN_TRIG_US    = 200;    // reject edges closer than this

// ------------------------- globals -------------------------------
RTC_DS3231 rtc;
DHT dht(PIN_DHT, DHTTYPE);

volatile uint32_t trigSeq      = 0;
volatile uint32_t trigMicros   = 0;
volatile uint32_t trigMillis   = 0;
volatile bool     trigPending  = false;
volatile uint32_t lastEdgeUs   = 0;
volatile uint32_t missedFrames = 0;

uint32_t rtcEpoch = 0, rtcAnchorMs = 0;
uint32_t lastDhtMs = 0, lastRtcMs = 0, lastStatMs = 0, lastDhtGoodMs = 0;
uint32_t statSeqMark = 0;
uint16_t dhtOk = 0, dhtFail = 0;
uint8_t  ledLevel = 255;
float    lastRateHz = 0;

float tempC = NAN, rh = NAN;
bool  streaming = false, rtcOk = false, heartbeat = true;

// ------------------------- ISR -----------------------------------
void onFrameTrigger() {
  uint32_t now = micros();
  if (now - lastEdgeUs < MIN_TRIG_US) return;   // glitch / ringing
  lastEdgeUs = now;
  if (trigPending) missedFrames++;              // previous frame unsent
  trigMicros = now;
  trigMillis = millis();
  trigSeq++;
  trigPending = true;
}

// ------------------------- helpers -------------------------------
void setLeds(uint8_t level) {
  ledLevel = level;
  if (level == 0)        digitalWrite(PIN_LED_GATE, LOW);
  else if (level == 255) digitalWrite(PIN_LED_GATE, HIGH);
  else                   analogWrite(PIN_LED_GATE, level);   // ~980 Hz
}

void anchorClock() {
  if (!rtcOk) return;
  DateTime t = rtc.now();
  rtcEpoch    = t.unixtime();
  rtcAnchorMs = millis();
}

// ONE forced sample, then the companion value from the same packet.
// Forcing both would hit the sensor inside its 2 s dead time and the
// second call would always return NaN.
bool readDht() {
  float t = dht.readTemperature(false, true);   // celsius, force fresh
  float h = dht.readHumidity(false);            // same packet, cached

  if (isnan(t) || isnan(h)) { dhtFail++; return false; }

  tempC = t;
  rh    = h;
  dhtOk++;
  lastDhtGoodMs = millis();
  return true;
}

// Five reads with the trigger interrupt detached, spaced past the
// sensor's dead time. Run once with the LEDs on, then send '0' and
// run again to isolate power-rail droop from interrupt interference.
void selfTest() {
  Serial.println(F("#selftest,start - interrupt detached"));
  Serial.print(F("#selftest,leds=")); Serial.println(ledLevel);
  detachInterrupt(digitalPinToInterrupt(PIN_TRIG));

  uint8_t good = 0;
  for (uint8_t i = 0; i < 5; i++) {
    float t = dht.readTemperature(false, true);
    float h = dht.readHumidity(false);
    Serial.print(F("#test,")); Serial.print(i); Serial.print(',');
    if (isnan(t) || isnan(h)) {
      Serial.println(F("FAIL"));
    } else {
      good++;
      Serial.print(t, 1); Serial.print(','); Serial.println(h, 1);
    }
    delay(2200);                    // respect the dead time
  }

  Serial.print(F("#selftest,good=")); Serial.print(good); Serial.println(F("/5"));
  if (good == 5)     Serial.println(F("#selftest,clean without the ISR -> interrupt is the cause"));
  else if (good > 0) Serial.println(F("#selftest,intermittent -> decoupling / signal integrity"));
  else               Serial.println(F("#selftest,none -> send '0' and retest; if still 0, check wiring"));

  attachInterrupt(digitalPinToInterrupt(PIN_TRIG), onFrameTrigger, RISING);
  Serial.println(F("#selftest,end - interrupt reattached"));
}

void printStats() {
  uint32_t seqNow, miss;
  noInterrupts(); seqNow = trigSeq; miss = missedFrames; interrupts();

  Serial.print(F("#stat,frames="));  Serial.print(seqNow);
  Serial.print(F(",rate="));         Serial.print(lastRateHz, 1);
  Serial.print(F("Hz,missed="));     Serial.print(miss);
  Serial.print(F(",dhtOk="));        Serial.print(dhtOk);
  Serial.print(F(",dhtFail="));      Serial.print(dhtFail);
  Serial.print(F(",T="));
  if (isnan(tempC)) Serial.print(F("nan")); else Serial.print(tempC, 1);
  Serial.print(F(",RH="));
  if (isnan(rh))    Serial.print(F("nan")); else Serial.print(rh, 1);
  Serial.print(F(",age="));
  Serial.print(lastDhtGoodMs ? (millis() - lastDhtGoodMs) : 0);
  Serial.print(F("ms,led="));        Serial.print(ledLevel);
  Serial.print(F(",stream="));       Serial.println(streaming ? 1 : 0);
}

void printHeader() {
  Serial.println(F("#fmt,seq,epoch_s,ms,micros,a0,a1,tempC,rh,missed"));
  Serial.println(F("#pins,trig=D2,gate=D5,dht=D7,i2c=A4/A5,analog=A0/A1"));
  Serial.print(F("#rtc,")); Serial.println(rtcOk ? F("ok") : F("FAIL"));
  Serial.print(F("#dht,")); Serial.println(dhtOk ? F("ok") : F("no valid read yet"));
  printStats();
}

// ------------------------- setup ---------------------------------
void setup() {
  Serial.begin(BAUD);
  while (!Serial) { ; }

  pinMode(PIN_LED_GATE, OUTPUT);
  setLeds(255);                    // illuminator on at boot

  pinMode(PIN_TRIG, INPUT);        // INPUT_PULLUP if DAQ is open-collector
  dht.begin();

  Wire.begin();
  rtcOk = rtc.begin();
  if (rtcOk) {
    if (rtc.lostPower()) rtc.adjust(DateTime(F(__DATE__), F(__TIME__)));
    anchorClock();
  }

  delay(2000);                     // DHT22 needs this before first read
  readDht();
  lastDhtMs = millis();

  attachInterrupt(digitalPinToInterrupt(PIN_TRIG), onFrameTrigger, RISING);
  printHeader();
}

// ------------------------- loop ----------------------------------
void loop() {

  // ---- serial commands ----
  while (Serial.available()) {
    char c = Serial.read();
    switch (c) {
      case 'S': case 's':
        noInterrupts(); trigPending = false; interrupts();
        streaming = true; anchorClock();
        Serial.println(F("#start")); break;
      case 'X': case 'x':
        streaming = false; Serial.println(F("#stop")); break;
      case 'Z': case 'z':
        noInterrupts(); trigSeq = 0; missedFrames = 0; trigPending = false; interrupts();
        statSeqMark = 0; Serial.println(F("#zero")); break;
      case '1': setLeds(255); Serial.println(F("#leds,255")); break;
      case '0': setLeds(0);   Serial.println(F("#leds,0"));   break;
      case 'B': case 'b': {
        long v = Serial.parseInt();
        setLeds((uint8_t)constrain(v, 0, 255));
        Serial.print(F("#leds,")); Serial.println(ledLevel);
        break;
      }
      case 'T': case 't': selfTest(); break;
      case 'H': case 'h':
        heartbeat = !heartbeat;
        Serial.print(F("#heartbeat,")); Serial.println(heartbeat ? 1 : 0); break;
      case 'R': case 'r': printStats(); break;
      case '?': printHeader(); break;
      default: break;
    }
  }

  uint32_t now = millis();

  // ---- absolute-time anchor, once per second ----
  if (now - lastRtcMs >= RTC_PERIOD_MS) { lastRtcMs = now; anchorClock(); }

  // ---- DHT22: read between bursts if possible, force if stale ----
  bool due   = (now - lastDhtMs >= DHT_PERIOD_MS);
  bool quiet = (now - trigMillis > DHT_GUARD_MS);
  bool stale = (now - lastDhtMs >= DHT_FORCE_MS);
  if (due && (quiet || stale)) { lastDhtMs = now; readDht(); }

  // ---- once-per-second frame statistics ----
  if (now - lastStatMs >= STAT_PERIOD_MS) {
    uint32_t seqNow;
    noInterrupts(); seqNow = trigSeq; interrupts();
    lastRateHz  = (seqNow - statSeqMark) * 1000.0 / (now - lastStatMs);
    statSeqMark = seqNow;
    lastStatMs  = now;
    if (heartbeat) printStats();
  }

  // ---- one CSV line per DAQ frame ----
  if (trigPending) {
    uint32_t seq, us, ms, miss;
    noInterrupts();
    seq = trigSeq; us = trigMicros; ms = trigMillis; miss = missedFrames;
    trigPending = false;
    interrupts();

    int va = analogRead(CH_A);
    int vb = analogRead(CH_B);

    if (streaming) {
      uint32_t elapsed = ms - rtcAnchorMs;
      Serial.print('D');                          Serial.print(',');
      Serial.print(seq);                          Serial.print(',');
      Serial.print(rtcEpoch + elapsed/1000UL);    Serial.print(',');
      Serial.print((uint16_t)(elapsed % 1000UL)); Serial.print(',');
      Serial.print(us);                           Serial.print(',');
      Serial.print(va);                           Serial.print(',');
      Serial.print(vb);                           Serial.print(',');
      if (isnan(tempC)) Serial.print(F("nan")); else Serial.print(tempC, 2);
      Serial.print(',');
      if (isnan(rh))    Serial.print(F("nan")); else Serial.print(rh, 2);
      Serial.print(',');
      Serial.println(miss);
    }
  }
}
