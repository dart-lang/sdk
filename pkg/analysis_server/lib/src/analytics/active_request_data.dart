// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Data about a request that was received and is being handled.
class ActiveRequestData {
  /// The name of the request that was received.
  final String method;

  /// The time at which the client sent the request.
  final int? clientRequestTime;

  /// The time at which the request was received.
  final DateTime startTime;

  /// Initialize a newly created data holder.
  ActiveRequestData(this.method, this.clientRequestTime, this.startTime);
}
