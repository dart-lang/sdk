// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/util/performance/operation_performance.dart';

/// Compute a string representing a code completion operation at the
/// given source and location.
///
/// This string is useful for displaying to users in a diagnostic context.
String computeCompletionSnippet(String contents, int offset) {
  if (contents == null ||
      offset == null ||
      offset < 0 ||
      contents.length < offset) {
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
  String path;
  String snippet = '';
  int suggestionCount = -1;
  OperationPerformanceImpl _operation;

  int get elapsedInMilliseconds {
    return _operation.elapsed.inMilliseconds;
  }

  String get suggestionCountStr {
    if (suggestionCount < 1) return '';
    return '$suggestionCount';
  }

  Future<T> runRequestOperation<T>(
    Future<T> Function(OperationPerformanceImpl) operation,
  ) async {
    var rootOperation = OperationPerformanceImpl('<root>');
    try {
      return rootOperation.runAsync('<request>', (performance) async {
        return await operation(performance);
      });
    } finally {
      _operation = rootOperation.children.first;
    }
  }

  void setContentsAndOffset(String contents, int offset) {
    snippet = computeCompletionSnippet(contents, offset);
  }
}
