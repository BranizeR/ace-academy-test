from django.contrib import admin
from .models import Coach

@admin.register(Coach)
class CoachAdmin(admin.ModelAdmin):
    list_display = ('id', 'first_name', 'last_name', 'phone', 'email', 'sport', 'experience_years', 'is_active')
    list_filter = ('sport', 'is_active', 'experience_years')
    search_fields = ('first_name', 'last_name', 'phone', 'email', 'sport__name')
    ordering = ('first_name', 'last_name')
