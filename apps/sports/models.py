from django.db import models
from django.core.validators import MinLengthValidator, RegexValidator

class Sport(models.Model):
    name = models.CharField(
        max_length=100,
        unique=True,
        validators=[
            MinLengthValidator(2, message="Sport name must be at least 2 characters long."),
            RegexValidator(
                regex=r'^[A-Za-z\s]+$',
                message="Sport name must contain only letters and spaces."
            )
        ],
        help_text="Unique name of the sport (e.g., Football, Tennis)"
    )
    description = models.TextField(
        blank=True,
        default='',
        help_text="Optional description or details about the sport"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'sports'
        ordering = ['name']
        verbose_name = "Sport"
        verbose_name_plural = "Sports"

    def __str__(self):
        return self.name
