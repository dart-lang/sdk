// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server_plugin/src/correction/performance.dart';
import 'package:analysis_server_plugin/src/utilities/string_extensions.dart';

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
  }) : snippet = content.withCaretAt(offset),
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
