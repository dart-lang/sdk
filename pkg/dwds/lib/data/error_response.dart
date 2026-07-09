// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class ErrorResponse {
  final String error;
  final String stackTrace;

  ErrorResponse({required this.error, required this.stackTrace});

  factory ErrorResponse.fromJson(Map<String, dynamic> json) {
    return ErrorResponse(
      error: json['error'] as String,
      stackTrace: json['stackTrace'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'error': error, 'stackTrace': stackTrace};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ErrorResponse &&
        other.error == error &&
        other.stackTrace == stackTrace;
  }

  @override
  int get hashCode => Object.hash(error, stackTrace);

  @override
  String toString() => 'ErrorResponse(error: $error, stackTrace: $stackTrace)';
}
