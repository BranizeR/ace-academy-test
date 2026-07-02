import json
from channels.generic.websocket import AsyncWebsocketConsumer

class AcademyUpdateConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.group_name = 'academy_updates'

        # Join group
        await self.channel_layer.group_add(
            self.group_name,
            self.channel_name
        )
        await self.accept()

    async def disconnect(self, close_code):
        # Leave group
        await self.channel_layer.group_discard(
            self.group_name,
            self.channel_name
        )

    # Receive message from group
    async def broadcast_change(self, event):
        event_type = event.get('event')
        # Send message to WebSocket
        await self.send(text_data=json.dumps({
            'event': event_type
        }))


def broadcast_event(event_name):
    from asgiref.sync import async_to_sync
    from channels.layers import get_channel_layer
    channel_layer = get_channel_layer()
    if channel_layer:
        async_to_sync(channel_layer.group_send)(
            'academy_updates',
            {
                'type': 'broadcast_change',
                'event': event_name
            }
        )
