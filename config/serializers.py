from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework import serializers
from django.contrib.auth import get_user_model

class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    def validate(self, attrs):
        username = attrs.get(self.username_field)
        password = attrs.get('password')
        
        UserModel = get_user_model()
        try:
            # First check by email, then username
            user = UserModel.objects.get(email=username)
        except UserModel.DoesNotExist:
            try:
                user = UserModel.objects.get(username=username)
            except UserModel.DoesNotExist:
                raise serializers.ValidationError({"detail": "No active account found with the given credentials"})
                
        if not user.check_password(password):
            raise serializers.ValidationError({"detail": "No active account found with the given credentials"})
            
        if hasattr(user, 'student_profile') and user.student_profile:
            status = user.student_profile.status
            if status == 'Pending':
                raise serializers.ValidationError({"detail": "Your account is awaiting approval."})
            elif status == 'Rejected':
                raise serializers.ValidationError({"detail": "Your account has been rejected."})
                
        return super().validate(attrs)
