#!/usr/bin/env python3
"""
Script to update all existing users in the database with correct risk categories.
This fixes the issue where users have "Unknown" risk categories.
"""

import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), 'riskCalculation'))

from riskCalculation.calc import add_risk_categories_to_users

def main():
    print("🔄 Updating risk categories for all users in the database...")
    print("=" * 60)
    
    try:
        add_risk_categories_to_users()
        print("\n✅ Successfully updated all users with correct risk categories!")
        print("🎉 All users should now have proper baseline_risk_category and final_risk_category values.")
        
    except Exception as e:
        print(f"\n❌ Error updating users: {str(e)}")
        print("Please check your Firebase configuration and try again.")
        return 1
    
    return 0

if __name__ == "__main__":
    exit_code = main()
    sys.exit(exit_code)
