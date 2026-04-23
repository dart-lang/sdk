// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library hot_reload_response;

/// A response to a hot reload request.
class HotReloadResponse {
  /// The unique identifier matching the request.
  final String id;

  /// Whether the hot reload succeeded on the client.
  final bool success;

  /// An optional error message if success is false.
  final String? errorMessage;

  HotReloadResponse({
    required this.id,
    required this.success,
    this.errorMessage,
  });

  /// Creates a [HotReloadResponse] from a JSON map.
  factory HotReloadResponse.fromJson(Map<String, dynamic> json) {
    return HotReloadResponse(
      id: json['id'] as String,
      success: json['success'] as bool,
      errorMessage: json['error'] as String?,
    );
  }

  /// Converts this [HotReloadResponse] to a JSON map.
  Map<String, dynamic> toJson() => {
    'id': id,
    'success': success,
    if (errorMessage != null) 'error': errorMessage,
  };

  @override
  bool operator ==(Object other) =>
      identical(other, this) ||
      other is HotReloadResponse &&
          id == other.id &&
          success == other.success &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => Object.hash(id, success, errorMessage);

  @override
  String toString() =>
      'HotReloadResponse(id: $id, success: $success, errorMessage: $errorMessage)';
}
