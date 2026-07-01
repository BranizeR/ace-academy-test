from rest_framework import viewsets
from .models import Attendance
from .serializers import AttendanceSerializer

class AttendanceViewSet(viewsets.ModelViewSet):
    """
    ViewSet for viewing and editing Attendance records.
    Provides standard REST CRUD actions.
    Supports filtering by student_id, batch_id, date, and status.
    """
    queryset = Attendance.objects.select_related('student', 'batch__sport', 'coach').all()
    serializer_class = AttendanceSerializer

    def get_queryset(self):
        queryset = super().get_queryset()
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
