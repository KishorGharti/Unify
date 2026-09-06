class NetworkInfo {
  bool _isConnected = true;

  bool get isConnected => _isConnected;

  void setConnected(bool connected) {
    _isConnected = connected;
  }
}
