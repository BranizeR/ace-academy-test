from rest_framework import viewsets, filters
from .models import Coach
from .serializers import CoachSerializer

class CoachViewSet(viewsets.ModelViewSet):
    """
    ViewSet for viewing and editing Coach instances.
    Provides standard REST CRUD actions.
    Supports filtering by sport_id (e.g. /api/coaches/?sport_id=1) and is_active (e.g. /api/coaches/?is_active=true).
    Supports searching by name, phone, email, and sport name.
    """
    queryset = Coach.objects.select_related('sport').all()
    serializer_class = CoachSerializer
    filter_backends = [filters.SearchFilter]
    search_fields = ['first_name', 'last_name', 'phone', 'email', 'sport__name']

    def get_queryset(self):
        queryset = super().get_queryset()
        sport_id = self.request.query_params.get('sport_id')
        is_active = self.request.query_params.get('is_active')

        if sport_id:
            queryset = queryset.filter(sport_id=sport_id)
        if is_active is not None:
            # Convert string query param to boolean
            is_active_bool = is_active.lower() in ['true', '1', 'yes']
            queryset = queryset.filter(is_active=is_active_bool)

        return queryset
