from django.urls import re_path
from apps.sports import consumers

websocket_urlpatterns = [
    re_path(r'^ws/academy/$', consumers.AcademyUpdateConsumer.as_asgi()),
]
