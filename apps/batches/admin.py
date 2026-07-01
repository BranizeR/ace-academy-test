from django.contrib import admin
from .models import Batch

@admin.register(Batch)
class BatchAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'sport', 'start_time', 'end_time', 'capacity', 'created_at')
    list_filter = ('sport', 'start_time')
    search_fields = ('name', 'sport__name')
    ordering = ('start_time', 'name')
