// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Heuristical thresholds used in the type flow analysis.
class TFAConfiguration {
  /// Interface invocations are approximated using raw arguments
  /// after number of invocations with same selector but different arguments
  /// exceeds this limit.
  final int maxInterfaceInvocationsPerSelector;

  /// Analysis considers approximating direct invocation
  /// if number of operations in its summary exceeds this threshold.
  final int largeSummarySize;

  /// Direct invocations are approximated using raw arguments
  /// if their summary exceeds [largeSummarySize] and number of
  /// invocations with same selector but different arguments
  /// exceeds this limit.
  final int maxDirectInvocationsPerSelector;

  /// Maximum number of concrete types which can be used to calculate
  /// precise subtype cone specialization. If number of allocated types
  /// exceeds this limit, then wide cone approximation is used.
  final int maxAllocatedTypesInSetSpecialization;

  /// If an invocation is invalidated more than [invalidationLimit] times,
  /// then its result is saturated in order to guarantee convergence.
  final int invalidationLimit;

  /// Avoid processing calls synchronuously in the analysis
  /// when call stack depth reaches this limit (to avoid stack overflow).
  final int maxCallStackDepth;

  const TFAConfiguration({
    this.maxInterfaceInvocationsPerSelector = 1000,
    this.largeSummarySize = 300,
    this.maxDirectInvocationsPerSelector = 10,
    this.maxAllocatedTypesInSetSpecialization = 128,
    this.invalidationLimit = 1000,
    this.maxCallStackDepth = 500,
  });
}

const defaultTFAConfiguration = TFAConfiguration();
