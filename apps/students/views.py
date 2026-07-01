from rest_framework import viewsets, filters
from .models import Student
from .serializers import StudentSerializer

class StudentViewSet(viewsets.ModelViewSet):
    """
    ViewSet for viewing and editing Student instances.
    Provides standard REST CRUD actions.
    Supports filtering by batch_id, is_active, and sport_id.
    Supports searching by name, phone, email, and batch name.
    """
    queryset = Student.objects.select_related('batch__sport').all()
    serializer_class = StudentSerializer
    filter_backends = [filters.SearchFilter]
    search_fields = ['first_name', 'last_name', 'phone', 'email', 'batch__name']

    def get_queryset(self):
        queryset = super().get_queryset()
        batch_id = self.request.query_params.get('batch_id')
        is_active = self.request.query_params.get('is_active')
        sport_id = self.request.query_params.get('sport_id')

        if batch_id:
            queryset = queryset.filter(batch_id=batch_id)
        if is_active is not None:
            is_active_bool = is_active.lower() in ['true', '1', 'yes']
            queryset = queryset.filter(is_active=is_active_bool)
        if sport_id:
            queryset = queryset.filter(batch__sport_id=sport_id)

        return queryset
