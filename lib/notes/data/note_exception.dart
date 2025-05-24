class NoteException implements Exception {
  final String message;
  final int? statusCode;
  final String? details;

  NoteException(this.message, {this.statusCode, this.details});

  @override
  String toString() =>
      'NoteException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}${details != null ? '\nDetails: $details' : ''}';
}

class NetworkException extends NoteException {
  NetworkException([String? message])
    : super(message ?? 'Network error occurred');
}

class NotFoundException extends NoteException {
  NotFoundException([String? message])
    : super(message ?? 'Resource not found', statusCode: 404);
}

class ServerException extends NoteException {
  ServerException([String? message])
    : super(message ?? 'Server error occurred', statusCode: 500);
}

class ValidationException extends NoteException {
  ValidationException([String? message, String? details])
    : super(message ?? 'Validation error', statusCode: 400, details: details);
}

class UnauthorizedException extends NoteException {
  UnauthorizedException([String? message])
    : super(message ?? 'Unauthorized access', statusCode: 401);
}
