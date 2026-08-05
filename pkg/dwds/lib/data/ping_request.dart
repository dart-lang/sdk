// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A ping request to check client connection.
class PingRequest {
  PingRequest();

  Map<String, dynamic> toJson() => {};

  factory PingRequest.fromJson(Map<String, dynamic> json) {
    return PingRequest();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PingRequest;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'PingRequest';
}
