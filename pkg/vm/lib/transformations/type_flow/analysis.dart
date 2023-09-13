// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Global type flow analysis.

import 'dart:collection';
import 'dart:core' hide Type;
import 'dart:math' show max;

import 'package:kernel/target/targets.dart' show Target;
import 'package:kernel/ast.dart' hide Statement, StatementVisitor;
import 'package:kernel/class_hierarchy.dart' show ClosedWorldClassHierarchy;
import 'package:kernel/library_index.dart' show LibraryIndex;
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/type_environment.dart';
import 'package:vm/transformations/pragma.dart';

import 'calls.dart';
import 'native_code.dart';
import 'protobuf_handler.dart' show ProtobufHandler;
import 'summary.dart';
import 'summary_collector.dart';
import 'types.dart';
import 'utils.dart';

// TODO(alexmarkov)
// Unordered list of various improvements in type flow analysis,
// organized in several categories:
//
// === Correctness ===
// * Verify incremental re-calculation by fresh analysis starting with known
//   allocated classes.
//
// === Precision ===
// * Handle '==' with null.
// * Special type inference rules for binary int operators.
// * Support function types, better handle closures.
// * Support generic types: substitution, passing type arguments. Figure out
//   when generic type should be approximated.
//
// === Efficiency of the analysis ===
// * Add benchmark to measure analysis time continuously.
// * Figure out better strategy of processing an invocation if its result is
//   not used. Consider creating summaries eagerly (to discover allocated
//   classes early) but analyzing them lazily.
//

/// Maintains set of dependent invocations.
class _DependencyTracker {
  Set<_Invocation>? _dependentInvocations;

  void addDependentInvocation(_Invocation invocation) {
    if (!identical(invocation, this)) {
      var dependentInvocations = _dependentInvocations;
      if (dependentInvocations == null) {
        _dependentInvocations = dependentInvocations = Set<_Invocation>();
      }
      dependentInvocations.add(invocation);
    }
  }

  void invalidateDependentInvocations(_WorkList workList) {
    final dependentInvocations = _dependentInvocations;
    if (dependentInvocations != null) {
      if (kPrintTrace) {
        tracePrint('   - CHANGED: $this');
        for (var di in dependentInvocations) {
          tracePrint('     - invalidating $di');
        }
      }
      dependentInvocations.forEach(workList.invalidateInvocation);
    }
  }
}

/// _Invocation class represents the in-flight invocation detached from a
/// particular call site, e.g. it is a selector and arguments.
/// This is the basic unit of processing in type flow analysis.
/// Call sites calling the same method with the same argument types
/// may reuse results of the analysis through the same _Invocation instance.
abstract base class _Invocation extends _DependencyTracker
    with LinkedListEntry<_Invocation> {
  final Selector selector;
  final Args<Type> args;

  Type? result;

  /// Result of the invocation calculated before invocation was invalidated.
  /// Used to check if the re-analysis of the invocation yields the same
  /// result or not (to avoid invalidation of callers if result hasn't changed).
  Type? invalidatedResult;

  /// Number of times result of this invocation was invalidated.
  int invalidationCounter = 0;

  /// Whether a call-site directed to this invocation can call through the
  /// unchecked entry-point.
  bool typeChecksNeeded = false;

  /// If an invocation is invalidated more than [invalidationLimit] times,
  /// its result is saturated in order to guarantee convergence.
  static const int invalidationLimit = 1000;

  _Invocation(this.selector, this.args);

  /// Initialize invocation before it is cached and processed.
  void init() {}

  Type process(TypeFlowAnalysis typeFlowAnalysis);

  /// Returns result of this invocation if its available without
  /// further analysis, or `null` if it's not available.
  /// Used for recursive calls while this invocation is being processed.
  Type? get resultForRecursiveInvocation => result;

  /// Use [type] as a current computed result of this invocation.
  /// If this invocation was invalidated, and the invalidated result is
  /// different, then invalidate all dependent invocations as well.
  /// Result type may be saturated if this invocation was invalidated
  /// too many times.
  void setResult(TypeFlowAnalysis typeFlowAnalysis, Type type) {
    result = type;

    if (invalidatedResult != null) {
      if (invalidatedResult != result) {
        invalidateDependentInvocations(typeFlowAnalysis.workList);

        invalidationCounter++;
        Statistics.maxInvalidationsPerInvocation =
            max(Statistics.maxInvalidationsPerInvocation, invalidationCounter);
        // In rare cases, loops in dependencies and approximation of
        // recursive invocations may cause infinite bouncing of result
        // types. To prevent infinite looping and guarantee convergence of
        // the analysis, result is saturated after invocation is invalidated
        // at least [_Invocation.invalidationLimit] times.
        if (invalidationCounter > _Invocation.invalidationLimit) {
          result = result!
              .union(invalidatedResult!, typeFlowAnalysis.hierarchyCache);
        }
      }
      invalidatedResult = null;
    }
  }

  // Only take selector and args into account as _Invocation objects
  // are cached in _InvocationsCache using selector and args as a key.
  @override
  bool operator ==(other) =>
      identical(this, other) ||
      (other is _Invocation) &&
          (this.selector == other.selector) &&
          (this.args == other.args);

  @override
  int get hashCode => (selector.hashCode ^ args.hashCode + 31) & kHashMask;

  @override
  String toString() => "_Invocation $selector $args";

  /// Processes noSuchMethod() invocation and returns its result.
  /// Used if target is not found or number of arguments is incorrect.
  Type _processNoSuchMethod(Type receiver, TypeFlowAnalysis typeFlowAnalysis) {
    tracePrint("Processing noSuchMethod for receiver $receiver");

    final nsmSelector = new InterfaceSelector(
        typeFlowAnalysis.hierarchyCache.objectNoSuchMethod,
        callKind: CallKind.Method);

    final nsmArgs = new Args<Type>([
      receiver,
      typeFlowAnalysis.hierarchyCache.fromStaticType(
          typeFlowAnalysis.coreTypes.invocationLegacyRawType, false)
    ]);

    final nsmInvocation =
        typeFlowAnalysis._invocationsCache.getInvocation(nsmSelector, nsmArgs);

    final Type type =
        typeFlowAnalysis.workList.processInvocation(nsmInvocation);

    // Result of this invocation depends on the result of noSuchMethod
    // invocation.
    nsmInvocation.addDependentInvocation(this);

    return type;
  }
}

final class _DirectInvocation extends _Invocation {
  _DirectInvocation(DirectSelector selector, Args<Type> args)
      : super(selector, args);

  @override
  void init() {
    // We don't emit [TypeCheck] statements for bounds checks of type
    // parameters, so if there are any type parameters, we must assume
    // they could fail bounds checks.
    //
    // TODO(sjindel): Use [TypeCheck] to avoid bounds checks.
    final function = selector.member!.function;
    if (function != null) {
      for (TypeParameter tp in function.typeParameters) {
        if (tp.isCovariantByClass) {
          typeChecksNeeded = true;
        }
      }
    } else {
      Field field = selector.member as Field;
      if (selector.callKind == CallKind.PropertySet) {
        // TODO(dartbug.com/40615): Use TFA results to improve this criterion.
        if (field.isCovariantByClass) {
          typeChecksNeeded = true;
        }
      }
    }
  }

  @override
  Type process(TypeFlowAnalysis typeFlowAnalysis) {
    assert(typeFlowAnalysis.currentInvocation == this);

    if (selector.member is Field) {
      return _processField(typeFlowAnalysis);
    } else {
      return _processFunction(typeFlowAnalysis);
    }
  }

  Type _processField(TypeFlowAnalysis typeFlowAnalysis) {
    final Field field = selector.member as Field;
    final int firstParamIndex = field.isStatic ? 0 : 1;
    final _FieldValue fieldValue = typeFlowAnalysis.getFieldValue(field);

    switch (selector.callKind) {
      case CallKind.PropertyGet:
        assert(args.values.length == firstParamIndex);
        assert(args.names.isEmpty);
        fieldValue.isGetterUsed = true;
        return fieldValue.getValue(
            typeFlowAnalysis, field.isStatic ? null : args.values[0]);

      case CallKind.PropertySet:
      case CallKind.SetFieldInConstructor:
        assert(args.values.length == firstParamIndex + 1);
        assert(args.names.isEmpty);
        if (selector.callKind == CallKind.PropertySet) {
          fieldValue.isSetterUsed = true;
        }
        final Type setterArg = args.values[firstParamIndex];
        fieldValue.setValue(
            setterArg, typeFlowAnalysis, field.isStatic ? null : args.receiver);
        return emptyType;

      case CallKind.Method:
        // Call via field.
        // TODO(alexmarkov): support function types and use inferred type
        // to get more precise return type.
        fieldValue.isGetterUsed = true;
        final receiver = fieldValue.getValue(
            typeFlowAnalysis, field.isStatic ? null : args.values[0]);
        if (receiver != emptyType) {
          typeFlowAnalysis.applyCall(/* callSite = */ null,
              DynamicSelector.kCall, new Args.withReceiver(args, receiver),
              isResultUsed: false, processImmediately: false);
        }
        return nullableAnyType;

      case CallKind.FieldInitializer:
        assert(args.values.length == firstParamIndex);
        assert(args.names.isEmpty);
        Type initializerResult = typeFlowAnalysis
            .getSummary(field)
            .apply(args, typeFlowAnalysis.hierarchyCache, typeFlowAnalysis);
        if (field.isStatic &&
            !field.isConst &&
            initializerResult is! NullableType) {
          // If initializer of a static field throws an exception,
          // then field is initialized with null value.
          // TODO(alexmarkov): Try to prove that static field initializer
          // does not throw exception.
          initializerResult = initializerResult.nullable();
        }
        if (kPrintTrace) {
          tracePrint("Result of ${field} initializer: $initializerResult");
        }
        fieldValue.setValue(initializerResult, typeFlowAnalysis,
            field.isStatic ? null : args.receiver);
        fieldValue.isInitialized = true;
        return emptyType;
    }
  }

  Type _processFunction(TypeFlowAnalysis typeFlowAnalysis) {
    final Member member = selector.member!;
    if (selector.memberAgreesToCallKind(member)) {
      if (_argumentsValid()) {
        final summary = typeFlowAnalysis.getSummary(member);
        // If result type is known upfront (doesn't depend on the flow),
        // set it eagerly so recursive invocations are able to use it.
        final summaryResult = summary.result;
        if (summaryResult is Type &&
            !typeFlowAnalysis.workList._isPending(this)) {
          assert(result == null || result == summaryResult);
          setResult(typeFlowAnalysis, summaryResult);
        }
        return summary.apply(
            args, typeFlowAnalysis.hierarchyCache, typeFlowAnalysis);
      } else {
        assert(selector.callKind == CallKind.Method);
        return _processNoSuchMethod(args.receiver, typeFlowAnalysis);
      }
    } else {
      if (selector.callKind == CallKind.PropertyGet) {
        // Tear-off.
        // TODO(alexmarkov): capture receiver type
        assert((member is Procedure) && !member.isGetter && !member.isSetter);
        typeFlowAnalysis.addRawCall(new DirectSelector(member));
        typeFlowAnalysis._tearOffTaken.add(member);
        return nullableAnyType;
      } else {
        // Call via getter.
        // TODO(alexmarkov): capture receiver type
        assert((selector.callKind == CallKind.Method) &&
            (member is Procedure) &&
            member.isGetter);
        typeFlowAnalysis.addRawCall(
            new DirectSelector(member, callKind: CallKind.PropertyGet));
        typeFlowAnalysis.applyCall(/* callSite = */ null, DynamicSelector.kCall,
            new Args.withReceiver(args, nullableAnyType),
            isResultUsed: false, processImmediately: false);
        return nullableAnyType;
      }
    }
  }

  bool _argumentsValid() {
    final member = selector.member!;
    final function = member.function!;
    final int positionalArguments = args.positionalCount;

    final int firstParamIndex =
        numTypeParams(member) + (hasReceiverArg(member) ? 1 : 0);
    final int requiredParameters =
        firstParamIndex + function.requiredParameterCount;
    if (positionalArguments < requiredParameters) {
      return false;
    }

    final int positionalParameters =
        firstParamIndex + function.positionalParameters.length;
    if (positionalArguments > positionalParameters) {
      return false;
    }

    if (args.names.isNotEmpty) {
      // TODO(dartbug.com/32292): make sure parameters are sorted in kernel AST
      // and iterate parameters in parallel, without lookup.
      for (var name in args.names) {
        if (findNamedParameter(function, name) == null) {
          return false;
        }
      }
    }

    return true;
  }
}

final class _DispatchableInvocation extends _Invocation {
  bool _isPolymorphic = false;
  Set<Call>? _callSites; // Populated only if not polymorphic.
  Member? _monomorphicTarget;
  _DirectInvocation? _monomorphicDirectInvocation;

  @override
  set typeChecksNeeded(bool value) {
    if (typeChecksNeeded) return;
    if (value) {
      super.typeChecksNeeded = true;
      _notifyCallSites();
    }
  }

  /// Marker for noSuchMethod() invocation in the map of invocation targets.
  static final Member kNoSuchMethodMarker = new Procedure(
      new Name('noSuchMethod&&'), ProcedureKind.Method, new FunctionNode(null),
      fileUri: dummyUri);

  _DispatchableInvocation(Selector selector, Args<Type> args)
      : super(selector, args) {
    assert(selector is! DirectSelector);
  }

  @override
  Type process(TypeFlowAnalysis typeFlowAnalysis) {
    assert(typeFlowAnalysis.currentInvocation == this);

    // Collect all possible targets for this invocation,
    // along with more accurate receiver types for each target.
    final targets = <Member, _ReceiverTypeBuilder>{};
    _collectTargetsForReceiverType(args.receiver, targets, typeFlowAnalysis);

    // Calculate result as a union of results of direct invocations
    // corresponding to each target.
    Type result = emptyType;

    if (targets.isEmpty) {
      tracePrint("No targets...");
    } else {
      if (targets.length == 1) {
        final target = targets.keys.single;
        if (target != kNoSuchMethodMarker) {
          _setMonomorphicTarget(target);
        } else {
          _setPolymorphic();
        }
      } else {
        _setPolymorphic();
      }

      targets
          .forEach((Member target, _ReceiverTypeBuilder receiverTypeBuilder) {
        Type receiver = receiverTypeBuilder.toType();
        Type type;

        if (target == kNoSuchMethodMarker) {
          // Non-dynamic call-sites must hit NSM-forwarders in Dart 2.
          assert(selector is DynamicSelector);
          type = _processNoSuchMethod(receiver, typeFlowAnalysis);
        } else {
          final directSelector =
              new DirectSelector(target, callKind: selector.callKind);

          Args<Type> directArgs = args;
          if (args.receiver != receiver) {
            directArgs = new Args<Type>.withReceiver(args, receiver);
          }

          final directInvocation = typeFlowAnalysis._invocationsCache
              .getInvocation(directSelector, directArgs);

          if (!_isPolymorphic) {
            assert(target == _monomorphicTarget);
            _monomorphicDirectInvocation =
                directInvocation as _DirectInvocation;
          }

          type = typeFlowAnalysis.workList.processInvocation(directInvocation);
          if (kPrintTrace) {
            tracePrint('Dispatch: $directInvocation, result: $type');
          }

          // Result of this invocation depends on the results of direct
          // invocations corresponding to each target.
          directInvocation.addDependentInvocation(this);

          if (selector.callKind != CallKind.PropertyGet) {
            if (selector is DynamicSelector) {
              typeFlowAnalysis._methodsAndSettersCalledDynamically.add(target);
            } else if (selector is VirtualSelector) {
              typeFlowAnalysis._calledViaThis.add(target);
            } else {
              typeFlowAnalysis._calledViaInterfaceSelector.add(target);
            }
          } else {
            if (selector is DynamicSelector) {
              typeFlowAnalysis._gettersCalledDynamically.add(target);
            }
          }

          if (directInvocation.typeChecksNeeded) {
            typeChecksNeeded = true;
          }
        }

        result = result.union(type, typeFlowAnalysis.hierarchyCache);
      });
    }

    // TODO(alexmarkov): handle closures more precisely
    if ((selector is DynamicSelector) && (selector.name.text == "call")) {
      tracePrint("Possible closure call, result is dynamic");
      result = nullableAnyType;
    }

    return result;
  }

  void _collectTargetsForReceiverType(
      Type receiver,
      Map<Member, _ReceiverTypeBuilder> targets,
      TypeFlowAnalysis typeFlowAnalysis) {
    assert(receiver != emptyType); // should be filtered earlier

    final bool isNullableReceiver = receiver is NullableType;
    if (isNullableReceiver) {
      receiver = receiver.baseType;
      assert(receiver is! NullableType);
    }

    if (selector is InterfaceSelector) {
      final staticReceiverType = typeFlowAnalysis.hierarchyCache
          .getTFClass(selector.member!.enclosingClass!)
          .coneType;
      receiver = receiver.intersection(
          staticReceiverType, typeFlowAnalysis.hierarchyCache);
      assert(receiver is! NullableType);

      if (kPrintTrace) {
        tracePrint("Narrowed down receiver type: $receiver");
      }
    }

    if (receiver is ConeType) {
      // Specialization of type cone will add dependency of the current
      // invocation to the receiver class. A new allocated class discovered
      // in the receiver cone will invalidate this invocation.
      receiver = typeFlowAnalysis.hierarchyCache
          .specializeTypeCone(receiver.cls, allowWideCone: false);
    }

    assert(targets.isEmpty);

    if (receiver is ConcreteType) {
      _collectTargetsForConcreteType(receiver, targets, typeFlowAnalysis);
    } else if (receiver is SetType) {
      for (var type in receiver.types) {
        _collectTargetsForConcreteType(type, targets, typeFlowAnalysis);
      }
    } else if (receiver is AnyInstanceType) {
      _collectTargetsForSelector(targets, typeFlowAnalysis);
    } else {
      assert(receiver is EmptyType);
    }

    if (isNullableReceiver) {
      _collectTargetsForNull(targets, typeFlowAnalysis);
    }
  }

  void _collectTargetsForNull(Map<Member, _ReceiverTypeBuilder> targets,
      TypeFlowAnalysis typeFlowAnalysis) {
    final Member? target = typeFlowAnalysis.hierarchyCache._nullTFClass
        .getDispatchTarget(selector);
    if (target != null) {
      if (kPrintTrace) {
        tracePrint("Found $target for null receiver");
      }
      _getReceiverTypeBuilder(targets, target).addNull();
    }
  }

  void _collectTargetsForConcreteType(
      ConcreteType receiver,
      Map<Member, _ReceiverTypeBuilder> targets,
      TypeFlowAnalysis typeFlowAnalysis) {
    final cls = receiver.cls as _TFClassImpl;

    Member? target = cls.getDispatchTarget(selector);

    if (target != null) {
      if (kPrintTrace) {
        tracePrint("Found $target for concrete receiver $receiver");
      }
      _getReceiverTypeBuilder(targets, target).addConcreteType(receiver);
    } else {
      if (typeFlowAnalysis.hierarchyCache.hasNonTrivialNoSuchMethod(cls)) {
        if (kPrintTrace) {
          tracePrint("Found non-trivial noSuchMethod for receiver $receiver");
        }
        _getReceiverTypeBuilder(targets, kNoSuchMethodMarker)
            .addConcreteType(receiver);
      } else if (selector is DynamicSelector) {
        if (kPrintTrace) {
          tracePrint(
              "Dynamic selector - adding noSuchMethod for receiver $receiver");
        }
        _getReceiverTypeBuilder(targets, kNoSuchMethodMarker)
            .addConcreteType(receiver);
      } else {
        if (kPrintTrace) {
          tracePrint("Target is not found for receiver $receiver");
        }
      }
    }
  }

  void _collectTargetsForSelector(Map<Member, _ReceiverTypeBuilder> targets,
      TypeFlowAnalysis typeFlowAnalysis) {
    Selector selector = this.selector;
    if (selector is InterfaceSelector) {
      // TODO(alexmarkov): support generic types and make sure inferred types
      // are always same or better than static types.
//      assert(selector.member.enclosingClass ==
//          _typeFlowAnalysis.coreTypes.objectClass);
      selector = new DynamicSelector(selector.callKind, selector.name);
    }

    final receiver = args.receiver;
    final _DynamicTargetSet dynamicTargetSet = typeFlowAnalysis.hierarchyCache
        .getDynamicTargetSet(selector as DynamicSelector);

    dynamicTargetSet.addDependentInvocation(this);

    assert(targets.isEmpty);
    for (Member target in dynamicTargetSet.targets) {
      _getReceiverTypeBuilder(targets, target).addType(receiver);
    }

    // Conservatively include noSuchMethod if selector is not from Object,
    // as class might miss the implementation.
    if (!dynamicTargetSet.isObjectMember) {
      _getReceiverTypeBuilder(targets, kNoSuchMethodMarker).addType(receiver);
    }
  }

  _ReceiverTypeBuilder _getReceiverTypeBuilder(
          Map<Member, _ReceiverTypeBuilder> targets, Member member) =>
      targets[member] ??= new _ReceiverTypeBuilder();

  void _setPolymorphic() {
    if (!_isPolymorphic) {
      _isPolymorphic = true;
      _monomorphicTarget = null;
      typeChecksNeeded = true;

      _notifyCallSites();
      _callSites = null;
    }
  }

  void _setMonomorphicTarget(Member target) {
    assert(!_isPolymorphic);
    assert((_monomorphicTarget == null) || (_monomorphicTarget == target));
    _monomorphicTarget = target;

    _notifyCallSites();
  }

  void addCallSite(Call callSite) {
    _notifyCallSite(callSite);
    if (!callSite.isPolymorphic) {
      (_callSites ??= new Set<Call>()).add(callSite);
    }
  }

  /// Notify call site about changes in polymorphism or checkedness of this
  /// invocation.
  void _notifyCallSite(Call callSite) {
    if (_isPolymorphic) {
      callSite.setPolymorphic();
    } else {
      final monomorphicTarget = _monomorphicTarget;
      if (monomorphicTarget != null) {
        callSite.addTarget(monomorphicTarget);
      }
    }

    if (typeChecksNeeded) {
      callSite.setUseCheckedEntry();
    }
  }

  /// Notify call sites monitoring this invocation about changes in
  /// polymorphism of this invocation.
  void _notifyCallSites() {
    final callSites = _callSites;
    if (callSites != null) {
      callSites.forEach(_notifyCallSite);
    }
  }

  @override
  Type? get resultForRecursiveInvocation {
    if (result != null) {
      return result;
    }
    final monomorphicDirectInvocation = _monomorphicDirectInvocation;
    if (monomorphicDirectInvocation != null) {
      return monomorphicDirectInvocation.resultForRecursiveInvocation;
    }
    return null;
  }
}

/// Efficient builder of receiver type.
///
/// Supports the following operations:
/// 1) Add 1..N concrete types ordered by classId OR add 1 arbitrary type.
/// 2) Make type nullable.
class _ReceiverTypeBuilder {
  Type? _type;
  List<ConcreteType>? _list;
  bool _nullable = false;

  /// Appends a ConcreteType. May be called multiple times.
  /// Should not be used in conjunction with [addType].
  void addConcreteType(ConcreteType type) {
    final list = _list;
    if (list == null) {
      final Type? t = _type;
      if (t == null) {
        _type = type;
        return;
      }
      final ct = t as ConcreteType;

      assert(ct != type);
      assert(ct.cls.id < type.cls.id);
      _list = <ConcreteType>[ct, type];
      _type = null;
    } else {
      assert(list.last.cls.id < type.cls.id);
      list.add(type);
    }
  }

  /// Appends an arbitrary Type. May be called only once.
  /// Should not be used in conjunction with [addConcreteType].
  void addType(Type type) {
    assert(_type == null && _list == null);
    _type = type;
  }

  /// Makes the resulting type nullable.
  void addNull() {
    _nullable = true;
  }

  /// Returns union of added types.
  Type toType() {
    Type? t = _type;
    if (t == null) {
      final list = _list;
      if (list == null) {
        t = emptyType;
      } else {
        t = SetType(list);
      }
    } else {
      assert(_list == null);
    }

    if (_nullable) {
      t = t.nullable();
    }

    return t;
  }
}

/// Keeps track of number of cached [_Invocation] objects with
/// a particular selector and provides approximation if needed.
class _SelectorApproximation {
  /// Approximation [_Invocation] with raw arguments is created and used
  /// after number of [_Invocation] objects with same selector but
  /// different arguments reaches this limit.
  static const int maxInvocationsPerSelector = 5000;

  /// [_DirectInvocation] can be approximated with raw arguments
  /// if number of operations in its summary exceeds this threshold.
  static const int largeSummarySize = 300;

  /// If summary exceeds [largeSummarySize] and number of
  /// [_DirectInvocation] objects with same selector but
  /// different arguments exceeds this limit, then approximate
  /// [_DirectInvocation] with raw arguments is created and used.
  static const int maxDirectInvocationsPerSelector = 10;

  int count = 0;
  _Invocation? approximation;
}

/// Maintains ([Selector], [Args]) => [_Invocation] cache.
/// Invocations are cached in order to reuse previously calculated result.
class _InvocationsCache {
  final TypeFlowAnalysis _typeFlowAnalysis;
  final Set<_Invocation> _invocations = new Set<_Invocation>();
  final Map<InterfaceSelector, _SelectorApproximation>
      _interfaceSelectorApproximations =
      <InterfaceSelector, _SelectorApproximation>{};
  final Map<DirectSelector, _SelectorApproximation>
      _directSelectorApproximations =
      <DirectSelector, _SelectorApproximation>{};

  _InvocationsCache(this._typeFlowAnalysis);

  _Invocation getInvocation(Selector selector, Args<Type> args) {
    ++Statistics.invocationsQueriedInCache;
    final bool isDirectSelector = (selector is DirectSelector);
    _Invocation invocation = isDirectSelector
        ? new _DirectInvocation(selector, args)
        : new _DispatchableInvocation(selector, args);
    _Invocation? result = _invocations.lookup(invocation);
    if (result != null) {
      return result;
    }

    if (isDirectSelector) {
      // If there is a selector approximation (meaning the summary is large)
      // then number of distinct invocations per selector should be limited
      // in order to bound analysis time.

      final sa = _directSelectorApproximations[selector];
      if (sa != null) {
        if (sa.count >=
            _SelectorApproximation.maxDirectInvocationsPerSelector) {
          _Invocation? approximation = sa.approximation;
          if (approximation == null) {
            final rawArgs =
                _typeFlowAnalysis.summaryCollector.rawArguments(selector);
            sa.approximation =
                approximation = _DirectInvocation(selector, rawArgs);
            approximation.init();
            Statistics.approximateDirectInvocationsCreated++;
          }
          Statistics.approximateDirectInvocationsUsed++;
          return approximation;
        }
        ++sa.count;
      }
    } else if (selector is InterfaceSelector) {
      // Detect if there are too many invocations per selector. In such case,
      // approximate extra invocations with a single invocation with raw
      // arguments.

      final sa = (_interfaceSelectorApproximations[selector] ??=
          new _SelectorApproximation());

      if (sa.count >= _SelectorApproximation.maxInvocationsPerSelector) {
        _Invocation? approximation = sa.approximation;
        if (approximation == null) {
          final rawArgs =
              _typeFlowAnalysis.summaryCollector.rawArguments(selector);
          sa.approximation =
              approximation = _DispatchableInvocation(selector, rawArgs);
          approximation.init();
          Statistics.approximateInterfaceInvocationsCreated++;
        }
        Statistics.approximateInterfaceInvocationsUsed++;
        return approximation;
      }

      ++sa.count;
      Statistics.maxInvocationsCachedPerSelector =
          max(Statistics.maxInvocationsCachedPerSelector, sa.count);
    }

    invocation.init();
    bool added = _invocations.add(invocation);
    assert(added);
    ++Statistics.invocationsAddedToCache;
    return invocation;
  }

  void addDirectSelectorApproximation(DirectSelector selector) {
    _directSelectorApproximations[selector] ??= new _SelectorApproximation();
  }
}

class _FieldValue extends _DependencyTracker {
  final Field field;
  final Type staticType;
  final Summary? typeGuardSummary;
  Type value = emptyType;

  /// Flag indicating if field initializer was executed.
  bool isInitialized = false;

  /// Flag indicating if field getter was executed.
  bool isGetterUsed = false;

  /// Flag indicating if field setter was executed.
  bool isSetterUsed = false;

  _FieldValue(this.field, this.typeGuardSummary, TypesBuilder typesBuilder)
      : staticType = typesBuilder.fromStaticType(field.type, true) {
    if (field.initializer == null && _isDefaultValueOfFieldObservable()) {
      value = nullableEmptyType;
    }
  }

  bool _isDefaultValueOfFieldObservable() {
    if (field.isLate) {
      return false;
    }

    if (field.isStatic) {
      return true;
    }

    final enclosingClass = field.enclosingClass!;

    // Default value is not observable if every generative constructor
    // is redirecting or initializes the field.
    return !enclosingClass.constructors.every((Constructor constr) {
      for (var initializer in constr.initializers) {
        if ((initializer is RedirectingInitializer) ||
            ((initializer is FieldInitializer) &&
                (initializer.field == field))) {
          return true;
        }
      }
      return false;
    });
  }

  void ensureInitialized(
      TypeFlowAnalysis typeFlowAnalysis, Type? receiverType) {
    if (field.initializer != null) {
      assert(field.isStatic == (receiverType == null));
      final args = !field.isStatic ? <Type>[receiverType!] : const <Type>[];
      final initializerInvocation = typeFlowAnalysis._invocationsCache
          .getInvocation(
              new DirectSelector(field, callKind: CallKind.FieldInitializer),
              new Args<Type>(args));

      // It may update the field value.
      typeFlowAnalysis.workList.processInvocation(initializerInvocation);
    }
  }

  Type getValue(TypeFlowAnalysis typeFlowAnalysis, Type? receiverType) {
    ensureInitialized(typeFlowAnalysis, receiverType);
    addDependentInvocation(typeFlowAnalysis.currentInvocation);
    final typeGuardSummary = this.typeGuardSummary;
    return (typeGuardSummary != null)
        ? typeGuardSummary.apply(Args([receiverType!, value]),
            typeFlowAnalysis.hierarchyCache, typeFlowAnalysis)
        : value;
  }

  void setValue(
      Type newValue, TypeFlowAnalysis typeFlowAnalysis, Type? receiverType) {
    // Make sure type cones are specialized before putting them into field
    // value, in order to ensure that dependency is established between
    // cone's base type and corresponding field setter.
    //
    // This ensures correct invalidation in the following scenario:
    //
    // 1) setValue(Cone(X)).
    //    It sets field value to Cone(X).
    //
    // 2) setValue(Y).
    //    It calculates Cone(X) U Y, specializing Cone(X).
    //    This establishes class X --> setter(Y)  dependency.
    //    If X does not have allocated subclasses, then Cone(X) is specialized
    //    to Empty and the new field value is Y.
    //
    // 3) A new allocated subtype is added to X.
    //    This invalidates setter(Y). However, recalculation of setter(Y)
    //    does not yield correct field value, as value calculated on step 1 is
    //    already lost, and repeating setValue(Y) will not change field value.
    //
    // The eager specialization of field value ensures that specialization
    // will happen on step 1 and dependency class X --> setter(Cone(X))
    // is established.
    //
    final hierarchy = typeFlowAnalysis.hierarchyCache;
    // TODO(sjindel/tfa): Perform narrowing inside 'TypeCheck'.
    final typeGuardSummary = this.typeGuardSummary;
    final narrowedNewValue = typeGuardSummary != null
        ? typeGuardSummary
            .apply(new Args([receiverType!, newValue]), hierarchy,
                typeFlowAnalysis)
            .intersection(staticType, hierarchy)
        : newValue.specialize(hierarchy).intersection(staticType, hierarchy);
    Type newType =
        value.union(narrowedNewValue, hierarchy).specialize(hierarchy);
    assert(newType.isSpecialized);

    if (newType != value) {
      if (kPrintTrace) {
        tracePrint("Set field $field value $newType");
      }
      invalidateDependentInvocations(typeFlowAnalysis.workList);
      value = newType;
    }
  }

  @override
  String toString() => "_FieldValue $field => $value";
}

class _SharedVariableImpl extends _DependencyTracker implements SharedVariable {
  final String name;
  Type value = emptyType;

  _SharedVariableImpl(VariableDeclaration decl) : name = decl.name ?? '__tmp';

  @override
  Type getValue(
      TypeHierarchy typeHierarchy, covariant TypeFlowAnalysis callHandler) {
    addDependentInvocation(callHandler.currentInvocation);
    return value;
  }

  @override
  void setValue(
      Type newValue, TypeHierarchy hierarchy, CallHandler callHandler) {
    // Make sure type cones are specialized before putting them into shared
    // variables, in order to ensure that dependency is established between
    // cone's base type and corresponding invocation accessing variable.
    newValue = value.union(newValue, hierarchy).specialize(hierarchy);
    assert(newValue.isSpecialized);

    if (newValue != value) {
      invalidateDependentInvocations(
          (callHandler as TypeFlowAnalysis).workList);
      value = newValue;
    }
  }

  @override
  String toString() => name;
}

class _DynamicTargetSet extends _DependencyTracker {
  final DynamicSelector selector;
  final Set<Member> targets = new Set<Member>();
  final bool isObjectMember;

  _DynamicTargetSet(this.selector, this.isObjectMember);
}

class _TFClassImpl extends TFClass {
  /// Maximum number of concrete types to use when calculating
  /// subtype cone specialization. If number of allocated types
  /// exceeds this constant, then WideConeType approximation is used.
  static const int maxAllocatedTypesInSetSpecializations = 128;

  final _TFClassImpl? superclass;
  final Set<_TFClassImpl> supertypes; // List of super-types including this.
  final Set<_TFClassImpl> _allocatedSubtypes = new Set<_TFClassImpl>();
  late final Map<Name, Member> _dispatchTargetsSetters =
      _initDispatchTargets(true);
  late final Map<Name, Member> _dispatchTargetsNonSetters =
      _initDispatchTargets(false);
  final _DependencyTracker dependencyTracker = new _DependencyTracker();

  /// Flag indicating if this class has a noSuchMethod() method not inherited
  /// from Object.
  /// Lazy initialized by ClassHierarchyCache.hasNonTrivialNoSuchMethod().
  bool? hasNonTrivialNoSuchMethod;

  _TFClassImpl(int id, Class classNode, this.superclass, this.supertypes,
      RecordShape? recordShape)
      : super(id, classNode, recordShape) {
    supertypes.add(this);
  }

  Type? _specializedConeType;
  Type get specializedConeType =>
      _specializedConeType ??= _calculateConeTypeSpecialization();

  bool get hasWideCone =>
      _allocatedSubtypes.length > maxAllocatedTypesInSetSpecializations;

  late final WideConeType _wideConeType = WideConeType(this);
  WideConeType get wideConeType {
    assert(hasWideCone);
    return _wideConeType;
  }

  Type _calculateConeTypeSpecialization() {
    final int numSubTypes = _allocatedSubtypes.length;
    if (numSubTypes == 0) {
      return emptyType;
    } else if (numSubTypes == 1) {
      return _allocatedSubtypes.single.concreteType;
    } else {
      List<ConcreteType> types = <ConcreteType>[];
      for (var sub in _allocatedSubtypes) {
        types.add(sub.concreteType);
      }
      // SetType constructor expects a list of ConcreteTypes sorted by classId
      // (for faster intersections and unions).
      types.sort();
      return SetType(types);
    }
  }

  void addAllocatedSubtype(_TFClassImpl subType) {
    _allocatedSubtypes.add(subType);
    _specializedConeType = null; // Reset cached specialization.
  }

  Map<Name, Member> _initDispatchTargets(bool setters) {
    Map<Name, Member> targets;
    final superclass = this.superclass;
    if (superclass != null) {
      targets = Map.from(setters
          ? superclass._dispatchTargetsSetters
          : superclass._dispatchTargetsNonSetters);
    } else {
      targets = {};
    }
    for (Field f in classNode.fields) {
      if (!f.isStatic && !f.isAbstract) {
        if (!setters || f.hasSetter) {
          targets[f.name] = f;
        }
      }
    }
    for (Procedure p in classNode.procedures) {
      if (!p.isStatic && !p.isAbstract) {
        if (p.isSetter == setters) {
          targets[p.name] = p;
        }
      }
    }
    final recordShape = this.recordShape;
    if (recordShape != null && !setters) {
      for (int i = 0; i < recordShape.numFields; ++i) {
        final name = Name(recordShape.fieldName(i));
        final member = targets[name];
        if (member == null) {
          final Field field = Field.immutable(name, fileUri: artificialNodeUri);
          field.parent = classNode;
          targets[name] = field;
        } else if (member is! Field) {
          throw 'Invalid record class $classNode: $member (at ${member.location}) should be a field.';
        }
      }
    }
    return targets;
  }

  Member? getDispatchTarget(Selector selector) {
    return (selector.isSetter
        ? _dispatchTargetsSetters
        : _dispatchTargetsNonSetters)[selector.name];
  }

  String dump() => "$this {supers: $supertypes}";
}

class GenericInterfacesInfoImpl implements GenericInterfacesInfo {
  final ClosedWorldClassHierarchy hierarchy;

  final supertypeOffsetsCache = <SubtypePair, int>{};
  final cachedFlattenedTypeArgs = <Class, List<DartType>>{};
  final cachedFlattenedTypeArgsForNonGeneric = <Class, List<Type>>{};

  late final RuntimeTypeTranslatorImpl closedTypeTranslator;

  GenericInterfacesInfoImpl(CoreTypes coreTypes, this.hierarchy) {
    closedTypeTranslator =
        RuntimeTypeTranslatorImpl.forClosedTypes(coreTypes, this);
  }

  List<DartType> flattenedTypeArgumentsFor(Class klass,
      {bool useCache = true}) {
    final cached = useCache ? cachedFlattenedTypeArgs[klass] : null;
    if (cached != null) return cached;

    final flattenedTypeArguments = List<DartType>.from(klass.typeParameters.map(
        (t) => new TypeParameterType(
            t, TypeParameterType.computeNullabilityFromBound(t))));

    for (final Supertype intf in hierarchy.genericSupertypesOf(klass)) {
      int offset = findOverlap(flattenedTypeArguments, intf.typeArguments);
      flattenedTypeArguments.addAll(
          intf.typeArguments.skip(flattenedTypeArguments.length - offset));
      supertypeOffsetsCache[SubtypePair(klass, intf.classNode)] = offset;
    }

    return flattenedTypeArguments;
  }

  int genericInterfaceOffsetFor(Class klass, Class iface) {
    if (klass == iface) return 0;

    final pair = new SubtypePair(klass, iface);
    int? offset = supertypeOffsetsCache[pair];

    if (offset != null) return offset;

    flattenedTypeArgumentsFor(klass);
    offset = supertypeOffsetsCache[pair];

    if (offset == null) {
      throw "Invalid call to genericInterfaceOffsetFor.";
    }

    return offset;
  }

  List<Type> flattenedTypeArgumentsForNonGeneric(Class klass) {
    List<Type>? result = cachedFlattenedTypeArgsForNonGeneric[klass];
    if (result != null) return result;

    List<DartType> flattenedTypeArgs =
        flattenedTypeArgumentsFor(klass, useCache: false);
    result = <Type>[];
    for (DartType arg in flattenedTypeArgs) {
      final translated = closedTypeTranslator.translate(arg);
      assert(translated is RuntimeType || translated is UnknownType);
      result.add(translated as Type);
    }
    cachedFlattenedTypeArgsForNonGeneric[klass] = result;
    return result;
  }
}

// TODO(alexmarkov): Rename to _TypeHierarchyImpl.
class _ClassHierarchyCache extends TypeHierarchy {
  final TypeFlowAnalysis _typeFlowAnalysis;
  final CoreTypes coreTypes;
  final GenericInterfacesInfo genericInterfacesInfo;
  final Map<Class, _TFClassImpl> classes = <Class, _TFClassImpl>{};
  final Set<Class> allocatedClasses = Set<Class>();
  final Set<_TFClassImpl> allocatedTFClasses = Set<_TFClassImpl>();
  final Map<RecordShape, _TFClassImpl> recordClasses =
      <RecordShape, _TFClassImpl>{};

  /// Object.noSuchMethod().
  final Member objectNoSuchMethod;

  static final Name noSuchMethodName = new Name("noSuchMethod");

  /// Class hierarchy is sealed after analysis is finished.
  /// Once it is sealed, no new allocated classes may be added and no new
  /// targets of invocations may appear.
  /// It also means that there is no need to add dependencies on classes.
  bool _sealed = false;

  int _classIdCounter = 0;

  final Map<DynamicSelector, _DynamicTargetSet> _dynamicTargets =
      <DynamicSelector, _DynamicTargetSet>{};

  late final _TFClassImpl _objectTFClass = getTFClass(coreTypes.objectClass);

  late final _TFClassImpl _nullTFClass =
      getTFClass(coreTypes.deprecatedNullClass);

  _ClassHierarchyCache(this._typeFlowAnalysis, this.genericInterfacesInfo,
      this.coreTypes, bool nullSafety)
      : objectNoSuchMethod =
            coreTypes.index.getProcedure('dart:core', 'Object', 'noSuchMethod'),
        super(coreTypes, nullSafety);

  @override
  _TFClassImpl getTFClass(Class c) {
    return classes[c] ??= _createTFClass(c, null);
  }

  _TFClassImpl _createTFClass(Class c, RecordShape? recordShape) {
    final supertypes = new Set<_TFClassImpl>();
    for (var sup in c.supers) {
      supertypes.addAll(getTFClass(sup.classNode).supertypes);
    }
    Class? superclassNode = c.superclass;
    _TFClassImpl? superclass =
        superclassNode != null ? getTFClass(superclassNode) : null;
    return _TFClassImpl(
        ++_classIdCounter, c, superclass, supertypes, recordShape);
  }

  ConcreteType addAllocatedClass(_TFClassImpl cls) {
    assert(!cls.classNode.isAbstract);
    assert(!_sealed);

    if (allocatedTFClasses.add(cls)) {
      allocatedClasses.add(cls.classNode);

      cls.addAllocatedSubtype(cls);
      cls.dependencyTracker
          .invalidateDependentInvocations(_typeFlowAnalysis.workList);

      for (var supertype in cls.supertypes) {
        supertype.addAllocatedSubtype(cls);
        supertype.dependencyTracker
            .invalidateDependentInvocations(_typeFlowAnalysis.workList);
      }

      for (var targetSet in _dynamicTargets.values) {
        _addDynamicTarget(cls, targetSet);
      }
    }

    return cls.concreteType;
  }

  @override
  Type getRecordType(RecordShape shape, bool allocated) {
    final cls = getRecordClass(shape);
    return allocated ? addAllocatedClass(cls) : cls.coneType;
  }

  _TFClassImpl getRecordClass(RecordShape shape) =>
      recordClasses[shape] ??= _createRecordClass(shape);

  _TFClassImpl _createRecordClass(RecordShape shape) {
    final Class c = _typeFlowAnalysis.target.getRecordImplementationClass(
        coreTypes, shape.numPositionalFields, shape.namedFields);
    if (c.isAbstract) {
      throw 'Record class $c should not be abstract';
    }
    return _createTFClass(c, shape);
  }

  Field getRecordField(RecordShape shape, String name) {
    final cls = getRecordClass(shape);
    return cls._dispatchTargetsNonSetters[Name(name)] as Field;
  }

  void seal() {
    _sealed = true;
  }

  @override
  bool isSubtype(Class sub, Class sup) {
    if (kPrintTrace) {
      tracePrint("isSubtype for sub = $sub, sup = $sup");
    }
    if (identical(sub, sup)) {
      return true;
    }

    _TFClassImpl subClassData = getTFClass(sub);
    _TFClassImpl superClassData = getTFClass(sup);

    return subClassData.supertypes.contains(superClassData);
  }

  @override
  Type specializeTypeCone(TFClass baseClass, {bool allowWideCone = false}) {
    if (kPrintTrace) {
      tracePrint("specializeTypeCone for $baseClass");
    }
    Statistics.typeConeSpecializations++;

    if (baseClass.classNode == coreTypes.objectClass) {
      return anyInstanceType;
    }

    final _TFClassImpl cls = baseClass as _TFClassImpl;

    if (allowWideCone && cls.hasWideCone) {
      Statistics.typeSpecializationsUsedWideCone++;
      return cls.wideConeType;
    }

    if (!_sealed) {
      cls.dependencyTracker
          .addDependentInvocation(_typeFlowAnalysis.currentInvocation);
    }

    return cls.specializedConeType;
  }

  bool hasNonTrivialNoSuchMethod(TFClass c) {
    final classImpl = c as _TFClassImpl;
    bool? value = classImpl.hasNonTrivialNoSuchMethod;
    if (value == null) {
      classImpl.hasNonTrivialNoSuchMethod = value =
          (classImpl._dispatchTargetsNonSetters[noSuchMethodName] !=
              objectNoSuchMethod);
    }
    return value;
  }

  _DynamicTargetSet getDynamicTargetSet(DynamicSelector selector) {
    return (_dynamicTargets[selector] ??= _createDynamicTargetSet(selector));
  }

  _DynamicTargetSet _createDynamicTargetSet(DynamicSelector selector) {
    final isObjectMethod = _objectTFClass.getDispatchTarget(selector) != null;

    final targetSet = new _DynamicTargetSet(selector, isObjectMethod);
    for (final cls in allocatedTFClasses) {
      _addDynamicTarget(cls, targetSet);
    }
    return targetSet;
  }

  void _addDynamicTarget(_TFClassImpl cls, _DynamicTargetSet targetSet) {
    assert(!_sealed);
    final selector = targetSet.selector;
    final member = cls.getDispatchTarget(selector);
    if (member != null) {
      if (targetSet.targets.add(member)) {
        targetSet.invalidateDependentInvocations(_typeFlowAnalysis.workList);
      }
    }
  }

  @override
  List<DartType> flattenedTypeArgumentsFor(Class klass) =>
      genericInterfacesInfo.flattenedTypeArgumentsFor(klass);

  @override
  int genericInterfaceOffsetFor(Class klass, Class iface) =>
      genericInterfacesInfo.genericInterfaceOffsetFor(klass, iface);

  @override
  List<Type> flattenedTypeArgumentsForNonGeneric(Class klass) =>
      genericInterfacesInfo.flattenedTypeArgumentsForNonGeneric(klass);

  @override
  String toString() {
    StringBuffer buf = new StringBuffer();
    buf.write("ClassHierarchyCache {\n");
    buf.write("  allocated classes:\n");
    allocatedClasses.forEach((c) {
      buf.write("    $c\n");
    });
    buf.write("  classes:\n");
    classes.values.forEach((c) {
      buf.write("    ${c.dump()}\n");
    });
    buf.write("}\n");
    return buf.toString();
  }
}

class _WorkList {
  final TypeFlowAnalysis _typeFlowAnalysis;
  final LinkedList<_Invocation> pending = new LinkedList<_Invocation>();
  final Set<_Invocation> processing = new Set<_Invocation>();
  final List<_Invocation> callStack = <_Invocation>[];

  _WorkList(this._typeFlowAnalysis);

  bool _isPending(_Invocation invocation) => invocation.list != null;

  void enqueueInvocation(_Invocation invocation) {
    assert(invocation.result == null);
    if (_isPending(invocation)) {
      // Re-add the invocation to the tail of the pending queue.
      pending.remove(invocation);
      assert(!_isPending(invocation));
    }
    pending.add(invocation);
  }

  void invalidateInvocation(_Invocation invocation) {
    Statistics.invocationsInvalidated++;
    if (invocation.result != null) {
      assert(invocation.invalidatedResult == null);
      invocation.invalidatedResult = invocation.result;
      invocation.result = null;
    }
    enqueueInvocation(invocation);
  }

  bool invalidateProtobufFields() {
    final protobufHandler = _typeFlowAnalysis.protobufHandler;
    if (protobufHandler == null) {
      return false;
    }
    final fields = protobufHandler.getInvalidatedFields();
    if (fields.isEmpty) {
      return false;
    }
    // Protobuf handler replaced contents of static field initializers.
    for (var field in fields) {
      assert(field.isStatic);
      // Reset summary in order to rebuild it.
      _typeFlowAnalysis._summaries.remove(field);
      // Invalidate (and enqueue) field initializer invocation.
      final initializerInvocation = _typeFlowAnalysis._invocationsCache
          .getInvocation(
              DirectSelector(field, callKind: CallKind.FieldInitializer),
              Args<Type>(const <Type>[]));
      invalidateInvocation(initializerInvocation);
    }
    return true;
  }

  void process() {
    for (;;) {
      if (pending.isEmpty && !invalidateProtobufFields()) {
        break;
      }
      assert(callStack.isEmpty && processing.isEmpty);
      Statistics.iterationsOverInvocationsWorkList++;
      processInvocation(pending.first);
    }
  }

  Type processInvocation(_Invocation invocation) {
    Type? result = invocation.result;
    if (result != null) {
      // Already processed.
      Statistics.usedCachedResultsOfInvocations++;
      return result;
    }

    // Test if tracing is enabled to avoid expensive message formatting.
    if (kPrintTrace) {
      tracePrint(
          'PROCESSING $invocation, invalidatedResult ${invocation.invalidatedResult}',
          1);
    }

    if (processing.add(invocation)) {
      // Do not process too many calls in the call stack as
      // it may cause stack overflow in the analysis.
      const int kMaxCallsInCallStack = 500;
      if (callStack.length > kMaxCallsInCallStack) {
        Statistics.deepInvocationsDeferred++;
        // If there is invalidatedResult, then use it.
        // When actual result is inferred it will be compared against
        // invalidatedResult and all dependent invocations will be invalidated
        // accordingly.
        //
        // Otherwise, if invocation is not invalidated yet, use empty type
        // as a result but immediately invalidate it in order to recompute.
        // Static type would be too inaccurate.
        if (invocation.invalidatedResult == null) {
          invocation.result = emptyType;
        }
        // Conservatively assume that this invocation may trigger
        // parameter type checks. This is needed because caller may not be
        // invalidated and recomputed if this invocation yields the
        // same result.
        invocation.typeChecksNeeded = true;
        invalidateInvocation(invocation);
        assert(invocation.result == null);
        assert(invocation.invalidatedResult != null);
        assert(_isPending(invocation));
        if (kPrintTrace) {
          tracePrint("Processing deferred due to deep call stack.");
          tracePrint(
              'END PROCESSING $invocation, RESULT ${invocation.invalidatedResult}',
              -1);
        }
        processing.remove(invocation);
        return invocation.invalidatedResult!;
      }

      callStack.add(invocation);
      pending.remove(invocation);

      result = invocation.process(_typeFlowAnalysis);

      invocation.setResult(_typeFlowAnalysis, result);

      // setResult may saturate result to ensure convergence.
      result = invocation.result!;

      // Invocation is still pending - it was invalidated while being processed.
      // Move result to invalidatedResult.
      if (_isPending(invocation)) {
        Statistics.invocationsInvalidatedDuringProcessing++;
        invocation.invalidatedResult = invocation.result;
        invocation.result = null;
      }

      final last = callStack.removeLast();
      assert(identical(last, invocation));

      processing.remove(invocation);

      Statistics.invocationsProcessed++;
      if (kPrintTrace) {
        tracePrint('END PROCESSING $invocation, RESULT $result', -1);
      }
      return result;
    } else {
      // Recursive invocation.
      final result = invocation.resultForRecursiveInvocation;
      if (result != null) {
        if (kPrintTrace) {
          tracePrint("Already known type for recursive invocation: $result");
          tracePrint('END PROCESSING $invocation, RESULT $result', -1);
        }
        return result;
      }
      // Fall back to static type.
      Statistics.recursiveInvocationsApproximated++;
      final staticType = _typeFlowAnalysis.hierarchyCache
          .fromStaticType(invocation.selector.staticReturnType, true);
      if (kPrintTrace) {
        tracePrint(
            "Approximated recursive invocation with static type $staticType");
        tracePrint('END PROCESSING $invocation, RESULT $staticType', -1);
      }
      return staticType;
    }
  }
}

class TypeFlowAnalysis
    implements EntryPointsListener, CallHandler, SharedVariableBuilder {
  final Target target;
  final TypeEnvironment environment;
  final CoreTypes coreTypes;
  final LibraryIndex libraryIndex;
  final PragmaAnnotationParser annotationMatcher;
  final ProtobufHandler? protobufHandler;
  late NativeCodeOracle nativeCodeOracle;
  late _ClassHierarchyCache hierarchyCache;
  late SummaryCollector summaryCollector;
  late _InvocationsCache _invocationsCache;
  late _WorkList workList;
  GenericInterfacesInfo _genericInterfacesInfo;

  final Map<Member, Summary> _summaries = <Member, Summary>{};
  final Map<Field, _FieldValue> _fieldValues = <Field, _FieldValue>{};
  final Map<VariableDeclaration, _SharedVariableImpl> _sharedCapturedVariables =
      {};
  final Set<Member> _tearOffTaken = new Set<Member>();
  final Set<Member> _methodsAndSettersCalledDynamically = new Set<Member>();
  final Set<Member> _gettersCalledDynamically = new Set<Member>();
  final Set<Member> _calledViaInterfaceSelector = new Set<Member>();
  final Set<Member> _calledViaThis = new Set<Member>();

  TypeFlowAnalysis(
      this.target,
      Component component,
      this.coreTypes,
      ClosedWorldClassHierarchy hierarchy,
      this._genericInterfacesInfo,
      this.environment,
      this.libraryIndex,
      this.protobufHandler,
      PragmaAnnotationParser? matcher)
      : annotationMatcher =
            matcher ?? new ConstantPragmaAnnotationParser(coreTypes, target) {
    nativeCodeOracle = new NativeCodeOracle(libraryIndex, annotationMatcher);
    hierarchyCache = new _ClassHierarchyCache(
        this, _genericInterfacesInfo, coreTypes, target.flags.soundNullSafety);
    summaryCollector = new SummaryCollector(
        target,
        environment,
        hierarchy,
        this,
        hierarchyCache,
        nativeCodeOracle,
        hierarchyCache,
        this,
        protobufHandler);
    _invocationsCache = new _InvocationsCache(this);
    workList = new _WorkList(this);

    component.accept(new PragmaEntryPointsVisitor(
        this, nativeCodeOracle, annotationMatcher));
  }

  _Invocation get currentInvocation => workList.callStack.last;

  Summary getSummary(Member member) {
    Summary? summary = _summaries[member];
    if (summary == null) {
      _summaries[member] = summary = summaryCollector.createSummary(member);
      if (summary.statements.length >=
          _SelectorApproximation.largeSummarySize) {
        final DirectSelector selector =
            currentInvocation.selector as DirectSelector;
        _invocationsCache.addDirectSelectorApproximation(selector);
      }
    }
    return summary;
  }

  _FieldValue getFieldValue(Field field) {
    _FieldValue? fieldValue = _fieldValues[field];
    if (fieldValue == null) {
      Summary? typeGuardSummary = null;
      if (field.isCovariantByClass) {
        typeGuardSummary = summaryCollector.createSummary(field,
            fieldSummaryType: FieldSummaryType.kFieldGuard);
      }
      fieldValue = _FieldValue(field, typeGuardSummary, hierarchyCache);
      _fieldValues[field] = fieldValue;
    }
    return fieldValue;
  }

  void process() {
    workList.process();
    hierarchyCache.seal();
  }

  /// Returns true if analysis found that given member
  /// could be executed / field could be accessed.
  bool isMemberUsed(Member member) {
    if (member is Field) {
      return _fieldValues.containsKey(member);
    } else {
      return _summaries.containsKey(member);
    }
  }

  /// Returns true if analysis found that initializer of the given [field]
  /// could be executed.
  bool isFieldInitializerUsed(Field field) {
    final fieldValue = _fieldValues[field];
    if (fieldValue != null) {
      return fieldValue.isInitialized;
    }
    return false;
  }

  /// Returns true if analysis found that getter corresponding to the given
  /// [field] could be executed.
  bool isFieldGetterUsed(Field field) {
    final fieldValue = _fieldValues[field];
    if (fieldValue != null) {
      return fieldValue.isGetterUsed;
    }
    return false;
  }

  /// Returns true if analysis found that setter corresponding to the given
  /// [field] could be executed.
  bool isFieldSetterUsed(Field field) {
    final fieldValue = _fieldValues[field];
    if (fieldValue != null) {
      return fieldValue.isSetterUsed;
    }
    return false;
  }

  bool isClassAllocated(Class c) => hierarchyCache.allocatedClasses.contains(c);

  Call? callSite(TreeNode node) => summaryCollector.callSites[node];

  TypeCheck? explicitCast(AsExpression cast) =>
      summaryCollector.explicitCasts[cast];

  TypeCheck? isTest(IsExpression node) => summaryCollector.isTests[node];

  NarrowNotNull? nullTest(TreeNode node) => summaryCollector.nullTests[node];

  Type? fieldType(Field field) => _fieldValues[field]?.value;

  Type? capturedVariableType(VariableDeclaration v) =>
      _sharedCapturedVariables[v]?.value;

  Args<Type>? argumentTypes(Member member) => _summaries[member]?.argumentTypes;

  Type? argumentType(Member member, VariableDeclaration memberParam) {
    return _summaries[member]?.argumentType(member, memberParam);
  }

  List<VariableDeclaration>? uncheckedParameters(Member member) =>
      _summaries[member]?.uncheckedParameters;

  bool isTearOffTaken(Member member) => _tearOffTaken.contains(member);

  /// Returns true if this member is called on a receiver with static type
  /// dynamic. Getters are not tracked. For fields, only setter is tracked.
  bool isCalledDynamically(Member member) =>
      _methodsAndSettersCalledDynamically.contains(member);

  /// Returns true if this getter (or implicit getter for field) is called
  /// on a receiver with static type dynamic.
  bool isGetterCalledDynamically(Member member) =>
      _gettersCalledDynamically.contains(member);

  /// Returns true if this member is called via this call.
  /// Getters are not tracked. For fields, only setter is tracked.
  bool isCalledViaThis(Member member) => _calledViaThis.contains(member);

  /// Returns true if this member is called via non-this call.
  /// Getters are not tracked. For fields, only setter is tracked.
  bool isCalledNotViaThis(Member member) =>
      _methodsAndSettersCalledDynamically.contains(member) ||
      _calledViaInterfaceSelector.contains(member);

  /// Update the summary parameters to reflect a signature change with moved
  /// and/or removed parameters.
  void adjustFunctionParameters(Member member) {
    _summaries[member]?.adjustFunctionParameters(member);
  }

  /// ---- Implementation of [CallHandler] interface. ----

  @override
  Type applyCall(Call? callSite, Selector selector, Args<Type> args,
      {bool isResultUsed = true, bool processImmediately = true}) {
    _Invocation invocation = _invocationsCache.getInvocation(selector, args);

    // Test if tracing is enabled to avoid expensive message formatting.
    if (kPrintTrace) {
      tracePrint("APPLY $invocation");
    }

    if ((callSite != null) && (invocation is _DispatchableInvocation)) {
      invocation.addCallSite(callSite);
    }

    // TODO(alexmarkov): Figure out better strategy of processing
    // an invocation if its result is not used.
    // Enqueueing such invocations regresses the analysis time considerably.

    if (processImmediately) {
      if (isResultUsed) {
        invocation.addDependentInvocation(currentInvocation);
      }

      return workList.processInvocation(invocation);
    } else {
      assert(!isResultUsed);

      if (invocation.result == null) {
        workList.enqueueInvocation(invocation);
      }

      return emptyType;
    }
  }

  @override
  void typeCheckTriggered() {
    currentInvocation.typeChecksNeeded = true;
  }

  /// ---- Implementation of [EntryPointsListener] interface. ----

  @override
  void addFieldUsedInConstant(Field field, Type instance, Type value) {
    assert(!field.isStatic);
    final fieldValue = getFieldValue(field);
    fieldValue.setValue(value, this, instance);
    // Make sure the field is retained as removing fields used in constants
    // may affect identity of the constants.
    fieldValue.isGetterUsed = true;
  }

  @override
  void addRawCall(Selector selector) {
    if (kPrintDebug) {
      debugPrint("ADD RAW CALL: $selector");
    }
    assert(selector is! DynamicSelector); // TODO(alexmarkov)

    applyCall(null, selector, summaryCollector.rawArguments(selector),
        isResultUsed: false, processImmediately: false);
  }

  @override
  ConcreteType addAllocatedClass(Class c) {
    if (kPrintDebug) {
      debugPrint("ADD ALLOCATED CLASS: $c");
    }
    return hierarchyCache.addAllocatedClass(hierarchyCache.getTFClass(c));
  }

  @override
  Field getRecordPositionalField(RecordShape shape, int pos) =>
      hierarchyCache.getRecordField(shape, shape.fieldName(pos));

  @override
  Field getRecordNamedField(RecordShape shape, String name) =>
      hierarchyCache.getRecordField(shape, name);

  @override
  void recordMemberCalledViaInterfaceSelector(Member target) {
    _calledViaInterfaceSelector.add(target);
  }

  @override
  void recordMemberCalledViaThis(Member target) {
    _calledViaThis.add(target);
  }

  @override
  void recordTearOff(Member target) {
    _tearOffTaken.add(target);
  }

  /// ---- Implementation of [SharedVariableBuilder] interface. ----

  @override
  SharedVariable getSharedVariable(VariableDeclaration variable) =>
      _sharedCapturedVariables[variable] ??= _SharedVariableImpl(variable);
}
