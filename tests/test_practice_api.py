import requests

# Base URL for API. Test locally on EC2 - "http://localhost:8000/api"
BASE_URL = "https://api.linguallearn.org/api"

# Test practice activity creation
def test_create_practice_activity():
    """Test creating a practice activity with correct schema fields"""
    response = requests.post(f"{BASE_URL}/practice", json={
        "user_id": 1,
        "language_code": "es-do",
        "activity_type": "journal",
        "skill_focus": "writing",
        "title": "Daily Practice",
        "content": "Practiced vocabulary",
        "notes": "Good session",
        "duration_minutes": 30
    })

    assert response.status_code == 200  # API returns 200, not 201
    data = response.json()
    assert "activity_id" in data
    assert data["user_id"] == 1
    assert data["language_code"] == "es-do"
    print("✅ Practice activity creation test passed")

# Test retrieving practice activities
def test_get_user_activities():
    """Test retrieving user practice activities"""
    response = requests.get(f"{BASE_URL}/practice/user/1")

    assert response.status_code == 200
    data = response.json()
    assert "activities" in data
    assert data["user_id"] == 1
    print("✅ Get user activities test passed")

# Test practice statistics
def test_practice_stats():
    """Test practice statistics aggregation"""
    response = requests.get(f"{BASE_URL}/practice/stats/1")

    assert response.status_code == 200
    data = response.json()
    assert "by_activity_type" in data
    print("✅ Practice stats test passed")

if __name__ == "__main__":
    test_create_practice_activity()
    test_get_user_activities()
    test_practice_stats()
    print("\n✅ All practice API tests passed!")
