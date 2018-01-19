// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Global type flow analysis.
library kernel.transformations.analysis;

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
// * Add unit tests!!!
// * Support dynamic calls via getters & dynamic tear-offs.
// * Re-evaluate field initializer if its dependency changes (avoid
//   re-using cached value).
// * Handle noSuchMethod invocations correctly (especially in case of dynamic
//   calls).
// * Verify incremental re-calculation by fresh analysis starting with known
//   allocated classes.
// * Auto-generate entry_points.json during build.
// * Support FutureOr<T> properly.
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
class _Invocation extends _DependencyTracker {
  final Selector selector;
  final Args<Type> args;

  Type result;

  /// Result of the invocation calculated before invocation was invalidated.
  /// Used to check if the re-analysis of the invocation yields the same
  /// result or not (to avoid invalidation of callers if result hasn't changed).
  Type invalidatedResult;

  bool _isPolymorphic = false;
  Set<Call> _callSites; // Populated only if non-direct and not polymorphic.
  Member _monomorphicTarget;

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

  void setPolymorphic() {
    if (!_isPolymorphic) {
      _isPolymorphic = true;
      _monomorphicTarget = null;

      _notifyCallSites();

      _callSites = null; // No longer needed.
    }
  }

  void setMonomorphicTarget(Member target) {
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

class _InvocationsCache {
  final Set<_Invocation> _invocations = new Set<_Invocation>();

  _Invocation getInvocation(Selector selector, Args<Type> args) {
    _Invocation invocation = new _Invocation(selector, args);
    _Invocation result = _invocations.lookup(invocation);
    if (result == null) {
      bool added = _invocations.add(invocation);
      assertx(added);
      result = invocation;
    }
    return result;
  }
}

/// Base class for handlers of invocations of a member.
abstract class _MemberInvocationHandler extends _DependencyTracker {
  final Member member;
  Summary _summary;

  _MemberInvocationHandler(this.member);

  Summary getSummary(TypeFlowAnalysis typeFlowAnalysis) {
    return _summary ??= typeFlowAnalysis.summaryCollector.createSummary(member);
  }

  Type handleInvocation(
      _Invocation invocation, TypeFlowAnalysis typeFlowAnalysis);

  @override
  String toString() => "_M $member";
}

class _ProcedureInvocationHandler extends _MemberInvocationHandler {
  _ProcedureInvocationHandler(Member member) : super(member);

  @override
  Type handleInvocation(
      _Invocation invocation, TypeFlowAnalysis typeFlowAnalysis) {
    if (invocation.selector.memberAgreesToCallKind(member)) {
      if (_isLegalNumberOfArguments(invocation)) {
        addDependentInvocation(typeFlowAnalysis.currentInvocation);
        return getSummary(typeFlowAnalysis).apply(
            invocation.args, typeFlowAnalysis.hierarchyCache, typeFlowAnalysis);
      } else {
        return new Type.empty();
      }
    } else {
      if (invocation.selector.callKind == CallKind.PropertyGet) {
        // Tear-off.
        // TODO(alexmarkov): capture receiver type
        assertx((member is Procedure) &&
            !(member as Procedure).isGetter &&
            !(member as Procedure).isSetter);
        typeFlowAnalysis.addRawCall(new DirectSelector(member));
        return new Type.fromStatic(const DynamicType());
      } else {
        // Call via getter.
        // TODO(alexmarkov): capture receiver type
        assertx((invocation.selector.callKind == CallKind.Method) &&
            (member is Procedure) &&
            (member as Procedure).isGetter);
        typeFlowAnalysis.addRawCall(
            new DirectSelector(member, callKind: CallKind.PropertyGet));
        return new Type.fromStatic(const DynamicType());
      }
    }
  }

  bool _isLegalNumberOfArguments(_Invocation invocation) {
    final function = member.function;
    assertx(function != null);

    final int positionalArguments = invocation.args.positionalCount;

    final int firstParamIndex = hasReceiverArg(member) ? 1 : 0;
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

class _FieldGetterInvocationHandler extends _MemberInvocationHandler {
  Type value;

  _FieldGetterInvocationHandler(Field member) : super(member);

  Field get field => member as Field;

  int get receiverCount => field.isStatic ? 0 : 1;

  void ensureInitialized(TypeFlowAnalysis typeFlowAnalysis) {
    if (value == null) {
      // Evaluate initializer
      final args = new Args<Type>(const <Type>[]);
      value = getSummary(typeFlowAnalysis)
          .apply(args, typeFlowAnalysis.hierarchyCache, typeFlowAnalysis);

      // TODO(alexmarkov): re-evaluate initializer on invalidations
    }
  }

  @override
  Type handleInvocation(
      _Invocation invocation, TypeFlowAnalysis typeFlowAnalysis) {
    ensureInitialized(typeFlowAnalysis);

    if (invocation.selector.callKind == CallKind.PropertyGet) {
      assertx(invocation.args.values.length == receiverCount);
      assertx(invocation.args.names.isEmpty);
      addDependentInvocation(typeFlowAnalysis.currentInvocation);
      return value;
    } else {
      // Call via field.
      assertx(invocation.selector.callKind == CallKind.Method);
      return new Type.fromStatic(const DynamicType());
    }
  }

  @override
  String toString() => "_GetF $member {value: $value}";
}

class _FieldSetterInvocationHandler extends _MemberInvocationHandler {
  final _FieldGetterInvocationHandler getter;

  _FieldSetterInvocationHandler(this.getter) : super(getter.field);

  Field get field => getter.field;
  int get receiverCount => getter.receiverCount;

  @override
  Type handleInvocation(
      _Invocation invocation, TypeFlowAnalysis typeFlowAnalysis) {
    getter.ensureInitialized(typeFlowAnalysis);
    assertx(invocation.selector.callKind == CallKind.PropertySet);

    assertx(invocation.args.values.length == receiverCount + 1);
    assertx(invocation.args.names.isEmpty);
    final Type setterArg = invocation.args.values[receiverCount];

    final Type newType =
        getter.value.union(setterArg, typeFlowAnalysis.hierarchyCache);
    if (newType != getter.value) {
      getter.invalidateDependentInvocations(typeFlowAnalysis.workList);
      getter.value = newType;
    }
    return new Type.empty();
  }

  @override
  String toString() => "_SetF $member";
}

class _DynamicInvocationHandler extends _DependencyTracker {
  final DynamicSelector selector;
  final Set<Member> targets = new Set<Member>();

  _DynamicInvocationHandler(this.selector);
}

class _ClassData extends _DependencyTracker {
  final Class class_;
  final Set<_ClassData> supertypes; // List of super-types including this.
  final Set<_ClassData> allocatedSubtypes = new Set<_ClassData>();

  _ClassData(this.class_, this.supertypes) {
    supertypes.add(this);
  }

  @override
  String toString() => "_C $class_";

  String dump() => "$this {supers: $supertypes}";
}

class _ClassHierarchyCache implements TypeHierarchy {
  final TypeFlowAnalysis _typeFlowAnalysis;
  final ClosedWorldClassHierarchy hierarchy;
  final Set<Class> allocatedClasses = new Set<Class>();
  final Map<Class, _ClassData> classes = <Class, _ClassData>{};

  /// Class hierarchy is sealed after analysis is finished.
  /// Once it is sealed, no new allocated classes may be added and no new
  /// targets of invocations may appear.
  /// It also means that there is no need to add dependencies on classes.
  bool _sealed = false;

  final Map<Member, _ProcedureInvocationHandler> _procedureHandlers =
      <Member, _ProcedureInvocationHandler>{};
  final Map<Field, _FieldGetterInvocationHandler> _fieldGetterHandlers =
      <Field, _FieldGetterInvocationHandler>{};
  final Map<Field, _FieldSetterInvocationHandler> _fieldSetterHandlers =
      <Field, _FieldSetterInvocationHandler>{};
  final Map<DynamicSelector, _DynamicInvocationHandler> _dynamicHandlers =
      <DynamicSelector, _DynamicInvocationHandler>{};

  _ClassHierarchyCache(this._typeFlowAnalysis, this.hierarchy);

  _ClassData getClassData(Class c) {
    return classes[c] ??= _createClassData(c);
  }

  _ClassData _createClassData(Class c) {
    final supertypes = new Set<_ClassData>();
    for (var sup in c.supers) {
      supertypes.addAll(getClassData(sup.classNode).supertypes);
    }
    return new _ClassData(c, supertypes);
  }

  void addAllocatedClass(Class cl) {
    assertx(!cl.isAbstract);
    assertx(!_sealed);

    if (allocatedClasses.add(cl)) {
      final _ClassData classData = getClassData(cl);
      classData.allocatedSubtypes.add(classData);
      classData.invalidateDependentInvocations(_typeFlowAnalysis.workList);

      for (var supertype in classData.supertypes) {
        supertype.allocatedSubtypes.add(classData);
        supertype.invalidateDependentInvocations(_typeFlowAnalysis.workList);
      }

      for (var handler in _dynamicHandlers.values) {
        _addDynamicTarget(cl, handler);
      }
    }
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

    // TODO(alexmarkov): take type arguments into account.

    // TODO(alexmarkov): consider approximating type if number of allocated
    // subtypes is too large

    if (base == const DynamicType() ||
        base == _typeFlowAnalysis.environment.objectType) {
      return const AnyType();
    }

    _ClassData classData = getClassData((base as InterfaceType).classNode);

    final allocatedSubtypes = classData.allocatedSubtypes;
    if (!_sealed) {
      classData.addDependentInvocation(_typeFlowAnalysis.currentInvocation);
    }

    final int numSubTypes = allocatedSubtypes.length;

    if (numSubTypes == 0) {
      return new Type.empty();
    } else if (numSubTypes == 1) {
      return new Type.concrete(allocatedSubtypes.single.class_.rawType);
    } else {
      Set<ConcreteType> types = new Set<ConcreteType>();
      for (var sub in allocatedSubtypes) {
        types.add(new Type.concrete(sub.class_.rawType));
      }
      return new SetType(types);
    }
  }

  _MemberInvocationHandler getMemberHandler(Member member, CallKind callKind) {
    if (member is Field) {
      if (callKind == CallKind.PropertySet) {
        return _fieldSetterHandlers[member] ??=
            new _FieldSetterInvocationHandler(
                getMemberHandler(member, CallKind.PropertyGet));
      } else {
        return _fieldGetterHandlers[member] ??=
            new _FieldGetterInvocationHandler(member);
      }
    } else {
      return _procedureHandlers[member] ??=
          new _ProcedureInvocationHandler(member);
    }
  }

  bool isMemberUsed(Member member) {
    if (member is Field) {
      return _fieldGetterHandlers[member]?.value != null;
    } else {
      return _procedureHandlers[member]?._summary != null;
    }
  }

  Iterable<Member> getDynamicTargets(DynamicSelector selector) {
    final handler =
        (_dynamicHandlers[selector] ??= _createDynamicHandler(selector));
    return handler.targets;
  }

  _DynamicInvocationHandler _createDynamicHandler(DynamicSelector selector) {
    final handler = new _DynamicInvocationHandler(selector);
    for (Class c in allocatedClasses) {
      _addDynamicTarget(c, handler);
    }
    return handler;
  }

  void _addDynamicTarget(Class c, _DynamicInvocationHandler handler) {
    assertx(!_sealed);
    final selector = handler.selector;
    final member = hierarchy.getDispatchTarget(c, selector.name,
        setter: selector.isSetter);
    if (member != null) {
      if (selector.memberAgreesToCallKind(member)) {
        if (handler.targets.add(member)) {
          handler.invalidateDependentInvocations(_typeFlowAnalysis.workList);
        }
      } else {
        if (selector.callKind == CallKind.Method) {
          // Call via getter/field.
          // TODO(alexmarkov)
          // assertx(false);
        } else {
          assertx(selector.callKind == CallKind.PropertyGet);
          // Tear-off.
          // TODO(alexmarkov)
          // assertx(false);
        }
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
    buf.write("  handlers:\n");
    _procedureHandlers.values.forEach((handler) {
      buf.write("    $handler\n");
    });
    _fieldGetterHandlers.values.forEach((handler) {
      buf.write("    $handler\n");
    });
    _fieldSetterHandlers.values.forEach((handler) {
      buf.write("    $handler\n");
    });
    buf.write("}\n");
    return buf.toString();
  }
}

class _InvocationAnalyzer {
  final TypeFlowAnalysis _typeFlowAnalysis;

  _InvocationAnalyzer(this._typeFlowAnalysis);

  Type processInvocation(_Invocation invocation) {
    final Selector selector = invocation.selector;
    Type result = null;

    if (selector is DirectSelector) {
      result = _processDirectInvocation(selector, invocation);
    } else {
      result = _processMultipleTargets(selector, invocation);
    }

    assertx(result != null);
    invocation.result = result;

    if (invocation.invalidatedResult != null) {
      if (invocation.invalidatedResult != result) {
        invocation.invalidateDependentInvocations(_typeFlowAnalysis.workList);
      }
      invocation.invalidatedResult = null;
    }

    return result;
  }

  Type _processDirectInvocation(
      DirectSelector selector, _Invocation invocation) {
    final handler = _typeFlowAnalysis.hierarchyCache
        .getMemberHandler(selector.member, selector.callKind);
    return handler.handleInvocation(invocation, _typeFlowAnalysis);
  }

  Type _processMultipleTargets(Selector selector, _Invocation invocation) {
    Iterable<_MemberInvocationHandler> targets = _collectTargets(invocation);
    Type result = new Type.empty();

    if (targets.isEmpty) {
      tracePrint("No targets...");
    } else {
      if (targets.length == 1) {
        invocation.setMonomorphicTarget(targets.single.member);
      } else {
        invocation.setPolymorphic();
      }
      for (var handler in targets) {
        Type type = handler.handleInvocation(invocation, _typeFlowAnalysis);
        result = result.union(type, _typeFlowAnalysis.hierarchyCache);
      }
    }

    // TODO(alexmarkov): handle closures more precisely
    if ((selector is DynamicSelector) && (selector.name.name == "call")) {
      tracePrint("Possible closure call, result is dynamic");
      result = new Type.fromStatic(const DynamicType());
    }

    return result;
  }

  Iterable<_MemberInvocationHandler> _collectTargets(_Invocation invocation) {
    assertx(invocation.selector is! DirectSelector);

    Type receiver = invocation.args.receiver;
    assertx(receiver != const EmptyType()); // should be filtered earlier

    Set<Member> targets = new Set<Member>();
    _collectForReceiverType(receiver, invocation.selector, targets);

    return targets.map((Member member) => _typeFlowAnalysis.hierarchyCache
        .getMemberHandler(member, invocation.selector.callKind));
  }

  void _collectForReceiverType(
      Type receiver, Selector selector, Set<Member> targets) {
    if (receiver is NullableType) {
      _collectForConcreteType(
          _typeFlowAnalysis.environment.nullType, selector, targets);
      receiver = (receiver as NullableType).baseType;
      assertx(receiver is! NullableType);
    }

    if (selector is InterfaceSelector) {
      final staticReceiverType =
          new Type.fromStatic(selector.member.enclosingClass.rawType);
      receiver = receiver.intersection(
          staticReceiverType, _typeFlowAnalysis.hierarchyCache);
      assertx(receiver is! NullableType);

      tracePrint("Narrowed down receiver type: $receiver");
    }

    if (receiver is ConeType) {
      receiver = _typeFlowAnalysis.hierarchyCache
          .specializeTypeCone((receiver as ConeType).dartType);
    }

    if (receiver is ConcreteType) {
      _collectForConcreteType(receiver.dartType, selector, targets);
    } else if (receiver is SetType) {
      for (var type in receiver.types) {
        _collectForConcreteType(type.dartType, selector, targets);
      }
    } else if (receiver is AnyType) {
      _collectForSelector(selector, targets);
    } else {
      assertx(receiver is EmptyType);
    }
  }

  void _collectForConcreteType(
      DartType receiver, Selector selector, Set<Member> targets) {
    if (receiver is FunctionType) {
      assertx((selector is DynamicSelector) && (selector.name.name == "call"));
      return;
    }

    assertx(receiver is InterfaceType); // TODO(alexmarkov)

    Class class_ = (receiver as InterfaceType).classNode;

    Member target = _typeFlowAnalysis.hierarchyCache.hierarchy
        .getDispatchTarget(class_, selector.name, setter: selector.isSetter);

    if (target != null) {
      tracePrint("Found $target for concrete receiver type $receiver");
      targets.add(target);
    } else {
      tracePrint("Target is not found for concrete receiver type $receiver");
    }
  }

  void _collectForSelector(Selector selector, Set<Member> targets) {
    if (selector is InterfaceSelector) {
      // TODO(alexmarkov): support generic types and make sure inferred types
      // are always same or better than static types.
//      assertx(selector.member.enclosingClass ==
//          _typeFlowAnalysis.environment.coreTypes.objectClass, details: selector);
      selector = new DynamicSelector(selector.callKind, selector.name);
    }

    targets.addAll(_typeFlowAnalysis.hierarchyCache
        .getDynamicTargets(selector as DynamicSelector));
  }
}

class _WorkList {
  final TypeFlowAnalysis _typeFlowAnalysis;
  final Set<_Invocation> pending = new Set<_Invocation>();
  final Set<_Invocation> processing = new Set<_Invocation>();
  final List<_Invocation> callStack = <_Invocation>[];

  _WorkList(this._typeFlowAnalysis);

  void enqueueInvocation(_Invocation invocation) {
    assertx(invocation.result == null);
    if (!pending.add(invocation)) {
      // Re-add the invocation to the tail of the pending queue.
      pending.remove(invocation);
      pending.add(invocation);
    }
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
      _Invocation invocation = pending.first;

      // Remove from pending before processing, as the invocation
      // could be invalidated and re-added to pending while processing.
      pending.remove(invocation);

      processInvocation(invocation);
      assertx(invocation.result != null);
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

      final Type result =
          _typeFlowAnalysis.invocationAnalyzer.processInvocation(invocation);

      final last = callStack.removeLast();
      assertx(identical(last, invocation));

      processing.remove(invocation);

      Statistics.invocationsProcessed++;
      return result;
    } else {
      // Recursive invocation, approximate with static type.
      Statistics.recursiveInvocationsApproximated++;
      return new Type.fromStatic(invocation.selector.staticReturnType);
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
  _InvocationAnalyzer invocationAnalyzer;
  _WorkList workList;

  TypeFlowAnalysis(
      ClosedWorldClassHierarchy hierarchy, this.environment, this.libraryIndex,
      {List<String> entryPointsJSONFiles})
      : nativeCodeOracle = new NativeCodeOracle(libraryIndex) {
    hierarchyCache = new _ClassHierarchyCache(this, hierarchy);
    summaryCollector =
        new SummaryCollector(environment, this, nativeCodeOracle);
    invocationAnalyzer = new _InvocationAnalyzer(this);
    workList = new _WorkList(this);

    if (entryPointsJSONFiles != null) {
      nativeCodeOracle.processEntryPointsJSONFiles(entryPointsJSONFiles, this);
    }
  }

  _Invocation get currentInvocation => workList.callStack.last;

  void process() {
    workList.process();
    hierarchyCache.seal();
  }

  bool isMemberUsed(Member member) => hierarchyCache.isMemberUsed(member);

  Call callSite(TreeNode node) => summaryCollector.callSites[node];

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

    if (callSite != null) {
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
  void addAllocatedClass(Class c) {
    debugPrint("ADD ALLOCATED CLASS: $c");
    hierarchyCache.addAllocatedClass(c);
  }

  @override
  void addAllocatedType(InterfaceType type) {
    tracePrint("ADD ALLOCATED TYPE: $type");

    // TODO(alexmarkov): take type arguments into account.

    hierarchyCache.addAllocatedClass(type.classNode);
  }
}
