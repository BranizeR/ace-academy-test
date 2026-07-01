from django.contrib import admin
from .models import Attendance

@admin.register(Attendance)
class AttendanceAdmin(admin.ModelAdmin):
    list_display = ('id', 'student', 'batch', 'coach', 'date', 'status', 'created_at')
    list_filter = ('batch', 'date', 'status')
    search_fields = ('student__first_name', 'student__last_name', 'batch__name', 'coach__first_name', 'coach__last_name')
    ordering = ('-date', 'student__first_name')
