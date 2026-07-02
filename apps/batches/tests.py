import datetime
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from django.contrib.auth.models import User
from rest_framework_simplejwt.tokens import RefreshToken
from apps.sports.models import Sport
from .models import Batch

class BatchAPITests(APITestCase):

    def setUp(self):
        self.user = User.objects.create_user(username='testuser', email='test@example.com', password='password123')
        refresh = RefreshToken.for_user(self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')
        self.sport = Sport.objects.create(name="Football", description="Football sport")
        self.batch = Batch.objects.create(
            name="Morning A",
            sport=self.sport,
            start_time=datetime.time(6, 0),
            end_time=datetime.time(8, 0),
            capacity=20
        )
        self.list_create_url = reverse('batch-list')
        self.detail_url = reverse('batch-detail', kwargs={'pk': self.batch.id})

    def test_create_batch_success(self):
        data = {
            "name": "Evening B",
            "sport": self.sport.id,
            "start_time": "18:00:00",
            "end_time": "20:00:00",
            "capacity": 15
        }
        response = self.client.post(self.list_create_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(Batch.objects.count(), 2)

    def test_create_batch_invalid_times_end_before_start(self):
        data = {
            "name": "Invalid Batch",
            "sport": self.sport.id,
            "start_time": "10:00:00",
            "end_time": "09:00:00",  # End time before start time
            "capacity": 10
        }
        response = self.client.post(self.list_create_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("end_time", response.data)

    def test_create_batch_invalid_times_equal(self):
        data = {
            "name": "Invalid Batch",
            "sport": self.sport.id,
            "start_time": "10:00:00",
            "end_time": "10:00:00",  # End time equal to start time
            "capacity": 10
        }
        response = self.client.post(self.list_create_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("end_time", response.data)

    def test_create_batch_invalid_capacity(self):
        data = {
            "name": "Zero Capacity",
            "sport": self.sport.id,
            "start_time": "08:00:00",
            "end_time": "10:00:00",
            "capacity": 0  # Invalid capacity
        }
        response = self.client.post(self.list_create_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("capacity", response.data)

    def test_get_batches_list(self):
        response = self.client.get(self.list_create_url, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('results', response.data)

    def test_filter_batches_by_sport(self):
        # Create another sport and batch
        other_sport = Sport.objects.create(name="Tennis", description="Tennis sport")
        other_batch = Batch.objects.create(
            name="Tennis Morning",
            sport=other_sport,
            start_time=datetime.time(9, 0),
            end_time=datetime.time(10, 30),
            capacity=10
        )
        
        # Test filtering
        response = self.client.get(f"{self.list_create_url}?sport_id={other_sport.id}", format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 1)
        self.assertEqual(response.data['results'][0]['name'], "Tennis Morning")

    def test_update_batch(self):
        data = {
            "name": "Morning Updated",
            "sport": self.sport.id,
            "start_time": "06:30:00",
            "end_time": "08:30:00",
            "capacity": 25
        }
        response = self.client.put(self.detail_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.batch.refresh_from_db()
        self.assertEqual(self.batch.name, "Morning Updated")
        self.assertEqual(self.batch.capacity, 25)

    def test_delete_batch(self):
        response = self.client.delete(self.detail_url, format='json')
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertEqual(Batch.objects.count(), 0)

    def test_search_batches(self):
        # Search by batch name
        response = self.client.get(f"{self.list_create_url}?search=Morning", format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 1)
        self.assertEqual(response.data['results'][0]['name'], "Morning A")

        # Search by sport name
        response = self.client.get(f"{self.list_create_url}?search=Football", format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 1)
        self.assertEqual(response.data['results'][0]['sport_detail']['name'], "Football")

