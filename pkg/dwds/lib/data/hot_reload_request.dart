// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library hot_reload_request;

/// A request to hot reload the application.
class HotReloadRequest {
  /// A unique identifier for this request.
  final String id;

  HotReloadRequest({required this.id});

  /// Creates a [HotReloadRequest] from a JSON map.
  factory HotReloadRequest.fromJson(Map<String, dynamic> json) {
    return HotReloadRequest(id: json['id'] as String);
  }

  /// Converts this [HotReloadRequest] to a JSON map.
  Map<String, dynamic> toJson() => {'id': id};

  @override
  bool operator ==(Object other) =>
      identical(other, this) || other is HotReloadRequest && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'HotReloadRequest(id: $id)';
}
