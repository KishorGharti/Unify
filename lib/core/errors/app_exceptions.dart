class AppException implements Exception {
  final String message;
  final int? statusCode;

  AppException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException([String message = 'No Internet connection detected']) : super(message);
}

class UnauthorizedException extends AppException {
  UnauthorizedException([String message = 'Session expired, please login again']) : super(message, statusCode: 401);
}

class ForbiddenException extends AppException {
  ForbiddenException([String message = 'You do not have permission for this action']) : super(message, statusCode: 403);
}

class NotFoundException extends AppException {
  NotFoundException([String message = 'Requested resource not found']) : super(message, statusCode: 404);
}

class ServerException extends AppException {
  ServerException([String message = 'Internal server error occurred']) : super(message, statusCode: 500);
}

class TenantNotFoundException extends AppException {
  TenantNotFoundException([String message = 'Workspace tenant not found or inactive']) : super(message, statusCode: 404);
}
