// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library hot_restart_request;

/// A request to hot restart the application.
class HotRestartRequest {
  /// A unique identifier for this request.
  final String id;

  HotRestartRequest({required this.id});

  /// Creates a [HotRestartRequest] from a JSON map.
  factory HotRestartRequest.fromJson(Map<String, dynamic> json) {
    return HotRestartRequest(id: json['id'] as String);
  }

  /// Converts this [HotRestartRequest] to a JSON map.
  Map<String, dynamic> toJson() => {'id': id};

  @override
  bool operator ==(Object other) =>
      identical(other, this) || other is HotRestartRequest && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'HotRestartRequest(id: $id)';
}
