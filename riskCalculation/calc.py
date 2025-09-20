class User:
    def __init__(self, phototype, age, severity_score, risk_score=0):
        self.phototype = phototype
        self.age = age
        self.severity_score = severity_score
        self.risk_score = risk_score
    
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

    def classify_ers(self, ers):
        if 0.1 <= ers <= 0.3:
            return "Very Low"
        elif 0.31 <= ers <= 0.6:
            return "Low"
        elif 0.61 <= ers <= 1.0:
            return "Medium"
        elif 1.01 <= ers <= 1.5:
            return "High"
        elif ers > 1.5:
            return "Very High"
        else:
            return "Unknown"

    def calculate_erythemal_risk_score(self):
        ref = self.get_ref()
        am = self.get_age_modifier()
        cm = self.get_condition_modifier()
        ers = ref * am * cm
        self.risk_score = ers  # Update the risk_score attribute
        risk_category = self.classify_ers(ers)
        return {
            "REF": ref,
            "Age Modifier": am,
            "Condition Modifier": cm,
            "ERS": ers,
            "Risk Category": risk_category
        }

if __name__ == "__main__":
    print("Fitzpatrick Phototype : ", end="")
    phototype = int(input().strip())
    print("Age: ", end="")
    age = int(input().strip())
    print("Pre-existing skin condition severity (0-5, if multiple, comma-separated): ", end="")
    severity_input = int(input().strip())
    
    # Create a User instance with all attributes
    user = User(phototype, age, severity_input)
    result = user.calculate_erythemal_risk_score()
    
    print("\n--- Erythemal Risk Assessment ---")
    print(f"REF (Phototype): {result['REF']}")
    print(f"Age Modifier: {result['Age Modifier']}")
    print(f"Condition Modifier: {result['Condition Modifier']}")
    print(f"Erythemal Risk Score (ERS): {result['ERS']:.2f}")
    print(f"Risk Category: {result['Risk Category']}")
    print(f"User's stored risk score: {user.risk_score:.2f}")
    print(f"User's severity score: {user.severity_score}")