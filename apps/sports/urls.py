from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import SportViewSet, DashboardView

router = DefaultRouter()
router.register(r'sports', SportViewSet, basename='sport')

urlpatterns = [
    path('', include(router.urls)),
    path('dashboard/', DashboardView.as_view(), name='dashboard'),
]
