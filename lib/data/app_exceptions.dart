class AppExceptions implements Exception {
  final String? _message;
  final String? _prefix;

  AppExceptions([this._message, this._prefix]);

  @override
  String toString() {
    return '$_prefix: $_message';
  }
}

class FetchDataException extends AppExceptions {
  FetchDataException([String? message])
      : super(message, 'Error During Communication');
}

class NoInternetException extends AppExceptions {
  NoInternetException([String? message])
      : super(message, 'No Internet Connection');
}

class RequestTimeoutException extends AppExceptions {
  RequestTimeoutException([String? message])
      : super(message, 'Request Timed Out');
}

class BadRequestException extends AppExceptions {
  BadRequestException([String? message])
      : super(message, 'Invalid Request');
}

class UnauthorizedException extends AppExceptions {
  UnauthorizedException([String? message])
      : super(message, 'Unauthorized Request');
}

class InvalidInputException extends AppExceptions {
  InvalidInputException([String? message])
      : super(message, 'Invalid Input');
}

class ResourceNotFoundException extends AppExceptions {
  ResourceNotFoundException([String? message])
      : super(message, 'Resource Not Found');
}

class ConflictException extends AppExceptions {
  ConflictException([String? message])
      : super(message, 'Resource Conflict');
}

class ServerException extends AppExceptions {
  ServerException([String? message])
      : super(message, 'Internal Server Error');
}