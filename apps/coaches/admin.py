from django import forms
from django.contrib import admin
from django.contrib.auth.models import User
from .models import Coach

class CoachAdminForm(forms.ModelForm):
    password = forms.CharField(
        widget=forms.PasswordInput(),
        required=False,
        help_text="Password for the coach user account. Required on creation, optional on edit (leave blank to keep current)."
    )

    class Meta:
        model = Coach
        fields = '__all__'
        exclude = ['user']

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        if self.instance and self.instance.pk:
            self.fields['password'].required = False
            self.fields['password'].label = "New Password (optional)"
        else:
            self.fields['password'].required = True

    def clean(self):
        cleaned_data = super().clean()
        email = cleaned_data.get('email')
        phone = cleaned_data.get('phone')
        
        # Check duplicate email on User and Coach (excluding self if editing)
        exclude_coach_id = self.instance.pk if self.instance else None
        exclude_user_id = self.instance.user.pk if self.instance and self.instance.user else None
        
        if email:
            if User.objects.filter(email=email).exclude(pk=exclude_user_id).exists() or Coach.objects.filter(email=email).exclude(pk=exclude_coach_id).exists():
                self.add_error('email', "Coach with this email already exists.")
                
        if phone:
            if Coach.objects.filter(phone=phone).exclude(pk=exclude_coach_id).exists():
                self.add_error('phone', "Coach with this phone number already exists.")
                
        return cleaned_data

@admin.register(Coach)
class CoachAdmin(admin.ModelAdmin):
    form = CoachAdminForm
    list_display = ('id', 'first_name', 'last_name', 'phone', 'email', 'sport', 'experience_years', 'is_active')
    list_filter = ('sport', 'is_active', 'experience_years')
    search_fields = ('first_name', 'last_name', 'phone', 'email', 'sport__name')
    ordering = ('first_name', 'last_name')

    def save_model(self, request, obj, form, change):
        password = form.cleaned_data.get('password')
        if not change:
            # Creation mode
            # Create Django User
            user = User.objects.create_user(
                username=obj.email,
                email=obj.email,
                password=password,
                first_name=obj.first_name,
                last_name=obj.last_name
            )
            obj.user = user
            super().save_model(request, obj, form, change)
        else:
            # Edit mode
            super().save_model(request, obj, form, change)
            if obj.user:
                user = obj.user
                user.email = obj.email
                user.username = obj.email
                user.first_name = obj.first_name
                user.last_name = obj.last_name
                if password:
                    user.set_password(password)
                user.save()
            else:
                user = User.objects.create_user(
                    username=obj.email,
                    email=obj.email,
                    password=password or "TempPassword123!",
                    first_name=obj.first_name,
                    last_name=obj.last_name
                )
                obj.user = user
                obj.save()
