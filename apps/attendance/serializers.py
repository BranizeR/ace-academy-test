from rest_framework import serializers
from django.utils import timezone
from .models import Attendance
from apps.students.models import Student
from apps.students.serializers import StudentSerializer
from apps.batches.models import Batch
from apps.batches.serializers import BatchSerializer
from apps.coaches.models import Coach
from apps.coaches.serializers import CoachSerializer

class AttendanceSerializer(serializers.ModelSerializer):
    student = serializers.PrimaryKeyRelatedField(
        queryset=Student.objects.all(),
        help_text="ID of the student"
    )
    student_detail = StudentSerializer(source='student', read_only=True)
    
    batch = serializers.PrimaryKeyRelatedField(
        queryset=Batch.objects.all(),
        help_text="ID of the batch session"
    )
    batch_detail = BatchSerializer(source='batch', read_only=True)

    coach = serializers.PrimaryKeyRelatedField(
        queryset=Coach.objects.all(),
        required=False,
        allow_null=True,
        help_text="ID of the coach who marked this attendance"
    )
    coach_detail = CoachSerializer(source='coach', read_only=True)

    class Meta:
        model = Attendance
        fields = [
            'id', 'student', 'student_detail', 'batch', 'batch_detail', 
            'coach', 'coach_detail', 'date', 'status', 'remarks', 
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']

    def validate(self, data):
        student = data.get('student')
        batch = data.get('batch')
        date = data.get('date')

        # Handle updates and partial updates
        if not student and self.instance:
            student = self.instance.student
        if not batch and self.instance:
            batch = self.instance.batch
        if not date and self.instance:
            date = self.instance.date

        import datetime
        if date:
            if isinstance(date, datetime.datetime):
                date = date.date()
            if date > timezone.localdate():
                raise serializers.ValidationError({
                    "date": "Attendance date cannot be in the future."
                })

        if student and batch and student.batch != batch:
            raise serializers.ValidationError({
                "student": f"Student {student.first_name} {student.last_name} is not enrolled in the batch '{batch.name}'."
            })

        return data
