from rest_framework import viewsets, filters
from .models import Batch
from .serializers import BatchSerializer

class BatchViewSet(viewsets.ModelViewSet):
    """
    ViewSet for viewing and editing Batch instances.
    Provides GET list, POST create, GET retrieve, PUT update, DELETE destroy.
    Supports filtering by sport_id in query parameters (e.g. /api/batches/?sport_id=1).
    Supports searching by batch name and sport name.
    """
    queryset = Batch.objects.select_related('sport').all()
    serializer_class = BatchSerializer
    filter_backends = [filters.SearchFilter]
    search_fields = ['name', 'sport__name']

    def get_queryset(self):
        queryset = super().get_queryset()
        sport_id = self.request.query_params.get('sport_id')
        if sport_id:
            queryset = queryset.filter(sport_id=sport_id)
        return queryset
