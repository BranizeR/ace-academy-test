from django.db import models
from django.core.exceptions import ValidationError
from django.utils import timezone

class Attendance(models.Model):
    STATUS_CHOICES = [
        ('P', 'Present'),
        ('A', 'Absent'),
        ('L', 'Late'),
        ('E', 'Excused'),
    ]

    student = models.ForeignKey(
        'students.Student',
        on_delete=models.CASCADE,
        related_name='attendances',
        help_text="The student whose attendance is being marked"
    )
    batch = models.ForeignKey(
        'batches.Batch',
        on_delete=models.CASCADE,
        related_name='attendances',
        help_text="The batch session"
    )
    coach = models.ForeignKey(
        'coaches.Coach',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='marked_attendances',
        help_text="The coach who marked this attendance record"
    )
    date = models.DateField(
        default=timezone.localdate,
        help_text="The date of the session"
    )
    status = models.CharField(
        max_length=1,
        choices=STATUS_CHOICES,
        help_text="Attendance status (Present, Absent, Late, Excused)"
    )
    remarks = models.TextField(
        blank=True,
        default='',
        help_text="Optional comments or notes (e.g. medical reason)"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'attendance'
        ordering = ['-date', 'student__first_name']
        constraints = [
            models.UniqueConstraint(
                fields=['student', 'batch', 'date'],
                name='unique_student_batch_date_attendance'
            )
        ]
        verbose_name = "Attendance"
        verbose_name_plural = "Attendance Records"

    def clean(self):
        super().clean()
        
        # 1. Date cannot be in the future
        import datetime
        if self.date:
            current_date = self.date
            if isinstance(current_date, datetime.datetime):
                current_date = current_date.date()
            if current_date > timezone.localdate():
                raise ValidationError({
                    'date': "Attendance date cannot be in the future."
                })
            
        # 2. Student must be enrolled in the specified batch
        if self.student and self.batch:
            if self.student.batch != self.batch:
                raise ValidationError({
                    'student': f"Student {self.student.first_name} {self.student.last_name} is not enrolled in the batch '{self.batch.name}'."
                })

    def save(self, *args, **kwargs):
        self.full_clean()
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.student.first_name} - {self.batch.name} on {self.date.strftime('%Y-%m-%d')}: {self.get_status_display()}"
