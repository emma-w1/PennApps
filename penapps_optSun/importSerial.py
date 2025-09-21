import serial
import time
import firebase_admin
from firebase_admin import credentials, firestore

# === CONFIG ===
SERIAL_PORT = 'COM7'  # Replace with your Arduino COM port
BAUD_RATE = 9600
SERVICE_ACCOUNT_FILE = 'firebase_key.json'
FIRESTORE_COLLECTION = 'users'
# ===============

# Initialize Firebase
cred = credentials.Certificate(SERVICE_ACCOUNT_FILE)
firebase_admin.initialize_app(cred)
db = firestore.client()

def main():
    try:
        ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1)
        print(f"Connected to {SERIAL_PORT} at {BAUD_RATE} baud.")
    except serial.SerialException as e:
        print(f"Error opening serial port: {e}")
        return

    while True:
        try:
            line = ser.readline().decode('utf-8').strip()
            if line:
                try:
                    # Expecting line like: "512,5.12"
                    parts = line.split(",")
                    if len(parts) == 3:
                        uv_raw = int(parts[0])
                        uv_index = float(parts[1])
                        is_pressed = int(parts[2])

                        # Push both to Firebase
                        db.collection(FIRESTORE_COLLECTION).document('latest').set({
                            'uv_raw': uv_raw,
                            'uv_index': uv_index,
                            'is_pressed': is_pressed, 
                            'timestamp': firestore.SERVER_TIMESTAMP
                        })

                        print(f"Pushed UV Raw: {uv_raw}, UV Index: {uv_index}, is_pressed: {is_pressed}")
                    else:
                        print(f"Unexpected data format: {line}")
                except ValueError:
                    print(f"Non-numeric data received: {line}")
        except Exception as e:
            print(f"Error: {e}")

        time.sleep(1)

if __name__ == "__main__":
    main()
