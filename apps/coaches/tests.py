from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from django.contrib.auth.models import User
from rest_framework_simplejwt.tokens import RefreshToken
from apps.sports.models import Sport
from .models import Coach

class CoachAPITests(APITestCase):

    def setUp(self):
        self.user = User.objects.create_user(username='testuser', email='test@example.com', password='password123')
        refresh = RefreshToken.for_user(self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')
        self.sport = Sport.objects.create(name="Football", description="Football sport")
        self.coach = Coach.objects.create(
            first_name="John",
            last_name="Doe",
            phone="9876543210",
            email="john.doe@example.com",
            sport=self.sport,
            experience_years=5,
            is_active=True
        )
        self.list_create_url = reverse('coach-list')
        self.detail_url = reverse('coach-detail', kwargs={'pk': self.coach.id})

    def test_create_coach_success(self):
        data = {
            "first_name": "Jane",
            "last_name": "Smith",
            "phone": "9876543211",
            "email": "jane.smith@example.com",
            "sport": self.sport.id,
            "experience_years": 3,
            "is_active": True
        }
        response = self.client.post(self.list_create_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(Coach.objects.count(), 2)

    def test_create_coach_invalid_phone(self):
        data = {
            "first_name": "Jane",
            "last_name": "Smith",
            "phone": "123",  # Too short, invalid format
            "email": "jane.smith@example.com",
            "sport": self.sport.id
        }
        response = self.client.post(self.list_create_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("phone", response.data)

    def test_create_coach_invalid_email(self):
        data = {
            "first_name": "Jane",
            "last_name": "Smith",
            "phone": "9876543212",
            "email": "not-an-email",  # Invalid email format
            "sport": self.sport.id
        }
        response = self.client.post(self.list_create_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("email", response.data)

    def test_create_coach_duplicate_email(self):
        data = {
            "first_name": "Jane",
            "last_name": "Smith",
            "phone": "9876543212",
            "email": "john.doe@example.com",  # Duplicate email
            "sport": self.sport.id
        }
        response = self.client.post(self.list_create_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_create_coach_duplicate_phone(self):
        data = {
            "first_name": "Jane",
            "last_name": "Smith",
            "phone": "9876543210",  # Duplicate phone
            "email": "jane.smith@example.com",
            "sport": self.sport.id
        }
        response = self.client.post(self.list_create_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_get_coaches_list(self):
        response = self.client.get(self.list_create_url, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('results', response.data)

    def test_filter_coaches_by_sport(self):
        other_sport = Sport.objects.create(name="Tennis", description="Tennis sport")
        other_coach = Coach.objects.create(
            first_name="Rafa",
            last_name="Nadal",
            phone="9876543213",
            email="rafa@example.com",
            sport=other_sport,
            experience_years=15,
            is_active=True
        )
        response = self.client.get(f"{self.list_create_url}?sport_id={other_sport.id}", format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 1)
        self.assertEqual(response.data['results'][0]['first_name'], "Rafa")

    def test_filter_coaches_by_active_status(self):
        inactive_coach = Coach.objects.create(
            first_name="Retired",
            last_name="Coach",
            phone="9876543214",
            email="retired@example.com",
            sport=self.sport,
            experience_years=20,
            is_active=False  # Inactive
        )
        response = self.client.get(f"{self.list_create_url}?is_active=false", format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 1)
        self.assertEqual(response.data['results'][0]['first_name'], "Retired")

    def test_update_coach(self):
        data = {
            "first_name": "John",
            "last_name": "Updated",
            "phone": "9876543210",
            "email": "john.doe@example.com",
            "experience_years": 6
        }
        response = self.client.put(self.detail_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.coach.refresh_from_db()
        self.assertEqual(self.coach.last_name, "Updated")
        self.assertEqual(self.coach.experience_years, 6)

    def test_delete_coach(self):
        response = self.client.delete(self.detail_url, format='json')
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertEqual(Coach.objects.count(), 0)

    def test_search_coaches(self):
        # Search by first name
        response = self.client.get(f"{self.list_create_url}?search=John", format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 1)
        self.assertEqual(response.data['results'][0]['first_name'], "John")

        # Search by sport name
        response = self.client.get(f"{self.list_create_url}?search=Football", format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 1)
        self.assertEqual(response.data['results'][0]['sport_detail']['name'], "Football")

    def test_create_coach_with_user_and_login_success(self):
        data = {
            "first_name": "Loginable",
            "last_name": "Coach",
            "phone": "9998887776",
            "email": "loginable.coach@example.com",
            "sport": self.sport.id,
            "experience_years": 4,
            "is_active": True,
            "password": "CoachPassword123!"
        }
        # Create via API
        response = self.client.post(self.list_create_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        
        # Verify Django user exists
        user_exists = User.objects.filter(email="loginable.coach@example.com").exists()
        self.assertTrue(user_exists)
        
        # Verify login using JWT endpoint
        login_url = reverse('token_obtain_pair')
        login_data = {
            "username": "loginable.coach@example.com",
            "password": "CoachPassword123!"
        }
        # Reset auth credentials to test direct login
        self.client.credentials()
        login_response = self.client.post(login_url, login_data, format='json')
        self.assertEqual(login_response.status_code, status.HTTP_200_OK)
        self.assertIn("access", login_response.data)

    def test_duplicate_email_on_creation_returns_bad_request(self):
        # We already have self.coach with email john.doe@example.com
        data = {
            "first_name": "Duplicate",
            "last_name": "Email",
            "phone": "9998887777",
            "email": "john.doe@example.com",
            "sport": self.sport.id,
            "password": "SomePassword123!"
        }
        response = self.client.post(self.list_create_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("email", response.data)

    def test_duplicate_phone_on_creation_returns_bad_request(self):
        # We already have self.coach with phone 9876543210
        data = {
            "first_name": "Duplicate",
            "last_name": "Phone",
            "phone": "9876543210",
            "email": "unique.coach@example.com",
            "sport": self.sport.id,
            "password": "SomePassword123!"
        }
        response = self.client.post(self.list_create_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("phone", response.data)

    def test_delete_coach_cascades_django_user_deletion(self):
        # First, create a coach with user
        data = {
            "first_name": "Deletable",
            "last_name": "Coach",
            "phone": "9990001112",
            "email": "deletable@example.com",
            "sport": self.sport.id,
            "password": "CoachPassword123!"
        }
        response = self.client.post(self.list_create_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        coach_id = response.data['id']
        
        # Verify user exists
        self.assertTrue(User.objects.filter(email="deletable@example.com").exists())
        
        # Delete the coach
        delete_url = reverse('coach-detail', kwargs={'pk': coach_id})
        # Set authorization header back
        refresh = RefreshToken.for_user(self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')
        delete_response = self.client.delete(delete_url, format='json')
        self.assertEqual(delete_response.status_code, status.HTTP_204_NO_CONTENT)
        
        # Verify coach is deleted
        self.assertFalse(Coach.objects.filter(id=coach_id).exists())
        # Verify related user is deleted
        self.assertFalse(User.objects.filter(email="deletable@example.com").exists())

