from django.contrib import admin
from .models import Student

@admin.register(Student)
class StudentAdmin(admin.ModelAdmin):
    list_display = ('id', 'first_name', 'last_name', 'phone', 'email', 'dob', 'gender', 'batch', 'is_active')
    list_filter = ('batch', 'gender', 'is_active')
    search_fields = ('first_name', 'last_name', 'phone', 'email', 'batch__name', 'batch__sport__name')
    ordering = ('first_name', 'last_name')
