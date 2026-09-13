import 'dart:async';
import 'socket_events.dart';

abstract class WebSocketService {
  Stream<SocketEvent> get eventStream;
  bool get isConnected;
  Future<void> connect({required String token, required String tenantId});
  Future<void> disconnect();
  void subscribeToConversation(String conversationId);
  void unsubscribeFromConversation(String conversationId);
  void emit(String event, Map<String, dynamic> data);
}

class UnifyWebSocketService implements WebSocketService {
  final _eventController = StreamController<SocketEvent>.broadcast();
  bool _isConnected = false;
  String? _tenantId;
  final Set<String> _subscribedConversations = {};

  @override
  Stream<SocketEvent> get eventStream => _eventController.stream;

  @override
  bool get isConnected => _isConnected;

  @override
  Future<void> connect({required String token, required String tenantId}) async {
    _tenantId = tenantId;
    _isConnected = true;
  }

  @override
  Future<void> disconnect() async {
    _isConnected = false;
    _subscribedConversations.clear();
  }

  @override
  void subscribeToConversation(String conversationId) {
    _subscribedConversations.add(conversationId);
  }

  @override
  void unsubscribeFromConversation(String conversationId) {
    _subscribedConversations.remove(conversationId);
  }

  @override
  void emit(String event, Map<String, dynamic> data) {

  }

  void dispatchLocalEvent(SocketEvent event) {
    _eventController.add(event);
  }

  void dispose() {
    _eventController.close();
  }
}
