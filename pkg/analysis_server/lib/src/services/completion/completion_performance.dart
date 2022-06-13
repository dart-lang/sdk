// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/server/performance.dart';

/// Compute a string representing a code completion operation at the
/// given source and location.
///
/// This string is useful for displaying to users in a diagnostic context.
String _computeCompletionSnippet(String contents, int offset) {
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

/// Overall performance of a code completion operation.
class CompletionPerformance extends RequestPerformance {
  final String path;
  final String snippet;
  int? computedSuggestionCount;
  int? transmittedSuggestionCount;

  CompletionPerformance({
    required super.performance,
    required this.path,
    super.requestLatency,
    required String content,
    required int offset,
  })  : snippet = _computeCompletionSnippet(content, offset),
        super(operation: 'Completion');

  String get computedSuggestionCountStr {
    if (computedSuggestionCount == null) return '';
    return '$computedSuggestionCount';
  }

  int get elapsedInMilliseconds {
    return performance.elapsed.inMilliseconds;
  }

  String get transmittedSuggestionCountStr {
    if (transmittedSuggestionCount == null) return '';
    return '$transmittedSuggestionCount';
  }
}
