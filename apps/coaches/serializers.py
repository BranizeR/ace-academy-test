from rest_framework import serializers
from .models import Coach
from apps.sports.models import Sport
from apps.sports.serializers import SportSerializer

class CoachSerializer(serializers.ModelSerializer):
    sport = serializers.PrimaryKeyRelatedField(
        queryset=Sport.objects.all(),
        required=False,
        allow_null=True,
        help_text="ID of the sport this coach specializes in"
    )
    sport_detail = SportSerializer(source='sport', read_only=True)
    full_name = serializers.SerializerMethodField()

    class Meta:
        model = Coach
        fields = [
            'id', 'first_name', 'last_name', 'full_name', 
            'phone', 'email', 'sport', 'sport_detail', 
            'experience_years', 'is_active', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']

    def get_full_name(self, obj):
        return f"{obj.first_name} {obj.last_name}"
