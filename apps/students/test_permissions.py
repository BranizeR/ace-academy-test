import datetime
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from django.contrib.auth.models import User
from rest_framework_simplejwt.tokens import RefreshToken

from apps.sports.models import Sport
from apps.batches.models import Batch
from apps.coaches.models import Coach
from apps.students.models import Student
from apps.attendance.models import Attendance

class RoleBasedAuthorizationTests(APITestCase):

    def setUp(self):
        # Create Sport
        self.sport = Sport.objects.create(name="Football", description="Football sport")

        # Create Admins, Coaches, Students users
        self.admin_user = User.objects.create_user(username='admin_user', email='admin@example.com', password='password123', is_staff=True)
        self.coach_user = User.objects.create_user(username='coach_user', email='coach@example.com', password='password123')
        self.student_user = User.objects.create_user(username='student_user', email='student@example.com', password='password123')

        # Create Coach Profile
        self.coach = Coach.objects.create(
            user=self.coach_user,
            first_name="John",
            last_name="Doe",
            phone="9876543210",
            email="coach@example.com",
            sport=self.sport,
            experience_years=5
        )

        # Create Batches
        self.batch_assigned = Batch.objects.create(
            name="Batch Assigned",
            sport=self.sport,
            coach=self.coach,
            start_time=datetime.time(6, 0),
            end_time=datetime.time(8, 0),
            capacity=10
        )
        self.batch_unassigned = Batch.objects.create(
            name="Batch Unassigned",
            sport=self.sport,
            start_time=datetime.time(8, 0),
            end_time=datetime.time(10, 0),
            capacity=10
        )

        # Create Student Profile
        self.student = Student.objects.create(
            user=self.student_user,
            first_name="Alice",
            last_name="Green",
            phone="9876543211",
            email="student@example.com",
            dob=datetime.date(2010, 5, 20),
            gender="F",
            batch=self.batch_assigned
        )

        # Create another student (unrelated)
        self.other_student = Student.objects.create(
            first_name="Bob",
            last_name="Smith",
            phone="9876543212",
            email="bob@example.com",
            dob=datetime.date(2008, 10, 12),
            gender="M",
            batch=self.batch_unassigned
        )

        # Create Attendance
        self.attendance_assigned = Attendance.objects.create(
            student=self.student,
            batch=self.batch_assigned,
            coach=self.coach,
            date=datetime.date.today(),
            status="P"
        )
        self.attendance_unassigned = Attendance.objects.create(
            student=self.other_student,
            batch=self.batch_unassigned,
            date=datetime.date.today(),
            status="P"
        )

    def authenticate_as(self, user):
        refresh = RefreshToken.for_user(user)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')

    def test_unauthenticated_requests_401(self):
        self.client.credentials()  # Clear auth
        response = self.client.get(reverse('sport-list'))
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_admin_full_access(self):
        self.authenticate_as(self.admin_user)
        
        # Admin can view all batches
        response = self.client.get(reverse('batch-list'))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['count'], 2)

        # Admin can view all students
        response = self.client.get(reverse('student-list'))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['count'], 2)

        # Admin can delete sport
        response = self.client.delete(reverse('sport-detail', kwargs={'pk': self.sport.id}))
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)

    def test_coach_restrictions(self):
        self.authenticate_as(self.coach_user)

        # Coach can only view assigned batches
        response = self.client.get(reverse('batch-list'))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['count'], 1)
        self.assertEqual(response.data['results'][0]['name'], "Batch Assigned")

        # Coach can only view students in assigned batches
        response = self.client.get(reverse('student-list'))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['count'], 1)
        self.assertEqual(response.data['results'][0]['first_name'], "Alice")

        # Coach cannot delete students
        response = self.client.delete(reverse('student-detail', kwargs={'pk': self.student.id}))
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

        # Coach cannot view other coaches' profiles
        response = self.client.get(reverse('coach-list'))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['count'], 1)  # Only views self

    def test_student_restrictions(self):
        self.authenticate_as(self.student_user)

        # Student gets 403 for sports
        response = self.client.get(reverse('sport-list'))
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

        # Student gets 403 for batches
        response = self.client.get(reverse('batch-list'))
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

        # Student can only view their own profile
        response = self.client.get(reverse('student-list'))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['count'], 1)
        self.assertEqual(response.data['results'][0]['first_name'], "Alice")

        # Student can only view their own attendance
        response = self.client.get(reverse('attendance-list'))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['count'], 1)
        self.assertEqual(response.data['results'][0]['student'], self.student.id)

        # Student cannot modify their own profile
        data = {"first_name": "NewName"}
        response = self.client.patch(reverse('student-detail', kwargs={'pk': self.student.id}), data, format='json')
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_student_registration_workflow(self):
        # 1. Register a student self-registration
        registration_data = {
            "first_name": "Test",
            "last_name": "Student",
            "email": "teststudent@example.com",
            "password": "password123",
            "phone": "9876543299",
            "dob": "2012-04-15",
            "gender": "M"
        }
        self.client.credentials()  # Anonymous
        response = self.client.post('/api/register/', registration_data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIn("Awaiting admin approval", response.data['detail'])

        # Verify Student model was created with status=Pending and is_active=False
        new_student = Student.objects.get(email="teststudent@example.com")
        self.assertEqual(new_student.status, "Pending")
        self.assertFalse(new_student.is_active)

        # 2. Try logging in with the pending account
        login_data = {
            "username": "teststudent@example.com",
            "password": "password123"
        }
        response = self.client.post('/api/token/', login_data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("Your account is awaiting approval.", response.data['detail'])

        # 3. Approve student as Admin
        self.authenticate_as(self.admin_user)
        approve_url = reverse('student-approve', kwargs={'pk': new_student.id})
        response = self.client.post(approve_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        # Verify status changes
        new_student.refresh_from_db()
        self.assertEqual(new_student.status, "Approved")
        self.assertTrue(new_student.is_active)

        # 4. Attempt login again after approval
        self.client.credentials()  # Clear auth
        response = self.client.post('/api/token/', login_data, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("access", response.data)
        self.assertIn("refresh", response.data)

