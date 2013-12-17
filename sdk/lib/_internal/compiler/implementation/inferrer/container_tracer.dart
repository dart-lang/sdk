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

// A set of selectors we know do not escape the elements inside the
// list.
Set<String> doesNotEscapeElementSet = new Set<String>.from(
  const <String>[
    // From Object.
    '==',
    'hashCode',
    'toString',
    'noSuchMethod',
    'runtimeType',

    // From Iterable.
    'isEmpty',
    'isNotEmpty',
    'length',
    'any',
    'contains',
    'every',
    'join',

    // From List.
    'add',
    'addAll',
    'clear',
    'fillRange',
    'indexOf',
    'insert',
    'insertAll',
    'lastIndexOf',
    'remove',
    'removeRange',
    'replaceRange',
    'setAll',
    'setRange',
    'shuffle',
    '[]=',

    // From JSArray.
    'checkMutable',
    'checkGrowable',
  ]);

bool _VERBOSE = false;

class ContainerTracerVisitor implements TypeInformationVisitor {
  final ListTypeInformation container;
  final TypeGraphInferrerEngine inferrer;
  final Compiler compiler;


  // Work list that gets populated with [TypeInformation] that could
  // contain the container.
  final List<TypeInformation> workList = <TypeInformation>[];

  // Work list of containers to analyze after analyzing the users of a
  // [TypeInformation] that may be [container]. We know [container]
  // has been stored in these containers and we must check how
  // [container] escapes from these containers.
  final List<ListTypeInformation> containersToAnalyze =
      <ListTypeInformation>[];

  // The current [TypeInformation] in the analysis.
  TypeInformation currentUser;

  // The list of found assignments to the container.
  final List<TypeInformation> assignments = <TypeInformation>[];

  bool callsGrowableMethod = false;
  bool continueAnalyzing = true;
  
  static const int MAX_ANALYSIS_COUNT = 16;
  final Setlet<Element> analyzedElements = new Setlet<Element>();

  ContainerTracerVisitor(this.container, inferrer)
      : this.inferrer = inferrer, this.compiler = inferrer.compiler;

  void addNewEscapeInformation(TypeInformation info) {
    if (container.flowsInto.contains(info)) return;
    container.flowsInto.add(info);
    workList.add(info);
  }

  List<TypeInformation> run() {
    // Collect the [TypeInformation] where the container can flow in,
    // as well as the operations done on all these [TypeInformation]s.
    addNewEscapeInformation(container);
    while (!workList.isEmpty) {
      currentUser = workList.removeLast();
      currentUser.users.forEach((TypeInformation info) {
        analyzedElements.add(info.owner);
        info.accept(this);
      });
      while (!containersToAnalyze.isEmpty) {
        analyzeStoredIntoContainer(containersToAnalyze.removeLast());
      }
      if (!continueAnalyzing) break;
      if (analyzedElements.length > MAX_ANALYSIS_COUNT) {
        bailout('Too many users');
        break;
      }
    }

    if (continueAnalyzing) {
      if (!callsGrowableMethod && container.inferredLength == null) {
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
    callsGrowableMethod = true;
  }

  visitNarrowTypeInformation(NarrowTypeInformation info) {
    addNewEscapeInformation(info);
  }

  visitPhiElementTypeInformation(PhiElementTypeInformation info) {
    addNewEscapeInformation(info);
  }

  visitElementInContainerTypeInformation(
      ElementInContainerTypeInformation info) {
    addNewEscapeInformation(info);
  }

  visitListTypeInformation(ListTypeInformation info) {
    containersToAnalyze.add(info);
  }

  visitMapTypeInformation(MapTypeInformation info) {
    bailout('Stored in a map');
  }

  visitConcreteTypeInformation(ConcreteTypeInformation info) {}

  visitClosureCallSiteTypeInformation(ClosureCallSiteTypeInformation info) {
    bailout('Passed to a closure');
  }

  visitStaticCallSiteTypeInformation(StaticCallSiteTypeInformation info) {
    Element called = info.calledElement;
    if (called.isForeign(compiler) && called.name == 'JS') {
      bailout('Used in JS ${info.call}');
    }
    if (inferrer.types.getInferredTypeOf(called) == currentUser) {
      addNewEscapeInformation(info);
    }
  }

  void analyzeStoredIntoContainer(ListTypeInformation container) {
    inferrer.analyzeContainer(container);
    if (container.bailedOut) {
      bailout('Stored in a container that bailed out');
    } else {
      container.flowsInto.forEach((flow) {
        flow.users.forEach((user) {
          if (user is !DynamicCallSiteTypeInformation) return;
          if (user.receiver != flow) return;
          if (returnsElementTypeSet.contains(user.selector)) {
            addNewEscapeInformation(user);
          } else if (!doesNotEscapeElementSet.contains(user.selector.name)) {
            bailout('Escape from a container');
          }
        });
      });
    }
  }

  bool isAddedToContainer(DynamicCallSiteTypeInformation info) {
    var receiverType = info.receiver.type;
    if (!receiverType.isContainer) return false;
    String selectorName = info.selector.name;
    List<TypeInformation> arguments = info.arguments.positional;
    return (selectorName == '[]=' && currentUser == arguments[1])
        || (selectorName == 'insert' && currentUser == arguments[0])
        || (selectorName == 'add' && currentUser == arguments[0]);
  }

  visitDynamicCallSiteTypeInformation(DynamicCallSiteTypeInformation info) {
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
    } else if (isAddedToContainer(info)) {
      ContainerTypeMask mask = info.receiver.type;
      if (mask.allocationNode != null) {
        ListTypeInformation container =
            inferrer.types.allocatedLists[mask.allocationNode];
        containersToAnalyze.add(container);
      } else {
        // The [ContainerTypeMask] is a union of two containers, and
        // we lose track of where these containers have been allocated
        // at this point.
        bailout('Stored in too many containers');
      }
    }

    if (info.targets
            .map((element) => inferrer.types.getInferredTypeOf(element))
            .any((other) => other == currentUser)) {
      addNewEscapeInformation(info);
    }
  }

  bool isClosure(Element element) {
    if (!element.isFunction()) return false;
    Element outermost = element.getOutermostEnclosingMemberOrTopLevel();
    return outermost.declaration != element.declaration;
  }

  bool isParameterOfListAddingMethod(Element element) {
    if (!element.isParameter()) return false;
    if (element.getEnclosingClass() != compiler.backend.listImplementation) {
      return false;
    }
    Element method = element.enclosingElement;
    return (method.name == '[]=')
        || (method.name == 'add')
        || (method.name == 'insert');
  }

  visitElementTypeInformation(ElementTypeInformation info) {
    if (info.isClosurized()) {
      bailout('Returned from a closurized method');
    }
    if (isClosure(info.element)) {
      bailout('Returned from a closure');
    }
    if (compiler.backend.isNeededForReflection(info.element)) {
      bailout('Escape in reflection');
    }
    if (isParameterOfListAddingMethod(info.element)) {
      // These elements are being handled in
      // [visitDynamicCallSiteTypeInformation].
      return;
    }
    addNewEscapeInformation(info);
  }
}
