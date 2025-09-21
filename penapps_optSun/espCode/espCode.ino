#include <ESP8266WiFi.h>
#include <WiFiClientSecure.h>
#include <ArduinoJson.h>
#include <Wire.h>
#include "Adafruit_VEML6070.h"

// === Wi-Fi & Firebase Config ===
const char* ssid = "PennApps";
const char* password = "hackathon";

const char* firebaseProjectId = "pennapps-c80df";
const char* firebaseApiKey = "AIzaSyBsbt5Amc8-DpXgKAwsZebNXjN1XkXYNH0";

const char* host = "firestore.googleapis.com";
const int httpsPort = 443;

// === Hardware Pins ===
const int ledPin = D5;       // GPIO14
const int buttonPin = D3;    // GPIO13 (INPUT_PULLUP)
Adafruit_VEML6070 uv = Adafruit_VEML6070();

// === Connect to Wi-Fi ===
void connectWiFi() {
  Serial.print("Connecting to WiFi");
  WiFi.begin(ssid, password);
  unsigned long startTime = millis();

  while (WiFi.status() != WL_CONNECTED && millis() - startTime < 10000) {
    Serial.print(".");
    delay(500);
    yield();
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n WiFi connected!");
    Serial.print("IP: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("\n Failed to connect to WiFi");
  }
}

// === Send Data to Firebase ===
void sendToFirebase(int uv_raw, float uv_index, int is_pressed) {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("WiFi disconnected, reconnecting...");
    connectWiFi();
    if (WiFi.status() != WL_CONNECTED) {
      Serial.println(" Still not connected, skipping send.");
      return;
    }
  }

  // JSON Payload
  StaticJsonDocument<256> doc;
  doc["fields"]["uv_raw"]["integerValue"] = uv_raw;
  doc["fields"]["uv_index"]["doubleValue"] = uv_index;
  doc["fields"]["is_pressed"]["integerValue"] = is_pressed;
  String jsonPayload;
  serializeJson(doc, jsonPayload);

  // Create Secure Client
  WiFiClientSecure client;
  client.setInsecure(); // Only for testing

  String url = "/v1/projects/" + String(firebaseProjectId) +
               "/databases/(default)/documents/users/latest?key=" +
               firebaseApiKey;

  Serial.println(" Connecting to Firebase...");
  if (!client.connect(host, httpsPort)) {
    Serial.println("Firebase connection failed");
    return;
  }

  client.println("PATCH " + url + " HTTP/1.1");
  client.println("Host: firestore.googleapis.com");
  client.println("Content-Type: application/json");
  client.print("Content-Length: ");
  client.println(jsonPayload.length());
  client.println();
  client.println(jsonPayload);

  // Read response
  while (client.connected()) {
    String line = client.readStringUntil('\n');
    if (line == "\r") break;
  }

  String response = client.readString();
  Serial.println(" Firebase response:");
  Serial.println(response);
}

// === Setup ===
void setup() {
  Serial.begin(115200);
  delay(500);
  Serial.println(" Setup started");

  pinMode(ledPin, OUTPUT);
  pinMode(buttonPin, INPUT_PULLUP);

  connectWiFi();

  Wire.begin();  // Initialize I2C
  uv.begin(VEML6070_1_T);
}

// === Main Loop ===
void loop() {
  uint16_t uvRaw = uv.readUV();

  // Safety fallback if sensor not detected
  if (uvRaw == 0xFFFF) {
    Serial.println("UV sensor error (not connected?)");
    uvRaw = 0;
  }
  int is_pressed; 
  float uvIndex = (uvRaw / 1024.0) * 11.0;

  if(digitalRead(buttonPin) == LOW) {
       is_pressed = 1; 
  } else {
     is_pressed = 0;
  }
 

  Serial.printf(" UV Raw: %d, UV Index: %.2f, Button: %d\n", uvRaw, uvIndex, is_pressed);

  // LED logic
  if (uvRaw > 40) {
    digitalWrite(ledPin, HIGH);
  } else {
    digitalWrite(ledPin, LOW);
  }

  // Send to Firebase
  sendToFirebase(uvRaw, uvIndex, is_pressed);

  delay(3000);
  yield(); // prevent watchdog reset
}
