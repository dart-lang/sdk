// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Global type flow analysis.
library kernel.transformations.analysis;

import 'dart:collection';
import 'dart:core' hide Type;

import 'package:kernel/ast.dart' hide Statement, StatementVisitor;
import 'package:kernel/class_hierarchy.dart' show ClosedWorldClassHierarchy;
import 'package:kernel/library_index.dart' show LibraryIndex;
import 'package:kernel/type_environment.dart';

import 'calls.dart';
import 'native_code.dart';
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
// * Auto-generate entry_points.json during build.
//
// === Precision ===
// * Handle '==' with null.
// * Special type inference rules for binary int operators.
// * Support function types, better handle closures.
// * Support generic types: substitution, passing type arguments. Figure out
//   when generic type should be approximated.
// * Support named parameters (remove their approximation with static types).
//
// === Efficiency of the analysis ===
// * Add benchmark to measure analysis time continuously.
// * Figure out better strategy of processing an invocation if its result is
//   not used. Consider creating summaries eagerly (to discover allocated
//   classes early) but analyzing them lazily.
//

/// Maintains set of dependent invocations.
class _DependencyTracker {
  Set<_Invocation> _dependentInvocations;

  void addDependentInvocation(_Invocation invocation) {
    if (!identical(invocation, this)) {
      _dependentInvocations ??= new Set<_Invocation>();
      _dependentInvocations.add(invocation);
    }
  }

  void invalidateDependentInvocations(_WorkList workList) {
    if (_dependentInvocations != null) {
      _dependentInvocations.forEach(workList.invalidateInvocation);
    }
  }
}

/// _Invocation class represents the in-flight invocation detached from a
/// particular call site, e.g. it is a selector and arguments.
/// This is the basic unit of processing in type flow analysis.
/// Call sites calling the same method with the same argument types
/// may reuse results of the analysis through the same _Invocation instance.
abstract class _Invocation extends _DependencyTracker
    with LinkedListEntry<_Invocation> {
  final Selector selector;
  final Args<Type> args;

  Type result;

  /// Result of the invocation calculated before invocation was invalidated.
  /// Used to check if the re-analysis of the invocation yields the same
  /// result or not (to avoid invalidation of callers if result hasn't changed).
  Type invalidatedResult;

  Type process(TypeFlowAnalysis typeFlowAnalysis);

  _Invocation(this.selector, this.args);

  // Only take selector and args into account as _Invocation objects
  // are cached in _InvocationsCache using selector and args as a key.
  @override
  bool operator ==(other) =>
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
      new Type.cone(
          typeFlowAnalysis.environment.coreTypes.invocationClass.rawType)
    ]);

    final nsmInvocation =
        typeFlowAnalysis._invocationsCache.getInvocation(nsmSelector, nsmArgs);

    final Type type =
        typeFlowAnalysis.workList.processInvocation(nsmInvocation);

    // Result of this invocation depends on the result of noSuchMethod
    // inovcation.
    nsmInvocation.addDependentInvocation(this);

    return type;
  }
}

class _DirectInvocation extends _Invocation {
  _DirectInvocation(DirectSelector selector, Args<Type> args)
      : super(selector, args);

  @override
  Type process(TypeFlowAnalysis typeFlowAnalysis) {
    assertx(typeFlowAnalysis.currentInvocation == this);

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
        assertx(args.values.length == firstParamIndex);
        assertx(args.names.isEmpty);
        return fieldValue.getValue(typeFlowAnalysis);

      case CallKind.PropertySet:
        assertx(args.values.length == firstParamIndex + 1);
        assertx(args.names.isEmpty);
        final Type setterArg = args.values[firstParamIndex];
        fieldValue.setValue(setterArg, typeFlowAnalysis);
        return const EmptyType();

      case CallKind.Method:
        // Call via field.
        // TODO(alexmarkov): support function types and use inferred type
        // to get more precise return type.
        return new Type.fromStatic(const DynamicType());

      case CallKind.FieldInitializer:
        assertx(args.values.isEmpty);
        assertx(args.names.isEmpty);
        fieldValue.setValue(
            typeFlowAnalysis
                .getSummary(field)
                .apply(args, typeFlowAnalysis.hierarchyCache, typeFlowAnalysis),
            typeFlowAnalysis);
        return const EmptyType();
    }

    // Make dartanalyzer happy.
    throw 'Unexpected call kind ${selector.callKind}';
  }

  Type _processFunction(TypeFlowAnalysis typeFlowAnalysis) {
    final Member member = selector.member;
    if (selector.memberAgreesToCallKind(member)) {
      if (_isLegalNumberOfArguments()) {
        return typeFlowAnalysis
            .getSummary(member)
            .apply(args, typeFlowAnalysis.hierarchyCache, typeFlowAnalysis);
      } else {
        assertx(selector.callKind == CallKind.Method);
        return _processNoSuchMethod(args.receiver, typeFlowAnalysis);
      }
    } else {
      if (selector.callKind == CallKind.PropertyGet) {
        // Tear-off.
        // TODO(alexmarkov): capture receiver type
        assertx((member is Procedure) && !member.isGetter && !member.isSetter);
        typeFlowAnalysis.addRawCall(new DirectSelector(member));
        return new Type.fromStatic(const DynamicType());
      } else {
        // Call via getter.
        // TODO(alexmarkov): capture receiver type
        assertx((selector.callKind == CallKind.Method) &&
            (member is Procedure) &&
            member.isGetter);
        typeFlowAnalysis.addRawCall(
            new DirectSelector(member, callKind: CallKind.PropertyGet));
        return new Type.fromStatic(const DynamicType());
      }
    }
  }

  bool _isLegalNumberOfArguments() {
    final function = selector.member.function;
    assertx(function != null);

    final int positionalArguments = args.positionalCount;

    final int firstParamIndex = hasReceiverArg(selector.member) ? 1 : 0;
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

    return true;
  }
}

class _DispatchableInvocation extends _Invocation {
  bool _isPolymorphic = false;
  Set<Call> _callSites; // Populated only if not polymorphic.
  Member _monomorphicTarget;

  /// Marker for noSuchMethod() invocation in the map of invocation targets.
  static final Member kNoSuchMethodMarker =
      new Procedure(new Name('noSuchMethod&&'), ProcedureKind.Method, null);

  _DispatchableInvocation(Selector selector, Args<Type> args)
      : super(selector, args) {
    assertx(selector is! DirectSelector);
  }

  @override
  Type process(TypeFlowAnalysis typeFlowAnalysis) {
    assertx(typeFlowAnalysis.currentInvocation == this);

    // Collect all possible targets for this invocation,
    // along with more accurate receiver types for each target.
    final targets = <Member, _ReceiverTypeBuilder>{};
    _collectTargetsForReceiverType(args.receiver, targets, typeFlowAnalysis);

    // Calculate result as a union of results of direct invocations
    // corresponding to each target.
    Type result = new Type.empty();

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

          type = typeFlowAnalysis.workList.processInvocation(directInvocation);

          // Result of this invocation depends on the results of direct
          // invocations corresponding to each target.
          directInvocation.addDependentInvocation(this);
        }

        result = result.union(type, typeFlowAnalysis.hierarchyCache);
      });
    }

    // TODO(alexmarkov): handle closures more precisely
    if ((selector is DynamicSelector) && (selector.name.name == "call")) {
      tracePrint("Possible closure call, result is dynamic");
      result = new Type.fromStatic(const DynamicType());
    }

    return result;
  }

  void _collectTargetsForReceiverType(
      Type receiver,
      Map<Member, _ReceiverTypeBuilder> targets,
      TypeFlowAnalysis typeFlowAnalysis) {
    assertx(receiver != const EmptyType()); // should be filtered earlier

    final bool isNullableReceiver = receiver is NullableType;
    if (isNullableReceiver) {
      receiver = (receiver as NullableType).baseType;
      assertx(receiver is! NullableType);
    }

    if (selector is InterfaceSelector) {
      final staticReceiverType =
          new Type.fromStatic(selector.member.enclosingClass.rawType);
      receiver = receiver.intersection(
          staticReceiverType, typeFlowAnalysis.hierarchyCache);
      assertx(receiver is! NullableType);

      if (kPrintTrace) {
        tracePrint("Narrowed down receiver type: $receiver");
      }
    }

    if (receiver is ConeType) {
      // Specialization of type cone will add dependency of the current
      // invocation to the receiver class. A new allocated class discovered
      // in the receiver cone will invalidate this invocation.
      receiver = typeFlowAnalysis.hierarchyCache
          .specializeTypeCone((receiver as ConeType).dartType);
    }

    assertx(targets.isEmpty);

    if (receiver is ConcreteType) {
      _collectTargetsForConcreteType(receiver, targets, typeFlowAnalysis);
    } else if (receiver is SetType) {
      for (var type in receiver.types) {
        _collectTargetsForConcreteType(type, targets, typeFlowAnalysis);
      }
    } else if (receiver is AnyType) {
      _collectTargetsForSelector(targets, typeFlowAnalysis);
    } else {
      assertx(receiver is EmptyType);
    }

    if (isNullableReceiver) {
      _collectTargetsForNull(targets, typeFlowAnalysis);
    }
  }

  // TODO(alexmarkov): Consider caching targets for Null type.
  void _collectTargetsForNull(Map<Member, _ReceiverTypeBuilder> targets,
      TypeFlowAnalysis typeFlowAnalysis) {
    Class nullClass = typeFlowAnalysis.environment.coreTypes.nullClass;

    Member target = typeFlowAnalysis.hierarchyCache.hierarchy
        .getDispatchTarget(nullClass, selector.name, setter: selector.isSetter);

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
    DartType receiverDartType = receiver.dartType;

    assertx(receiverDartType is! FunctionType);
    assertx(receiverDartType is InterfaceType); // TODO(alexmarkov)

    Class class_ = (receiverDartType as InterfaceType).classNode;

    Member target = typeFlowAnalysis.hierarchyCache.hierarchy
        .getDispatchTarget(class_, selector.name, setter: selector.isSetter);

    if (target != null) {
      if (kPrintTrace) {
        tracePrint("Found $target for concrete receiver $receiver");
      }
      _getReceiverTypeBuilder(targets, target).addConcreteType(receiver);
    } else {
      if (typeFlowAnalysis.hierarchyCache.hasNonTrivialNoSuchMethod(class_)) {
        if (kPrintTrace) {
          tracePrint("Found non-trivial noSuchMethod for receiver $receiver");
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
//      assertx(selector.member.enclosingClass ==
//          _typeFlowAnalysis.environment.coreTypes.objectClass, details: selector);
      selector = new DynamicSelector(selector.callKind, selector.name);
    }

    final receiver = args.receiver;
    final _DynamicTargetSet dynamicTargetSet = typeFlowAnalysis.hierarchyCache
        .getDynamicTargetSet(selector as DynamicSelector);

    dynamicTargetSet.addDependentInvocation(this);

    assertx(targets.isEmpty);
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

      _notifyCallSites();

      _callSites = null; // No longer needed.
    }
  }

  void _setMonomorphicTarget(Member target) {
    assertx(!_isPolymorphic);
    assertx((_monomorphicTarget == null) || (_monomorphicTarget == target));
    _monomorphicTarget = target;

    _notifyCallSites();
  }

  void addCallSite(Call callSite) {
    if (selector is DirectSelector) {
      return;
    }

    _notifyCallSite(callSite);

    if (!callSite.isPolymorphic) {
      assertx(!_isPolymorphic);
      (_callSites ??= new Set<Call>()).add(callSite);
    }
  }

  /// Notify call site about changes in polymorphism of this invocation.
  void _notifyCallSite(Call callSite) {
    assert(selector is! DirectSelector);

    if (_isPolymorphic) {
      callSite.setPolymorphic();
    } else {
      if (_monomorphicTarget != null) {
        callSite.addTarget(_monomorphicTarget);
      }
    }
  }

  /// Notify call sites monitoring this invocation about changes in
  /// polymorphism of this invocation.
  void _notifyCallSites() {
    if (_callSites != null) {
      _callSites.forEach(_notifyCallSite);
    }
  }
}

/// Efficient builder of receiver type.
///
/// Supports the following operations:
/// 1) Add 1..N concrete types ordered by classId OR add 1 arbitrary type.
/// 2) Make type nullable.
class _ReceiverTypeBuilder {
  Type _type;
  List<ConcreteType> _list;
  bool _nullable = false;

  /// Appends a ConcreteType. May be called multiple times.
  /// Should not be used in conjunction with [addType].
  void addConcreteType(ConcreteType type) {
    if (_list == null) {
      if (_type == null) {
        _type = type;
        return;
      }

      assertx(_type is ConcreteType);
      assertx(_type != type);

      _list = new List<ConcreteType>();
      _list.add(_type);

      _type = null;
    }

    assertx(_list.last.classId.compareTo(type.classId) < 0);
    _list.add(type);
  }

  /// Appends an arbitrary Type. May be called only once.
  /// Should not be used in conjunction with [addConcreteType].
  void addType(Type type) {
    assertx(_type == null && _list == null);
    _type = type;
  }

  /// Makes the resulting type nullable.
  void addNull() {
    _nullable = true;
  }

  /// Returns union of added types.
  Type toType() {
    Type t = _type;
    if (t == null) {
      if (_list == null) {
        t = const EmptyType();
      } else {
        t = new SetType(_list);
      }
    } else {
      assertx(_list == null);
    }

    if (_nullable) {
      if (t is! NullableType) {
        t = new NullableType(t);
      }
    }

    return t;
  }
}

class _InvocationsCache {
  final Set<_Invocation> _invocations = new Set<_Invocation>();

  _Invocation getInvocation(Selector selector, Args<Type> args) {
    _Invocation invocation = (selector is DirectSelector)
        ? new _DirectInvocation(selector, args)
        : new _DispatchableInvocation(selector, args);
    _Invocation result = _invocations.lookup(invocation);
    if (result == null) {
      bool added = _invocations.add(invocation);
      assertx(added);
      result = invocation;
    }
    return result;
  }
}

class _FieldValue extends _DependencyTracker {
  final Field field;
  Type value;
  _DirectInvocation _initializerInvocation;

  _FieldValue(this.field) {
    if (field.initializer == null && _isDefaultValueOfFieldObservable()) {
      value = new Type.nullable(const EmptyType());
    } else {
      value = const EmptyType();
    }
  }

  bool _isDefaultValueOfFieldObservable() {
    if (field.isStatic) {
      return true;
    }

    final enclosingClass = field.enclosingClass;
    assertx(enclosingClass != null);

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

  void ensureInitialized(TypeFlowAnalysis typeFlowAnalysis) {
    if (field.initializer != null) {
      if (_initializerInvocation == null) {
        _initializerInvocation = typeFlowAnalysis._invocationsCache
            .getInvocation(
                new DirectSelector(field, callKind: CallKind.FieldInitializer),
                new Args<Type>(const <Type>[]));
      }

      // It may update the field value.
      typeFlowAnalysis.workList.processInvocation(_initializerInvocation);
    }
  }

  Type getValue(TypeFlowAnalysis typeFlowAnalysis) {
    ensureInitialized(typeFlowAnalysis);
    addDependentInvocation(typeFlowAnalysis.currentInvocation);
    return value;
  }

  void setValue(Type newValue, TypeFlowAnalysis typeFlowAnalysis) {
    final Type newType = value.union(newValue, typeFlowAnalysis.hierarchyCache);
    if (newType != value) {
      tracePrint("Set field $field value $newType");
      invalidateDependentInvocations(typeFlowAnalysis.workList);
      value = newType;
    }
  }

  @override
  String toString() => "_FieldValue $field => $value";
}

class _DynamicTargetSet extends _DependencyTracker {
  final DynamicSelector selector;
  final Set<Member> targets = new Set<Member>();
  final bool isObjectMember;

  _DynamicTargetSet(this.selector, this.isObjectMember);
}

class _ClassData extends _DependencyTracker implements ClassId<_ClassData> {
  final int _id;
  final Class class_;
  final Set<_ClassData> supertypes; // List of super-types including this.
  final Set<_ClassData> allocatedSubtypes = new Set<_ClassData>();

  /// Flag indicating if this class has a noSuchMethod() method not inherited
  /// from Object.
  /// Lazy initialized by _ClassHierarchyCache.hasNonTrivialNoSuchMethod().
  bool hasNonTrivialNoSuchMethod;

  _ClassData(this._id, this.class_, this.supertypes) {
    supertypes.add(this);
  }

  ConcreteType _concreteType;
  ConcreteType get concreteType =>
      _concreteType ??= new ConcreteType(this, class_.rawType);

  @override
  int get hashCode => _id;

  @override
  bool operator ==(other) => (other is _ClassData) && (this._id == other._id);

  @override
  int compareTo(_ClassData other) => this._id.compareTo(other._id);

  @override
  String toString() => "_C $class_";

  String dump() => "$this {supers: $supertypes}";
}

class _ClassHierarchyCache implements TypeHierarchy {
  final TypeFlowAnalysis _typeFlowAnalysis;
  final ClosedWorldClassHierarchy hierarchy;
  final Set<Class> allocatedClasses = new Set<Class>();
  final Map<Class, _ClassData> classes = <Class, _ClassData>{};

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

  _ClassHierarchyCache(this._typeFlowAnalysis, this.hierarchy)
      : objectNoSuchMethod = hierarchy.getDispatchTarget(
            _typeFlowAnalysis.environment.coreTypes.objectClass,
            noSuchMethodName) {
    assertx(objectNoSuchMethod != null);
  }

  _ClassData getClassData(Class c) {
    return classes[c] ??= _createClassData(c);
  }

  _ClassData _createClassData(Class c) {
    final supertypes = new Set<_ClassData>();
    for (var sup in c.supers) {
      supertypes.addAll(getClassData(sup.classNode).supertypes);
    }
    return new _ClassData(++_classIdCounter, c, supertypes);
  }

  ConcreteType addAllocatedClass(Class cl) {
    assertx(!cl.isAbstract);
    assertx(!_sealed);

    final _ClassData classData = getClassData(cl);

    if (allocatedClasses.add(cl)) {
      classData.allocatedSubtypes.add(classData);
      classData.invalidateDependentInvocations(_typeFlowAnalysis.workList);

      for (var supertype in classData.supertypes) {
        supertype.allocatedSubtypes.add(classData);
        supertype.invalidateDependentInvocations(_typeFlowAnalysis.workList);
      }

      for (var targetSet in _dynamicTargets.values) {
        _addDynamicTarget(cl, targetSet);
      }
    }

    return classData.concreteType;
  }

  void seal() {
    _sealed = true;
  }

  @override
  bool isSubtype(DartType subType, DartType superType) {
    if (kPrintTrace) {
      tracePrint("isSubtype for sub = $subType (${subType
              .runtimeType}), sup = $superType (${superType.runtimeType})");
    }
    if (subType == superType) {
      return true;
    }

    // TODO(alexmarkov): handle function types properly
    if (subType is FunctionType) {
      subType = _typeFlowAnalysis.environment.rawFunctionType;
    }
    if (superType is FunctionType) {
      superType = _typeFlowAnalysis.environment.rawFunctionType;
    }
    // TODO(alexmarkov): handle generic types properly.
    if (subType is TypeParameterType) {
      subType = (subType as TypeParameterType).bound;
    }
    if (superType is TypeParameterType) {
      superType = (superType as TypeParameterType).bound;
    }

    assertx(subType is InterfaceType, details: subType); // TODO(alexmarkov)
    assertx(superType is InterfaceType, details: superType); // TODO(alexmarkov)

    Class subClass = (subType as InterfaceType).classNode;
    Class superClass = (superType as InterfaceType).classNode;
    if (subClass == superClass) {
      return true;
    }

    // TODO(alexmarkov): handle FutureOr more precisely (requires generics).
    if (superClass == _typeFlowAnalysis.environment.futureOrClass) {
      return true;
    }

    _ClassData subClassData = getClassData(subClass);
    _ClassData superClassData = getClassData(superClass);

    return subClassData.supertypes.contains(superClassData);
  }

  @override
  Type specializeTypeCone(DartType base) {
    tracePrint("specializeTypeCone for $base");
    Statistics.typeConeSpecializations++;

    // TODO(alexmarkov): handle function types properly
    if (base is FunctionType) {
      base = _typeFlowAnalysis.environment.rawFunctionType;
    }

    if (base is TypeParameterType) {
      base = (base as TypeParameterType).bound;
    }

    assertx(base is InterfaceType); // TODO(alexmarkov)
    final baseClass = (base as InterfaceType).classNode;

    // TODO(alexmarkov): take type arguments into account.

    // TODO(alexmarkov): consider approximating type if number of allocated
    // subtypes is too large

    if (base == const DynamicType() ||
        base == _typeFlowAnalysis.environment.objectType ||
        // TODO(alexmarkov): handle FutureOr more precisely (requires generics).
        baseClass == _typeFlowAnalysis.environment.futureOrClass) {
      return const AnyType();
    }

    _ClassData classData = getClassData(baseClass);

    final allocatedSubtypes = classData.allocatedSubtypes;
    if (!_sealed) {
      classData.addDependentInvocation(_typeFlowAnalysis.currentInvocation);
    }

    final int numSubTypes = allocatedSubtypes.length;

    if (numSubTypes == 0) {
      return new Type.empty();
    } else if (numSubTypes == 1) {
      return allocatedSubtypes.single.concreteType;
    } else {
      List<ConcreteType> types = new List<ConcreteType>();
      for (var sub in allocatedSubtypes) {
        types.add(sub.concreteType);
      }
      // TODO(alexmarkov): cache result of specialization or keep allocatedSubtypes sorted
      types.sort();
      return new SetType(types);
    }
  }

  bool hasNonTrivialNoSuchMethod(Class c) {
    final classData = getClassData(c);
    classData.hasNonTrivialNoSuchMethod ??=
        (hierarchy.getDispatchTarget(c, noSuchMethodName) !=
            objectNoSuchMethod);
    return classData.hasNonTrivialNoSuchMethod;
  }

  _DynamicTargetSet getDynamicTargetSet(DynamicSelector selector) {
    return (_dynamicTargets[selector] ??= _createDynamicTargetSet(selector));
  }

  _DynamicTargetSet _createDynamicTargetSet(DynamicSelector selector) {
    // TODO(alexmarkov): consider caching the set of Object selectors.
    final isObjectMethod = (hierarchy.getDispatchTarget(
            _typeFlowAnalysis.environment.coreTypes.objectClass, selector.name,
            setter: selector.isSetter) !=
        null);

    final targetSet = new _DynamicTargetSet(selector, isObjectMethod);
    for (Class c in allocatedClasses) {
      _addDynamicTarget(c, targetSet);
    }
    return targetSet;
  }

  void _addDynamicTarget(Class c, _DynamicTargetSet targetSet) {
    assertx(!_sealed);
    final selector = targetSet.selector;
    final member = hierarchy.getDispatchTarget(c, selector.name,
        setter: selector.isSetter);
    if (member != null) {
      if (targetSet.targets.add(member)) {
        targetSet.invalidateDependentInvocations(_typeFlowAnalysis.workList);
      }
    }
  }

  @override
  String toString() {
    StringBuffer buf = new StringBuffer();
    buf.write("_ClassHierarchyCache {\n");
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
    assertx(invocation.result == null);
    if (_isPending(invocation)) {
      // Re-add the invocation to the tail of the pending queue.
      pending.remove(invocation);
      assertx(!_isPending(invocation));
    }
    pending.add(invocation);
  }

  void invalidateInvocation(_Invocation invocation) {
    Statistics.invocationsInvalidated++;
    if (invocation.result != null) {
      invocation.invalidatedResult = invocation.result;
      invocation.result = null;
    }
    enqueueInvocation(invocation);
  }

  void process() {
    while (pending.isNotEmpty) {
      assertx(callStack.isEmpty && processing.isEmpty);
      processInvocation(pending.first);
    }
  }

  Type processInvocation(_Invocation invocation) {
    if (invocation.result != null) {
      // Already processed.
      Statistics.usedCachedResultsOfInvocations++;
      return invocation.result;
    }

    // Test if tracing is enabled to avoid expensive message formatting.
    if (kPrintTrace) {
      tracePrint('PROCESSING $invocation');
    }

    if (processing.add(invocation)) {
      callStack.add(invocation);
      pending.remove(invocation);

      final Type result = invocation.process(_typeFlowAnalysis);

      assertx(result != null);
      invocation.result = result;

      if (invocation.invalidatedResult != null) {
        if (invocation.invalidatedResult != result) {
          invocation.invalidateDependentInvocations(this);
        }
        invocation.invalidatedResult = null;
      }

      // Invocation is still pending - it was invalidated while being processed.
      // Move result to invalidatedResult.
      if (_isPending(invocation)) {
        invocation.invalidatedResult = result;
        invocation.result = null;
      }

      final last = callStack.removeLast();
      assertx(identical(last, invocation));

      processing.remove(invocation);

      Statistics.invocationsProcessed++;
      return result;
    } else {
      // Recursive invocation, approximate with static type.
      Statistics.recursiveInvocationsApproximated++;
      final staticType =
          new Type.fromStatic(invocation.selector.staticReturnType);
      tracePrint(
          "Approximated recursive invocation with static type $staticType");
      return staticType;
    }
  }
}

class TypeFlowAnalysis implements EntryPointsListener, CallHandler {
  final TypeEnvironment environment;
  final LibraryIndex libraryIndex;
  final NativeCodeOracle nativeCodeOracle;
  _ClassHierarchyCache hierarchyCache;
  SummaryCollector summaryCollector;
  _InvocationsCache _invocationsCache = new _InvocationsCache();
  _WorkList workList;

  final Map<Member, Summary> _summaries = <Member, Summary>{};
  final Map<Field, _FieldValue> _fieldValues = <Field, _FieldValue>{};

  TypeFlowAnalysis(
      ClosedWorldClassHierarchy hierarchy, this.environment, this.libraryIndex,
      {List<String> entryPointsJSONFiles})
      : nativeCodeOracle = new NativeCodeOracle(libraryIndex) {
    hierarchyCache = new _ClassHierarchyCache(this, hierarchy);
    summaryCollector =
        new SummaryCollector(environment, this, nativeCodeOracle);
    workList = new _WorkList(this);

    if (entryPointsJSONFiles != null) {
      nativeCodeOracle.processEntryPointsJSONFiles(entryPointsJSONFiles, this);
    }
  }

  _Invocation get currentInvocation => workList.callStack.last;

  Summary getSummary(Member member) {
    return _summaries[member] ??= summaryCollector.createSummary(member);
  }

  _FieldValue getFieldValue(Field field) {
    return _fieldValues[field] ??= new _FieldValue(field);
  }

  void process() {
    workList.process();
    hierarchyCache.seal();
  }

  bool isMemberUsed(Member member) {
    if (member is Field) {
      return _fieldValues.containsKey(member);
    } else {
      return _summaries.containsKey(member);
    }
  }

  Call callSite(TreeNode node) => summaryCollector.callSites[node];

  Type fieldType(Field field) => _fieldValues[field]?.value;

  Args<Type> argumentTypes(Member member) => _summaries[member]?.argumentTypes;

  /// ---- Implementation of [CallHandler] interface. ----

  @override
  Type applyCall(
      Call callSite, Selector selector, Args<Type> args, bool isResultUsed,
      {bool processImmediately: true}) {
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
      assertx(!isResultUsed);

      if (invocation.result == null) {
        workList.enqueueInvocation(invocation);
      }

      return null;
    }
  }

  /// ---- Implementation of [EntryPointsListener] interface. ----

  @override
  void addRawCall(Selector selector) {
    debugPrint("ADD RAW CALL: $selector");
    assertx(selector is! DynamicSelector); // TODO(alexmarkov)

    applyCall(null, selector, summaryCollector.rawArguments(selector), false,
        processImmediately: false);
  }

  @override
  ConcreteType addAllocatedClass(Class c) {
    debugPrint("ADD ALLOCATED CLASS: $c");
    return hierarchyCache.addAllocatedClass(c);
  }
}
