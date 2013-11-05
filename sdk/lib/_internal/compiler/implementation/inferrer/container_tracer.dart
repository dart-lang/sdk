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

bool _VERBOSE = false;

class ContainerTracerVisitor implements TypeInformationVisitor {
  final ContainerTypeInformation container;
  final TypeGraphInferrerEngine inferrer;
  final Compiler compiler;

  // The set of [TypeInformation] where the traced container could
  // flow in, and operations done on them.
  final Setlet<TypeInformation> allUsers = new Setlet<TypeInformation>();

  // The list of found assignments to the container.
  final List<TypeInformation> assignments = <TypeInformation>[];

  bool enableLengthTracking = true;
  bool continueAnalyzing = true;

  static const int MAX_ANALYSIS_COUNT = 16;
  final Setlet<Element> analyzedElements = new Setlet<Element>();

  ContainerTracerVisitor(this.container, inferrer)
      : this.inferrer = inferrer, this.compiler = inferrer.compiler;

  List<TypeInformation> run() {
    // Collect the [TypeInformation] where the container can flow in,
    // as well as the operations done on all these [TypeInformation]s.
    List<TypeInformation> workList = <TypeInformation>[];
    allUsers.add(container);
    workList.add(container);
    while (!workList.isEmpty) {
      TypeInformation user = workList.removeLast();
      user.users.forEach((TypeInformation info) {
        if (allUsers.contains(info)) return;
        allUsers.add(info);
        analyzedElements.add(info.owner);
        if (info.reachedBy(user, inferrer)) {
          workList.add(info);
        }
      });
      if (analyzedElements.length > MAX_ANALYSIS_COUNT) {
        bailout('Too many users');
        break;
      }
    }

    if (continueAnalyzing) {
      for (TypeInformation info in allUsers) {
        info.accept(this);
        if (!continueAnalyzing) break;
      }
    }

    if (continueAnalyzing) {
      if (enableLengthTracking && container.inferredLength == null) {
        container.inferredLength = container.originalLength;
      }
      return assignments;
    }
    return null;
  }

  void bailout(String reason) {
    if (_VERBOSE) {
      ContainerTypeMask mask = container.type;
      print('Bailing out on ${mask.allocationNode} ${mask.allocationElement} '
            'because: $reason');
    }
    continueAnalyzing = false;
    enableLengthTracking = false;
  }

  visitNarrowTypeInformation(NarrowTypeInformation info) {}
  visitPhiElementTypeInformation(PhiElementTypeInformation info) {}
  visitElementInContainerTypeInformation(
      ElementInContainerTypeInformation info) {}

  visitContainerTypeInformation(ContainerTypeInformation info) {
    if (container != info) {
      bailout('Stored in a container');
    }
  }

  visitConcreteTypeInformation(ConcreteTypeInformation info) {}

  visitClosureCallSiteTypeInformation(ClosureCallSiteTypeInformation info) {
    bailout('Passed to a closure');
  }

  visitStaticCallSiteTypeInformation(StaticCallSiteTypeInformation info) {
    analyzedElements.add(info.caller);
    Element called = info.calledElement;
    if (called.isForeign(compiler) && called.name == 'JS') {
      bailout('Used in JS ${info.call}');
    }
  }

  visitDynamicCallSiteTypeInformation(DynamicCallSiteTypeInformation info) {
    Selector selector = info.selector;
    String selectorName = selector.name;
    if (allUsers.contains(info.receiver)) {
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
        enableLengthTracking = false;
      }
      if (selectorName == 'length' && selector.isSetter()) {
        enableLengthTracking = false;
        assignments.add(inferrer.types.nullType);
      }
    } else if (selector.isCall()
               && !info.targets.every((element) => element.isFunction())) {
      bailout('Passed to a closure');
      return;
    }
  }

  bool isClosure(Element element) {
    if (!element.isFunction()) return false;
    Element outermost = element.getOutermostEnclosingMemberOrTopLevel();
    return outermost.declaration != element.declaration;
  }

  visitElementTypeInformation(ElementTypeInformation info) {
    if (isClosure(info.element)) {
      bailout('Returned from a closure');
    }
  }
}
