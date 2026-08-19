import 'package:examisai/data/response/status.dart';

class ApiResponse<T> {
  final Status? status;
  final T? data;
  final String? message;

  ApiResponse(this.status, this.data, this.message);

  ApiResponse.loading()
      : status = Status.LOADING,
        data = null,
        message = null;

  ApiResponse.completed(this.data)
      : status = Status.COMPLETED,
        message = null;

  ApiResponse.error(this.message)
      : status = Status.ERROR,
        data = null;

  @override
  String toString() {
    return 'Status: $status\n Data: $data\n Message: $message';
  }
}