// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library compiler.src.inferrer.node_tracer;

import '../common/names.dart' show Identifiers;
import '../compiler.dart' show Compiler;
import '../elements/elements.dart';
import '../types/types.dart' show ContainerTypeMask, MapTypeMask;
import '../util/util.dart' show Setlet;
import 'debug.dart' as debug;
import 'type_graph_inferrer.dart' show TypeGraphInferrerEngine;
import 'type_graph_nodes.dart';

// A set of selectors we know do not escape the elements inside the
// list.
Set<String> doesNotEscapeListSet = new Set<String>.from(const <String>[
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
  'contains',
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

Set<String> doesNotEscapeMapSet = new Set<String>.from(const <String>[
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
  'containsValue',
  '[]=',
  // [keys] only allows key values to escape, which we do not track.
  'keys'
]);

/// Common logic to trace a value through the type inference graph nodes.
abstract class TracerVisitor<T extends TypeInformation>
    implements TypeInformationVisitor {
  final T tracedType;
  final TypeGraphInferrerEngine inferrer;
  final Compiler compiler;

  static const int MAX_ANALYSIS_COUNT = 16;
  final Setlet<Element> analyzedElements = new Setlet<Element>();

  TracerVisitor(this.tracedType, TypeGraphInferrerEngine inferrer)
      : this.inferrer = inferrer,
        this.compiler = inferrer.compiler;

  // Work list that gets populated with [TypeInformation] that could
  // contain the container.
  final List<TypeInformation> workList = <TypeInformation>[];

  // Work list of lists to analyze after analyzing the users of a
  // [TypeInformation]. We know the [tracedType] has been stored in these
  // lists and we must check how it escapes from these lists.
  final List<ListTypeInformation> listsToAnalyze = <ListTypeInformation>[];
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

  bool _wouldBeTooManyUsers(Set users) {
    int seenSoFar = analyzedElements.length;
    if (seenSoFar + users.length <= MAX_ANALYSIS_COUNT) return false;
    int actualWork = users
        .where((TypeInformation user) => !analyzedElements.contains(user.owner))
        .length;
    return seenSoFar + actualWork > MAX_ANALYSIS_COUNT;
  }

  void analyze() {
    // Collect the [TypeInformation] where the list can flow in,
    // as well as the operations done on all these [TypeInformation]s.
    addNewEscapeInformation(tracedType);
    while (!workList.isEmpty) {
      currentUser = workList.removeLast();
      if (_wouldBeTooManyUsers(currentUser.users)) {
        bailout('Too many users');
        break;
      }
      for (TypeInformation info in currentUser.users) {
        analyzedElements.add(info.owner);
        info.accept(this);
      }
      while (!listsToAnalyze.isEmpty) {
        analyzeStoredIntoList(listsToAnalyze.removeLast());
      }
      while (!mapsToAnalyze.isEmpty) {
        analyzeStoredIntoMap(mapsToAnalyze.removeLast());
      }
      if (!continueAnalyzing) break;
    }
  }

  void bailout(String reason) {
    if (debug.VERBOSE) {
      print('Bailing out on $tracedType because: $reason');
    }
    continueAnalyzing = false;
  }

  void visitAwaitTypeInformation(AwaitTypeInformation info) {
    bailout("Passed through await");
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
    // We do not track the use of keys from a map, so we have to bail.
    bailout('Used as key in Map');
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

  void visitBoolLiteralTypeInformation(BoolLiteralTypeInformation info) {}

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
          if (user is! DynamicCallSiteTypeInformation) return;
          if (user.receiver != flow) return;
          if (inferrer.returnsListElementTypeSet.contains(user.selector)) {
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
          if (user is! DynamicCallSiteTypeInformation) return;
          if (user.receiver != flow) return;
          if (user.selector.isIndex) {
            addNewEscapeInformation(user);
          } else if (!doesNotEscapeMapSet.contains(user.selector.name)) {
            bailout('Escape from a map via [${user.selector.name}]');
          }
        });
      });
    }
  }

  /**
   * Checks whether this is a call to a list adding method. The definition
   * of what list adding means has to stay in sync with
   * [isParameterOfListAddingMethod].
   */
  bool isAddedToContainer(DynamicCallSiteTypeInformation info) {
    if (info.arguments == null) return false;
    var receiverType = info.receiver.type;
    if (!receiverType.isContainer) return false;
    String selectorName = info.selector.name;
    List<TypeInformation> arguments = info.arguments.positional;
    return (selectorName == '[]=' && currentUser == arguments[1]) ||
        (selectorName == 'insert' && currentUser == arguments[1]) ||
        (selectorName == 'add' && currentUser == arguments[0]);
  }

  bool isIndexSetOnMap(DynamicCallSiteTypeInformation info) {
    if (info.arguments == null) return false;
    var receiverType = info.receiver.type;
    if (!receiverType.isMap) return false;
    return info.selector.name == '[]=';
  }

  /**
   * Checks whether this is a call to a map adding method for values. The
   * definition of map adding method has to stay in sync with
   * [isParameterOfMapAddingMethod].
   */
  bool isValueAddedToMap(DynamicCallSiteTypeInformation info) {
    return isIndexSetOnMap(info) && currentUser == info.arguments.positional[1];
  }

  /**
   * Checks whether this is a call to a map adding method for keys. The
   * definition of map adding method has to stay in sync with
   * [isParameterOfMapAddingMethod].
   */
  bool isKeyAddedToMap(DynamicCallSiteTypeInformation info) {
    return isIndexSetOnMap(info) && currentUser == info.arguments.positional[0];
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
    } else if (isKeyAddedToMap(info)) {
      // We do not track the use of keys from a map, so we have to bail.
      bailout('Used as key in Map');
    }

    if (info.targetsIncludeComplexNoSuchMethod(inferrer) &&
        info.arguments != null &&
        info.arguments.contains(currentUser)) {
      bailout('Passed to noSuchMethod');
    }

    Iterable<Element> inferredTargetTypes = info.targets.map((element) {
      return inferrer.types.getInferredTypeOf(element);
    });
    if (inferredTargetTypes.any((user) => user == currentUser)) {
      addNewEscapeInformation(info);
    }
  }

  /**
   * Check whether element is the parameter of a list adding method.
   * The definition of what a list adding method is has to stay in sync with
   * [isAddedToContainer].
   */
  bool isParameterOfListAddingMethod(Element element) {
    if (!element.isRegularParameter) return false;
    if (element.enclosingClass != compiler.backend.listImplementation) {
      return false;
    }
    Element method = element.enclosingElement;
    return (method.name == '[]=') ||
        (method.name == 'add') ||
        (method.name == 'insert');
  }

  /**
   * Check whether element is the parameter of a list adding method.
   * The definition of what a list adding method is has to stay in sync with
   * [isValueAddedToMap] and [isKeyAddedToMap].
   */
  bool isParameterOfMapAddingMethod(Element element) {
    if (!element.isRegularParameter) return false;
    if (element.enclosingClass != compiler.backend.mapImplementation) {
      return false;
    }
    Element method = element.enclosingElement;
    return (method.name == '[]=');
  }

  bool isClosure(Element element) {
    if (!element.isFunction) return false;

    /// Creating an instance of a class that implements [Function] also
    /// closurizes the corresponding [call] member. We do not currently
    /// track these, thus the check for [isClosurized] on such a method will
    /// return false. Instead we catch that case here for now.
    // TODO(herhut): Handle creation of closures from instances of Function.
    if (element.isInstanceMember && element.name == Identifiers.call) {
      return true;
    }
    Element outermost = element.outermostEnclosingMemberOrTopLevel;
    return outermost.declaration != element.declaration;
  }

  void visitMemberTypeInformation(MemberTypeInformation info) {
    if (info.isClosurized) {
      bailout('Returned from a closurized method');
    }
    if (isClosure(info.element)) {
      bailout('Returned from a closure');
    }
    if (!inferrer.compiler.backend
        .canBeUsedForGlobalOptimizations(info.element)) {
      bailout('Escape to code that has special backend treatment');
    }
    addNewEscapeInformation(info);
  }

  void visitParameterTypeInformation(ParameterTypeInformation info) {
    ParameterElement element = info.element;
    if (inferrer.isNativeElement(element.functionDeclaration)) {
      bailout('Passed to a native method');
    }
    if (!inferrer.compiler.backend
        .canBeUsedForGlobalOptimizations(info.element)) {
      bailout('Escape to code that has special backend treatment');
    }
    if (isParameterOfListAddingMethod(info.element) ||
        isParameterOfMapAddingMethod(info.element)) {
      // These elements are being handled in
      // [visitDynamicCallSiteTypeInformation].
      return;
    }
    addNewEscapeInformation(info);
  }
}
