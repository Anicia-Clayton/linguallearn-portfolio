import requests

# Base URL for API. Test locally on EC2 - "http://localhost:8000/api"
BASE_URL = "https://api.linguallearn.org/api"

# Test ASL vocabulary creation
def test_create_asl_vocabulary():
    """Test creating ASL vocabulary with correct schema"""
    response = requests.post(f"{BASE_URL}/asl/vocabulary", json={
        "user_id": 1,
        "sign_name": "thank_you",
        "video_url": "https://d32ck5h7bhebbh.cloudfront.net/asl/pocketsign/greetings/thank_you.mp4",
        "category": "greetings",
        "difficulty_level": 1
    })

    assert response.status_code == 200  # API returns 200, not 201
    data = response.json()
    assert "asl_card_id" in data
    assert data["user_id"] == 1
    print("✅ ASL vocabulary creation test passed")

# Test retrieving ASL vocabulary
def test_get_asl_vocabulary():
    """Test retrieving ASL vocabulary for user"""
    response = requests.get(f"{BASE_URL}/asl/vocabulary/user/1")

    assert response.status_code == 200
    data = response.json()
    assert "vocabulary" in data
    print("✅ Get ASL vocabulary test passed")

# Test practice recording
def test_record_practice():
    """Test incrementing practice count"""
    response = requests.put(f"{BASE_URL}/asl/vocabulary/1/practice")

    assert response.status_code == 200
    data = response.json()
    assert "times_practiced" in data
    print("✅ Record practice test passed")

if __name__ == "__main__":
    test_create_asl_vocabulary()
    test_get_asl_vocabulary()
    test_record_practice()
    print("\n✅ All ASL API tests passed!")
