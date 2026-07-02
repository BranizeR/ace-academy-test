from rest_framework.permissions import BasePermission

class IsAdmin(BasePermission):
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        if request.user.is_superuser or request.user.is_staff:
            return True
        return not hasattr(request.user, 'coach_profile') and not hasattr(request.user, 'student_profile')

class IsCoach(BasePermission):
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        return hasattr(request.user, 'coach_profile') and request.user.coach_profile is not None

class IsStudent(BasePermission):
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        return hasattr(request.user, 'student_profile') and request.user.student_profile is not None

class SportPermission(BasePermission):
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        if request.user.is_superuser or request.user.is_staff or (not hasattr(request.user, 'coach_profile') and not hasattr(request.user, 'student_profile')):
            return True
        if hasattr(request.user, 'coach_profile'):
            return request.method in ['GET', 'HEAD', 'OPTIONS']
        return False

class BatchPermission(BasePermission):
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        if request.user.is_superuser or request.user.is_staff or (not hasattr(request.user, 'coach_profile') and not hasattr(request.user, 'student_profile')):
            return True
        if hasattr(request.user, 'coach_profile'):
            return request.method in ['GET', 'HEAD', 'OPTIONS']
        return False

class CoachPermission(BasePermission):
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        if request.user.is_superuser or request.user.is_staff or (not hasattr(request.user, 'coach_profile') and not hasattr(request.user, 'student_profile')):
            return True
        if hasattr(request.user, 'coach_profile'):
            return request.method in ['GET', 'HEAD', 'OPTIONS']
        return False

    def has_object_permission(self, request, view, obj):
        if request.user.is_superuser or request.user.is_staff or (not hasattr(request.user, 'coach_profile') and not hasattr(request.user, 'student_profile')):
            return True
        if hasattr(request.user, 'coach_profile'):
            return obj == request.user.coach_profile
        return False

class StudentPermission(BasePermission):
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        if request.user.is_superuser or request.user.is_staff or (not hasattr(request.user, 'coach_profile') and not hasattr(request.user, 'student_profile')):
            return True
        if hasattr(request.user, 'coach_profile'):
            return request.method in ['GET', 'HEAD', 'OPTIONS', 'PATCH'] or getattr(view, 'action', None) in ['approve', 'reject']
        if hasattr(request.user, 'student_profile'):
            return request.method in ['GET', 'HEAD', 'OPTIONS']
        return False

    def has_object_permission(self, request, view, obj):
        if request.user.is_superuser or request.user.is_staff or (not hasattr(request.user, 'coach_profile') and not hasattr(request.user, 'student_profile')):
            return True
        if hasattr(request.user, 'coach_profile'):
            if obj.status in ['Pending', 'Rejected']:
                if request.method == 'PATCH':
                    batch_id = request.data.get('batch')
                    if batch_id:
                        assigned_batches = request.user.coach_profile.batches.all()
                        return assigned_batches.filter(id=batch_id).exists()
                return True
            assigned_batches = request.user.coach_profile.batches.all()
            return obj.batch in assigned_batches
        if hasattr(request.user, 'student_profile'):
            return obj == request.user.student_profile
        return False

class AttendancePermission(BasePermission):
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        if request.user.is_superuser or request.user.is_staff or (not hasattr(request.user, 'coach_profile') and not hasattr(request.user, 'student_profile')):
            return True
        if hasattr(request.user, 'coach_profile'):
            return request.method in ['GET', 'HEAD', 'OPTIONS', 'POST', 'PUT', 'PATCH']
        if hasattr(request.user, 'student_profile'):
            return request.method in ['GET', 'HEAD', 'OPTIONS']
        return False

    def has_object_permission(self, request, view, obj):
        if request.user.is_superuser or request.user.is_staff or (not hasattr(request.user, 'coach_profile') and not hasattr(request.user, 'student_profile')):
            return True
        if hasattr(request.user, 'coach_profile'):
            assigned_batches = request.user.coach_profile.batches.all()
            return obj.batch in assigned_batches
        if hasattr(request.user, 'student_profile'):
            return obj.student == request.user.student_profile
        return False
