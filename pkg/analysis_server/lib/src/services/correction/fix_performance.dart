// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/server/performance.dart';

// TODO(pq): update to share w/ completion_performance
/// Compute a string representing a get fixes request at the
/// given source and location.
///
/// This string is useful for displaying to users in a diagnostic context.
String _computeSourceSnippet(String contents, int offset) {
  if (offset < 0 || contents.length < offset) {
    return '???';
  }
  var start = offset;
  while (start > 0) {
    var ch = contents[start - 1];
    if (ch == '\r' || ch == '\n') {
      break;
    }
    --start;
  }
  var end = offset;
  while (end < contents.length) {
    var ch = contents[end];
    if (ch == '\r' || ch == '\n') {
      break;
    }
    ++end;
  }
  var prefix = contents.substring(start, offset);
  var suffix = contents.substring(offset, end);
  return '$prefix^$suffix';
}

/// Overall performance of a request for quick fixes operation.
class GetFixesPerformance extends RequestPerformance {
  final String path;
  final String snippet;

  GetFixesPerformance({
    required super.performance,
    required this.path,
    super.requestLatency,
    required String content,
    required int offset,
  }) : snippet = _computeSourceSnippet(content, offset),
       super(operation: 'GetFixes');

  int get elapsedInMilliseconds => performance.elapsed.inMilliseconds;
}
