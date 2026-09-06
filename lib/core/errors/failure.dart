abstract class Failure {
  final String message;
  final int? statusCode;

  const Failure(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  const ServerFailure(String message, {int? statusCode}) : super(message, statusCode: statusCode);
}

class AuthFailure extends Failure {
  const AuthFailure(String message, {int? statusCode}) : super(message, statusCode: statusCode);
}

class TenantFailure extends Failure {
  const TenantFailure(String message, {int? statusCode}) : super(message, statusCode: statusCode);
}

class NetworkFailure extends Failure {
  const NetworkFailure(String message) : super(message);
}

class CacheFailure extends Failure {
  const CacheFailure(String message) : super(message);
}

class ChannelFailure extends Failure {
  const ChannelFailure(String message, {int? statusCode}) : super(message, statusCode: statusCode);
}
