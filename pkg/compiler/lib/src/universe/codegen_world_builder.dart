// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import '../common.dart';
import '../common/names.dart' show Identifiers;
import '../common_elements.dart';
import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import '../js_backend/annotations.dart' show AnnotationsData;
import '../js_backend/interceptor_data.dart' show OneShotInterceptorData;
import '../js_backend/native_data.dart' show NativeBasicData;
import '../js_model/elements.dart';
import '../util/enumset.dart';
import '../util/util.dart';
import '../world.dart';
import 'call_structure.dart';
import 'member_usage.dart';
import 'selector.dart' show Selector;
import 'use.dart'
    show ConstantUse, DynamicUse, DynamicUseKind, StaticUse, StaticUseKind;
import 'world_builder.dart';

/// World builder specific to codegen.
///
/// This adds additional access to liveness of selectors and elements.
abstract class CodegenWorldBuilder implements WorldBuilder {
  /// Register [constant] as needed for emission.
  void addCompileTimeConstantForEmission(ConstantValue constant);

  /// Close the codegen world builder and return the immutable [CodegenWorld]
  /// as the result.
  CodegenWorld close();
}

// The immutable result of the [CodegenWorldBuilder].
abstract class CodegenWorld extends BuiltWorld {
  /// Calls [f] for each generic call method on a live closure class.
  void forEachGenericClosureCallMethod(void Function(FunctionEntity) f);

  bool hasInvokedGetter(MemberEntity member);

  /// Returns `true` if [member] is invoked as a setter.
  bool hasInvokedSetter(MemberEntity member);

  Map<Selector, SelectorConstraints> invocationsByName(String name);

  Iterable<Selector> getterInvocationsByName(String name);

  Iterable<Selector> setterInvocationsByName(String name);

  void forEachInvokedName(
      f(String name, Map<Selector, SelectorConstraints> selectors));

  void forEachInvokedGetter(
      f(String name, Map<Selector, SelectorConstraints> selectors));

  void forEachInvokedSetter(
      f(String name, Map<Selector, SelectorConstraints> selectors));

  /// All directly instantiated classes, that is, classes with a generative
  /// constructor that has been called directly and not only through a
  /// super-call.
  // TODO(johnniwinther): Improve semantic precision.
  Iterable<ClassEntity> get directlyInstantiatedClasses;

  Iterable<ClassEntity> get constructorReferences;

  /// All directly or indirectly instantiated classes.
  Iterable<ClassEntity> get instantiatedClasses;

  bool methodsNeedsSuperGetter(FunctionEntity function);

  /// The calls [f] for all static fields.
  void forEachStaticField(void Function(FieldEntity) f);

  /// Returns the types that are live as constant type literals.
  Iterable<DartType> get constTypeLiterals;

  /// Returns the types that are live as constant type arguments.
  Iterable<DartType> get liveTypeArguments;

  /// Returns a list of constants topologically sorted so that dependencies
  /// appear before the dependent constant.
  ///
  /// [preSortCompare] is a comparator function that gives the constants a
  /// consistent order prior to the topological sort which gives the constants
  /// an ordering that is less sensitive to perturbations in the source code.
  Iterable<ConstantValue> getConstantsForEmission(
      [Comparator<ConstantValue> preSortCompare]);

  /// Returns `true` if [member] is called from a subclass via `super`.
  bool isAliasedSuperMember(MemberEntity member);

  OneShotInterceptorData get oneShotInterceptorData;
}

class CodegenWorldBuilderImpl extends WorldBuilderBase
    implements CodegenWorldBuilder {
  final JClosedWorld _closedWorld;
  final OneShotInterceptorData _oneShotInterceptorData;

  /// The set of all directly instantiated classes, that is, classes with a
  /// generative constructor that has been called directly and not only through
  /// a super-call.
  ///
  /// Invariant: Elements are declaration elements.
  // TODO(johnniwinther): [_directlyInstantiatedClasses] and
  // [_instantiatedTypes] sets should be merged.
  final Set<ClassEntity> _directlyInstantiatedClasses = {};

  /// The set of all directly instantiated types, that is, the types of the
  /// directly instantiated classes.
  ///
  /// See [_directlyInstantiatedClasses].
  final Set<InterfaceType> _instantiatedTypes = {};

  /// Classes implemented by directly instantiated classes.
  final Set<ClassEntity> _implementedClasses = {};

  final Map<String, Map<Selector, SelectorConstraints>> _invokedNames = {};
  final Map<String, Map<Selector, SelectorConstraints>> _invokedGetters = {};
  final Map<String, Map<Selector, SelectorConstraints>> _invokedSetters = {};

  final Map<ClassEntity, ClassUsage> _processedClasses = {};

  Map<ClassEntity, ClassUsage> get classUsageForTesting => _processedClasses;

  /// Map of registered usage of static and instance members.
  final Map<MemberEntity, MemberUsage> _memberUsage = {};

  /// Map containing instance members of live classes that have not yet been
  /// fully invoked dynamically.
  ///
  /// A method is fully invoked if all is optional parameter have been passed
  /// in some invocation.
  final Map<String, Set<MemberUsage>> _invokableInstanceMembersByName = {};

  /// Map containing instance members of live classes that have not yet been
  /// read from dynamically.
  final Map<String, Set<MemberUsage>> _readableInstanceMembersByName = {};

  /// Map containing instance members of live classes that have not yet been
  /// written to dynamically.
  final Map<String, Set<MemberUsage>> _writableInstanceMembersByName = {};

  final Set<DartType> _isChecks = {};

  final SelectorConstraintsStrategy _selectorConstraintsStrategy;

  final Set<ConstantValue> _constantValues = {};

  final Set<DartType> _constTypeLiterals = {};
  final Set<DartType> _liveTypeArguments = {};
  final Set<TypeVariableType> _namedTypeVariablesNewRti = {};
  final Set<ClassEntity> _constructorReferences = {};

  CodegenWorldBuilderImpl(this._closedWorld, this._selectorConstraintsStrategy,
      this._oneShotInterceptorData);

  ElementEnvironment get _elementEnvironment => _closedWorld.elementEnvironment;

  NativeBasicData get _nativeBasicData => _closedWorld.nativeData;

  Iterable<ClassEntity> get instantiatedClasses => _processedClasses.keys
      .where((cls) => _processedClasses[cls].isInstantiated);

  // TODO(johnniwinther): Improve semantic precision.
  @override
  Iterable<ClassEntity> get directlyInstantiatedClasses {
    return _directlyInstantiatedClasses;
  }

  /// Register [type] as (directly) instantiated.
  // TODO(johnniwinther): Fully enforce the separation between exact, through
  // subclass and through subtype instantiated types/classes.
  // TODO(johnniwinther): Support unknown type arguments for generic types.
  void registerTypeInstantiation(
      InterfaceType type, ClassUsedCallback classUsed) {
    ClassEntity cls = type.element;
    bool isNative = _nativeBasicData.isNativeClass(cls);
    _instantiatedTypes.add(type);
    // We can't use the closed-world assumption with native abstract
    // classes; a native abstract class may have non-abstract subclasses
    // not declared to the program.  Instances of these classes are
    // indistinguishable from the abstract class.
    if (!cls.isAbstract || isNative) {
      _directlyInstantiatedClasses.add(cls);
      _processInstantiatedClass(cls, classUsed);
    }

    // TODO(johnniwinther): Replace this by separate more specific mappings that
    // include the type arguments.
    if (_implementedClasses.add(cls)) {
      classUsed(cls, _getClassUsage(cls).implement());
      _elementEnvironment.forEachSupertype(cls, (InterfaceType supertype) {
        if (_implementedClasses.add(supertype.element)) {
          classUsed(
              supertype.element, _getClassUsage(supertype.element).implement());
        }
      });
    }
  }

  bool _hasMatchingSelector(Map<Selector, SelectorConstraints> selectors,
      MemberEntity member, JClosedWorld world) {
    if (selectors == null) return false;
    for (Selector selector in selectors.keys) {
      if (selector.appliesUnnamed(member)) {
        SelectorConstraints masks = selectors[selector];
        if (masks.canHit(member, selector.memberName, world)) {
          return true;
        }
      }
    }
    return false;
  }

  Iterable<CallStructure> _getMatchingCallStructures(
      Map<Selector, SelectorConstraints> selectors, MemberEntity member) {
    if (selectors == null) return const [];
    Set<CallStructure> callStructures;
    for (Selector selector in selectors.keys) {
      if (selector.appliesUnnamed(member)) {
        SelectorConstraints masks = selectors[selector];
        if (masks.canHit(member, selector.memberName, _closedWorld)) {
          callStructures ??= {};
          callStructures.add(selector.callStructure);
        }
      }
    }
    return callStructures ?? const [];
  }

  Iterable<CallStructure> _getInvocationCallStructures(MemberEntity member) {
    return _getMatchingCallStructures(_invokedNames[member.name], member);
  }

  bool _hasInvokedGetter(MemberEntity member) {
    return _hasMatchingSelector(
        _invokedGetters[member.name], member, _closedWorld);
  }

  bool _hasInvokedSetter(MemberEntity member) {
    return _hasMatchingSelector(
        _invokedSetters[member.name], member, _closedWorld);
  }

  void registerDynamicUse(
      DynamicUse dynamicUse, MemberUsedCallback memberUsed) {
    Selector selector = dynamicUse.selector;
    String methodName = selector.name;

    void _process(
        Map<String, Set<MemberUsage>> memberMap,
        EnumSet<MemberUse> action(MemberUsage usage),
        bool shouldBeRemoved(MemberUsage usage)) {
      _processSet(memberMap, methodName, (MemberUsage usage) {
        if (selector.appliesUnnamed(usage.entity) &&
            _selectorConstraintsStrategy.appliedUnnamed(
                dynamicUse, usage.entity, _closedWorld)) {
          memberUsed(usage.entity, action(usage));
          return shouldBeRemoved(usage);
        }
        return false;
      });
    }

    switch (dynamicUse.kind) {
      case DynamicUseKind.INVOKE:
        registerDynamicInvocation(
            dynamicUse.selector, dynamicUse.typeArguments);
        if (_registerNewSelector(dynamicUse, _invokedNames)) {
          _process(
              _invokableInstanceMembersByName,
              (m) => m.invoke(Accesses.dynamicAccess, selector.callStructure),
              // If not all optional parameters have been passed in invocations
              // we must keep the member in [_invokableInstanceMembersByName].
              (u) => !u.hasPendingDynamicInvoke);
        }
        break;
      case DynamicUseKind.GET:
        if (_registerNewSelector(dynamicUse, _invokedGetters)) {
          _process(
              _readableInstanceMembersByName,
              (m) => m.read(Accesses.dynamicAccess),
              (u) => !u.hasPendingDynamicRead);
        }
        break;
      case DynamicUseKind.SET:
        if (_registerNewSelector(dynamicUse, _invokedSetters)) {
          _process(
              _writableInstanceMembersByName,
              (m) => m.write(Accesses.dynamicAccess),
              (u) => !u.hasPendingDynamicWrite);
        }
        break;
    }
  }

  bool _registerNewSelector(DynamicUse dynamicUse,
      Map<String, Map<Selector, SelectorConstraints>> selectorMap) {
    Selector selector = dynamicUse.selector;
    String name = selector.name;
    Object constraint = dynamicUse.receiverConstraint;
    Map<Selector, SelectorConstraints> selectors =
        selectorMap[name] ??= Maplet<Selector, SelectorConstraints>();
    UniverseSelectorConstraints constraints = selectors[selector];
    if (constraints == null) {
      selectors[selector] = _selectorConstraintsStrategy
          .createSelectorConstraints(selector, constraint);
      return true;
    }
    return constraints.addReceiverConstraint(constraint);
  }

  void registerIsCheck(covariant DartType type) {
    _isChecks.add(type);
  }

  void registerNamedTypeVariableNewRti(TypeVariableType type) {
    _namedTypeVariablesNewRti.add(type);
  }

  void registerStaticUse(StaticUse staticUse, MemberUsedCallback memberUsed) {
    MemberEntity element = staticUse.element;
    EnumSet<MemberUse> useSet = EnumSet<MemberUse>();
    MemberUsage usage = _getMemberUsage(element, useSet);
    switch (staticUse.kind) {
      case StaticUseKind.STATIC_TEAR_OFF:
        useSet.addAll(usage.read(Accesses.staticAccess));
        break;
      case StaticUseKind.INSTANCE_FIELD_GET:
      case StaticUseKind.INSTANCE_FIELD_SET:
      case StaticUseKind.CALL_METHOD:
        // TODO(johnniwinther): Avoid this. Currently [FIELD_GET] and
        // [FIELD_SET] contains [BoxFieldElement]s which we cannot enqueue.
        // Also [CLOSURE] contains [LocalFunctionElement] which we cannot
        // enqueue.
        break;
      case StaticUseKind.SUPER_INVOKE:
        registerStaticInvocation(staticUse);
        useSet.addAll(
            usage.invoke(Accesses.superAccess, staticUse.callStructure));
        break;
      case StaticUseKind.STATIC_INVOKE:
        registerStaticInvocation(staticUse);
        useSet.addAll(
            usage.invoke(Accesses.staticAccess, staticUse.callStructure));
        break;
      case StaticUseKind.SUPER_FIELD_SET:
        useSet.addAll(usage.write(Accesses.superAccess));
        break;
      case StaticUseKind.SUPER_SETTER_SET:
        useSet.addAll(usage.write(Accesses.superAccess));
        break;
      case StaticUseKind.STATIC_SET:
        useSet.addAll(usage.write(Accesses.staticAccess));
        break;
      case StaticUseKind.SUPER_TEAR_OFF:
        useSet.addAll(usage.read(Accesses.superAccess));
        break;
      case StaticUseKind.SUPER_GET:
        useSet.addAll(usage.read(Accesses.superAccess));
        break;
      case StaticUseKind.STATIC_GET:
        useSet.addAll(usage.read(Accesses.staticAccess));
        break;
      case StaticUseKind.FIELD_INIT:
        useSet.addAll(usage.init());
        break;
      case StaticUseKind.FIELD_CONSTANT_INIT:
        useSet.addAll(usage.constantInit(staticUse.constant));
        break;
      case StaticUseKind.CONSTRUCTOR_INVOKE:
      case StaticUseKind.CONST_CONSTRUCTOR_INVOKE:
        // We don't track parameters in the codegen world builder, so we
        // pass `null` instead of the concrete call structure.
        useSet.addAll(
            usage.invoke(Accesses.staticAccess, staticUse.callStructure));
        break;
      case StaticUseKind.DIRECT_INVOKE:
        MemberEntity member = staticUse.element;
        // We don't track parameters in the codegen world builder, so we
        // pass `null` instead of the concrete call structure.
        useSet.addAll(
            usage.invoke(Accesses.staticAccess, staticUse.callStructure));
        if (staticUse.typeArguments?.isNotEmpty ?? false) {
          registerDynamicInvocation(
              Selector.call(member.memberName, staticUse.callStructure),
              staticUse.typeArguments);
        }
        break;
      case StaticUseKind.INLINING:
        registerStaticInvocation(staticUse);
        break;
      case StaticUseKind.CLOSURE:
      case StaticUseKind.CLOSURE_CALL:
        failedAt(CURRENT_ELEMENT_SPANNABLE,
            "Static use ${staticUse.kind} is not supported during codegen.");
    }
    if (useSet.isNotEmpty) {
      memberUsed(usage.entity, useSet);
    }
  }

  void processClassMembers(ClassEntity cls, MemberUsedCallback memberUsed,
      {bool checkEnqueuerConsistency: false}) {
    _elementEnvironment.forEachClassMember(cls,
        (ClassEntity cls, MemberEntity member) {
      _processInstantiatedClassMember(cls, member, memberUsed,
          checkEnqueuerConsistency: checkEnqueuerConsistency);
    });
  }

  void _processInstantiatedClassMember(
      ClassEntity cls, MemberEntity member, MemberUsedCallback memberUsed,
      {bool checkEnqueuerConsistency: false}) {
    if (!member.isInstanceMember) return;
    EnumSet<MemberUse> useSet = EnumSet<MemberUse>();
    MemberUsage usage = _getMemberUsage(member, useSet);
    if (useSet.isNotEmpty) {
      if (checkEnqueuerConsistency) {
        throw SpannableAssertionFailure(member,
            'Unenqueued usage of $member: \nbefore: <none>\nafter : $usage');
      } else {
        memberUsed(member, useSet);
      }
    }
  }

  MemberUsage _getMemberUsage(MemberEntity member, EnumSet<MemberUse> useSet,
      {bool checkEnqueuerConsistency: false}) {
    // TODO(johnniwinther): Change [TypeMask] to not apply to a superclass
    // member unless the class has been instantiated. Similar to
    // [StrongModeConstraint].
    MemberUsage usage = _memberUsage[member];
    if (usage == null) {
      MemberAccess potentialAccess = _closedWorld.getMemberAccess(member);
      if (member.isInstanceMember) {
        String memberName = member.name;
        ClassEntity cls = member.enclosingClass;
        bool isNative = _nativeBasicData.isNativeClass(cls);
        usage = MemberUsage(member, potentialAccess: potentialAccess);
        if (member.isField && !isNative) {
          useSet.addAll(usage.init());
        }
        if (member is JSignatureMethod) {
          // We mark signature methods as "always used" to prevent them from
          // being optimized away.
          // TODO(johnniwinther): Make this a part of the regular enqueueing.
          useSet.addAll(
              usage.invoke(Accesses.dynamicAccess, CallStructure.NO_ARGS));
        }

        if (usage.hasPendingDynamicRead && _hasInvokedGetter(member)) {
          useSet.addAll(usage.read(Accesses.dynamicAccess));
        }
        if (usage.hasPendingDynamicWrite && _hasInvokedSetter(member)) {
          useSet.addAll(usage.write(Accesses.dynamicAccess));
        }
        if (usage.hasPendingDynamicInvoke) {
          Iterable<CallStructure> callStructures =
              _getInvocationCallStructures(member);
          for (CallStructure callStructure in callStructures) {
            useSet.addAll(usage.invoke(Accesses.dynamicAccess, callStructure));
            if (!usage.hasPendingDynamicInvoke) {
              break;
            }
          }
        }

        if (!checkEnqueuerConsistency) {
          if (usage.hasPendingDynamicInvoke) {
            _invokableInstanceMembersByName
                .putIfAbsent(memberName, () => {})
                .add(usage);
          }
          if (usage.hasPendingDynamicRead) {
            _readableInstanceMembersByName
                .putIfAbsent(memberName, () => {})
                .add(usage);
          }
          if (usage.hasPendingDynamicWrite) {
            _writableInstanceMembersByName
                .putIfAbsent(memberName, () => {})
                .add(usage);
          }
        }
      } else {
        usage = MemberUsage(member, potentialAccess: potentialAccess);
        if (member.isField) {
          useSet.addAll(usage.init());
        }
      }
      if (!checkEnqueuerConsistency) {
        _memberUsage[member] = usage;
      }
    } else {
      if (checkEnqueuerConsistency) {
        usage = usage.clone();
      }
    }
    return usage;
  }

  void _processSet(Map<String, Set<MemberUsage>> map, String memberName,
      bool f(MemberUsage e)) {
    Set<MemberUsage> members = map[memberName];
    if (members == null) return;
    // [f] might add elements to [: map[memberName] :] during the loop below
    // so we create a new list for [: map[memberName] :] and prepend the
    // [remaining] members after the loop.
    map[memberName] = {};
    Set<MemberUsage> remaining = {};
    for (MemberUsage member in members) {
      if (!f(member)) remaining.add(member);
    }
    map[memberName].addAll(remaining);
  }

  /// Return the canonical [ClassUsage] for [cls].
  ClassUsage _getClassUsage(ClassEntity cls) {
    return _processedClasses.putIfAbsent(cls, () => ClassUsage(cls));
  }

  void _processInstantiatedClass(ClassEntity cls, ClassUsedCallback classUsed) {
    // Registers [superclass] as instantiated. Returns `true` if it wasn't
    // already instantiated and we therefore have to process its superclass as
    // well.
    bool processClass(ClassEntity superclass) {
      ClassUsage usage = _getClassUsage(superclass);
      if (!usage.isInstantiated) {
        classUsed(usage.cls, usage.instantiate());
        return true;
      }
      return false;
    }

    while (cls != null && processClass(cls)) {
      cls = _elementEnvironment.getSuperClass(cls);
    }
  }

  /// Set of all registered compiled constants.
  final Set<ConstantValue> _compiledConstants = {};

  Iterable<ConstantValue> get compiledConstantsForTesting => _compiledConstants;

  @override
  void addCompileTimeConstantForEmission(ConstantValue constant) {
    _compiledConstants.add(constant);
  }

  /// Register the constant [use] with this world builder. Returns `true` if
  /// the constant use was new to the world.
  bool registerConstantUse(ConstantUse use) {
    addCompileTimeConstantForEmission(use.value);
    return _constantValues.add(use.value);
  }

  void registerConstTypeLiteral(DartType type) {
    _constTypeLiterals.add(type);
  }

  void registerTypeArgument(DartType type) {
    _liveTypeArguments.add(type);
  }

  void registerConstructorReference(InterfaceType type) {
    _constructorReferences.add(type.element);
  }

  @override
  CodegenWorld close() {
    Map<MemberEntity, MemberUsage> liveMemberUsage = {};
    _memberUsage.forEach((MemberEntity member, MemberUsage usage) {
      if (usage.hasUse) {
        liveMemberUsage[member] = usage;
      }
    });
    return CodegenWorldImpl(_closedWorld, liveMemberUsage,
        constTypeLiterals: _constTypeLiterals,
        constructorReferences: _constructorReferences,
        directlyInstantiatedClasses: directlyInstantiatedClasses,
        typeVariableTypeLiterals: typeVariableTypeLiterals,
        instantiatedClasses: instantiatedClasses,
        isChecks: _isChecks,
        namedTypeVariablesNewRti: _namedTypeVariablesNewRti,
        instantiatedTypes: _instantiatedTypes,
        liveTypeArguments: _liveTypeArguments,
        compiledConstants: _compiledConstants,
        invokedNames: _invokedNames,
        invokedGetters: _invokedGetters,
        invokedSetters: _invokedSetters,
        staticTypeArgumentDependencies: staticTypeArgumentDependencies,
        dynamicTypeArgumentDependencies: dynamicTypeArgumentDependencies,
        oneShotInterceptorData: _oneShotInterceptorData);
  }
}

class CodegenWorldImpl implements CodegenWorld {
  JClosedWorld _closedWorld;

  final Map<MemberEntity, MemberUsage> _liveMemberUsage;

  @override
  final Iterable<DartType> constTypeLiterals;

  @override
  final Iterable<ClassEntity> constructorReferences;

  @override
  final Iterable<ClassEntity> directlyInstantiatedClasses;

  @override
  final Iterable<TypeVariableType> typeVariableTypeLiterals;

  @override
  final Iterable<ClassEntity> instantiatedClasses;

  @override
  final Iterable<DartType> isChecks;

  @override
  final Set<TypeVariableType> namedTypeVariablesNewRti;

  @override
  final Iterable<InterfaceType> instantiatedTypes;

  @override
  final Iterable<DartType> liveTypeArguments;

  final Iterable<ConstantValue> _compiledConstants;

  final Map<String, Map<Selector, SelectorConstraints>> _invokedNames;

  final Map<String, Map<Selector, SelectorConstraints>> _invokedGetters;

  final Map<String, Map<Selector, SelectorConstraints>> _invokedSetters;

  final Map<Entity, Set<DartType>> _staticTypeArgumentDependencies;

  final Map<Selector, Set<DartType>> _dynamicTypeArgumentDependencies;

  @override
  final OneShotInterceptorData oneShotInterceptorData;

  CodegenWorldImpl(this._closedWorld, this._liveMemberUsage,
      {this.constTypeLiterals,
      this.constructorReferences,
      this.directlyInstantiatedClasses,
      this.typeVariableTypeLiterals,
      this.instantiatedClasses,
      this.isChecks,
      this.namedTypeVariablesNewRti,
      this.instantiatedTypes,
      this.liveTypeArguments,
      Iterable<ConstantValue> compiledConstants,
      Map<String, Map<Selector, SelectorConstraints>> invokedNames,
      Map<String, Map<Selector, SelectorConstraints>> invokedGetters,
      Map<String, Map<Selector, SelectorConstraints>> invokedSetters,
      Map<Entity, Set<DartType>> staticTypeArgumentDependencies,
      Map<Selector, Set<DartType>> dynamicTypeArgumentDependencies,
      this.oneShotInterceptorData})
      : _compiledConstants = compiledConstants,
        _invokedNames = invokedNames,
        _invokedGetters = invokedGetters,
        _invokedSetters = invokedSetters,
        _staticTypeArgumentDependencies = staticTypeArgumentDependencies,
        _dynamicTypeArgumentDependencies = dynamicTypeArgumentDependencies;

  @override
  AnnotationsData get annotationsData => _closedWorld.annotationsData;

  @override
  void forEachStaticField(void Function(FieldEntity) f) {
    bool failure = false;
    _liveMemberUsage.forEach((MemberEntity member, MemberUsage usage) {
      if (member is FieldEntity && (member.isStatic || member.isTopLevel)) {
        f(member);
      }
    });
    if (failure) throw 'failure';
  }

  @override
  void forEachGenericMethod(Function f) {
    _liveMemberUsage.forEach((MemberEntity member, MemberUsage usage) {
      if (member is FunctionEntity &&
          _closedWorld.elementEnvironment
              .getFunctionTypeVariables(member)
              .isNotEmpty) {
        f(member);
      }
    });
  }

  @override
  void forEachGenericInstanceMethod(Function f) {
    _liveMemberUsage.forEach((MemberEntity member, MemberUsage usage) {
      if (member is FunctionEntity &&
          member.isInstanceMember &&
          _closedWorld.elementEnvironment
              .getFunctionTypeVariables(member)
              .isNotEmpty) {
        f(member);
      }
    });
  }

  @override
  void forEachGenericClosureCallMethod(Function f) {
    _liveMemberUsage.forEach((MemberEntity member, MemberUsage usage) {
      if (member.name == Identifiers.call &&
          member.isInstanceMember &&
          member.enclosingClass.isClosure &&
          member is FunctionEntity &&
          _closedWorld.elementEnvironment
              .getFunctionTypeVariables(member)
              .isNotEmpty) {
        f(member);
      }
    });
  }

  List<FunctionEntity> _userNoSuchMethodsCache;

  @override
  Iterable<FunctionEntity> get userNoSuchMethods {
    if (_userNoSuchMethodsCache == null) {
      _userNoSuchMethodsCache = [];

      _liveMemberUsage.forEach((MemberEntity member, MemberUsage memberUsage) {
        if (member is FunctionEntity) {
          if (member.isInstanceMember &&
              member.name == Identifiers.noSuchMethod_ &&
              !_closedWorld.commonElements
                  .isDefaultNoSuchMethodImplementation(member)) {
            _userNoSuchMethodsCache.add(member);
          }
        }
      });
    }

    return _userNoSuchMethodsCache;
  }

  @override
  Iterable<Local> get genericLocalFunctions => const [];

  Set<FunctionEntity> _closurizedMembersCache;

  @override
  Iterable<FunctionEntity> get closurizedMembers {
    if (_closurizedMembersCache == null) {
      _closurizedMembersCache = {};
      _liveMemberUsage.forEach((MemberEntity member, MemberUsage usage) {
        if ((member.isFunction || member is JGeneratorBody) &&
            member.isInstanceMember &&
            usage.hasRead) {
          _closurizedMembersCache.add(member);
        }
      });
    }
    return _closurizedMembersCache;
  }

  Set<FunctionEntity> _closurizedStaticsCache;

  @override
  Iterable<FunctionEntity> get closurizedStatics {
    if (_closurizedStaticsCache == null) {
      _closurizedStaticsCache = {};
      _liveMemberUsage.forEach((MemberEntity member, MemberUsage usage) {
        if (member.isFunction &&
            (member.isStatic || member.isTopLevel) &&
            usage.hasRead) {
          _closurizedStaticsCache.add(member);
        }
      });
    }
    return _closurizedStaticsCache;
  }

  Map<MemberEntity, DartType> _genericCallablePropertiesCache;

  @override
  Map<MemberEntity, DartType> get genericCallableProperties {
    if (_genericCallablePropertiesCache == null) {
      _genericCallablePropertiesCache = {};
      _liveMemberUsage.forEach((MemberEntity member, MemberUsage usage) {
        if (usage.hasRead) {
          DartType type;
          if (member.isField) {
            type = _closedWorld.elementEnvironment.getFieldType(member);
          } else if (member.isGetter) {
            type = _closedWorld.elementEnvironment
                .getFunctionType(member)
                .returnType;
          }
          if (type == null) return;
          if (_closedWorld.dartTypes.canAssignGenericFunctionTo(type)) {
            _genericCallablePropertiesCache[member] = type;
          }
        }
      });
    }
    return _genericCallablePropertiesCache;
  }

  @override
  void forEachStaticTypeArgument(
      void f(Entity function, Set<DartType> typeArguments)) {
    _staticTypeArgumentDependencies.forEach(f);
  }

  @override
  void forEachDynamicTypeArgument(
      void f(Selector selector, Set<DartType> typeArguments)) {
    _dynamicTypeArgumentDependencies.forEach(f);
  }

  @override
  void forEachInvokedName(
      f(String name, Map<Selector, SelectorConstraints> selectors)) {
    _invokedNames.forEach(f);
  }

  @override
  void forEachInvokedGetter(
      f(String name, Map<Selector, SelectorConstraints> selectors)) {
    _invokedGetters.forEach(f);
  }

  @override
  void forEachInvokedSetter(
      f(String name, Map<Selector, SelectorConstraints> selectors)) {
    _invokedSetters.forEach(f);
  }

  @override
  bool hasInvokedGetter(MemberEntity member) {
    MemberUsage memberUsage = _liveMemberUsage[member];
    if (memberUsage == null) return false;
    return memberUsage.reads.contains(Access.dynamicAccess);
  }

  @override
  bool methodsNeedsSuperGetter(FunctionEntity function) {
    MemberUsage memberUsage = _liveMemberUsage[function];
    if (memberUsage == null) return false;
    return memberUsage.reads.contains(Access.superAccess);
  }

  @override
  bool hasInvokedSetter(MemberEntity member) {
    MemberUsage memberUsage = _liveMemberUsage[member];
    if (memberUsage == null) return false;
    return memberUsage.writes.contains(Access.dynamicAccess);
  }

  Map<Selector, SelectorConstraints> _asUnmodifiable(
      Map<Selector, SelectorConstraints> map) {
    if (map == null) return null;
    return UnmodifiableMapView(map);
  }

  @override
  Map<Selector, SelectorConstraints> invocationsByName(String name) {
    return _asUnmodifiable(_invokedNames[name]);
  }

  @override
  Iterable<Selector> getterInvocationsByName(String name) {
    return _invokedGetters[name]?.keys;
  }

  @override
  Iterable<Selector> setterInvocationsByName(String name) {
    return _invokedSetters[name]?.keys;
  }

  @override
  Iterable<ConstantValue> getConstantsForEmission(
      [Comparator<ConstantValue> preSortCompare]) {
    // We must emit dependencies before their uses.
    Set<ConstantValue> seenConstants = {};
    List<ConstantValue> result = [];

    void addConstant(ConstantValue constant) {
      if (!seenConstants.contains(constant)) {
        constant.getDependencies().forEach(addConstant);
        assert(!seenConstants.contains(constant));
        result.add(constant);
        seenConstants.add(constant);
      }
    }

    if (preSortCompare != null) {
      List<ConstantValue> sorted = _compiledConstants.toList();
      sorted.sort(preSortCompare);
      sorted.forEach(addConstant);
    } else {
      _compiledConstants.forEach(addConstant);
    }
    return result;
  }

  @override
  bool isAliasedSuperMember(MemberEntity member) {
    MemberUsage usage = _liveMemberUsage[member];
    if (usage == null) return false;
    return usage.invokes.contains(Access.superAccess) ||
        usage.writes.contains(Access.superAccess);
  }
}
