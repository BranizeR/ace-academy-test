from rest_framework import serializers
from django.utils import timezone
from .models import Student
from apps.batches.models import Batch
from apps.batches.serializers import BatchSerializer

class StudentSerializer(serializers.ModelSerializer):
    batch = serializers.PrimaryKeyRelatedField(
        queryset=Batch.objects.all(),
        required=False,
        allow_null=True,
        help_text="ID of the batch the student is enrolled in"
    )
    batch_detail = BatchSerializer(source='batch', read_only=True)
    full_name = serializers.SerializerMethodField()

    class Meta:
        model = Student
        fields = [
            'id', 'first_name', 'last_name', 'full_name', 
            'phone', 'email', 'dob', 'gender', 'batch', 
            'batch_detail', 'is_active', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']

    def get_full_name(self, obj):
        return f"{obj.first_name} {obj.last_name}"

    def validate_dob(self, value):
        if value > timezone.now().date():
            raise serializers.ValidationError("Date of birth cannot be in the future.")
        return value

    def validate(self, data):
        batch = data.get('batch')
        
        # Check updates and partial updates
        if 'batch' not in data and self.instance:
            batch = self.instance.batch
            
        if batch:
            students_in_batch = Student.objects.filter(batch=batch)
            if self.instance and self.instance.pk:
                students_in_batch = students_in_batch.exclude(pk=self.instance.pk)
                
            if students_in_batch.count() >= batch.capacity:
                raise serializers.ValidationError({
                    "batch": f"Cannot assign student to this batch because it has reached its maximum capacity of {batch.capacity}."
                })
        return data
