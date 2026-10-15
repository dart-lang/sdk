// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "dart:developer";

// package:http_profile adds WebSocket profiling information to this list by
// using the [addWebSocketProfilingData] API below.
List<Map<String, dynamic>> _webSocketProfilingData = <Map<String, dynamic>>[];

/// Records the data associated with a WebSocket connection for profiling
/// purposes.
///
/// This function should never be called directly. Instead, use
/// [package:http_profile](https://pub.dev/packages/http_profile).
void addWebSocketProfilingData(Map<String, dynamic> connectionProfile) {
  _webSocketProfilingData.add(connectionProfile);
  connectionProfile['id'] = 'from_package/${_webSocketProfilingData.length}';
}

/// Returns the data added through [addWebSocketProfilingData].
///
/// This function is only meant for use by networking profilers and the format
/// of the returned data may change over time.
List<Map<String, dynamic>> getWebSocketProfilingData() {
  return UnmodifiableListView(_webSocketProfilingData);
}
