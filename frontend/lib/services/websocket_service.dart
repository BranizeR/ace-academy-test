import 'dart:convert';
import 'dart:io';
import 'api_service.dart';

class WebSocketService {
  static WebSocket? _socket;
  static bool _shouldReconnect = false;
  static final List<Function(String)> _listeners = [];

  static void addListener(Function(String) listener) {
    _listeners.add(listener);
  }

  static void removeListener(Function(String) listener) {
    _listeners.remove(listener);
  }

  static void connect() {
    _shouldReconnect = true;
    final wsUrl = ApiService.baseUrl.replaceFirst('http', 'ws').replaceAll('/api', '/ws/academy/');
    _connectSocket(wsUrl);
  }

  static void _connectSocket(String url) async {
    if (!_shouldReconnect) return;
    try {
      _socket = await WebSocket.connect(url).timeout(const Duration(seconds: 5));
      _socket!.listen(
        (data) {
          try {
            final parsed = jsonDecode(data);
            final event = parsed['event'] as String?;
            if (event != null) {
              for (var listener in List.from(_listeners)) {
                listener(event);
              }
            }
          } catch (_) {}
        },
        onError: (err) {
          _reconnect(url);
        },
        onDone: () {
          _reconnect(url);
        },
        cancelOnError: true,
      );
    } catch (_) {
      _reconnect(url);
    }
  }

  static void _reconnect(String url) {
    if (!_shouldReconnect) return;
    Future.delayed(const Duration(seconds: 3), () {
      _connectSocket(url);
    });
  }

  static void disconnect() {
    _shouldReconnect = false;
    _socket?.close();
    _socket = null;
  }
}
