from django.db import models
from django.core.validators import RegexValidator
from django.core.exceptions import ValidationError
from django.utils import timezone
from django.contrib.auth.models import User

class Student(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, null=True, blank=True, related_name='student_profile')
    GENDER_CHOICES = [
        ('M', 'Male'),
        ('F', 'Female'),
        ('O', 'Other'),
    ]

    first_name = models.CharField(max_length=50)
    last_name = models.CharField(max_length=50)
    phone = models.CharField(
        max_length=15,
        unique=True,
        validators=[
            RegexValidator(
                regex=r'^[1-9]\d{9}$',
                message="Phone number must be exactly 10 digits (first digit cannot be 0)."
            )
        ],
        help_text="Contact number of the student (must be unique)"
    )
    email = models.EmailField(
        unique=True,
        help_text="Email address of the student (must be unique)"
    )
    dob = models.DateField(
        verbose_name="Date of Birth",
        help_text="Student's date of birth"
    )
    gender = models.CharField(
        max_length=1,
        choices=GENDER_CHOICES,
        help_text="Gender classification"
    )
    batch = models.ForeignKey(
        'batches.Batch',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='students',
        help_text="The training batch the student is enrolled in"
    )
    status = models.CharField(
        max_length=10,
        choices=[('Pending', 'Pending'), ('Approved', 'Approved'), ('Rejected', 'Rejected')],
        default='Pending',
        help_text="Registration status of the student"
    )
    is_active = models.BooleanField(
        default=False,
        help_text="Designates whether this student is currently active"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'students'
        ordering = ['first_name', 'last_name']
        verbose_name = "Student"
        verbose_name_plural = "Students"

    def clean(self):
        super().clean()
        if self.dob and self.dob > timezone.now().date():
            raise ValidationError({
                'dob': "Date of birth cannot be in the future."
            })
        
        if self.batch:
            students_in_batch = Student.objects.filter(batch=self.batch)
            if self.pk:
                students_in_batch = students_in_batch.exclude(pk=self.pk)
            
            if students_in_batch.count() >= self.batch.capacity:
                raise ValidationError({
                    'batch': f"Cannot assign student to this batch because it has reached its maximum capacity of {self.batch.capacity}."
                })

    def save(self, *args, **kwargs):
        if kwargs.pop('clean', True):
            self.full_clean()
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.first_name} {self.last_name} ({self.batch.name if self.batch else 'Unassigned'})"

from django.db.models.signals import post_delete
from django.dispatch import receiver

@receiver(post_delete, sender=Student)
def delete_related_user(sender, instance, **kwargs):
    if instance.user:
        instance.user.delete()
