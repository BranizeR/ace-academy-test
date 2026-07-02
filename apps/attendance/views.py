from rest_framework import viewsets
from .models import Attendance
from .serializers import AttendanceSerializer
from config.permissions import AttendancePermission

class AttendanceViewSet(viewsets.ModelViewSet):
    """
    ViewSet for viewing and editing Attendance records.
    Provides standard REST CRUD actions.
    Supports filtering by student_id, batch_id, date, and status.
    """
    permission_classes = [AttendancePermission]
    queryset = Attendance.objects.select_related('student', 'batch__sport', 'coach').all()
    serializer_class = AttendanceSerializer

    def get_queryset(self):
        user = self.request.user
        queryset = super().get_queryset()

        if hasattr(user, 'coach_profile') and user.coach_profile:
            queryset = queryset.filter(batch__coach=user.coach_profile)
        elif hasattr(user, 'student_profile') and user.student_profile:
            queryset = queryset.filter(student=user.student_profile)

        student_id = self.request.query_params.get('student_id')
        batch_id = self.request.query_params.get('batch_id')
        date = self.request.query_params.get('date')
        status_param = self.request.query_params.get('status')

        if student_id:
            queryset = queryset.filter(student_id=student_id)
        if batch_id:
            queryset = queryset.filter(batch_id=batch_id)
        if date:
            queryset = queryset.filter(date=date)
        if status_param:
            queryset = queryset.filter(status=status_param.upper())

        return queryset

    def perform_create(self, serializer):
        user = self.request.user
        if hasattr(user, 'coach_profile') and user.coach_profile:
            serializer.save(coach=user.coach_profile)
        else:
            serializer.save()
