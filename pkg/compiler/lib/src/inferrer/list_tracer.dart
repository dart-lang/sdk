// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library compiler.src.inferrer.list_tracer;

import '../common/names.dart';
import '../elements/entities.dart';
import '../universe/selector.dart' show Selector;
import '../util/util.dart' show Setlet;
import 'node_tracer.dart';
import 'type_graph_nodes.dart';

/// A set of selector names that [List] implements, that we know do not
/// change the element type of the list, or let the list escape to code
/// that might change the element type.
Set<String> okListSelectorsSet = new Set<String>.from(const <String>[
  // From Object.
  '==',
  'hashCode',
  'toString',
  'noSuchMethod',
  'runtimeType',

  // From Iterable.
  'iterator',
  'map',
  'where',
  'expand',
  'contains',
  'forEach',
  'reduce',
  'fold',
  'every',
  'join',
  'any',
  'toList',
  'toSet',
  'length',
  'isEmpty',
  'isNotEmpty',
  'take',
  'takeWhile',
  'skip',
  'skipWhile',
  'first',
  'last',
  'single',
  'firstWhere',
  'lastWhere',
  'singleWhere',
  'elementAt',

  // From List.
  '[]',
  'length',
  'reversed',
  'sort',
  'indexOf',
  'lastIndexOf',
  'clear',
  'remove',
  'removeAt',
  'removeLast',
  'removeWhere',
  'retainWhere',
  'sublist',
  'getRange',
  'removeRange',
  'asMap',

  // From JSArray.
  'checkMutable',
  'checkGrowable',
]);

Set<String> doNotChangeLengthSelectorsSet = new Set<String>.from(const <String>[
  // From Object.
  '==',
  'hashCode',
  'toString',
  'noSuchMethod',
  'runtimeType',

  // From Iterable.
  'iterator',
  'map',
  'where',
  'expand',
  'contains',
  'forEach',
  'reduce',
  'fold',
  'every',
  'join',
  'any',
  'toList',
  'toSet',
  'length',
  'isEmpty',
  'isNotEmpty',
  'take',
  'takeWhile',
  'skip',
  'skipWhile',
  'first',
  'last',
  'single',
  'firstWhere',
  'lastWhere',
  'singleWhere',
  'elementAt',

  // From List.
  '[]',
  '[]=',
  'length',
  'reversed',
  'sort',
  'indexOf',
  'lastIndexOf',
  'sublist',
  'getRange',
  'asMap',

  // From JSArray.
  'checkMutable',
  'checkGrowable',
]);

class ListTracerVisitor extends TracerVisitor {
  // The [Set] of found assignments to the list.
  Set<TypeInformation> assignments = new Setlet<TypeInformation>();
  bool callsGrowableMethod = false;

  ListTracerVisitor(tracedType, inferrer) : super(tracedType, inferrer);

  /// Returns [true] if the analysis completed successfully, [false] if it
  /// bailed out. In the former case, [assignments] holds a list of
  /// [TypeInformation] nodes that flow into the element type of this list.
  bool run() {
    analyze();
    ListTypeInformation list = tracedType;
    if (continueAnalyzing) {
      if (!callsGrowableMethod && list.inferredLength == null) {
        list.inferredLength = list.originalLength;
      }
      list.addFlowsIntoTargets(flowsInto);
      return true;
    } else {
      callsGrowableMethod = true;
      assignments = null;
      return false;
    }
  }

  @override
  visitClosureCallSiteTypeInformation(ClosureCallSiteTypeInformation info) {
    bailout('Passed to a closure');
  }

  @override
  visitStaticCallSiteTypeInformation(StaticCallSiteTypeInformation info) {
    super.visitStaticCallSiteTypeInformation(info);
    MemberEntity called = info.calledElement;
    if (inferrer.closedWorld.commonElements.isForeign(called) &&
        called.name == Identifiers.JS) {
      bailout('Used in JS ${info.debugName}');
    }
  }

  @override
  visitDynamicCallSiteTypeInformation(DynamicCallSiteTypeInformation info) {
    super.visitDynamicCallSiteTypeInformation(info);
    Selector selector = info.selector;
    String selectorName = selector.name;
    if (currentUser == info.receiver) {
      if (!okListSelectorsSet.contains(selectorName)) {
        if (selector.isCall) {
          int positionalLength = info.arguments.positional.length;
          if (selectorName == 'add') {
            if (positionalLength == 1) {
              assignments.add(info.arguments.positional[0]);
            }
          } else if (selectorName == 'insert') {
            if (positionalLength == 2) {
              assignments.add(info.arguments.positional[1]);
            }
          } else {
            bailout('Used in a not-ok selector');
            return;
          }
        } else if (selector.isIndexSet) {
          assignments.add(info.arguments.positional[1]);
        } else if (!selector.isIndex) {
          bailout('Used in a not-ok selector');
          return;
        }
      }
      if (!doNotChangeLengthSelectorsSet.contains(selectorName)) {
        callsGrowableMethod = true;
      }
      if (selectorName == 'length' && selector.isSetter) {
        callsGrowableMethod = true;
        assignments.add(inferrer.types.nullType);
      }
    } else if (selector.isCall &&
        (info.hasClosureCallTargets ||
            info.concreteTargets.any((element) => !element.isFunction))) {
      bailout('Passed to a closure');
      return;
    }
  }
}
