from django.contrib.auth.models import User
from rest_framework import serializers
from .models import Coach
from apps.sports.models import Sport
from apps.sports.serializers import SportSerializer

class CoachSerializer(serializers.ModelSerializer):
    sport = serializers.PrimaryKeyRelatedField(
        queryset=Sport.objects.all(),
        required=False,
        allow_null=True,
        help_text="ID of the sport this coach specializes in"
    )
    sport_detail = SportSerializer(source='sport', read_only=True)
    full_name = serializers.SerializerMethodField()
    password = serializers.CharField(
        write_only=True,
        required=False,
        allow_blank=True,
        style={'input_type': 'password'},
        help_text="Password for the coach user account"
    )

    class Meta:
        model = Coach
        fields = [
            'id', 'first_name', 'last_name', 'full_name', 
            'phone', 'email', 'sport', 'sport_detail', 
            'experience_years', 'is_active', 'password', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']

    def get_full_name(self, obj):
        return f"{obj.first_name} {obj.last_name}"

    def create(self, validated_data):
        password = validated_data.pop('password', None)
        email = validated_data.get('email')
        phone = validated_data.get('phone')

        # Check duplicate email on User and Coach
        if User.objects.filter(email=email).exists() or Coach.objects.filter(email=email).exists():
            raise serializers.ValidationError({"email": "Coach with this email already exists."})

        # Check duplicate phone
        if Coach.objects.filter(phone=phone).exists():
            raise serializers.ValidationError({"phone": "Coach with this phone number already exists."})

        # Create Django User
        user = User.objects.create_user(
            username=email,
            email=email,
            password=password or "TempPassword123!",
            first_name=validated_data.get('first_name', ''),
            last_name=validated_data.get('last_name', '')
        )

        # Create Coach profile
        coach = Coach.objects.create(user=user, **validated_data)
        return coach

    def update(self, instance, validated_data):
        password = validated_data.pop('password', None)
        email = validated_data.get('email', instance.email)
        phone = validated_data.get('phone', instance.phone)

        # Check duplicate email
        if email != instance.email:
            if User.objects.filter(email=email).exclude(id=instance.user_id if instance.user else None).exists() or Coach.objects.filter(email=email).exclude(id=instance.id).exists():
                raise serializers.ValidationError({"email": "Coach with this email already exists."})

        # Check duplicate phone
        if phone != instance.phone:
            if Coach.objects.filter(phone=phone).exclude(id=instance.id).exists():
                raise serializers.ValidationError({"phone": "Coach with this phone number already exists."})

        # Update Coach profile fields
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()

        # Update User fields
        if instance.user:
            user = instance.user
            user.email = email
            user.username = email
            user.first_name = instance.first_name
            user.last_name = instance.last_name
            if password:
                user.set_password(password)
            user.save()

        return instance
