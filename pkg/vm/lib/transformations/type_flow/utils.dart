// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Declares miscellaneous utility functions and constants for type flow
/// analysis.
library vm.transformations.type_flow.utils;

import 'package:kernel/ast.dart' show Member, Constructor;

const bool kPrintTrace =
    const bool.fromEnvironment('global.type.flow.print.trace');

const bool kPrintDebug =
    const bool.fromEnvironment('global.type.flow.print.debug');

const bool kPrintStats =
    const bool.fromEnvironment('global.type.flow.print.stats');

/// Extended 'assert': always checks condition.
assertx(bool cond, {details}) {
  if (!cond) {
    throw 'Assertion failed.' + (details != null ? ' Details: $details' : '');
  }
}

tracePrint(Object message) {
  if (kPrintTrace) {
    print(message);
  }
}

debugPrint(Object message) {
  if (kPrintDebug) {
    print(message);
  }
}

statPrint(Object message) {
  if (kPrintStats) {
    print(message);
  }
}

const int kHashMask = 0x3fffffff;

bool hasReceiverArg(Member member) =>
    member.isInstanceMember || (member is Constructor);

/// Holds various statistic counters for type flow analysis.
class Statistics {
  static int summariesCreated = 0;
  static int summariesAnalyzed = 0;
  static int joinsApproximatedToBreakLoops = 0;
  static int invocationsProcessed = 0;
  static int usedCachedResultsOfInvocations = 0;
  static int invocationsInvalidated = 0;
  static int recursiveInvocationsApproximated = 0;
  static int typeConeSpecializations = 0;

  /// Resets statistic counters.
  static void reset() {
    summariesCreated = 0;
    summariesAnalyzed = 0;
    joinsApproximatedToBreakLoops = 0;
    invocationsProcessed = 0;
    usedCachedResultsOfInvocations = 0;
    invocationsInvalidated = 0;
    recursiveInvocationsApproximated = 0;
  }

  static void print(String caption) {
    statPrint("""${caption}:
    ${summariesCreated} summaries created
    ${summariesAnalyzed} summaries analyzed
    ${joinsApproximatedToBreakLoops} joins are approximated to break loops
    ${invocationsProcessed} invocations processed
    ${usedCachedResultsOfInvocations} times cached result of invocation is used
    ${invocationsInvalidated} invocations invalidated
    ${recursiveInvocationsApproximated} recursive invocations approximated
    ${typeConeSpecializations} type cones specialized
    """);
  }
}
