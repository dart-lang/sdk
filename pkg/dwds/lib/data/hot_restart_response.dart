// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A response to a hot restart request.
class HotRestartResponse {
  /// The unique identifier matching the request.
  final String id;

  /// Whether the hot restart succeeded on the client.
  final bool success;

  /// An optional error message if success is false.
  final String? errorMessage;

  HotRestartResponse({
    required this.id,
    required this.success,
    this.errorMessage,
  });

  factory HotRestartResponse.fromJson(Map<String, dynamic> json) =>
      HotRestartResponse(
        id: json['id'] as String,
        success: json['success'] as bool,
        errorMessage: json['error'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'success': success,
    if (errorMessage != null) 'error': errorMessage,
  };
}
