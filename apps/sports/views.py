from rest_framework import viewsets
from rest_framework.views import APIView
from rest_framework.response import Response
from django.utils import timezone

from .models import Sport
from .serializers import SportSerializer
from apps.students.models import Student
from apps.coaches.models import Coach
from apps.batches.models import Batch
from apps.attendance.models import Attendance

from config.permissions import SportPermission

class SportViewSet(viewsets.ModelViewSet):
    """
    ViewSet for viewing and editing sport instances.
    Provides standard endpoints: LIST, CREATE, RETRIEVE, UPDATE, DELETE
    """
    permission_classes = [SportPermission]
    queryset = Sport.objects.all()
    serializer_class = SportSerializer


class DashboardView(APIView):
    """
    APIView returning aggregated statistics for the academy dashboard.
    """
    def get(self, request, *args, **kwargs):
        user = request.user
        if hasattr(user, 'student_profile') and user.student_profile:
            return Response({"detail": "You do not have permission to view dashboard statistics."}, status=403)
            
        today = timezone.localdate()
        
        if not (user.is_superuser or user.is_staff) and hasattr(user, 'coach_profile') and user.coach_profile:
            coach = user.coach_profile
            batches = coach.batches.all()
            students = Student.objects.filter(batch__in=batches)
            present = Attendance.objects.filter(batch__in=batches, date=today, status='P').count()
            absent = Attendance.objects.filter(batch__in=batches, date=today, status='A').count()
            data = {
                "total_students": students.count(),
                "total_coaches": 1,
                "total_batches": batches.count(),
                "present_today": present,
                "absent_today": absent,
            }
        else:
            data = {
                "total_students": Student.objects.count(),
                "total_coaches": Coach.objects.count(),
                "total_batches": Batch.objects.count(),
                "present_today": Attendance.objects.filter(date=today, status='P').count(),
                "absent_today": Attendance.objects.filter(date=today, status='A').count(),
            }
        return Response(data)


class UserProfileView(APIView):
    """
    APIView returning details about the current logged-in user and their role.
    """
    def get(self, request, *args, **kwargs):
        user = request.user
        role = 'admin'
        profile_id = None
        first_name = user.first_name
        last_name = user.last_name
        
        if not (user.is_superuser or user.is_staff) and hasattr(user, 'coach_profile') and user.coach_profile:
            role = 'coach'
            profile_id = user.coach_profile.id
            first_name = user.coach_profile.first_name
            last_name = user.coach_profile.last_name
        elif not (user.is_superuser or user.is_staff) and hasattr(user, 'student_profile') and user.student_profile:
            role = 'student'
            profile_id = user.student_profile.id
            first_name = user.student_profile.first_name
            last_name = user.student_profile.last_name
            
        return Response({
            'id': user.id,
            'username': user.username,
            'email': user.email,
            'role': role,
            'profile_id': profile_id,
            'first_name': first_name,
            'last_name': last_name,
        })

