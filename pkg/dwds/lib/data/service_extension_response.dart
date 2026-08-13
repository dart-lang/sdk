// Copyright (c) 2025, the Dart project authors. All rights reserved.
// Defines the response for service extension calls over WebSocket.

class ServiceExtensionResponse {
  final String id;
  final bool success;
  final Map<String, dynamic>? result;
  final int? errorCode;
  final String? errorMessage;

  ServiceExtensionResponse({
    required this.id,
    required this.success,
    this.result,
    this.errorCode,
    this.errorMessage,
  });

  factory ServiceExtensionResponse.fromResult({
    required String id,
    required bool success,
    Map<String, dynamic>? result,
    int? errorCode,
    String? errorMessage,
  }) => ServiceExtensionResponse(
    id: id,
    success: success,
    result: result,
    errorCode: errorCode,
    errorMessage: errorMessage,
  );

  factory ServiceExtensionResponse.fromJson(Map<String, dynamic> json) =>
      ServiceExtensionResponse(
        id: json['id'] as String,
        success: json['success'] as bool,
        result: (json['result'] as Map?)?.cast<String, dynamic>(),
        errorCode: json['errorCode'] as int?,
        errorMessage: json['errorMessage'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'success': success,
    if (result != null) 'result': result,
    if (errorCode != null) 'errorCode': errorCode,
    if (errorMessage != null) 'errorMessage': errorMessage,
  };
}
