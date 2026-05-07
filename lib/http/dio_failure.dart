abstract class DioFailure {
  final String reason;
  final String statusCode;
  final String code;

  const DioFailure({
    required this.reason,
    required this.statusCode,
    this.code = '',
  });
}

class ApiFailure extends DioFailure {
  const ApiFailure({
    required super.reason,
    required super.statusCode,
    super.code,
  });
}
