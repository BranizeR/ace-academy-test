from django.core.exceptions import ValidationError
from django.db import models
from rest_framework import viewsets, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import Student
from .serializers import StudentSerializer
from config.permissions import StudentPermission, IsAdmin, IsCoach

class StudentViewSet(viewsets.ModelViewSet):
    """
    ViewSet for viewing and editing Student instances.
    Provides standard REST CRUD actions.
    Supports filtering by batch_id, is_active, sport_id, and status.
    Supports searching by name, phone, email, and batch name.
    """
    permission_classes = [StudentPermission]
    queryset = Student.objects.select_related('batch__sport').all()
    serializer_class = StudentSerializer
    filter_backends = [filters.SearchFilter]
    search_fields = ['first_name', 'last_name', 'phone', 'email', 'batch__name']

    def get_queryset(self):
        user = self.request.user
        queryset = super().get_queryset()
        status_param = self.request.query_params.get('status')

        if hasattr(user, 'coach_profile') and user.coach_profile:
            if status_param == 'Pending':
                queryset = queryset.filter(status='Pending')
            elif status_param == 'Rejected':
                queryset = queryset.filter(status='Rejected')
            else:
                queryset = queryset.filter(batch__coach=user.coach_profile)
                if status_param:
                    queryset = queryset.filter(status=status_param)
        elif hasattr(user, 'student_profile') and user.student_profile:
            queryset = queryset.filter(id=user.student_profile.id)
        else:
            if status_param:
                queryset = queryset.filter(status=status_param)

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

    @action(detail=True, methods=['post'], permission_classes=[IsAdmin | IsCoach])
    def approve(self, request, pk=None):
        student = self.get_object()
        student.status = 'Approved'
        student.is_active = True
        try:
            student.save()
        except ValidationError as e:
            return Response(e.message_dict if hasattr(e, 'message_dict') else {'detail': str(e)}, status=400)
        return Response({'status': 'Student approved successfully.'})

    @action(detail=True, methods=['post'], permission_classes=[IsAdmin | IsCoach])
    def reject(self, request, pk=None):
        student = self.get_object()
        student.status = 'Rejected'
        student.is_active = False
        try:
            student.save(clean=False)
        except ValidationError as e:
            return Response(e.message_dict if hasattr(e, 'message_dict') else {'detail': str(e)}, status=400)
        return Response({'status': 'Student rejected successfully.'})

    def perform_destroy(self, instance):
        user = instance.user
        instance.delete()
        if user:
            user.delete()
