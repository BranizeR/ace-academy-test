import datetime
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from django.contrib.auth.models import User
from rest_framework_simplejwt.tokens import RefreshToken
from apps.sports.models import Sport
from apps.batches.models import Batch
from .models import Student

class StudentAPITests(APITestCase):

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
        self.student = Student.objects.create(
            first_name="Alice",
            last_name="Green",
            phone="9876543210",
            email="alice@example.com",
            dob=datetime.date(2010, 5, 20),
            gender="F",
            batch=self.batch,
            is_active=True
        )
        self.list_create_url = reverse('student-list')
        self.detail_url = reverse('student-detail', kwargs={'pk': self.student.id})

    def test_create_student_success(self):
        data = {
            "first_name": "Bob",
            "last_name": "Smith",
            "phone": "9876543211",
            "email": "bob@example.com",
            "dob": "2008-10-12",
            "gender": "M",
            "batch": self.batch.id,
            "is_active": True
        }
        response = self.client.post(self.list_create_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(Student.objects.count(), 2)

    def test_create_student_future_dob(self):
        tomorrow = (datetime.date.today() + datetime.timedelta(days=1)).strftime('%Y-%m-%d')
        data = {
            "first_name": "Invalid",
            "last_name": "Student",
            "phone": "9876543211",
            "email": "invalid@example.com",
            "dob": tomorrow,  # Future date of birth
            "gender": "O",
            "batch": self.batch.id
        }
        response = self.client.post(self.list_create_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("dob", response.data)

    def test_create_student_invalid_phone(self):
        data = {
            "first_name": "Invalid",
            "last_name": "Phone",
            "phone": "abc",  # Invalid phone format
            "email": "invalid.phone@example.com",
            "dob": "2005-01-01",
            "gender": "M",
            "batch": self.batch.id
        }
        response = self.client.post(self.list_create_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("phone", response.data)

    def test_create_student_duplicate_email(self):
        data = {
            "first_name": "Duplicate",
            "last_name": "Email",
            "phone": "9876543212",
            "email": "alice@example.com",  # Duplicate email
            "dob": "2005-01-01",
            "gender": "F",
            "batch": self.batch.id
        }
        response = self.client.post(self.list_create_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_get_students_list(self):
        response = self.client.get(self.list_create_url, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('results', response.data)

    def test_filter_students_by_batch(self):
        other_batch = Batch.objects.create(
            name="Evening B",
            sport=self.sport,
            start_time=datetime.time(18, 0),
            end_time=datetime.time(20, 0),
            capacity=15
        )
        other_student = Student.objects.create(
            first_name="Bob",
            last_name="Smith",
            phone="9876543213",
            email="bob@example.com",
            dob=datetime.date(2009, 1, 1),
            gender="M",
            batch=other_batch
        )
        response = self.client.get(f"{self.list_create_url}?batch_id={other_batch.id}", format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 1)
        self.assertEqual(response.data['results'][0]['first_name'], "Bob")

    def test_filter_students_by_sport(self):
        other_sport = Sport.objects.create(name="Tennis", description="Tennis sport")
        other_batch = Batch.objects.create(
            name="Tennis Morning",
            sport=other_sport,
            start_time=datetime.time(9, 0),
            end_time=datetime.time(10, 30),
            capacity=10
        )
        other_student = Student.objects.create(
            first_name="Rafa",
            last_name="Nadal",
            phone="9876543214",
            email="rafa.student@example.com",
            dob=datetime.date(2011, 2, 2),
            gender="M",
            batch=other_batch
        )
        response = self.client.get(f"{self.list_create_url}?sport_id={other_sport.id}", format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 1)
        self.assertEqual(response.data['results'][0]['first_name'], "Rafa")

    def test_update_student(self):
        data = {
            "first_name": "Alice",
            "last_name": "Updated",
            "phone": "9876543200",
            "email": "alice.updated@example.com",
            "dob": "2010-05-20",
            "gender": "F",
            "batch": self.batch.id
        }
        response = self.client.put(self.detail_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.student.refresh_from_db()
        self.assertEqual(self.student.last_name, "Updated")
        self.assertEqual(self.student.phone, "9876543200")

    def test_delete_student(self):
        response = self.client.delete(self.detail_url, format='json')
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertEqual(Student.objects.count(), 0)

    def test_search_students(self):
        # Search by first name
        response = self.client.get(f"{self.list_create_url}?search=Alice", format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 1)
        self.assertEqual(response.data['results'][0]['first_name'], "Alice")

        # Search by batch name
        response = self.client.get(f"{self.list_create_url}?search=Morning", format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 1)
        self.assertEqual(response.data['results'][0]['batch_detail']['name'], "Morning A")

    def test_create_student_exceeds_batch_capacity(self):
        small_batch = Batch.objects.create(
            name="Small Batch",
            sport=self.sport,
            start_time=datetime.time(10, 0),
            end_time=datetime.time(11, 0),
            capacity=1
        )
        # Move self.student to small_batch, filling it
        self.student.batch = small_batch
        self.student.save()

        # Try to enroll another student in small_batch
        data = {
            "first_name": "Bob",
            "last_name": "Smith",
            "phone": "9876543219",
            "email": "bob.limit@example.com",
            "dob": "2010-01-01",
            "gender": "M",
            "batch": small_batch.id
        }
        response = self.client.post(self.list_create_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("batch", response.data)


