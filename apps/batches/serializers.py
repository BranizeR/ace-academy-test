from rest_framework import serializers
from .models import Batch
from apps.sports.models import Sport
from apps.sports.serializers import SportSerializer

class BatchSerializer(serializers.ModelSerializer):
    sport = serializers.PrimaryKeyRelatedField(
        queryset=Sport.objects.all(),
        help_text="The ID of the sport"
    )
    sport_detail = SportSerializer(source='sport', read_only=True)

    class Meta:
        model = Batch
        fields = [
            'id', 'name', 'sport', 'sport_detail', 
            'start_time', 'end_time', 'capacity', 
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']

    def validate(self, data):
        # We need to perform validation here as well (for DRF's standard validation response format)
        start_time = data.get('start_time')
        end_time = data.get('end_time')

        # Since PUT/PATCH requests might only send partial data, check if both exist in the data context
        # Or fall back to instance attributes for updates
        if not start_time and self.instance:
            start_time = self.instance.start_time
        if not end_time and self.instance:
            end_time = self.instance.end_time

        if start_time and end_time and start_time >= end_time:
            raise serializers.ValidationError({
                "end_time": "End time must be strictly after start time."
            })
        return data
