import firebase_admin
from firebase_admin import credentials, firestore
import time
import os

# Get the directory where this script is located
script_dir = os.path.dirname(os.path.abspath(__file__))
firebase_key_path = os.path.join(script_dir, 'firebasekey.json')

# Check if the firebase key file exists
if not os.path.exists(firebase_key_path):
    print(f"Error: firebasekey.json not found at {firebase_key_path}")
    print("Please place your Firebase service account key file as 'firebasekey.json' in the same directory as this script.")
    exit(1)

try:
    cred = credentials.Certificate(firebase_key_path)
    firebase_admin.initialize_app(cred)
    print("Firebase initialized successfully!")
except Exception as e:
    print(f"Error initializing Firebase: {e}")
    print("Please check your firebasekey.json file.")
    exit(1)

# Initialize Firestore client
db = firestore.client()

class User:
    def __init__(self, phototype, age, severity_score, risk_score1=0, uv_intensity=0, location='default_location'):
        self.phototype = phototype
        self.age = age
        self.severity_score = severity_score
        self.risk_score1 = risk_score1
        # Fetch UV intensity from Firebase if not provided
        self.uv_intensity = uv_intensity if uv_intensity is not None else get_uv_intensity_from_firebase(location)
        # Tracking variables for recalculate_risk_score
        self.previous_uv_intensity = self.uv_intensity
        self.last_calculation_time = time.time()
        self.risk_score = 0  # Initialize risk_score

    def get_ref(self):
        ref_table = {
            1: 1.0,
            2: 0.8,
            3: 0.6,
            4: 0.4,
            5: 0.2,
            6: 0.1
        }
        return ref_table[self.phototype]

    def get_age_modifier(self):
        if self.age < 20:
            return 0.8
        elif 20 <= self.age <= 39:
            return 1.0
        elif 40 <= self.age <= 59:
            return 1.2
        elif 60 <= self.age <= 69:
            return 1.4
        else:  # 70+
            return 1.6

    def get_condition_modifier(self):
        # Uses the user's severity_score attribute
        modifier_map = {
            0: 1.0,
            1: 1.1,
            2: 1.2,
            3: 1.4,
            4: 1.6,
            5: 1.8
        }
        return modifier_map[self.severity_score]

    def classify_ers_baseline(self, ers):
        if 0 <= ers <= 0.58:
            return "Very Low"
        elif .59 <= ers <= 1.16:
            return "Low"
        elif 1.17 <= ers <= 1.75:
            return "Medium"
        elif 1.76 <= ers <= 2.34:
            return "High"
        elif ers > 2.35:
            return "Very High"

    def classify_ers_final(self, ers):
        if ers <= 1.15:
            return "Very Low"
        elif 1.16 <= ers <= 2.30:
            return "Low"
        elif 2.31 <= ers <= 3.45:
            return "Medium"
        elif 3.46 <= ers <= 4.60:
            return "High"
        elif ers > 4.61:
            return "Very High"

    def calculate_baseline_erythemal_risk_score(self):
        ref = self.get_ref()
        am = self.get_age_modifier()
        cm = self.get_condition_modifier()
        ers = ref * am * cm
        risk_category1 = self.classify_ers_baseline(ers)
        self.risk_score1 = ers  # Update the risk_score1 attribute
        return {
            "REF": ref,
            "Age Modifier": am,
            "Condition Modifier": cm,
            "Basline Risk Score": ers,
            "Baseline Risk Category": risk_category1,
            "UV Intensity": self.uv_intensity
        }

    def get_uv_modifier(self):
        """
        Calculate UV modifier based on raw sensor data.
        The sensor data is a raw integer value, not a UV index.
        Uses the raw sensor data directly without any scaling.
        """
        uv = self.uv_intensity
        if uv == 0:
            return -2.88
        else:
            proportion = uv / 165 #165 is max uv intensity
            return proportion * 2.88 #2.88 is max baseline score, we weight both the same

    def calculate_final_erythemal_risk_score(self):
        baseline = self.calculate_baseline_erythemal_risk_score()
        uv_modifier = self.get_uv_modifier()
        ers = baseline["Basline Risk Score"] + uv_modifier
        risk_category = self.classify_ers_final(ers)
        self.risk_score = ers  # Store the final risk score in the user instance
        return {
            "REF": baseline["REF"],
            "Age Modifier": baseline["Age Modifier"],
            "Condition Modifier": baseline["Condition Modifier"],
            "UV Modifier": uv_modifier,
            "ERS": ers,
            "Risk Category": risk_category
        }

    def recalculate_risk_score(self, raw_sensor_data):
        """
        Recalculates the risk score based on raw sensor data changes and time intervals.
        
        Args:
            raw_sensor_data: Current raw integer value from the UV sensor
            
        Returns:
            dict: Updated risk score information if recalculation occurred, None otherwise
        """
        current_time = time.time()
        time_since_last_calculation = current_time - self.last_calculation_time
        
        # Check if raw sensor data changed by 100 or more
        sensor_data_change = abs(raw_sensor_data - self.previous_uv_intensity)
        
        # Check if 15 minutes (900) seconds) have passed since last calculation
        time_threshold_exceeded = time_since_last_calculation >= 900
        
        # Recalculate if sensor data changed by 100+ OR 15 minutes have passed
        if sensor_data_change >= 100 or time_threshold_exceeded:
            # Update UV intensity with raw sensor data
            self.uv_intensity = raw_sensor_data
            
            # Recalculate the risk score
            result = self.calculate_final_erythemal_risk_score()
            
            # Update tracking variables
            self.previous_uv_intensity = raw_sensor_data
            self.last_calculation_time = current_time
            
            print(f"Risk score recalculated - Sensor data change: {sensor_data_change}, Time since last: {time_since_last_calculation:.1f}s")
            print(f"Raw sensor data: {raw_sensor_data}, UV modifier: {result['UV Modifier']:.3f}")
            return result
        else:
            # No recalculation needed
            return None

    def simulate_sensor_updates(self, duration_minutes=5):
        """
        Simulates sensor updates every second for testing purposes.
        
        Args:
            duration_minutes: How long to run the simulation in minutes
        """
        print(f"Starting sensor simulation for {duration_minutes} minutes...")
        print("Raw sensor data will be updated every second from Firebase")
        print("Risk score will be recalculated when sensor data changes by 100+ or every 30 minutes")
        print("-" * 60)
        
        end_time = time.time() + (duration_minutes * 60)
        
        while time.time() < end_time:
            # Get current raw sensor data from Firebase
            current_sensor_data = get_uv_intensity_from_firebase()
            
            # Try to recalculate risk score
            result = self.recalculate_risk_score(current_sensor_data)
            
            if result:
                print(f"Time: {time.strftime('%H:%M:%S')} - Raw sensor data: {current_sensor_data}")
                print(f"  ERS: {result['ERS']:.2f}, Category: {result['Risk Category']}")
                print(f"  UV Modifier: {result['UV Modifier']:.3f}")
                print("-" * 40)
            else:
                print(f"Time: {time.strftime('%H:%M:%S')} - Raw sensor data: {current_sensor_data} (no recalculation needed)")
            
            # Wait 1 second before next update
            time.sleep(1)

def get_uv_intensity_from_firebase(location='default_location'):
    """
    Get UV intensity from Firestore.
    For now, returns a default value since we don't have UV data in Firestore yet.
    """
    try:
        # Try to get UV intensity from Firestore
        uv_ref = db.collection('uv_intensity').document(location)
        uv_doc = uv_ref.get()
        
        if uv_doc.exists:
            uv_data = uv_doc.to_dict()
            return uv_data.get('value', 100)  # Default to 100 if no 'value' field
        else:
            # Return default value if no UV data exists
            return 100
    except Exception as e:
        print(f"Error getting UV intensity: {e}")
        return 100  # Default value

def add_risk_categories_to_users():
    """
    Add baseline_risk_category and final_risk_category fields to all users in Firestore.
    This is a focused function that only adds the two string fields you need.
    """
    try:
        # Get all users from Firestore
        users_ref = db.collection('users')
        users_docs = users_ref.stream()
        
        users_list = list(users_docs)
        if not users_list:
            print("No users found in the database.")
            return

        print(f"Adding risk categories to {len(users_list)} users...")
        print("-" * 60)

        for user_doc in users_list:
            try:
                user_id = user_doc.id
                user_info = user_doc.to_dict()
                
                # Extract user attributes
                phototype = user_info.get('skinToneIndex', 3)
                age = int(user_info.get('age', 25))  # Ensure age is an integer
                severity_score = int(user_info.get('conditionSeverity', 0))  # Ensure severity is an integer
                location = user_info.get('location', 'default_location')

                print(f"Processing user {user_id}...")

                # Get UV intensity
                uv_intensity = get_uv_intensity_from_firebase(location)

                # Create user and calculate risk scores
                user = User(phototype, age, severity_score, uv_intensity=uv_intensity, location=location)
                baseline = user.calculate_baseline_erythemal_risk_score()
                final = user.calculate_final_erythemal_risk_score()

                # Update ONLY the two category fields in Firestore
                user_doc.reference.update({
                    'baseline_risk_category': baseline["Baseline Risk Category"],
                    'final_risk_category': final["Risk Category"]
                })
                
                print(f"  ✓ Added categories for user {user_id}:")
                print(f"    Baseline: {baseline['Baseline Risk Category']}")
                print(f"    Final: {final['Risk Category']}")
                print()

            except Exception as e:
                print(f"  ✗ Error processing user {user_id}: {e}")
                continue

        print("Risk categories added successfully!")

    except Exception as e:
        print(f"Error accessing Firestore: {e}")

def continuously_monitor_uv_updates():
    """
    Continuously monitor UV intensity changes and update final risk categories for all users.
    This function runs indefinitely and updates risk scores when UV changes by 100+ or every 15 minutes.
    """
    print("Starting continuous UV monitoring...")
    print("This will monitor UV changes and update final risk categories in real-time")
    print("Press Ctrl+C to stop monitoring")
    print("-" * 60)
    
    # Get all users once at startup
    users_ref = db.collection('users')
    users_docs = list(users_ref.stream())
    
    if not users_docs:
        print("No users found in the database.")
        return
    
    # Create User objects for each user
    user_objects = {}
    for user_doc in users_docs:
        try:
            user_id = user_doc.id
            user_info = user_doc.to_dict()
            
            phototype = user_info.get('skinToneIndex', 3)
            age = int(user_info.get('age', 25))
            severity_score = int(user_info.get('conditionSeverity', 0))
            location = user_info.get('location', 'default_location')
            
            # Create user object
            user = User(phototype, age, severity_score, location=location)
            user_objects[user_id] = {
                'user': user,
                'doc_ref': user_doc.reference,
                'location': location
            }
            
            print(f"✓ Initialized monitoring for user {user_id}")
            
        except Exception as e:
            print(f"✗ Error initializing user {user_id}: {e}")
            continue
    
    print(f"\nMonitoring {len(user_objects)} users...")
    print("=" * 60)
    
    try:
        while True:
            current_time = time.strftime('%H:%M:%S')
            updates_made = 0
            
            for user_id, user_data in user_objects.items():
                try:
                    # Get current UV intensity for this user's location
                    current_uv = get_uv_intensity_from_firebase(user_data['location'])
                    
                    # Try to recalculate risk score
                    result = user_data['user'].recalculate_risk_score(current_uv)
                    
                    if result:
                        # Update the final risk category in Firestore
                        user_data['doc_ref'].update({
                            'final_risk_category': result["Risk Category"],
                            'last_uv_update': current_time,
                            'current_uv_intensity': current_uv
                        })
                        
                        print(f"[{current_time}] User {user_id}: UV={current_uv}, Final={result['Risk Category']}")
                        updates_made += 1
                    
                except Exception as e:
                    print(f"[{current_time}] Error updating user {user_id}: {e}")
                    continue
            
            if updates_made == 0:
                print(f"[{current_time}] No updates needed (UV changes < 100, time < 15min)")
            
            # Wait 1 second before next check
            time.sleep(1)
            
    except KeyboardInterrupt:
        print(f"\n[{time.strftime('%H:%M:%S')}] Monitoring stopped by user")
    except Exception as e:
        print(f"\n[{time.strftime('%H:%M:%S')}] Error during monitoring: {e}")

def simulate_uv_changes(duration_minutes=5):
    """
    Simulate UV intensity changes for testing the continuous monitoring.
    This writes random UV values to Firestore every second.
    """
    import random
    
    print(f"Simulating UV changes for {duration_minutes} minutes...")
    print("This will write random UV values to Firestore every second")
    print("Run continuously_monitor_uv_updates() in another terminal to see real-time updates")
    print("-" * 60)
    
    end_time = time.time() + (duration_minutes * 60)
    current_uv = 100  # Starting value
    
    try:
        while time.time() < end_time:
            # Simulate UV changes with random variation
            variation = random.randint(-30, 30)
            current_uv = max(0, current_uv + variation)  # Ensure non-negative
            
            # Write to Firestore
            uv_ref = db.collection('uv_intensity').document('default_location')
            uv_ref.set({
                'value': current_uv,
                'timestamp': time.time(),
                'last_updated': time.strftime('%H:%M:%S')
            })
            
            print(f"[{time.strftime('%H:%M:%S')}] Simulated UV: {current_uv}")
            time.sleep(1)
            
    except KeyboardInterrupt:
        print(f"\n[{time.strftime('%H:%M:%S')}] UV simulation stopped by user")
    except Exception as e:
        print(f"\n[{time.strftime('%H:%M:%S')}] Error during UV simulation: {e}")

def test_firebase_connection():
    """
    Test Firestore connection and check database structure
    """
    try:
        print("Testing Firestore connection...")
        
        # Test basic connection by listing collections
        collections = db.collections()
        collection_names = [col.id for col in collections]
        print(f"✓ Firestore connection successful!")
        print(f"Available collections: {collection_names}")
        
        # Check if users collection exists
        users_ref = db.collection('users')
        users_docs = list(users_ref.stream())
        
        if users_docs:
            print(f"✓ Found 'users' collection with {len(users_docs)} users")
            user_ids = [doc.id for doc in users_docs]
            print(f"User IDs: {user_ids}")
            
            # Show first user's structure
            first_user = users_docs[0]
            first_user_data = first_user.to_dict()
            print(f"First user ({first_user.id}) fields: {list(first_user_data.keys())}")
        else:
            print("✗ No 'users' collection found or no documents in users collection")
            
    except Exception as e:
        print(f"✗ Firestore connection failed: {e}")

# Test connection first
test_firebase_connection()

# Example usage:
print("\nChoose an option:")
print("1. add_risk_categories_to_users() - Add initial risk categories (run once)")
print("2. continuously_monitor_uv_updates() - Start continuous monitoring (runs forever)")
print("3. simulate_uv_changes(5) - Simulate UV changes for 5 minutes (for testing)")
print("\nRunning add_risk_categories_to_users() first...")
add_risk_categories_to_users()

print("\n" + "="*60)
print("CONTINUOUS MONITORING SETUP")
print("="*60)
print("To start continuous monitoring, run:")
print("continuously_monitor_uv_updates()")
print("\nTo test with simulated UV changes, run in another terminal:")
print("simulate_uv_changes(5)")

if __name__ == "__main__":
    print("Starting risk score calculation for all Firebase users...")
    print("This will calculate baseline and final risk scores for each user.")
    print("=" * 60)
    
    # The process_all_users() function is already called above
    # It will automatically process all users and update their risk scores