"""
Script to check Supabase database tables
"""
import asyncio
import os
from dotenv import load_dotenv
import httpx

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

async def check_all_tables():
    """Fetch data from all relevant tables"""
    base_url = f"{SUPABASE_URL}/rest/v1"
    headers = {
        "apikey": SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "Content-Type": "application/json",
    }
    
    async with httpx.AsyncClient() as client:
        # Check users table
        print("=" * 60)
        print("USERS TABLE")
        print("=" * 60)
        try:
            response = await client.get(f"{base_url}/users?select=*", headers=headers)
            if response.status_code == 200:
                users = response.json()
                print(f"Found {len(users)} user(s):")
                for user in users:
                    print(f"  - ID: {user.get('id', 'N/A')[:20]}...")
                    print(f"    Email: {user.get('email', 'N/A')}")
                    print(f"    Name: {user.get('display_name', 'N/A')}")
                    print(f"    Created: {user.get('created_at', 'N/A')}")
            else:
                print(f"Error: {response.status_code} - {response.text}")
        except Exception as e:
            print(f"Error: {e}")
        
        # Check saved_locations table
        print("\n" + "=" * 60)
        print("SAVED_LOCATIONS TABLE")
        print("=" * 60)
        try:
            response = await client.get(f"{base_url}/saved_locations?select=*", headers=headers)
            if response.status_code == 200:
                locations = response.json()
                print(f"Found {len(locations)} saved location(s):")
                for loc in locations:
                    print(f"  - ID: {loc.get('id', 'N/A')}")
                    print(f"    User ID: {loc.get('user_id', 'N/A')[:20]}...")
                    print(f"    Name: {loc.get('name', 'N/A')}")
                    print(f"    Lat: {loc.get('lat', 'N/A')}, Lng: {loc.get('lng', 'N/A')}")
                    print(f"    Created: {loc.get('created_at', 'N/A')}")
            else:
                print(f"Error: {response.status_code} - {response.text}")
        except Exception as e:
            print(f"Error: {e}")
        
        # Check exposure_history table
        print("\n" + "=" * 60)
        print("EXPOSURE_HISTORY TABLE")
        print("=" * 60)
        try:
            response = await client.get(f"{base_url}/exposure_history?select=*&limit=10", headers=headers)
            if response.status_code == 200:
                exposures = response.json()
                print(f"Found {len(exposures)} exposure record(s):")
                for exp in exposures:
                    print(f"  - ID: {exp.get('id', 'N/A')}")
                    print(f"    User ID: {exp.get('user_id', 'N/A')[:20]}...")
                    print(f"    Date: {exp.get('record_date', 'N/A')}")
                    print(f"    Score: {exp.get('total_exposure_score', 'N/A')}")
            else:
                print(f"Error: {response.status_code} - {response.text}")
        except Exception as e:
            print(f"Error: {e}")

if __name__ == "__main__":
    asyncio.run(check_all_tables())
