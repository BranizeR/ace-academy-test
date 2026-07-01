import datetime
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from apps.sports.models import Sport
from apps.batches.models import Batch
from apps.coaches.models import Coach
from apps.students.models import Student
from .models import Attendance

class AttendanceAPITests(APITestCase):

    def setUp(self):
        # Setup foundation objects
        self.sport = Sport.objects.create(name="Football", description="Football sport")
        self.batch = Batch.objects.create(
            name="Morning A",
            sport=self.sport,
            start_time=datetime.time(6, 0),
            end_time=datetime.time(8, 0),
            capacity=20
        )
        self.coach = Coach.objects.create(
            first_name="John",
            last_name="Doe",
            phone="9876543210",
            email="john.doe@example.com",
            sport=self.sport
        )
        self.student = Student.objects.create(
            first_name="Alice",
            last_name="Green",
            phone="9876543211",
            email="alice@example.com",
            dob=datetime.date(2010, 5, 20),
            gender="F",
            batch=self.batch
        )
        self.attendance = Attendance.objects.create(
            student=self.student,
            batch=self.batch,
            coach=self.coach,
            date=datetime.date.today(),
            status="P"
        )
        self.list_create_url = reverse('attendance-list')
        self.detail_url = reverse('attendance-detail', kwargs={'pk': self.attendance.id})

    def test_create_attendance_success(self):
        # Delete existing attendance for clean state
        self.attendance.delete()
        data = {
            "student": self.student.id,
            "batch": self.batch.id,
            "coach": self.coach.id,
            "date": datetime.date.today().strftime('%Y-%m-%d'),
            "status": "A",
            "remarks": "Sick"
        }
        response = self.client.post(self.list_create_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(Attendance.objects.count(), 1)

    def test_create_attendance_future_date(self):
        tomorrow = datetime.date.today() + datetime.timedelta(days=1)
        data = {
            "student": self.student.id,
            "batch": self.batch.id,
            "coach": self.coach.id,
            "date": tomorrow.strftime('%Y-%m-%d'),
            "status": "P"
        }
        response = self.client.post(self.list_create_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("date", response.data)

    def test_create_attendance_student_wrong_batch(self):
        # Create other batch not assigned to student
        other_batch = Batch.objects.create(
            name="Evening B",
            sport=self.sport,
            start_time=datetime.time(18, 0),
            end_time=datetime.time(20, 0),
            capacity=15
        )
        data = {
            "student": self.student.id,
            "batch": other_batch.id,  # Student is not in this batch
            "coach": self.coach.id,
            "date": datetime.date.today().strftime('%Y-%m-%d'),
            "status": "P"
        }
        response = self.client.post(self.list_create_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("student", response.data)

    def test_create_attendance_duplicate(self):
        # Attendance already exists in setUp, attempting to create duplicate
        data = {
            "student": self.student.id,
            "batch": self.batch.id,
            "coach": self.coach.id,
            "date": datetime.date.today().strftime('%Y-%m-%d'),
            "status": "A"
        }
        response = self.client.post(self.list_create_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_get_attendance_list(self):
        response = self.client.get(self.list_create_url, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('results', response.data)

    def test_filter_attendance_by_student(self):
        response = self.client.get(f"{self.list_create_url}?student_id={self.student.id}", format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 1)

    def test_filter_attendance_by_batch(self):
        response = self.client.get(f"{self.list_create_url}?batch_id={self.batch.id}", format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 1)

    def test_filter_attendance_by_date(self):
        today_str = datetime.date.today().strftime('%Y-%m-%d')
        response = self.client.get(f"{self.list_create_url}?date={today_str}", format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 1)

    def test_update_attendance(self):
        data = {
            "student": self.student.id,
            "batch": self.batch.id,
            "status": "L",  # Change status to Late
            "remarks": "Bus delayed"
        }
        response = self.client.put(self.detail_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.attendance.refresh_from_db()
        self.assertEqual(self.attendance.status, "L")
        self.assertEqual(self.attendance.remarks, "Bus delayed")

    def test_delete_attendance(self):
        response = self.client.delete(self.detail_url, format='json')
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertEqual(Attendance.objects.count(), 0)
