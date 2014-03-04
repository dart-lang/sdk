// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of type_graph_inferrer;

// A set of selectors we know do not escape the elements inside the
// list.
Set<String> doesNotEscapeListSet = new Set<String>.from(
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

Set<String> doesNotEscapeMapSet = new Set<String>.from(
  const <String>[
    // From Object.
    '==',
    'hashCode',
    'toString',
    'noSuchMethod',
    'runtimeType',
    // from Map.
    'isEmpty',
    'isNotEmpty',
    'length',
    'clear',
    'containsKey',
    'containsValue'
  ]);

abstract class TracerVisitor implements TypeInformationVisitor {
  final TypeInformation tracedType;
  final TypeGraphInferrerEngine inferrer;
  final Compiler compiler;

  static const int MAX_ANALYSIS_COUNT = 16;
  final Setlet<Element> analyzedElements = new Setlet<Element>();

  TracerVisitor(this.tracedType, inferrer)
      : this.inferrer = inferrer, this.compiler = inferrer.compiler;

  // Work list that gets populated with [TypeInformation] that could
  // contain the container.
  final List<TypeInformation> workList = <TypeInformation>[];

  // Work list of lists to analyze after analyzing the users of a
  // [TypeInformation]. We know the [tracedType] has been stored in these
  // lists and we must check how it escapes from these lists.
  final List<ListTypeInformation> listsToAnalyze =
      <ListTypeInformation>[];
  // Work list of maps to analyze after analyzing the users of a
  // [TypeInformation]. We know the [tracedType] has been stored in these
  // maps and we must check how it escapes from these maps.
  final List<MapTypeInformation> mapsToAnalyze = <MapTypeInformation>[];

  final Setlet<TypeInformation> flowsInto = new Setlet<TypeInformation>();

  // The current [TypeInformation] in the analysis.
  TypeInformation currentUser;
  bool continueAnalyzing = true;

  void addNewEscapeInformation(TypeInformation info) {
    if (flowsInto.contains(info)) return;
    flowsInto.add(info);
    workList.add(info);
  }

  void analyze() {
    // Collect the [TypeInformation] where the list can flow in,
    // as well as the operations done on all these [TypeInformation]s.
    addNewEscapeInformation(tracedType);
    while (!workList.isEmpty) {
      currentUser = workList.removeLast();
      currentUser.users.forEach((TypeInformation info) {
        analyzedElements.add(info.owner);
        info.accept(this);
      });
      while (!listsToAnalyze.isEmpty) {
        analyzeStoredIntoList(listsToAnalyze.removeLast());
      }
      while (!mapsToAnalyze.isEmpty) {
        analyzeStoredIntoMap(mapsToAnalyze.removeLast());
      }
      if (!continueAnalyzing) break;
      if (analyzedElements.length > MAX_ANALYSIS_COUNT) {
        bailout('Too many users');
        break;
      }
    }
  }

  void bailout(String reason) {
    if (_VERBOSE) {
      print('Bailing out on $tracedType because: $reason');
    }
    continueAnalyzing = false;
  }

  void visitNarrowTypeInformation(NarrowTypeInformation info) {
    addNewEscapeInformation(info);
  }

  void visitPhiElementTypeInformation(PhiElementTypeInformation info) {
    addNewEscapeInformation(info);
  }

  void visitElementInContainerTypeInformation(
      ElementInContainerTypeInformation info) {
    addNewEscapeInformation(info);
  }

  void visitKeyInMapTypeInformation(KeyInMapTypeInformation info) {
    addNewEscapeInformation(info);
  }

  void visitValueInMapTypeInformation(ValueInMapTypeInformation info) {
    addNewEscapeInformation(info);
  }

  void visitListTypeInformation(ListTypeInformation info) {
    listsToAnalyze.add(info);
  }

  void visitMapTypeInformation(MapTypeInformation info) {
    mapsToAnalyze.add(info);
  }
  void visitConcreteTypeInformation(ConcreteTypeInformation info) {}

  void visitStringLiteralTypeInformation(StringLiteralTypeInformation info) {}

  void visitClosureTypeInformation(ClosureTypeInformation info) {}

  void visitClosureCallSiteTypeInformation(
      ClosureCallSiteTypeInformation info) {}

  visitStaticCallSiteTypeInformation(StaticCallSiteTypeInformation info) {
    Element called = info.calledElement;
    if (inferrer.types.getInferredTypeOf(called) == currentUser) {
      addNewEscapeInformation(info);
    }
  }

  void analyzeStoredIntoList(ListTypeInformation list) {
    inferrer.analyzeListAndEnqueue(list);
    if (list.bailedOut) {
      bailout('Stored in a list that bailed out');
    } else {
      list.flowsInto.forEach((flow) {
        flow.users.forEach((user) {
          if (user is !DynamicCallSiteTypeInformation) return;
          if (user.receiver != flow) return;
          if (returnsListElementTypeSet.contains(user.selector)) {
            addNewEscapeInformation(user);
          } else if (!doesNotEscapeListSet.contains(user.selector.name)) {
            bailout('Escape from a list via [${user.selector.name}]');
          }
        });
      });
    }
  }

  void analyzeStoredIntoMap(MapTypeInformation map) {
    inferrer.analyzeMapAndEnqueue(map);
    if (map.bailedOut) {
      bailout('Stored in a map that bailed out');
    } else {
      map.flowsInto.forEach((flow) {
        flow.users.forEach((user) {
          if (user is !DynamicCallSiteTypeInformation) return;
          if (user.receiver != flow) return;
          if (user.selector.isIndex()) {
            addNewEscapeInformation(user);
          } else if (!doesNotEscapeMapSet.contains(user.selector.name)) {
            bailout('Escape from a map via [${user.selector.name}]');
          }
        });
      });
    }
  }

  bool isAddedToContainer(DynamicCallSiteTypeInformation info) {
    if (info.arguments == null) return false;
    var receiverType = info.receiver.type;
    if (!receiverType.isContainer) return false;
    String selectorName = info.selector.name;
    List<TypeInformation> arguments = info.arguments.positional;
    return (selectorName == '[]=' && currentUser == arguments[1])
        || (selectorName == 'insert' && currentUser == arguments[0])
        || (selectorName == 'add' && currentUser == arguments[0]);
  }

  bool isValueAddedToMap(DynamicCallSiteTypeInformation info) {
    if (info.arguments == null) return false;
    var receiverType = info.receiver.type;
    if (!receiverType.isMap) return false;
    String selectorName = info.selector.name;
    List<TypeInformation> arguments = info.arguments.positional;
    return selectorName == '[]=' && currentUser == arguments[1];
  }

  void visitDynamicCallSiteTypeInformation(
      DynamicCallSiteTypeInformation info) {
    if (isAddedToContainer(info)) {
      ContainerTypeMask mask = info.receiver.type;

      if (mask.allocationNode != null) {
        ListTypeInformation list =
            inferrer.types.allocatedLists[mask.allocationNode];
        listsToAnalyze.add(list);
      } else {
        // The [ContainerTypeMask] is a union of two containers, and
        // we lose track of where these containers have been allocated
        // at this point.
        bailout('Stored in too many containers');
      }
    } else if (isValueAddedToMap(info)) {
      MapTypeMask mask = info.receiver.type;
      if (mask.allocationNode != null) {
        MapTypeInformation map =
            inferrer.types.allocatedMaps[mask.allocationNode];
        mapsToAnalyze.add(map);
      } else {
        // The [MapTypeMask] is a union. See comment for
        // [ContainerTypeMask] above.
        bailout('Stored in too many maps');
      }
    }

    Iterable<Element> inferredTargetTypes = info.targets.map((element) {
      return inferrer.types.getInferredTypeOf(element);
    });
    if (inferredTargetTypes.any((user) => user == currentUser)) {
      addNewEscapeInformation(info);
    }
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

  bool isClosure(Element element) {
    if (!element.isFunction()) return false;
    Element outermost = element.getOutermostEnclosingMemberOrTopLevel();
    return outermost.declaration != element.declaration;
  }

  void visitElementTypeInformation(ElementTypeInformation info) {
    Element element = info.element;
    if (element.isParameter()
        && inferrer.isNativeElement(element.enclosingElement)) {
      bailout('Passed to a native method');
    }
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
