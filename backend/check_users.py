"""
Script to check users in Supabase database
"""
import asyncio
import os
from dotenv import load_dotenv
import httpx

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

async def check_users():
    """Fetch all users from the users table"""
    base_url = f"{SUPABASE_URL}/rest/v1"
    headers = {
        "apikey": SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "Content-Type": "application/json",
    }
    
    async with httpx.AsyncClient() as client:
        # Check users table
        print("=" * 60)
        print("CHECKING USERS TABLE")
        print("=" * 60)
        
        try:
            response = await client.get(
                f"{base_url}/users?select=*",
                headers=headers
            )
            
            if response.status_code == 200:
                users = response.json()
                print(f"\nFound {len(users)} user(s):")
                print("-" * 60)
                
                for user in users:
                    print(f"ID: {user.get('id', 'N/A')[:20]}...")
                    print(f"Email: {user.get('email', 'N/A')}")
                    print(f"Display Name: {user.get('display_name', 'N/A')}")
                    print(f"Health Sensitivity: {user.get('health_sensitivity', 'N/A')}")
                    print(f"Created At: {user.get('created_at', 'N/A')}")
                    print("-" * 60)
            else:
                print(f"Error fetching users: {response.status_code}")
                print(f"Response: {response.text}")
                
        except Exception as e:
            print(f"Error: {e}")
        
        # Check saved_locations table
        print("\n" + "=" * 60)
        print("CHECKING SAVED LOCATIONS TABLE")
        print("=" * 60)
        
        try:
            response = await client.get(
                f"{base_url}/saved_locations?select=*",
                headers=headers
            )
            
            if response.status_code == 200:
                locations = response.json()
                print(f"\nFound {len(locations)} saved location(s):")
                print("-" * 60)
                
                for loc in locations:
                    print(f"ID: {loc.get('id', 'N/A')}")
                    print(f"User ID: {loc.get('user_id', 'N/A')[:20]}...")
                    print(f"Name: {loc.get('location_name', 'N/A')}")
                    print(f"Lat: {loc.get('lat', 'N/A')}, Lng: {loc.get('lng', 'N/A')}")
                    print("-" * 60)
            else:
                print(f"Error fetching locations: {response.status_code}")
                print(f"Response: {response.text}")
                
        except Exception as e:
            print(f"Error: {e}")
        
        # Check exposure_history table
        print("\n" + "=" * 60)
        print("CHECKING EXPOSURE HISTORY TABLE")
        print("=" * 60)
        
        try:
            response = await client.get(
                f"{base_url}/exposure_history?select=*&limit=10",
                headers=headers
            )
            
            if response.status_code == 200:
                exposures = response.json()
                print(f"\nFound {len(exposures)} exposure record(s):")
                print("-" * 60)
                
                for exp in exposures:
                    print(f"ID: {exp.get('id', 'N/A')}")
                    print(f"User ID: {exp.get('user_id', 'N/A')[:20]}...")
                    print(f"Date: {exp.get('record_date', 'N/A')}")
                    print(f"Score: {exp.get('total_exposure_score', 'N/A')}")
                    print("-" * 60)
            else:
                print(f"Error fetching exposures: {response.status_code}")
                print(f"Response: {response.text}")
                
        except Exception as e:
            print(f"Error: {e}")

if __name__ == "__main__":
    asyncio.run(check_users())
