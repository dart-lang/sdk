// Copyright (c) 2025, the Dart project authors. All rights reserved.
// Defines the request for service extension calls over WebSocket.

class ServiceExtensionRequest {
  final String id;
  final String method;
  final Map<String, dynamic> args;

  ServiceExtensionRequest({
    required this.id,
    required this.method,
    Map<String, dynamic>? args,
  }) : args = args ?? const <String, dynamic>{};

  factory ServiceExtensionRequest.fromArgs({
    required String id,
    required String method,
    required Map<String, dynamic> args,
  }) => ServiceExtensionRequest(id: id, method: method, args: args);

  factory ServiceExtensionRequest.fromJson(Map<String, dynamic> json) =>
      ServiceExtensionRequest(
        id: json['id'] as String,
        method: json['method'] as String,
        args:
            (json['args'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      );

  Map<String, dynamic> toJson() => {'id': id, 'method': method, 'args': args};
}
