from django.db import models
from django.core.validators import RegexValidator

class Coach(models.Model):
    first_name = models.CharField(max_length=50)
    last_name = models.CharField(max_length=50)
    phone = models.CharField(
        max_length=15,
        unique=True,
        validators=[
            RegexValidator(
                regex=r'^\+?[1-9]\d{9,14}$',
                message="Phone number must be in the format: '+919999999999' or '9999999999'. Must be between 10 to 15 digits."
            )
        ],
        help_text="Contact number of the coach (must be unique)"
    )
    email = models.EmailField(
        unique=True,
        help_text="Email address of the coach (must be unique)"
    )
    sport = models.ForeignKey(
        'sports.Sport',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='coaches',
        help_text="The sport this coach specializes in"
    )
    experience_years = models.PositiveIntegerField(
        default=0,
        help_text="Years of coaching experience"
    )
    is_active = models.BooleanField(
        default=True,
        help_text="Designates whether this coach profile is active"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'coaches'
        ordering = ['first_name', 'last_name']
        verbose_name = "Coach"
        verbose_name_plural = "Coaches"

    def __str__(self):
        return f"{self.first_name} {self.last_name} ({self.sport.name if self.sport else 'No Specialization'})"
