// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

/// A description of a single proposed fix for some problem.
final class Fix {
  /// A description of the fix being proposed.
  final FixKind kind;

  /// The change to be made in order to apply the fix.
  final SourceChange change;

  /// Initializes a newly created fix to have the given [kind] and [change].
  Fix({required this.kind, required this.change});

  @override
  String toString() {
    return 'Fix(kind=$kind, change=$change)';
  }

  /// Sorts fixes by their relevance.
  ///
  /// A fix with a higher relevance is sorted before a fix with a lower
  /// relevance. Fixes with the same relevance are sorted alphabetically.
  static int compareFixes(Fix a, Fix b) {
    if (a.kind.priority != b.kind.priority) {
      // A higher priority indicates a higher relevance
      // and should be sorted before a lower priority.
      return b.kind.priority - a.kind.priority;
    }
    return a.change.message.compareTo(b.change.message);
  }
}
