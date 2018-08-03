// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Declares miscellaneous utility functions and constants for type flow
/// analysis.
library vm.transformations.type_flow.utils;

import 'package:kernel/ast.dart'
    show Constructor, FunctionNode, Member, VariableDeclaration;

const bool kPrintTrace =
    const bool.fromEnvironment('global.type.flow.print.trace');

const bool kPrintDebug =
    const bool.fromEnvironment('global.type.flow.print.debug');

const bool kPrintStats =
    const bool.fromEnvironment('global.type.flow.print.stats');

const bool kRemoveAsserts =
    const bool.fromEnvironment('global.type.flow.remove.asserts');

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

/// Returns true if elements in [list] are in strictly increasing order.
/// List with duplicates is considered not sorted.
bool isSorted(List list) {
  for (int i = 0; i < list.length - 1; i++) {
    if (list[i].compareTo(list[i + 1]) >= 0) {
      return false;
    }
  }
  return true;
}

VariableDeclaration findNamedParameter(FunctionNode function, String name) {
  return function.namedParameters
      .firstWhere((p) => p.name == name, orElse: () => null);
}

/// Holds various statistic counters for type flow analysis.
class Statistics {
  static int summariesCreated = 0;
  static int summariesAnalyzed = 0;
  static int joinsApproximatedToBreakLoops = 0;
  static int invocationsProcessed = 0;
  static int usedCachedResultsOfInvocations = 0;
  static int invocationsInvalidated = 0;
  static int maxInvalidationsPerInvocation = 0;
  static int recursiveInvocationsApproximated = 0;
  static int typeConeSpecializations = 0;
  static int iterationsOverInvocationsWorkList = 0;
  static int invocationsInvalidatedDuringProcessing = 0;
  static int invocationsQueriedInCache = 0;
  static int invocationsAddedToCache = 0;
  static int maxInvocationsCachedPerSelector = 0;
  static int approximateInvocationsCreated = 0;
  static int approximateInvocationsUsed = 0;
  static int classesDropped = 0;
  static int membersDropped = 0;
  static int methodBodiesDropped = 0;
  static int fieldInitializersDropped = 0;
  static int constructorBodiesDropped = 0;
  static int callsDropped = 0;
  static int throwExpressionsPruned = 0;

  /// Resets statistic counters.
  static void reset() {
    summariesCreated = 0;
    summariesAnalyzed = 0;
    joinsApproximatedToBreakLoops = 0;
    invocationsProcessed = 0;
    usedCachedResultsOfInvocations = 0;
    invocationsInvalidated = 0;
    maxInvalidationsPerInvocation = 0;
    recursiveInvocationsApproximated = 0;
    typeConeSpecializations = 0;
    iterationsOverInvocationsWorkList = 0;
    invocationsInvalidatedDuringProcessing = 0;
    invocationsQueriedInCache = 0;
    invocationsAddedToCache = 0;
    maxInvocationsCachedPerSelector = 0;
    approximateInvocationsCreated = 0;
    approximateInvocationsUsed = 0;
    classesDropped = 0;
    membersDropped = 0;
    methodBodiesDropped = 0;
    fieldInitializersDropped = 0;
    constructorBodiesDropped = 0;
    callsDropped = 0;
    throwExpressionsPruned = 0;
  }

  static void print(String caption) {
    statPrint("""${caption}:
    ${summariesCreated} summaries created
    ${summariesAnalyzed} summaries analyzed
    ${joinsApproximatedToBreakLoops} joins are approximated to break loops
    ${invocationsProcessed} invocations processed
    ${usedCachedResultsOfInvocations} times cached result of invocation is used
    ${invocationsInvalidated} invocations invalidated
    ${maxInvalidationsPerInvocation} maximum invalidations per invocation
    ${recursiveInvocationsApproximated} recursive invocations approximated
    ${typeConeSpecializations} type cones specialized
    ${iterationsOverInvocationsWorkList} iterations over invocations work list
    ${invocationsInvalidatedDuringProcessing} invocations invalidated during processing
    ${invocationsQueriedInCache} invocations queried in cache
    ${invocationsAddedToCache} invocations added to cache
    ${maxInvocationsCachedPerSelector} maximum invocations cached per selector
    ${approximateInvocationsCreated} approximate invocations created
    ${approximateInvocationsUsed} times approximate invocation is used
    ${classesDropped} classes dropped
    ${membersDropped} members dropped
    ${methodBodiesDropped} method bodies dropped
    ${fieldInitializersDropped} field initializers dropped
    ${constructorBodiesDropped} constructor bodies dropped
    ${callsDropped} calls dropped
    ${throwExpressionsPruned} throw expressions pruned
    """);
  }
}
