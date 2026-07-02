from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver
from apps.students.models import Student
from apps.coaches.models import Coach
from apps.batches.models import Batch
from apps.sports.consumers import broadcast_event

@receiver(post_save, sender=Student)
def student_saved(sender, instance, created, **kwargs):
    if created:
        broadcast_event('student_registered')
    else:
        if instance.status == 'Approved':
            broadcast_event('student_approved')
        elif instance.status == 'Rejected':
            broadcast_event('student_rejected')

@receiver(post_delete, sender=Student)
def student_deleted(sender, instance, **kwargs):
    broadcast_event('student_deleted')

@receiver(post_save, sender=Coach)
def coach_saved(sender, instance, created, **kwargs):
    if created:
        broadcast_event('coach_created')

@receiver(post_save, sender=Batch)
def batch_saved(sender, instance, created, **kwargs):
    if created:
        broadcast_event('batch_created')
