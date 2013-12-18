// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of type_graph_inferrer;

/**
 * A set of selector names that [List] implements, that we know do not
 * change the element type of the list, or let the list escape to code
 * that might change the element type.
 */
Set<String> okSelectorsSet = new Set<String>.from(
  const <String>[
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

Set<String> doNotChangeLengthSelectorsSet = new Set<String>.from(
  const <String>[
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
  // The list of found assignments to the container.
  final List<TypeInformation> assignments = <TypeInformation>[];
  bool callsGrowableMethod = false;
  
  ListTracerVisitor(tracedType, inferrer) : super(tracedType, inferrer);

  List<TypeInformation> run() {
    analyze();
    ListTypeInformation container = tracedType;
    if (continueAnalyzing) {
      if (!callsGrowableMethod && container.inferredLength == null) {
        container.inferredLength = container.originalLength;
      }
      container.flowsInto.addAll(flowsInto);
      return assignments;
    } else {
      callsGrowableMethod = true;
      return null;
    }
  }

  visitMapTypeInformation(MapTypeInformation info) {
    bailout('Stored in a map');
  }

  visitClosureCallSiteTypeInformation(ClosureCallSiteTypeInformation info) {
    bailout('Passed to a closure');
  }

  visitStaticCallSiteTypeInformation(StaticCallSiteTypeInformation info) {
    super.visitStaticCallSiteTypeInformation(info);
    Element called = info.calledElement;
    if (called.isForeign(compiler) && called.name == 'JS') {
      bailout('Used in JS ${info.call}');
    }
  }

  visitDynamicCallSiteTypeInformation(DynamicCallSiteTypeInformation info) {
    super.visitDynamicCallSiteTypeInformation(info);
    Selector selector = info.selector;
    String selectorName = selector.name;
    if (currentUser == info.receiver) {
      if (!okSelectorsSet.contains(selectorName)) {
        if (selector.isCall()) {
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
        } else if (selector.isIndexSet()) {
          assignments.add(info.arguments.positional[1]);
        } else if (!selector.isIndex()) {
          bailout('Used in a not-ok selector');
          return;
        }
      }
      if (!doNotChangeLengthSelectorsSet.contains(selectorName)) {
        callsGrowableMethod = true;
      }
      if (selectorName == 'length' && selector.isSetter()) {
        callsGrowableMethod = true;
        assignments.add(inferrer.types.nullType);
      }
    } else if (selector.isCall()
               && !info.targets.every((element) => element.isFunction())) {
      bailout('Passed to a closure');
      return;
    }
  }
}
