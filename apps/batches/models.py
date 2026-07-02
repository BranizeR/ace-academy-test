from django.db import models
from django.core.validators import MinValueValidator
from django.core.exceptions import ValidationError

class Batch(models.Model):
    coach = models.ForeignKey(
        'coaches.Coach',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='batches',
        help_text="The coach assigned to this batch"
    )
    name = models.CharField(
        max_length=100,
        help_text="Name of the batch (e.g., Morning Pro, Evening Beginners)"
    )
    sport = models.ForeignKey(
        'sports.Sport',
        on_delete=models.CASCADE,
        related_name='batches',
        help_text="The sport associated with this batch"
    )
    start_time = models.TimeField(help_text="Start time of the training session")
    end_time = models.TimeField(help_text="End time of the training session")
    capacity = models.PositiveIntegerField(
        validators=[MinValueValidator(1, message="Batch capacity must be at least 1.")],
        help_text="Maximum capacity of students in this batch"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'batches'
        ordering = ['start_time', 'name']
        verbose_name = "Batch"
        verbose_name_plural = "Batches"

    def clean(self):
        super().clean()
        # Verify that end_time is after start_time
        if self.start_time and self.end_time:
            if self.start_time >= self.end_time:
                raise ValidationError({
                    'end_time': "End time must be strictly after start time."
                })

    def save(self, *args, **kwargs):
        # Trigger full clean to enforce validation on ORM operations
        self.full_clean()
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.name} - {self.sport.name} ({self.start_time.strftime('%H:%M')} - {self.end_time.strftime('%H:%M')})"
