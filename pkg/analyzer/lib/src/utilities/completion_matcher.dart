// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A matcher that is used in completion to filter out suggestions. The criteria
/// used to filter is specified in the implementations of the matchers.
abstract class CompletionMatcher {
  /// Computes how well the [candidate] matches the criteria specific to the
  /// implementation of the [CompletionMatcher], and returns a value in the
  /// range of [0, 1] for matching strings, and -1 for non-matching ones.
  double score(String candidate);
}

/// A [NoPrefixMatcher] will be used when there is no prefix specified in the
/// [CompletionRequest].
final class NoPrefixMatcher extends CompletionMatcher {
  @override
  double score(String candidate) {
    return 0;
  }
}
