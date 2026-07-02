from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from django.contrib.auth.models import User
from rest_framework_simplejwt.tokens import RefreshToken
from .models import Sport

class SportAPITests(APITestCase):

    def setUp(self):
        self.user = User.objects.create_user(username='testuser', email='test@example.com', password='password123')
        refresh = RefreshToken.for_user(self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')
        self.sport = Sport.objects.create(
            name="Football",
            description="A game played with a round ball and two teams."
        )
        self.list_create_url = reverse('sport-list')
        self.detail_url = reverse('sport-detail', kwargs={'pk': self.sport.id})

    def test_create_sport_success(self):
        data = {
            "name": "Cricket",
            "description": "Bat and ball game."
        }
        response = self.client.post(self.list_create_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(Sport.objects.count(), 2)
        self.assertEqual(Sport.objects.get(id=response.data['id']).name, "Cricket")

    def test_create_sport_duplicate_name(self):
        data = {
            "name": "Football",  # Duplicate
            "description": "Another football entry."
        }
        response = self.client.post(self.list_create_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_create_sport_invalid_name_too_short(self):
        data = {
            "name": "A",  # Less than 2 chars
            "description": "Invalid short name."
        }
        response = self.client.post(self.list_create_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("name", response.data)

    def test_create_sport_invalid_name_contains_numbers(self):
        data = {
            "name": "Tennis 123",  # Contains numbers
            "description": "Invalid format."
        }
        response = self.client.post(self.list_create_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("name", response.data)

    def test_get_sports_list(self):
        response = self.client.get(self.list_create_url, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        # We configured PageNumberPagination with default PAGE_SIZE 10, so results are in 'results'
        self.assertIn('results', response.data)
        self.assertEqual(len(response.data['results']), 1)

    def test_retrieve_sport(self):
        response = self.client.get(self.detail_url, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['name'], self.sport.name)

    def test_update_sport(self):
        data = {
            "name": "American Football",
            "description": "Updated description."
        }
        response = self.client.put(self.detail_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.sport.refresh_from_db()
        self.assertEqual(self.sport.name, "American Football")

    def test_delete_sport(self):
        response = self.client.delete(self.detail_url, format='json')
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertEqual(Sport.objects.count(), 0)


class DashboardAPITests(APITestCase):

    def test_dashboard_statistics(self):
        from django.contrib.auth.models import User
        from rest_framework_simplejwt.tokens import RefreshToken
        user = User.objects.create_user(username='dashboarduser', email='db@example.com', password='password123')
        refresh = RefreshToken.for_user(user)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')

        import datetime
        from apps.coaches.models import Coach
        from apps.batches.models import Batch
        from apps.students.models import Student
        from apps.attendance.models import Attendance

        # Create Sport
        sport = Sport.objects.create(name="Football", description="Football sport")
        
        # Create Coach
        Coach.objects.create(
            first_name="John",
            last_name="Doe",
            phone="9876543210",
            email="john@example.com",
            sport=sport
        )

        # Create Batch
        batch = Batch.objects.create(
            name="Morning A",
            sport=sport,
            start_time=datetime.time(6, 0),
            end_time=datetime.time(8, 0),
            capacity=10
        )

        # Create 2 Students
        student1 = Student.objects.create(
            first_name="Alice",
            last_name="Green",
            phone="9876543211",
            email="alice@example.com",
            dob=datetime.date(2010, 5, 20),
            gender="F",
            batch=batch
        )
        student2 = Student.objects.create(
            first_name="Bob",
            last_name="Smith",
            phone="9876543212",
            email="bob@example.com",
            dob=datetime.date(2008, 10, 12),
            gender="M",
            batch=batch
        )

        # Mark student1 Present, student2 Absent today
        Attendance.objects.create(
            student=student1,
            batch=batch,
            date=datetime.date.today(),
            status="P"
        )
        Attendance.objects.create(
            student=student2,
            batch=batch,
            date=datetime.date.today(),
            status="A"
        )

        # Query dashboard
        dashboard_url = reverse('dashboard')
        response = self.client.get(dashboard_url, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['total_students'], 2)
        self.assertEqual(response.data['total_coaches'], 1)
        self.assertEqual(response.data['total_batches'], 1)
        self.assertEqual(response.data['present_today'], 1)
        self.assertEqual(response.data['absent_today'], 1)

