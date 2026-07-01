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

class SportViewSet(viewsets.ModelViewSet):
    """
    ViewSet for viewing and editing sport instances.
    Provides standard endpoints: LIST, CREATE, RETRIEVE, UPDATE, DELETE
    """
    queryset = Sport.objects.all()
    serializer_class = SportSerializer


class DashboardView(APIView):
    """
    APIView returning aggregated statistics for the academy dashboard.
    """
    def get(self, request, *args, **kwargs):
        today = timezone.localdate()
        
        data = {
            "total_students": Student.objects.count(),
            "total_coaches": Coach.objects.count(),
            "total_batches": Batch.objects.count(),
            "present_today": Attendance.objects.filter(date=today, status='P').count(),
            "absent_today": Attendance.objects.filter(date=today, status='A').count(),
        }
        return Response(data)

