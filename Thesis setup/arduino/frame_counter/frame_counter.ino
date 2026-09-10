const byte ttlPin = 2;

volatile unsigned long frameCount = 0;
volatile bool newFrame = false;

void frameISR() {
  frameCount++;
  newFrame = true;
}

void setup() {
  pinMode(ttlPin, INPUT);
  Serial.begin(115200);
  attachInterrupt(digitalPinToInterrupt(ttlPin), frameISR, RISING);
}

void loop() {
  static unsigned long lastSent = 0;

  noInterrupts();
  unsigned long countCopy = frameCount;
  bool flagCopy = newFrame;
  newFrame = false;
  interrupts();

  if (flagCopy && countCopy != lastSent) {
    lastSent = countCopy;
    Serial.print("FRAME,");
    Serial.println(countCopy);
  }
}
