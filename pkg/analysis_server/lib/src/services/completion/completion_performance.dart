// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/util/performance/operation_performance.dart';

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
class CompletionPerformance {
  final OperationPerformance operation;
  final String path;
  final String snippet;
  int suggestionCount = -1;

  CompletionPerformance({
    required this.operation,
    required this.path,
    required String content,
    required int offset,
  }) : snippet = _computeCompletionSnippet(content, offset);

  int get elapsedInMilliseconds {
    return operation.elapsed.inMilliseconds;
  }

  String get suggestionCountStr {
    if (suggestionCount < 1) return '';
    return '$suggestionCount';
  }
}
