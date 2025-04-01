import requests
import sys

def check_service(url):
    try:
        response = requests.get(url)
        if response.status_code == 200:
            print(f"Service at {url} is up and running!")
        else:
            print(f"Service Down Alert! Status code: {response.status_code}")
    except Exception as e:
        print(f"Service Unreachable! Error: {e}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python script.py <URL>")
    else:
        url = sys.argv[1]
        check_service(url)
