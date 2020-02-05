// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common.dart';
import '../common/names.dart' show Identifiers, Names;
import '../common_elements.dart';
import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import '../ir/static_type.dart';
import '../js_backend/annotations.dart';
import '../js_backend/field_analysis.dart' show KFieldAnalysis;
import '../js_backend/backend_usage.dart'
    show BackendUsage, BackendUsageBuilder;
import '../js_backend/interceptor_data.dart' show InterceptorDataBuilder;
import '../js_backend/native_data.dart' show NativeBasicData, NativeDataBuilder;
import '../js_backend/no_such_method_registry.dart';
import '../js_backend/runtime_types_resolution.dart';
import '../kernel/element_map_impl.dart';
import '../kernel/kernel_world.dart';
import '../native/enqueue.dart' show NativeResolutionEnqueuer;
import '../options.dart';
import '../util/enumset.dart';
import '../util/util.dart';
import '../world.dart' show KClosedWorld, OpenWorld;
import 'call_structure.dart';
import 'class_hierarchy.dart' show ClassHierarchyBuilder, ClassQueries;
import 'class_set.dart';
import 'member_usage.dart';
import 'selector.dart' show Selector;
import 'use.dart'
    show ConstantUse, DynamicUse, DynamicUseKind, StaticUse, StaticUseKind;
import 'world_builder.dart';

abstract class ResolutionWorldBuilder implements WorldBuilder, OpenWorld {
  /// Returns `true` if [member] has been marked as used (called, read, etc.) in
  /// this world builder.
  // TODO(johnniwinther): Maybe this should be part of [ClosedWorld] (instead).
  bool isMemberUsed(MemberEntity member);

  /// The closed world computed by this world builder.
  ///
  /// This is only available after the world builder has been closed.
  KClosedWorld get closedWorldForTesting;

  void registerClass(ClassEntity cls);
}

/// Extended [ResolutionWorldBuilder] interface used by the
/// [ResolutionEnqueuer].
abstract class ResolutionEnqueuerWorldBuilder extends ResolutionWorldBuilder {
  /// Returns the classes registered as directly or indirectly instantiated.
  Iterable<ClassEntity> get processedClasses;

  /// Registers that [element] has been closurized.
  void registerClosurizedMember(MemberEntity element);

  /// Register [type] as (directly) instantiated.
  // TODO(johnniwinther): Fully enforce the separation between exact, through
  // subclass and through subtype instantiated types/classes.
  // TODO(johnniwinther): Support unknown type arguments for generic types.
  void registerTypeInstantiation(
      InterfaceType type, ClassUsedCallback classUsed,
      {ConstructorEntity constructor});

  /// Computes usage for all members declared by [cls]. Calls [membersUsed] with
  /// the usage changes for each member.
  ///
  /// If [checkEnqueuerConsistency] is `true` we check that no new member
  /// usage can be found. This check is performed without changing the already
  /// collected member usage.
  void processClassMembers(ClassEntity cls, MemberUsedCallback memberUsed,
      {bool checkEnqueuerConsistency: false});

  /// Applies the [dynamicUse] to applicable instance members. Calls
  /// [membersUsed] with the usage changes for each member.
  void registerDynamicUse(DynamicUse dynamicUse, MemberUsedCallback memberUsed);

  /// Applies the [staticUse] to applicable members. Calls [membersUsed] with
  /// the usage changes for each member.
  void registerStaticUse(StaticUse staticUse, MemberUsedCallback memberUsed);

  /// Register the constant [use] with this world builder. Returns `true` if
  /// the constant use was new to the world.
  bool registerConstantUse(ConstantUse use);

  bool isMemberProcessed(MemberEntity member);
  void registerProcessedMember(MemberEntity member);
  Iterable<MemberEntity> get processedMembers;

  /// Registers that [type] is checked in this world builder.
  void registerIsCheck(DartType type);

  void registerNamedTypeVariableNewRti(TypeVariableType typeVariable);

  void registerTypeVariableTypeLiteral(TypeVariableType typeVariable);
}

/// The type and kind of an instantiation registered through
/// `ResolutionWorldBuilder.registerTypeInstantiation`.
class Instance {
  final InterfaceType type;
  final Instantiation kind;

  Instance(this.type, this.kind);

  @override
  int get hashCode {
    return Hashing.objectHash(type, Hashing.objectHash(kind));
  }

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! Instance) return false;
    return type == other.type && kind == other.kind;
  }

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write(type);
    if (kind == Instantiation.DIRECTLY_INSTANTIATED) {
      sb.write(' directly');
    } else if (kind == Instantiation.ABSTRACTLY_INSTANTIATED) {
      sb.write(' abstractly');
    } else if (kind == Instantiation.UNINSTANTIATED) {
      sb.write(' none');
    }
    return sb.toString();
  }
}

/// Information about instantiations of a class.
class InstantiationInfo {
  /// A map from constructor of the class to their instantiated types.
  ///
  /// For instance
  ///
  ///    import 'dart:html';
  ///
  ///    abstract class AbstractClass<S> {
  ///      factory AbstractClass.a() = Class<S>.a;
  ///      factory AbstractClass.b() => new Class<S>.b();
  ///    }
  ///    class Class<T> implements AbstractClass<T> {
  ///      Class.a();
  ///      Class.b();
  ///      factory Class.c() = Class.b<T>;
  ///    }
  ///
  ///
  ///    main() {
  ///      new Class.a();
  ///      new Class<int>.a();
  ///      new Class<String>.b();
  ///      new Class<num>.c();
  ///      new AbstractClass<double>.a();
  ///      new AbstractClass<bool>.b();
  ///      new DivElement(); // native instantiation
  ///    }
  ///
  /// will generate the mappings
  ///
  ///    AbstractClass: {
  ///      AbstractClass.a: {
  ///        AbstractClass<double> none, // from `new AbstractClass<double>.a()`
  ///      },
  ///      AbstractClass.b: {
  ///        AbstractClass<bool> none, // from `new AbstractClass<bool>.b()`
  ///      },
  ///    },
  ///    Class: {
  ///      Class.a: {
  ///        Class directly, // from `new Class.a()`
  ///        Class<int> directly, // from `new Class<int>.a()`
  ///        Class<S> directly redirect, // from `factory AbstractClass.a`
  ///      },
  ///      Class.b: {
  ///        Class<String> directly, // from `new Class<String>.b()`
  ///        Class<T> directly redirect, // from `factory Class.c`
  ///        Class<S> directly, // from `factory AbstractClass.b`
  ///      },
  ///      Class.c: {
  ///        Class<num> directly, // from `new Class<num>.c()`
  ///      },
  ///    },
  ///    DivElement: {
  ///      DivElement: {
  ///        DivElement abstractly, // from `new DivElement()`
  ///      },
  ///    }
  ///
  /// If the constructor is unknown, for instance for native or mirror usage,
  /// `null` is used as key.
  Map<ConstructorEntity, Set<Instance>> instantiationMap;

  /// Register [type] as the instantiation [kind] using [constructor].
  void addInstantiation(
      ConstructorEntity constructor, InterfaceType type, Instantiation kind) {
    instantiationMap ??= <ConstructorEntity, Set<Instance>>{};
    instantiationMap
        .putIfAbsent(constructor, () => new Set<Instance>())
        .add(new Instance(type, kind));
    switch (kind) {
      case Instantiation.DIRECTLY_INSTANTIATED:
        isDirectlyInstantiated = true;
        break;
      case Instantiation.ABSTRACTLY_INSTANTIATED:
        isAbstractlyInstantiated = true;
        break;
      case Instantiation.UNINSTANTIATED:
        break;
      default:
        throw new StateError("Instantiation $kind is not allowed.");
    }
  }

  /// `true` if the class is either directly or abstractly instantiated.
  bool get hasInstantiation =>
      isDirectlyInstantiated || isAbstractlyInstantiated;

  /// `true` if the class is directly instantiated.
  bool isDirectlyInstantiated = false;

  /// `true` if the class is abstractly instantiated.
  bool isAbstractlyInstantiated = false;

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('InstantiationInfo[');
    if (instantiationMap != null) {
      bool needsComma = false;
      instantiationMap
          .forEach((ConstructorEntity constructor, Set<Instance> set) {
        if (needsComma) {
          sb.write(', ');
        }
        if (constructor != null) {
          sb.write(constructor);
        } else {
          sb.write('<unknown>');
        }
        sb.write(': ');
        sb.write(set);
        needsComma = true;
      });
    }
    sb.write(']');
    return sb.toString();
  }
}

/// Implementation of [ResolutionEnqueuerWorldBuilder].
class ResolutionWorldBuilderImpl extends WorldBuilderBase
    implements ResolutionEnqueuerWorldBuilder {
  /// Instantiation information for all classes with instantiated types.
  ///
  /// Invariant: Elements are declaration elements.
  final Map<ClassEntity, InstantiationInfo> _instantiationInfo =
      <ClassEntity, InstantiationInfo>{};

  /// Classes implemented by directly instantiated classes.
  final Set<ClassEntity> _implementedClasses = new Set<ClassEntity>();

  /// The set of all referenced static fields.
  ///
  /// Invariant: Elements are declaration elements.
  final Set<FieldEntity> _allReferencedStaticFields = new Set<FieldEntity>();

  /// Documentation wanted -- johnniwinther
  ///
  /// Invariant: Elements are declaration elements.
  final Set<FunctionEntity> _methodsNeedingSuperGetter =
      new Set<FunctionEntity>();
  final Map<String, Map<Selector, SelectorConstraints>> _invokedNames =
      <String, Map<Selector, SelectorConstraints>>{};
  final Map<String, Map<Selector, SelectorConstraints>> _invokedGetters =
      <String, Map<Selector, SelectorConstraints>>{};
  final Map<String, Map<Selector, SelectorConstraints>> _invokedSetters =
      <String, Map<Selector, SelectorConstraints>>{};

  final Map<ClassEntity, ClassUsage> _processedClasses =
      <ClassEntity, ClassUsage>{};

  Map<ClassEntity, ClassUsage> get classUsageForTesting => _processedClasses;

  /// Map of registered usage of members of live classes.
  final Map<MemberEntity, MemberUsage> _memberUsage =
      <MemberEntity, MemberUsage>{};

  Map<MemberEntity, MemberUsage> get memberUsageForTesting => _memberUsage;

  /// Map containing instance members of live classes that have not yet been
  /// fully invoked dynamically.
  ///
  /// A method is fully invoked if all is optional parameter have been passed
  /// in some invocation.
  final Map<String, Set<MemberUsage>> _invokableInstanceMembersByName =
      <String, Set<MemberUsage>>{};

  /// Map containing instance members of live classes that have not yet been
  /// read from dynamically.
  final Map<String, Set<MemberUsage>> _readableInstanceMembersByName =
      <String, Set<MemberUsage>>{};

  /// Map containing instance members of live classes that have not yet been
  /// written to dynamically.
  final Map<String, Set<MemberUsage>> _writableInstanceMembersByName =
      <String, Set<MemberUsage>>{};

  final Set<FieldEntity> _fieldSetters = new Set<FieldEntity>();

  final Set<DartType> _isChecks = new Set<DartType>();
  final Set<TypeVariableType> _namedTypeVariablesNewRti = {};

  /// Set of all closures in the program. Used by the mirror tracking system
  /// to find all live closure instances.
  final Set<Local> _localFunctions = new Set<Local>();

  final Set<FunctionEntity> _closurizedMembersWithFreeTypeVariables =
      new Set<FunctionEntity>();

  final CompilerOptions _options;
  final ElementEnvironment _elementEnvironment;
  final DartTypes _dartTypes;
  final CommonElements _commonElements;

  final NativeBasicData _nativeBasicData;
  final NativeDataBuilder _nativeDataBuilder;
  final InterceptorDataBuilder _interceptorDataBuilder;
  final BackendUsageBuilder _backendUsageBuilder;
  final RuntimeTypesNeedBuilder _rtiNeedBuilder;
  final KFieldAnalysis _allocatorAnalysis;
  final NativeResolutionEnqueuer _nativeResolutionEnqueuer;
  final NoSuchMethodRegistry _noSuchMethodRegistry;
  final AnnotationsDataBuilder _annotationsDataBuilder;

  final SelectorConstraintsStrategy _selectorConstraintsStrategy;
  final ClassHierarchyBuilder _classHierarchyBuilder;
  final ClassQueries _classQueries;

  bool _closed = false;
  KClosedWorld _closedWorldCache;
  final Set<MemberEntity> _liveInstanceMembers = new Set<MemberEntity>();

  final Set<ConstantValue> _constantValues = new Set<ConstantValue>();

  final Set<Local> _genericLocalFunctions = new Set<Local>();

  Set<MemberEntity> _processedMembers = new Set<MemberEntity>();

  bool get isClosed => _closed;

  final KernelToElementMapImpl _elementMap;

  ResolutionWorldBuilderImpl(
      this._options,
      this._elementMap,
      this._elementEnvironment,
      this._dartTypes,
      this._commonElements,
      this._nativeBasicData,
      this._nativeDataBuilder,
      this._interceptorDataBuilder,
      this._backendUsageBuilder,
      this._rtiNeedBuilder,
      this._allocatorAnalysis,
      this._nativeResolutionEnqueuer,
      this._noSuchMethodRegistry,
      this._annotationsDataBuilder,
      this._selectorConstraintsStrategy,
      this._classHierarchyBuilder,
      this._classQueries);

  @override
  Iterable<ClassEntity> get processedClasses => _processedClasses.keys
      .where((cls) => _processedClasses[cls].isInstantiated);

  @override
  bool isMemberProcessed(MemberEntity member) =>
      _processedMembers.contains(member);

  @override
  void registerProcessedMember(MemberEntity member) {
    _processedMembers.add(member);
  }

  @override
  Iterable<MemberEntity> get processedMembers => _processedMembers;

  @override
  KClosedWorld get closedWorldForTesting {
    if (!_closed) {
      failedAt(
          NO_LOCATION_SPANNABLE, "The world builder has not yet been closed.");
    }
    return _closedWorldCache;
  }

  // TODO(johnniwinther): Improve semantic precision.
  @override
  Iterable<ClassEntity> get directlyInstantiatedClasses {
    Set<ClassEntity> classes = new Set<ClassEntity>();
    getInstantiationMap().forEach((ClassEntity cls, InstantiationInfo info) {
      if (info.hasInstantiation) {
        classes.add(cls);
      }
    });
    return classes;
  }

  @override
  void registerClosurizedMember(MemberEntity element) {
    FunctionType type = _elementEnvironment.getFunctionType(element);
    if (type.containsTypeVariables) {
      _closurizedMembersWithFreeTypeVariables.add(element);
    }
  }

  // TODO(johnniwinther): Fully enforce the separation between exact, through
  // subclass and through subtype instantiated types/classes.
  // TODO(johnniwinther): Support unknown type arguments for generic types.
  @override
  void registerTypeInstantiation(
      InterfaceType type, ClassUsedCallback classUsed,
      {ConstructorEntity constructor}) {
    ClassEntity cls = type.element;
    InstantiationInfo info =
        _instantiationInfo.putIfAbsent(cls, () => new InstantiationInfo());
    Instantiation kind = Instantiation.UNINSTANTIATED;
    bool isNative = _nativeBasicData.isNativeClass(cls);
    // We can't use the closed-world assumption with native abstract
    // classes; a native abstract class may have non-abstract subclasses
    // not declared to the program.  Instances of these classes are
    // indistinguishable from the abstract class.
    if (!cls.isAbstract || isNative) {
      if (isNative) {
        kind = Instantiation.ABSTRACTLY_INSTANTIATED;
      } else {
        kind = Instantiation.DIRECTLY_INSTANTIATED;
      }
    }
    info.addInstantiation(constructor, type, kind);
    if (kind != Instantiation.UNINSTANTIATED) {
      _classHierarchyBuilder.updateClassHierarchyNodeForClass(cls,
          directlyInstantiated: info.isDirectlyInstantiated,
          abstractlyInstantiated: info.isAbstractlyInstantiated);
      _processInstantiatedClass(cls, classUsed);
    }

    // TODO(johnniwinther): Use [_instantiationInfo] to compute this information
    // instead.
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

  Iterable<CallStructure> _getMatchingCallStructures(
      Map<Selector, SelectorConstraints> selectors, MemberEntity member) {
    if (selectors == null) return const <CallStructure>[];
    Set<CallStructure> callStructures;
    for (Selector selector in selectors.keys) {
      if (selector.appliesUnnamed(member)) {
        SelectorConstraints masks = selectors[selector];
        if (masks.canHit(member, selector.memberName, this)) {
          callStructures ??= new Set<CallStructure>();
          callStructures.add(selector.callStructure);
        }
      }
    }
    return callStructures ?? const <CallStructure>[];
  }

  bool _hasMatchingSelector(
      Map<Selector, SelectorConstraints> selectors, MemberEntity member) {
    if (selectors == null) return false;
    for (Selector selector in selectors.keys) {
      if (selector.appliesUnnamed(member)) {
        SelectorConstraints masks = selectors[selector];
        if (masks.canHit(member, selector.memberName, this)) {
          return true;
        }
      }
    }
    return false;
  }

  /// Returns the instantiation map used for computing the closed world.
  Map<ClassEntity, InstantiationInfo> getInstantiationMap() {
    return _instantiationInfo;
  }

  Iterable<CallStructure> _getInvocationCallStructures(MemberEntity member) {
    return _getMatchingCallStructures(_invokedNames[member.name], member);
  }

  bool _hasInvokedGetter(MemberEntity member) {
    return _hasMatchingSelector(_invokedGetters[member.name], member);
  }

  bool _hasInvokedSetter(MemberEntity member) {
    return _hasMatchingSelector(_invokedSetters[member.name], member);
  }

  @override
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
                dynamicUse, usage.entity, this)) {
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
              (m) => m.invoke(
                  Accesses.dynamicAccess, dynamicUse.selector.callStructure),
              // If not all optional parameters have been passed in invocations
              // we must keep the member in [_invokableInstanceMembersByName].
              // TODO(johnniwinther): Also remove from
              // [_readableInstanceMembersByName] in case of getters/setters.
              (u) => !u.hasPendingDynamicInvoke);
        }
        break;
      case DynamicUseKind.GET:
        if (_registerNewSelector(dynamicUse, _invokedGetters)) {
          _process(
              _readableInstanceMembersByName,
              (m) => m.read(Accesses.dynamicAccess),
              // TODO(johnniwinther): Members cannot be partially read so
              // we should always remove them.
              // TODO(johnniwinther): Also remove from
              // [_invokableInstanceMembersByName] in case of methods.
              (u) => !u.hasPendingDynamicRead);
        }
        break;
      case DynamicUseKind.SET:
        if (_registerNewSelector(dynamicUse, _invokedSetters)) {
          _process(
              _writableInstanceMembersByName,
              (m) => m.write(Accesses.dynamicAccess),
              // TODO(johnniwinther): Members cannot be partially written so
              // we should always remove them.
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
    Map<Selector, SelectorConstraints> selectors = selectorMap.putIfAbsent(
        name, () => new Maplet<Selector, SelectorConstraints>());
    UniverseSelectorConstraints constraints = selectors[selector];
    if (constraints == null) {
      selectors[selector] = _selectorConstraintsStrategy
          .createSelectorConstraints(selector, constraint);
      return true;
    }
    return constraints.addReceiverConstraint(constraint);
  }

  @override
  void registerIsCheck(covariant DartType type) {
    _isChecks.add(type);
  }

  @override
  void registerNamedTypeVariableNewRti(TypeVariableType type) {
    _namedTypeVariablesNewRti.add(type);
  }

  @override
  bool registerConstantUse(ConstantUse use) {
    return _constantValues.add(use.value);
  }

  @override
  void registerStaticUse(StaticUse staticUse, MemberUsedCallback memberUsed) {
    if (staticUse.kind == StaticUseKind.CLOSURE) {
      Local localFunction = staticUse.element;
      FunctionType type =
          _elementEnvironment.getLocalFunctionType(localFunction);
      if (type.typeVariables.isNotEmpty) {
        _genericLocalFunctions.add(localFunction);
      }
      _localFunctions.add(staticUse.element);
      return;
    } else if (staticUse.kind == StaticUseKind.CLOSURE_CALL) {
      if (staticUse.typeArguments?.isNotEmpty ?? false) {
        registerDynamicInvocation(
            new Selector.call(Names.call, staticUse.callStructure),
            staticUse.typeArguments);
      }
      return;
    }

    MemberEntity element = staticUse.element;
    EnumSet<MemberUse> useSet = new EnumSet<MemberUse>();
    MemberUsage usage = _getMemberUsage(element, useSet);

    if ((element.isStatic || element.isTopLevel) && element.isField) {
      _allReferencedStaticFields.add(staticUse.element);
    }
    // TODO(johnniwinther): Avoid this. Currently [FIELD_GET] and
    // [FIELD_SET] contains [BoxFieldElement]s which we cannot enqueue.
    // Also [CLOSURE] contains [LocalFunctionElement] which we cannot
    // enqueue.

    switch (staticUse.kind) {
      case StaticUseKind.INSTANCE_FIELD_GET:
        break;
      case StaticUseKind.INSTANCE_FIELD_SET:
        _fieldSetters.add(staticUse.element);
        break;
      case StaticUseKind.CLOSURE:
      case StaticUseKind.CLOSURE_CALL:
        // Already handled above.
        break;
      case StaticUseKind.SUPER_TEAR_OFF:
        useSet.addAll(usage.read(Accesses.superAccess));
        _methodsNeedingSuperGetter.add(staticUse.element);
        break;
      case StaticUseKind.SUPER_FIELD_SET:
        _fieldSetters.add(staticUse.element);
        useSet.addAll(usage.write(Accesses.superAccess));
        break;
      case StaticUseKind.SUPER_GET:
        useSet.addAll(usage.read(Accesses.superAccess));
        break;
      case StaticUseKind.STATIC_GET:
        useSet.addAll(usage.read(Accesses.staticAccess));
        break;
      case StaticUseKind.STATIC_TEAR_OFF:
        useSet.addAll(usage.read(Accesses.staticAccess));
        break;
      case StaticUseKind.SUPER_SETTER_SET:
        useSet.addAll(usage.write(Accesses.superAccess));
        break;
      case StaticUseKind.STATIC_SET:
        useSet.addAll(usage.write(Accesses.staticAccess));
        break;
      case StaticUseKind.FIELD_INIT:
        useSet.addAll(usage.init());
        break;
      case StaticUseKind.FIELD_CONSTANT_INIT:
        useSet.addAll(usage.constantInit(staticUse.constant));
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
      case StaticUseKind.CONSTRUCTOR_INVOKE:
      case StaticUseKind.CONST_CONSTRUCTOR_INVOKE:
        useSet.addAll(
            usage.invoke(Accesses.staticAccess, staticUse.callStructure));
        break;
      case StaticUseKind.DIRECT_INVOKE:
        failedAt(element, 'Direct static use is not supported for resolution.');
        break;
      case StaticUseKind.INLINING:
      case StaticUseKind.CALL_METHOD:
        failedAt(CURRENT_ELEMENT_SPANNABLE,
            "Static use ${staticUse.kind} is not supported during resolution.");
    }
    if (useSet.isNotEmpty) {
      memberUsed(usage.entity, useSet);
    }
  }

  /// Called to create a [ClassUsage] for [cls].
  ///
  /// Subclasses override this to ensure needed invariants on [cls].
  ClassUsage _createClassUsage(covariant ClassEntity cls) =>
      new ClassUsage(cls);

  /// Return the canonical [ClassUsage] for [cls].
  ClassUsage _getClassUsage(ClassEntity cls) {
    return _processedClasses.putIfAbsent(cls, () {
      return _createClassUsage(cls);
    });
  }

  /// Register [cls] and all its superclasses as instantiated.
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

  @override
  void processClassMembers(ClassEntity cls, MemberUsedCallback memberUsed,
      {bool checkEnqueuerConsistency: false}) {
    _elementEnvironment.forEachClassMember(cls,
        (ClassEntity cls, MemberEntity member) {
      _processInstantiatedClassMember(cls, member, memberUsed,
          checkEnqueuerConsistency: checkEnqueuerConsistency);
    });
  }

  /// Call [updateUsage] on all [MemberUsage]s in the set in [map] for
  /// [memberName]. If [updateUsage] returns `true` the usage is removed from
  /// the set.
  void _processSet(Map<String, Set<MemberUsage>> map, String memberName,
      bool updateUsage(MemberUsage e)) {
    Set<MemberUsage> members = map[memberName];
    if (members == null) return;
    // [f] might add elements to [: map[memberName] :] during the loop below
    // so we create a new list for [: map[memberName] :] and prepend the
    // [remaining] members after the loop.
    map[memberName] = new Set<MemberUsage>();
    Set<MemberUsage> remaining = new Set<MemberUsage>();
    for (MemberUsage usage in members) {
      if (!updateUsage(usage)) {
        remaining.add(usage);
      }
    }
    map[memberName].addAll(remaining);
  }

  MemberUsage _getMemberUsage(MemberEntity member, EnumSet<MemberUse> useSet,
      {bool checkEnqueuerConsistency: false}) {
    MemberUsage usage = _memberUsage[member];
    if (usage == null) {
      if (member.isInstanceMember) {
        String memberName = member.name;
        ClassEntity cls = member.enclosingClass;
        // TODO(johnniwinther): Change this to use isNativeMember when we use
        // CFE constants.
        // The obvious thing to test here would be "member.isNative",
        // however, that only works after metadata has been parsed/analyzed,
        // and that may not have happened yet.
        // So instead we use the enclosing class, which we know have had
        // its metadata parsed and analyzed.
        // Note: this assumes that there are no non-native fields on native
        // classes, which may not be the case when a native class is subclassed.
        bool isNative = _nativeBasicData.isNativeClass(cls);
        usage = new MemberUsage(member);
        if (member.isField && !isNative) {
          useSet.addAll(usage.init());
        }
        if (!checkEnqueuerConsistency) {
          if (member.isField && isNative) {
            registerUsedElement(member);
          }
          if (member.isFunction &&
              member.name == Identifiers.call &&
              _elementEnvironment.isGenericClass(cls)) {
            _closurizedMembersWithFreeTypeVariables.add(member);
          }
        }

        if (usage.hasPendingDynamicRead && _hasInvokedGetter(member)) {
          useSet.addAll(usage.read(Accesses.dynamicAccess));
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
        if (usage.hasPendingDynamicWrite && _hasInvokedSetter(member)) {
          useSet.addAll(usage.write(Accesses.dynamicAccess));
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
        usage = new MemberUsage(member);
        if (member.isField) {
          useSet.addAll(usage.init());
        }
      }
      if (!checkEnqueuerConsistency) {
        _memberUsage[member] = usage;
      }
    }
    return usage;
  }

  void _processInstantiatedClassMember(
      ClassEntity cls, MemberEntity member, MemberUsedCallback memberUsed,
      {bool checkEnqueuerConsistency: false}) {
    if (!member.isInstanceMember) return;
    String memberName = member.name;

    MemberUsage usage = _memberUsage[member];
    if (usage == null) {
      EnumSet<MemberUse> useSet = new EnumSet<MemberUse>();
      usage = _getMemberUsage(member, useSet,
          checkEnqueuerConsistency: checkEnqueuerConsistency);
      if (useSet.isNotEmpty) {
        if (checkEnqueuerConsistency) {
          throw new SpannableAssertionFailure(member,
              'Unenqueued usage of $member: \nbefore: <none>\nafter : $usage');
        } else {
          memberUsed(usage.entity, useSet);
        }
      }
    } else {
      MemberUsage original = usage;
      if (checkEnqueuerConsistency) {
        usage = usage.clone();
      }
      if (usage.hasPendingDynamicUse) {
        EnumSet<MemberUse> useSet = new EnumSet<MemberUse>();
        if (usage.hasPendingDynamicRead && _hasInvokedGetter(member)) {
          useSet.addAll(usage.read(Accesses.dynamicAccess));
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
        if (usage.hasPendingDynamicWrite && _hasInvokedSetter(member)) {
          useSet.addAll(usage.write(Accesses.dynamicAccess));
        }
        if (!checkEnqueuerConsistency) {
          if (!usage.hasPendingDynamicRead) {
            _readableInstanceMembersByName[memberName]?.remove(usage);
          }
          if (!usage.hasPendingDynamicInvoke) {
            _invokableInstanceMembersByName[memberName]?.remove(usage);
          }
          if (!usage.hasPendingDynamicWrite) {
            _writableInstanceMembersByName[memberName]?.remove(usage);
          }
        }
        if (checkEnqueuerConsistency && !original.dataEquals(usage)) {
          _elementMap.reporter.internalError(
              member,
              'Unenqueued usage of $member: \n'
              'before: $original\nafter : $usage');
        }
        memberUsed(usage.entity, useSet);
      }
    }
  }

  @override
  void registerUsedElement(MemberEntity element) {
    if (element.isInstanceMember && !element.isAbstract) {
      _liveInstanceMembers.add(element);
    }
  }

  @override
  bool isMemberUsed(MemberEntity member) {
    return _memberUsage[member]?.hasUse ?? false;
  }

  Map<ClassEntity, Set<ClassEntity>> populateHierarchyNodes() {
    Map<ClassEntity, Set<ClassEntity>> typesImplementedBySubclasses =
        new Map<ClassEntity, Set<ClassEntity>>();

    // Updates the `isDirectlyInstantiated` and `isIndirectlyInstantiated`
    // properties of the [ClassHierarchyNode] for [cls].

    void addSubtypes(ClassEntity cls, InstantiationInfo info) {
      if (!info.hasInstantiation) {
        return;
      }
      _classHierarchyBuilder.updateClassHierarchyNodeForClass(cls,
          directlyInstantiated: info.isDirectlyInstantiated,
          abstractlyInstantiated: info.isAbstractlyInstantiated);

      // Walk through the superclasses, and record the types
      // implemented by that type on the superclasses.
      ClassEntity superclass = _classQueries.getSuperClass(cls);
      while (superclass != null) {
        Set<ClassEntity> typesImplementedBySubclassesOfCls =
            typesImplementedBySubclasses.putIfAbsent(
                superclass, () => new Set<ClassEntity>());
        for (InterfaceType current in _classQueries.getSupertypes(cls)) {
          typesImplementedBySubclassesOfCls.add(current.element);
        }
        superclass = _classQueries.getSuperClass(superclass);
      }
    }

    // Use the [:seenClasses:] set to include non-instantiated
    // classes: if the superclass of these classes require RTI, then
    // they also need RTI, so that a constructor passes the type
    // variables to the super constructor.
    getInstantiationMap().forEach(addSubtypes);

    return typesImplementedBySubclasses;
  }

  Iterable<MemberEntity> computeAssignedInstanceMembers() {
    Set<MemberEntity> assignedInstanceMembers = new Set<MemberEntity>();
    for (MemberEntity instanceMember in _liveInstanceMembers) {
      if (_hasInvokedSetter(instanceMember)) {
        assignedInstanceMembers.add(instanceMember);
      }
    }
    assignedInstanceMembers.addAll(_fieldSetters);
    return assignedInstanceMembers;
  }

  @override
  void registerClass(ClassEntity cls) {
    _classHierarchyBuilder.registerClass(cls);
  }

  @override
  bool isInheritedIn(
      MemberEntity member, ClassEntity type, ClassRelation relation) {
    // TODO(johnniwinther): Use the [member] itself to avoid enqueueing members
    // that are overridden.
    return isInheritedInClass(member.enclosingClass, type, relation);
  }

  bool isInheritedInClass(ClassEntity memberHoldingClass, ClassEntity type,
      ClassRelation relation) {
    switch (relation) {
      case ClassRelation.exact:
        return _classHierarchyBuilder.isInheritedInExactClass(
            memberHoldingClass, type);
      case ClassRelation.thisExpression:
        return _classHierarchyBuilder.isInheritedInThisClass(
            memberHoldingClass, type);
      case ClassRelation.subtype:
        if (memberHoldingClass == _commonElements.nullClass ||
            memberHoldingClass == _commonElements.jsNullClass) {
          // Members of `Null` and `JSNull` are always potential targets.
          return true;
        }
        return _classHierarchyBuilder.isInheritedInSubtypeOf(
            memberHoldingClass, type);
    }
    throw new UnsupportedError("Unexpected ClassRelation $relation.");
  }

  @override
  KClosedWorld closeWorld(DiagnosticReporter reporter) {
    Map<ClassEntity, Set<ClassEntity>> typesImplementedBySubclasses =
        populateHierarchyNodes();

    BackendUsage backendUsage = _backendUsageBuilder.close();
    _closed = true;

    Map<MemberEntity, MemberUsage> liveMemberUsage = {};
    _memberUsage.forEach((MemberEntity member, MemberUsage memberUsage) {
      if (memberUsage.hasUse) {
        liveMemberUsage[member] = memberUsage;
        assert(_processedMembers.contains(member),
            "Member $member is used but not processed: $memberUsage.");
      } else {
        assert(!_processedMembers.contains(member),
            "Member $member is processed but not used: $memberUsage.");
      }
    });
    for (MemberEntity member in _processedMembers) {
      assert(_memberUsage.containsKey(member),
          "Member $member is processed but has not usage.");
    }

    Set<InterfaceType> instantiatedTypes = new Set<InterfaceType>();
    getInstantiationMap().forEach((_, InstantiationInfo info) {
      if (info.instantiationMap != null) {
        for (Set<Instance> instances in info.instantiationMap.values) {
          for (Instance instance in instances) {
            instantiatedTypes.add(instance.type);
          }
        }
      }
    });

    KClosedWorld closedWorld = new KClosedWorldImpl(_elementMap,
        options: _options,
        elementEnvironment: _elementEnvironment,
        dartTypes: _dartTypes,
        commonElements: _commonElements,
        nativeData: _nativeDataBuilder.close(),
        interceptorData: _interceptorDataBuilder.close(),
        backendUsage: backendUsage,
        noSuchMethodData: _noSuchMethodRegistry.close(),
        rtiNeedBuilder: _rtiNeedBuilder,
        fieldAnalysis: _allocatorAnalysis,
        implementedClasses: _implementedClasses,
        liveNativeClasses: _nativeResolutionEnqueuer.liveNativeClasses,
        liveInstanceMembers: _liveInstanceMembers,
        assignedInstanceMembers: computeAssignedInstanceMembers(),
        liveMemberUsage: liveMemberUsage,
        mixinUses: _classHierarchyBuilder.mixinUses,
        typesImplementedBySubclasses: typesImplementedBySubclasses,
        classHierarchy: _classHierarchyBuilder.close(),
        annotationsData: _annotationsDataBuilder.close(_options),
        isChecks: _isChecks,
        staticTypeArgumentDependencies: staticTypeArgumentDependencies,
        dynamicTypeArgumentDependencies: dynamicTypeArgumentDependencies,
        typeVariableTypeLiterals: typeVariableTypeLiterals,
        genericLocalFunctions: _genericLocalFunctions,
        closurizedMembersWithFreeTypeVariables:
            _closurizedMembersWithFreeTypeVariables,
        localFunctions: _localFunctions,
        instantiatedTypes: instantiatedTypes);
    if (retainDataForTesting) {
      _closedWorldCache = closedWorld;
    }
    return closedWorld;
  }
}
