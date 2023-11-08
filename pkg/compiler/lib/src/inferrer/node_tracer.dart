// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library compiler.src.inferrer.node_tracer;

import '../common/names.dart' show Identifiers;
import '../elements/entities.dart';
import '../util/util.dart' show Setlet;
import 'abstract_value_domain.dart';
import 'debug.dart' as debug;
import 'engine.dart';
import 'type_graph_nodes.dart';

// A set of selectors we know do not escape the elements inside the
// list.
Set<String> doesNotEscapeListSet = Set<String>.from(const <String>[
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

Set<String> doesNotEscapeSetSet = Set<String>.from(const <String>[
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

  // From Set.
  'add',
  'addAll',
  'clear',
  'containsAll',
  'remove',
  'removeAll',
  'retainAll',
]);

Set<String> doesNotEscapeMapSet = Set<String>.from(const <String>[
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
abstract class TracerVisitor implements TypeInformationVisitor {
  final TypeInformation tracedType;
  final InferrerEngine inferrer;

  static const int MAX_ANALYSIS_COUNT =
      int.fromEnvironment('dart2js.tracing.limit', defaultValue: 32);
  // TODO(natebiggs): We allow null here to maintain current functionality
  // but we should verify we actually need to allow it.
  final Setlet<MemberEntity?> analyzedElements = Setlet();

  TracerVisitor(this.tracedType, this.inferrer);

  /// Work list that gets populated with [TypeInformation] that could
  /// contain the container.
  final List<TypeInformation> workList = [];

  /// Work list of lists to analyze after analyzing the users of a
  /// [TypeInformation]. We know the [tracedType] has been stored in these
  /// lists and we must check how it escapes from these lists.
  final List<ListTypeInformation> listsToAnalyze = [];

  /// Work list of sets to analyze after analyzing the users of a
  /// [TypeInformation]. We know the [tracedType] has been stored in these sets
  /// and we must check how it escapes from these sets.
  final List<SetTypeInformation> setsToAnalyze = [];

  /// Work list of maps to analyze after analyzing the users of a
  /// [TypeInformation]. We know the [tracedType] has been stored in these
  /// maps and we must check how it escapes from these maps.
  final List<MapTypeInformation> mapsToAnalyze = [];

  /// Work list of records to analyze after analyzing the users of a
  /// [TypeInformation]. We know the [tracedType] has been stored in these
  /// records and we must check how it escapes from these records.
  final List<RecordTypeInformation> recordsToAnalyze = [];

  final Setlet<TypeInformation> flowsInto = Setlet();

  // The current [TypeInformation] in the analysis.
  TypeInformation? currentUser;
  bool continueAnalyzing = true;

  void addNewEscapeInformation(TypeInformation info) {
    if (flowsInto.contains(info)) return;
    flowsInto.add(info);
    workList.add(info);
  }

  bool _wouldBeTooManyUsers(Set users) {
    int seenSoFar = analyzedElements.length;
    if (seenSoFar + users.length <= MAX_ANALYSIS_COUNT) return false;
    int actualWork = 0;
    for (TypeInformation user in users) {
      if (!analyzedElements.contains(user.owner)) {
        actualWork++;
        if (actualWork > MAX_ANALYSIS_COUNT - seenSoFar) return true;
      }
    }
    return false;
  }

  void analyze() {
    // Collect the [TypeInformation] where the list can flow in,
    // as well as the operations done on all these [TypeInformation]s.
    addNewEscapeInformation(tracedType);
    while (!workList.isEmpty) {
      final user = currentUser = workList.removeLast();
      if (_wouldBeTooManyUsers(user.users)) {
        bailout('Too many users');
        break;
      }
      for (final info in user.users) {
        analyzedElements.add(info.owner);
        info.accept(this);
      }
      while (!listsToAnalyze.isEmpty) {
        analyzeStoredIntoList(listsToAnalyze.removeLast());
      }
      while (setsToAnalyze.isNotEmpty) {
        analyzeStoredIntoSet(setsToAnalyze.removeLast());
      }
      while (!mapsToAnalyze.isEmpty) {
        analyzeStoredIntoMap(mapsToAnalyze.removeLast());
      }
      while (!recordsToAnalyze.isEmpty) {
        analyzeStoredIntoRecord(recordsToAnalyze.removeLast());
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

  @override
  void visitAwaitTypeInformation(AwaitTypeInformation info) {
    bailout("Passed through await");
  }

  @override
  void visitYieldTypeInformation(YieldTypeInformation info) {
    // TODO(29344): The enclosing sync*/async/async* method could have a
    // tracable TypeInformation for the Iterable / Future / Stream with an
    // element TypeInformation. Then YieldTypeInformation could connect the
    // source type information to the tracable element.
    bailout("Passed through yield");
  }

  @override
  void visitNarrowTypeInformation(NarrowTypeInformation info) {
    addNewEscapeInformation(info);
  }

  @override
  void visitPhiElementTypeInformation(PhiElementTypeInformation info) {
    addNewEscapeInformation(info);
  }

  @override
  void visitElementInContainerTypeInformation(
      ElementInContainerTypeInformation info) {
    addNewEscapeInformation(info);
  }

  @override
  void visitElementInSetTypeInformation(ElementInSetTypeInformation info) {
    addNewEscapeInformation(info);
  }

  @override
  void visitKeyInMapTypeInformation(KeyInMapTypeInformation info) {
    // We do not track the use of keys from a map, so we have to bail.
    bailout('Used as key in Map');
  }

  @override
  void visitRecordFieldAccessTypeInformation(
      RecordFieldAccessTypeInformation info) {}

  @override
  void visitValueInMapTypeInformation(ValueInMapTypeInformation info) {
    addNewEscapeInformation(info);
  }

  @override
  void visitListTypeInformation(ListTypeInformation info) {
    listsToAnalyze.add(info);
  }

  @override
  void visitSetTypeInformation(SetTypeInformation info) {
    setsToAnalyze.add(info);
  }

  @override
  void visitMapTypeInformation(MapTypeInformation info) {
    mapsToAnalyze.add(info);
  }

  @override
  void visitRecordTypeInformation(RecordTypeInformation info) {
    recordsToAnalyze.add(info);
  }

  @override
  void visitConcreteTypeInformation(ConcreteTypeInformation info) {}

  @override
  void visitStringLiteralTypeInformation(StringLiteralTypeInformation info) {}

  @override
  void visitBoolLiteralTypeInformation(BoolLiteralTypeInformation info) {}

  @override
  void visitClosureTypeInformation(ClosureTypeInformation info) {}

  @override
  void visitClosureCallSiteTypeInformation(
      ClosureCallSiteTypeInformation info) {}

  @override
  visitStaticCallSiteTypeInformation(StaticCallSiteTypeInformation info) {
    MemberEntity called = info.calledElement;
    TypeInformation inferred = inferrer.types.getInferredTypeOfMember(called);
    if (inferred == currentUser) {
      addNewEscapeInformation(info);
    }
  }

  void analyzeStoredIntoList(ListTypeInformation list) {
    inferrer.analyzeListAndEnqueue(list);
    if (list.bailedOut) {
      bailout('Stored in a list that bailed out');
    } else {
      list.flowsInto.forEach((TypeInformation flow) {
        flow.users.forEach((TypeInformation user) {
          if (user is DynamicCallSiteTypeInformation) {
            if (user.receiver != flow) return;
            if (inferrer.returnsListElementTypeSet.contains(user.selector)) {
              addNewEscapeInformation(user);
            } else if (!doesNotEscapeListSet.contains(user.selector?.name)) {
              bailout('Escape from a list via [${user.selector?.name}]');
            }
          }
        });
      });
    }
  }

  void analyzeStoredIntoSet(SetTypeInformation set) {
    inferrer.analyzeSetAndEnqueue(set);
    if (set.bailedOut) {
      bailout('Stored in a set that bailed out');
    } else {
      set.flowsInto.forEach((TypeInformation flow) {
        flow.users.forEach((TypeInformation user) {
          if (user is DynamicCallSiteTypeInformation) {
            if (user.receiver != flow) return;
            final selector = user.selector!;
            if (selector.isIndex) {
              addNewEscapeInformation(user);
            } else if (!doesNotEscapeSetSet.contains(selector.name)) {
              bailout('Escape from a set via [${selector.name}]');
            }
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
      map.flowsInto.forEach((TypeInformation flow) {
        flow.users.forEach((TypeInformation user) {
          if (user is DynamicCallSiteTypeInformation) {
            if (user.receiver != flow) return;
            final selector = user.selector!;
            if (selector.isIndex) {
              addNewEscapeInformation(user);
            } else if (!doesNotEscapeMapSet.contains(selector.name)) {
              bailout('Escape from a map via [${selector.name}]');
            }
          }
        });
      });
    }
  }

  void analyzeStoredIntoRecord(RecordTypeInformation record) {
    inferrer.analyzeRecordAndEnqueue(record);
    if (record.bailedOut) {
      bailout('Stored in a record that bailed out');
    } else {
      record.flowsInto.forEach((TypeInformation flow) {
        flow.users.forEach((TypeInformation user) {
          if (user is RecordFieldAccessTypeInformation) {
            final getterIndex =
                record.recordShape.indexOfGetterName(user.getterName);
            if (user.receiver == flow &&
                getterIndex >= 0 &&
                getterIndex < record.fieldTypes.length &&
                record.fieldTypes[getterIndex] == currentUser) {
              addNewEscapeInformation(user);
            }
          }
        });
      });
    }
  }

  /// Checks whether this is a call to a list adding method. The definition of
  /// what list adding means has to stay in sync with
  /// [isParameterOfListAddingMethod].
  bool mightAddToContainer(DynamicCallSiteTypeInformation info) {
    final arguments = info.arguments;
    if (arguments == null) return false;
    if (arguments.named.isNotEmpty) return false;
    String selectorName = info.selector!.name;
    List<TypeInformation> positionalArguments = arguments.positional;
    if (positionalArguments.length == 1) {
      return (selectorName == 'add' && currentUser == positionalArguments[0]);
    } else if (positionalArguments.length == 2) {
      return (selectorName == 'insert' &&
          currentUser == positionalArguments[1]);
    }
    return false;
  }

  bool isIndexSetArgument(DynamicCallSiteTypeInformation info, int index) {
    final selectorName = info.selector!.name;
    if (selectorName != '[]=') return false;
    assert(info.arguments!.length == 2);
    List<TypeInformation> arguments = info.arguments!.positional;
    return currentUser == arguments[index];
  }

  /// Checks whether the call site flows the currentUser to the key argument of
  /// an indexing setter. This must be kept in sync with
  /// [isParameterOfMapAddingMethod].
  bool isIndexSetKey(DynamicCallSiteTypeInformation info) {
    return isIndexSetArgument(info, 0);
  }

  /// Checks whether the call site flows the currentUser to the value argument
  /// of an indexing setter. This must be kept in sync with
  /// [isParameterOfListAddingMethod] and [isParameterOfMapAddingMethod].
  bool isIndexSetValue(DynamicCallSiteTypeInformation info) {
    return isIndexSetArgument(info, 1);
  }

  void bailoutIfReaches(bool predicate(ParameterTypeInformation e)) {
    for (var user in currentUser!.users) {
      if (user is ParameterTypeInformation) {
        if (predicate(user)) {
          bailout('Reached suppressed parameter without precise receiver');
          break;
        }
      }
    }
  }

  @override
  void visitDynamicCallSiteTypeInformation(
      DynamicCallSiteTypeInformation info) {
    void addsToContainer(AbstractValue mask) {
      final allocationNode =
          inferrer.abstractValueDomain.getAllocationNode(mask);
      if (allocationNode != null) {
        final list = inferrer.types.allocatedLists[allocationNode]
            as ListTypeInformation;
        listsToAnalyze.add(list);
      } else {
        // The [mask] is a union of two containers, and we lose track of where
        // these containers have been allocated at this point.
        bailout('Stored in too many containers');
      }
    }

    void addsToMapValue(AbstractValue mask) {
      final allocationNode =
          inferrer.abstractValueDomain.getAllocationNode(mask);
      if (allocationNode != null) {
        final map =
            inferrer.types.allocatedMaps[allocationNode] as MapTypeInformation;
        mapsToAnalyze.add(map);
      } else {
        // The [mask] is a union. See comment for [mask] above.
        bailout('Stored in too many maps');
      }
    }

    void addsToMapKey(AbstractValue mask) {
      // We do not track the use of keys from a map, so we have to bail.
      bailout('Used as key in Map');
    }

    // "a[...] = x" could be a list (container) or map assignment.
    if (isIndexSetValue(info)) {
      var receiverType = info.receiver.type;
      if (inferrer.abstractValueDomain.isContainer(receiverType)) {
        addsToContainer(receiverType);
      } else if (inferrer.abstractValueDomain.isMap(receiverType)) {
        addsToMapValue(receiverType);
      } else {
        // Not a container or map, so the targets could be any methods. There
        // are edges from the [currentUser] to the parameters of the targets, so
        // tracing will continue into the targets.  Tracing stops at parameters
        // that match the targets corresponding to the receiverTypes above (to
        // prevent imprecise results from tracing the implementation), so we
        // need compensate if one of the targets is in the target set. If there
        // is an edge to a parameter matching [isParameterOfListAddingMethod] or
        // [isParameterOfMapAddingMethod] then the traced value is being stored
        // into an untraced list or map.

        // TODO(sra): It would be more precise to specifically match the `value'
        // parameters of "operator []=".
        bailoutIfReaches(isParameterOfListAddingMethod);
        bailoutIfReaches(isParameterOfMapAddingMethod);
      }
    }

    // Could be:  m[x] = ...;
    if (isIndexSetKey(info)) {
      var receiverType = info.receiver.type;
      if (inferrer.abstractValueDomain.isMap(receiverType)) {
        addsToMapKey(receiverType);
      } else {
        bailoutIfReaches(isParameterOfListAddingMethod);
        bailoutIfReaches(isParameterOfMapAddingMethod);
      }
    }

    if (mightAddToContainer(info)) {
      var receiverType = info.receiver.type;
      if (inferrer.abstractValueDomain.isContainer(receiverType)) {
        addsToContainer(receiverType);
      } else {
        // Not a container, see note above.
        bailoutIfReaches(isParameterOfListAddingMethod);
      }
    }

    final arguments = info.arguments;
    if (info.targetsIncludeComplexNoSuchMethod(inferrer) &&
        arguments != null &&
        arguments.contains(currentUser)) {
      bailout('Passed to noSuchMethod');
    }

    final user = currentUser;
    if (user is MemberTypeInformation) {
      bool checkMember(MemberEntity member) {
        if (member == user.member) {
          addNewEscapeInformation(info);
          return false;
        }
        return true;
      }

      info.forEachConcreteTarget(inferrer.memberHierarchyBuilder, checkMember);
    }
  }

  /// Check whether element is the parameter of a list adding method.
  /// The definition of what a list adding method is has to stay in sync with
  /// [mightAddToContainer].
  bool isParameterOfListAddingMethod(ParameterTypeInformation parameterInfo) {
    if (!parameterInfo.isRegularParameter) return false;
    if (parameterInfo.method.enclosingClass !=
        inferrer.closedWorld.commonElements.jsArrayClass) {
      return false;
    }
    final name = parameterInfo.method.name;
    return (name == '[]=') || (name == 'add') || (name == 'insert');
  }

  /// Check whether element is the parameter of a list adding method.
  /// The definition of what a list adding method is has to stay in sync with
  /// [isIndexSetKey] and [isIndexSetValue].
  bool isParameterOfMapAddingMethod(ParameterTypeInformation parameterInfo) {
    if (!parameterInfo.isRegularParameter) return false;
    if (parameterInfo.method.enclosingClass !=
        inferrer.closedWorld.commonElements.mapLiteralClass) {
      return false;
    }
    final name = parameterInfo.method.name;
    return (name == '[]=');
  }

  bool isClosure(MemberEntity element) {
    if (!element.isFunction) return false;

    /// Creating an instance of a class that implements [Function] also
    /// closurizes the corresponding [call] member. We do not currently
    /// track these, thus the check for [isClosurized] on such a method will
    /// return false. Instead we catch that case here for now.
    // TODO(herhut): Handle creation of closures from instances of Function.
    if (element.isInstanceMember && element.name == Identifiers.call) {
      return true;
    }
    final cls = element.enclosingClass;
    return cls != null && cls.isClosure;
  }

  bool isAsync(MemberEntity element) =>
      element is FunctionEntity && element.asyncMarker == AsyncMarker.ASYNC;

  @override
  void visitMemberTypeInformation(MemberTypeInformation info) {
    if (info.isClosurized) {
      bailout('Returned from a closurized method');
    }
    if (isClosure(info.member)) {
      bailout('Returned from a closure');
    }
    if (isAsync(info.member)) {
      bailout('Returned from an async method');
    }

    final member = info.member;
    if (member is FieldEntity &&
        !inferrer.canFieldBeUsedForGlobalOptimizations(member)) {
      bailout('Escape to code that has special backend treatment');
    }
    addNewEscapeInformation(info);
  }

  @override
  void visitParameterTypeInformation(ParameterTypeInformation info) {
    if (inferrer.closedWorld.nativeData.isNativeMember(info.method)) {
      bailout('Passed to a native method');
    }
    if (!inferrer
        .canFunctionParametersBeUsedForGlobalOptimizations(info.method)) {
      bailout('Escape to code that has special backend treatment');
    }
    if (isParameterOfListAddingMethod(info) ||
        isParameterOfMapAddingMethod(info)) {
      // These elements are being handled in
      // [visitDynamicCallSiteTypeInformation].
      return;
    }
    addNewEscapeInformation(info);
  }

  bool dynamicCallTargetsNonFunction(DynamicCallSiteTypeInformation info) {
    return info.targets.any((target) => inferrer.memberHierarchyBuilder
        .anyTargetMember(target, (element) => !element.isFunction));
  }
}
