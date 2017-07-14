// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of world_builder;

abstract class ResolutionWorldBuilder implements WorldBuilder, OpenWorld {
  /// Set of all local functions in the program. Used by the mirror tracking
  /// system to find all live closure instances.
  Iterable<Local> get localFunctions;

  /// Set of (live) local functions (closures) whose signatures reference type
  /// variables.
  ///
  /// A live function is one whose enclosing member function has been enqueued.
  Iterable<Local> get localFunctionsWithFreeTypeVariables;

  /// Set of methods in instantiated classes that are potentially closurized.
  Iterable<FunctionEntity> get closurizedMembers;

  /// Set of live closurized members whose signatures reference type variables.
  ///
  /// A closurized method is considered live if the enclosing class has been
  /// instantiated.
  Iterable<FunctionEntity> get closurizedMembersWithFreeTypeVariables;

  /// Returns `true` if [cls] is considered to be implemented by an
  /// instantiated class, either directly, through subclasses or through
  /// subtypes. The latter case only contains spurious information from
  /// instantiations through factory constructors and mixins.
  // TODO(johnniwinther): Improve semantic precision.
  bool isImplemented(covariant ClassEntity cls);

  /// Set of all fields that are statically known to be written to.
  Iterable<FieldEntity> get fieldSetters;

  /// Call [f] for all classes with instantiated types. This includes the
  /// directly and abstractly instantiated classes but also classes whose type
  /// arguments are used in live factory constructors.
  void forEachInstantiatedClass(f(ClassEntity cls, InstantiationInfo info));

  /// Returns `true` if [member] is invoked as a setter.
  bool hasInvokedSetter(MemberEntity member);

  /// Returns `true` if [member] has been marked as used (called, read, etc.) in
  /// this world builder.
  // TODO(johnniwinther): Maybe this should be part of [ClosedWorld] (instead).
  bool isMemberUsed(MemberEntity member);

  /// The closed world computed by this world builder.
  ///
  /// This is only available after the world builder has been closed.
  ClosedWorld get closedWorldForTesting;
}

/// Extended [ResolutionWorldBuilder] interface used by the
/// [ResolutionEnqueuer].
abstract class ResolutionEnqueuerWorldBuilder extends ResolutionWorldBuilder {
  /// Returns the classes registered as directly or indirectly instantiated.
  Iterable<ClassEntity> get processedClasses;

  /// Registers that [element] has been closurized.
  void registerClosurizedMember(MemberEntity element);

  /// Register [type] as (directly) instantiated.
  ///
  /// If [byMirrors] is `true`, the instantiation is through mirrors.
  // TODO(johnniwinther): Fully enforce the separation between exact, through
  // subclass and through subtype instantiated types/classes.
  // TODO(johnniwinther): Support unknown type arguments for generic types.
  void registerTypeInstantiation(
      InterfaceType type, ClassUsedCallback classUsed,
      {ConstructorEntity constructor,
      bool byMirrors: false,
      bool isRedirection: false});

  /// Computes usage for all members declared by [cls]. Calls [membersUsed] with
  /// the usage changes for each member.
  void processClassMembers(ClassEntity cls, MemberUsedCallback memberUsed);

  /// Applies the [dynamicUse] to applicable instance members. Calls
  /// [membersUsed] with the usage changes for each member.
  void registerDynamicUse(DynamicUse dynamicUse, MemberUsedCallback memberUsed);

  /// Applies the [staticUse] to applicable members. Calls [membersUsed] with
  /// the usage changes for each member.
  void registerStaticUse(StaticUse staticUse, MemberUsedCallback memberUsed);

  /// Register the constant [use] with this world builder. Returns `true` if
  /// the constant use was new to the world.
  bool registerConstantUse(ConstantUse use);
}

/// The type and kind of an instantiation registered through
/// `ResolutionWorldBuilder.registerTypeInstantiation`.
class Instance {
  final InterfaceType type;
  final Instantiation kind;
  final bool isRedirection;

  Instance(this.type, this.kind, {this.isRedirection: false});

  int get hashCode {
    return Hashing.objectHash(
        type, Hashing.objectHash(kind, Hashing.objectHash(isRedirection)));
  }

  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! Instance) return false;
    return type == other.type &&
        kind == other.kind &&
        isRedirection == other.isRedirection;
  }

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
    if (isRedirection) {
      sb.write(' redirect');
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
      ConstructorEntity constructor, InterfaceType type, Instantiation kind,
      {bool isRedirection: false}) {
    instantiationMap ??= <ConstructorEntity, Set<Instance>>{};
    instantiationMap
        .putIfAbsent(constructor, () => new Set<Instance>())
        .add(new Instance(type, kind, isRedirection: isRedirection));
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

/// Base implementation of [ResolutionEnqueuerWorldBuilder].
abstract class ResolutionWorldBuilderBase
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
  final Set<FieldEntity> allReferencedStaticFields = new Set<FieldEntity>();

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: Elements are declaration elements.
   */
  final Set<FunctionEntity> methodsNeedingSuperGetter =
      new Set<FunctionEntity>();
  final Map<String, Map<Selector, SelectorConstraints>> _invokedNames =
      <String, Map<Selector, SelectorConstraints>>{};
  final Map<String, Map<Selector, SelectorConstraints>> _invokedGetters =
      <String, Map<Selector, SelectorConstraints>>{};
  final Map<String, Map<Selector, SelectorConstraints>> _invokedSetters =
      <String, Map<Selector, SelectorConstraints>>{};

  final Map<ClassEntity, _ClassUsage> _processedClasses =
      <ClassEntity, _ClassUsage>{};

  Map<ClassEntity, _ClassUsage> get classUsageForTesting => _processedClasses;

  /// Map of registered usage of static members of live classes.
  final Map<Entity, _StaticMemberUsage> _staticMemberUsage =
      <Entity, _StaticMemberUsage>{};

  Map<Entity, _StaticMemberUsage> get staticMemberUsageForTesting =>
      _staticMemberUsage;

  /// Map of registered usage of instance members of live classes.
  final Map<MemberEntity, _MemberUsage> _instanceMemberUsage =
      <MemberEntity, _MemberUsage>{};

  Map<MemberEntity, _MemberUsage> get instanceMemberUsageForTesting =>
      _instanceMemberUsage;

  /// Map containing instance members of live classes that are not yet live
  /// themselves.
  final Map<String, Set<_MemberUsage>> _instanceMembersByName =
      <String, Set<_MemberUsage>>{};

  /// Map containing instance methods of live classes that are not yet
  /// closurized.
  final Map<String, Set<_MemberUsage>> _instanceFunctionsByName =
      <String, Set<_MemberUsage>>{};

  /// Fields set.
  final Set<FieldEntity> fieldSetters = new Set<FieldEntity>();
  final Set<DartType> isChecks = new Set<DartType>();

  /// Set of all closures in the program. Used by the mirror tracking system
  /// to find all live closure instances.
  final Set<Local> localFunctions = new Set<Local>();

  /// Set of live local functions (closures) whose signatures reference type
  /// variables.
  ///
  /// A local function is considered live if the enclosing member function is
  /// live.
  final Set<Local> localFunctionsWithFreeTypeVariables = new Set<Local>();

  /// Set of methods in instantiated classes that are potentially closurized.
  final Set<FunctionEntity> closurizedMembers = new Set<FunctionEntity>();

  /// Set of live closurized members whose signatures reference type variables.
  ///
  /// A closurized method is considered live if the enclosing class has been
  /// instantiated.
  final Set<FunctionEntity> closurizedMembersWithFreeTypeVariables =
      new Set<FunctionEntity>();

  final CompilerOptions _options;
  final ElementEnvironment _elementEnvironment;
  final DartTypes _dartTypes;
  final CommonElements _commonElements;
  final ConstantSystem _constantSystem;

  final NativeBasicData _nativeBasicData;
  final NativeDataBuilder _nativeDataBuilder;
  final InterceptorDataBuilder _interceptorDataBuilder;
  final BackendUsageBuilder _backendUsageBuilder;
  final RuntimeTypesNeedBuilder _rtiNeedBuilder;
  final NativeResolutionEnqueuer _nativeResolutionEnqueuer;

  final SelectorConstraintsStrategy selectorConstraintsStrategy;

  bool hasRuntimeTypeSupport = false;
  bool hasIsolateSupport = false;
  bool hasFunctionApplySupport = false;

  bool _closed = false;
  ClosedWorld _closedWorldCache;
  final Set<MemberEntity> _liveInstanceMembers = new Set<MemberEntity>();

  final Set<TypedefEntity> _allTypedefs = new Set<TypedefEntity>();

  final Map<ClassEntity, Set<ClassEntity>> _mixinUses =
      new Map<ClassEntity, Set<ClassEntity>>();

  // We keep track of subtype and subclass relationships in four
  // distinct sets to make class hierarchy analysis faster.
  final Map<ClassEntity, ClassHierarchyNode> _classHierarchyNodes =
      <ClassEntity, ClassHierarchyNode>{};
  final Map<ClassEntity, ClassSet> _classSets = <ClassEntity, ClassSet>{};

  final Set<ConstantValue> _constantValues = new Set<ConstantValue>();

  bool get isClosed => _closed;

  ResolutionWorldBuilderBase(
      this._options,
      this._elementEnvironment,
      this._dartTypes,
      this._commonElements,
      this._constantSystem,
      this._nativeBasicData,
      this._nativeDataBuilder,
      this._interceptorDataBuilder,
      this._backendUsageBuilder,
      this._rtiNeedBuilder,
      this._nativeResolutionEnqueuer,
      this.selectorConstraintsStrategy);

  Iterable<ClassEntity> get processedClasses => _processedClasses.keys
      .where((cls) => _processedClasses[cls].isInstantiated);

  ClosedWorld get closedWorldForTesting {
    if (!_closed) {
      failedAt(
          NO_LOCATION_SPANNABLE, "The world builder has not yet been closed.");
    }
    return _closedWorldCache;
  }

  /// All directly instantiated classes, that is, classes with a generative
  /// constructor that has been called directly and not only through a
  /// super-call.
  // TODO(johnniwinther): Improve semantic precision.
  Iterable<ClassEntity> get directlyInstantiatedClasses {
    Set<ClassEntity> classes = new Set<ClassEntity>();
    getInstantiationMap().forEach((ClassEntity cls, InstantiationInfo info) {
      if (info.hasInstantiation) {
        classes.add(cls);
      }
    });
    return classes;
  }

  /// All directly instantiated types, that is, the types of the directly
  /// instantiated classes.
  ///
  /// See [directlyInstantiatedClasses].
  // TODO(johnniwinther): Improve semantic precision.
  Iterable<InterfaceType> get instantiatedTypes {
    Set<InterfaceType> types = new Set<InterfaceType>();
    getInstantiationMap().forEach((_, InstantiationInfo info) {
      if (info.instantiationMap != null) {
        for (Set<Instance> instances in info.instantiationMap.values) {
          for (Instance instance in instances) {
            types.add(instance.type);
          }
        }
      }
    });
    return types;
  }

  bool isImplemented(ClassEntity cls) {
    return _implementedClasses.contains(cls);
  }

  void registerClosurizedMember(MemberEntity element) {
    closurizedMembers.add(element);
    FunctionType type = _elementEnvironment.getFunctionType(element);
    if (type.containsTypeVariables) {
      closurizedMembersWithFreeTypeVariables.add(element);
    }
  }

  /// Register [type] as (directly) instantiated.
  ///
  /// If [byMirrors] is `true`, the instantiation is through mirrors.
  // TODO(johnniwinther): Fully enforce the separation between exact, through
  // subclass and through subtype instantiated types/classes.
  // TODO(johnniwinther): Support unknown type arguments for generic types.
  void registerTypeInstantiation(
      InterfaceType type, ClassUsedCallback classUsed,
      {ConstructorEntity constructor,
      bool byMirrors: false,
      bool isRedirection: false}) {
    ClassEntity cls = type.element;
    InstantiationInfo info =
        _instantiationInfo.putIfAbsent(cls, () => new InstantiationInfo());
    Instantiation kind = Instantiation.UNINSTANTIATED;
    bool isNative = _nativeBasicData.isNativeClass(cls);
    if (!cls.isAbstract ||
        // We can't use the closed-world assumption with native abstract
        // classes; a native abstract class may have non-abstract subclasses
        // not declared to the program.  Instances of these classes are
        // indistinguishable from the abstract class.
        isNative ||
        // Likewise, if this registration comes from the mirror system,
        // all bets are off.
        // TODO(herhut): Track classes required by mirrors seperately.
        byMirrors) {
      if (isNative || byMirrors) {
        kind = Instantiation.ABSTRACTLY_INSTANTIATED;
      } else {
        kind = Instantiation.DIRECTLY_INSTANTIATED;
      }
      _processInstantiatedClass(cls, classUsed);
    }
    info.addInstantiation(constructor, type, kind,
        isRedirection: isRedirection);

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

  @override
  void forEachInstantiatedClass(f(ClassEntity cls, InstantiationInfo info)) {
    getInstantiationMap().forEach(f);
  }

  bool _hasMatchingSelector(
      Map<Selector, SelectorConstraints> selectors, MemberEntity member) {
    if (selectors == null) return false;
    for (Selector selector in selectors.keys) {
      if (selector.appliesUnnamed(member)) {
        SelectorConstraints masks = selectors[selector];
        if (masks.applies(member, selector, this)) {
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

  bool _hasInvocation(MemberEntity member) {
    return _hasMatchingSelector(_invokedNames[member.name], member);
  }

  bool _hasInvokedGetter(MemberEntity member) {
    return _hasMatchingSelector(_invokedGetters[member.name], member) ||
        member.isFunction && methodsNeedingSuperGetter.contains(member);
  }

  bool hasInvokedSetter(MemberEntity member) {
    return _hasMatchingSelector(_invokedSetters[member.name], member);
  }

  void registerDynamicUse(
      DynamicUse dynamicUse, MemberUsedCallback memberUsed) {
    Selector selector = dynamicUse.selector;
    String methodName = selector.name;

    void _process(Map<String, Set<_MemberUsage>> memberMap,
        EnumSet<MemberUse> action(_MemberUsage usage)) {
      _processSet(memberMap, methodName, (_MemberUsage usage) {
        if (dynamicUse.appliesUnnamed(usage.entity, this)) {
          memberUsed(usage.entity, action(usage));
          return true;
        }
        return false;
      });
    }

    switch (dynamicUse.kind) {
      case DynamicUseKind.INVOKE:
        if (_registerNewSelector(dynamicUse, _invokedNames)) {
          _process(_instanceMembersByName, (m) => m.invoke());
        }
        break;
      case DynamicUseKind.GET:
        if (_registerNewSelector(dynamicUse, _invokedGetters)) {
          _process(_instanceMembersByName, (m) => m.read());
          _process(_instanceFunctionsByName, (m) => m.read());
        }
        break;
      case DynamicUseKind.SET:
        if (_registerNewSelector(dynamicUse, _invokedSetters)) {
          _process(_instanceMembersByName, (m) => m.write());
        }
        break;
    }
  }

  bool _registerNewSelector(DynamicUse dynamicUse,
      Map<String, Map<Selector, SelectorConstraints>> selectorMap) {
    Selector selector = dynamicUse.selector;
    String name = selector.name;
    ReceiverConstraint mask = dynamicUse.mask;
    Map<Selector, SelectorConstraints> selectors = selectorMap.putIfAbsent(
        name, () => new Maplet<Selector, SelectorConstraints>());
    UniverseSelectorConstraints constraints =
        selectors.putIfAbsent(selector, () {
      return selectorConstraintsStrategy.createSelectorConstraints(selector);
    });
    return constraints.addReceiverConstraint(mask);
  }

  void registerIsCheck(covariant DartType type) {
    isChecks.add(type);
  }

  bool registerConstantUse(ConstantUse use) {
    return _constantValues.add(use.value);
  }

  void registerStaticUse(StaticUse staticUse, MemberUsedCallback memberUsed) {
    if (staticUse.kind == StaticUseKind.CLOSURE) {
      Local localFunction = staticUse.element;
      FunctionType type =
          _elementEnvironment.getLocalFunctionType(localFunction);
      if (type.containsTypeVariables) {
        localFunctionsWithFreeTypeVariables.add(localFunction);
      }
      localFunctions.add(staticUse.element);
      return;
    }

    MemberEntity element = staticUse.element;
    _StaticMemberUsage usage = _staticMemberUsage.putIfAbsent(element, () {
      if ((element.isStatic || element.isTopLevel) && element.isFunction) {
        return new _StaticFunctionUsage(element);
      } else {
        return new _GeneralStaticMemberUsage(element);
      }
    });
    EnumSet<MemberUse> useSet = new EnumSet<MemberUse>();

    if ((element.isStatic || element.isTopLevel) && element.isField) {
      allReferencedStaticFields.add(staticUse.element);
    }
    // TODO(johnniwinther): Avoid this. Currently [FIELD_GET] and
    // [FIELD_SET] contains [BoxFieldElement]s which we cannot enqueue.
    // Also [CLOSURE] contains [LocalFunctionElement] which we cannot
    // enqueue.
    switch (staticUse.kind) {
      case StaticUseKind.FIELD_GET:
        break;
      case StaticUseKind.FIELD_SET:
        fieldSetters.add(staticUse.element);
        break;
      case StaticUseKind.CLOSURE:
        // Already handled above.
        break;
      case StaticUseKind.SUPER_TEAR_OFF:
        useSet.addAll(usage.tearOff());
        methodsNeedingSuperGetter.add(staticUse.element);
        break;
      case StaticUseKind.SUPER_FIELD_SET:
        fieldSetters.add(staticUse.element);
        useSet.addAll(usage.normalUse());
        break;
      case StaticUseKind.STATIC_TEAR_OFF:
        useSet.addAll(usage.tearOff());
        break;
      case StaticUseKind.GENERAL:
      case StaticUseKind.DIRECT_USE:
      case StaticUseKind.CONSTRUCTOR_INVOKE:
      case StaticUseKind.CONST_CONSTRUCTOR_INVOKE:
      case StaticUseKind.REDIRECTION:
        useSet.addAll(usage.normalUse());
        break;
      case StaticUseKind.DIRECT_INVOKE:
        failedAt(element, 'Direct static use is not supported for resolution.');
        break;
      case StaticUseKind.INLINING:
        failedAt(CURRENT_ELEMENT_SPANNABLE,
            "Static use ${staticUse.kind} is not supported during resolution.");
    }
    if (useSet.isNotEmpty) {
      memberUsed(usage.entity, useSet);
    }
  }

  /// Called to create a [_ClassUsage] for [cls].
  ///
  /// Subclasses override this to ensure needed invariants on [cls].
  _ClassUsage _createClassUsage(covariant ClassEntity cls) =>
      new _ClassUsage(cls);

  /// Return the canonical [_ClassUsage] for [cls].
  _ClassUsage _getClassUsage(ClassEntity cls) {
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
      _ClassUsage usage = _getClassUsage(superclass);
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

  /// Computes usage for all members declared by [cls]. Calls [membersUsed] with
  /// the usage changes for each member.
  void processClassMembers(ClassEntity cls, MemberUsedCallback memberUsed) {
    _elementEnvironment.forEachClassMember(cls,
        (ClassEntity cls, MemberEntity member) {
      _processInstantiatedClassMember(cls, member, memberUsed);
    });
  }

  /// Call [updateUsage] on all [_MemberUsage]s in the set in [map] for
  /// [memberName]. If [updateUsage] returns `true` the usage is removed from
  /// the set.
  void _processSet(Map<String, Set<_MemberUsage>> map, String memberName,
      bool updateUsage(_MemberUsage e)) {
    Set<_MemberUsage> members = map[memberName];
    if (members == null) return;
    // [f] might add elements to [: map[memberName] :] during the loop below
    // so we create a new list for [: map[memberName] :] and prepend the
    // [remaining] members after the loop.
    map[memberName] = new Set<_MemberUsage>();
    Set<_MemberUsage> remaining = new Set<_MemberUsage>();
    for (_MemberUsage usage in members) {
      if (!updateUsage(usage)) remaining.add(usage);
    }
    map[memberName].addAll(remaining);
  }

  void _processInstantiatedClassMember(ClassEntity cls,
      covariant MemberEntity member, MemberUsedCallback memberUsed) {
    if (!member.isInstanceMember) return;
    String memberName = member.name;
    // The obvious thing to test here would be "member.isNative",
    // however, that only works after metadata has been parsed/analyzed,
    // and that may not have happened yet.
    // So instead we use the enclosing class, which we know have had
    // its metadata parsed and analyzed.
    // Note: this assumes that there are no non-native fields on native
    // classes, which may not be the case when a native class is subclassed.
    _instanceMemberUsage.putIfAbsent(member, () {
      bool isNative = _nativeBasicData.isNativeClass(cls);
      _MemberUsage usage = new _MemberUsage(member, isNative: isNative);
      EnumSet<MemberUse> useSet = new EnumSet<MemberUse>();
      useSet.addAll(usage.appliedUse);
      if (member.isField && isNative) {
        registerUsedElement(member);
      }
      if (member.isFunction &&
          member.name == Identifiers.call &&
          _elementEnvironment.isGenericClass(cls)) {
        closurizedMembersWithFreeTypeVariables.add(member);
      }

      if (_hasInvokedGetter(member)) {
        useSet.addAll(usage.read());
      }
      if (_hasInvocation(member)) {
        useSet.addAll(usage.invoke());
      }
      if (hasInvokedSetter(member)) {
        useSet.addAll(usage.write());
      }

      if (usage.pendingUse.contains(MemberUse.NORMAL)) {
        // The element is not yet used. Add it to the list of instance
        // members to still be processed.
        _instanceMembersByName
            .putIfAbsent(memberName, () => new Set<_MemberUsage>())
            .add(usage);
      }
      if (usage.pendingUse.contains(MemberUse.CLOSURIZE_INSTANCE)) {
        // Store the member in [instanceFunctionsByName] to catch
        // getters on the function.
        _instanceFunctionsByName
            .putIfAbsent(memberName, () => new Set<_MemberUsage>())
            .add(usage);
      }

      memberUsed(usage.entity, useSet);
      return usage;
    });
  }

  /// Returns an iterable over all mixin applications that mixin [cls].
  Iterable<ClassEntity> allMixinUsesOf(ClassEntity cls) {
    Iterable<ClassEntity> uses = _mixinUses[cls];
    return uses != null ? uses : const <ClassEntity>[];
  }

  void registerTypedef(TypedefEntity typdef) {
    _allTypedefs.add(typdef);
  }

  void registerMixinUse(
      covariant ClassEntity mixinApplication, covariant ClassEntity mixin) {
    // TODO(johnniwinther): Add map restricted to live classes.
    // We don't support patch classes as mixin.
    Set<ClassEntity> users =
        _mixinUses.putIfAbsent(mixin, () => new Set<ClassEntity>());
    users.add(mixinApplication);
  }

  void registerUsedElement(MemberEntity element) {
    if (element.isInstanceMember && !element.isAbstract) {
      _liveInstanceMembers.add(element);
    }
  }

  ClosedWorld get closedWorldCache {
    assert(isClosed);
    return _closedWorldCache;
  }

  @override
  bool isMemberUsed(MemberEntity member) {
    if (member.isInstanceMember) {
      _MemberUsage usage = _instanceMemberUsage[member];
      if (usage != null && usage.hasUse) return true;
    }
    _StaticMemberUsage usage = _staticMemberUsage[member];
    return usage != null && usage.hasUse;
  }

  bool checkClass(covariant ClassEntity cls);
  bool validateClass(covariant ClassEntity cls);

  /// Returns the class mixed into [cls] if any.
  ClassEntity getAppliedMixin(covariant ClassEntity cls);

  /// Returns the hierarchy depth of [cls].
  int getHierarchyDepth(covariant ClassEntity cls);

  /// Returns `true` if [cls] implements `Function` either explicitly or through
  /// a `call` method.
  bool implementsFunction(covariant ClassEntity cls);

  /// Returns the superclass of [cls] if any.
  ClassEntity getSuperClass(covariant ClassEntity cls);

  /// Returns all supertypes of [cls].
  Iterable<InterfaceType> getSupertypes(covariant ClassEntity cls);

  ClassHierarchyNode _ensureClassHierarchyNode(ClassEntity cls) {
    assert(checkClass(cls));
    return _classHierarchyNodes.putIfAbsent(cls, () {
      ClassHierarchyNode parentNode;
      ClassEntity superclass = getSuperClass(cls);
      if (superclass != null) {
        parentNode = _ensureClassHierarchyNode(superclass);
      }
      return new ClassHierarchyNode(parentNode, cls, getHierarchyDepth(cls));
    });
  }

  ClassSet _ensureClassSet(ClassEntity cls) {
    assert(checkClass(cls));
    return _classSets.putIfAbsent(cls, () {
      ClassHierarchyNode node = _ensureClassHierarchyNode(cls);
      ClassSet classSet = new ClassSet(node);

      for (InterfaceType type in getSupertypes(cls)) {
        // TODO(johnniwinther): Optimization: Avoid adding [cls] to
        // superclasses.
        ClassSet subtypeSet = _ensureClassSet(type.element);
        subtypeSet.addSubtype(node);
      }

      ClassEntity appliedMixin = getAppliedMixin(cls);
      if (appliedMixin != null) {
        // TODO(johnniwinther): Store this in the [ClassSet].
        registerMixinUse(cls, appliedMixin);
      }

      return classSet;
    });
  }

  void _updateSuperClassHierarchyNodeForClass(ClassHierarchyNode node) {
    // Ensure that classes implicitly implementing `Function` are in its
    // subtype set.
    ClassEntity cls = node.cls;
    if (cls != _commonElements.functionClass && implementsFunction(cls)) {
      ClassSet subtypeSet = _ensureClassSet(_commonElements.functionClass);
      subtypeSet.addSubtype(node);
    }
    if (!node.isInstantiated && node.parentNode != null) {
      _updateSuperClassHierarchyNodeForClass(node.parentNode);
    }
  }

  void _updateClassHierarchyNodeForClass(ClassEntity cls,
      {bool directlyInstantiated: false, bool abstractlyInstantiated: false}) {
    ClassHierarchyNode node = _ensureClassHierarchyNode(cls);
    _updateSuperClassHierarchyNodeForClass(node);
    if (directlyInstantiated) {
      node.isDirectlyInstantiated = true;
    }
    if (abstractlyInstantiated) {
      node.isAbstractlyInstantiated = true;
    }
  }

  Map<ClassEntity, Set<ClassEntity>> populateHierarchyNodes() {
    Map<ClassEntity, Set<ClassEntity>> typesImplementedBySubclasses =
        new Map<ClassEntity, Set<ClassEntity>>();

    /// Updates the `isDirectlyInstantiated` and `isIndirectlyInstantiated`
    /// properties of the [ClassHierarchyNode] for [cls].

    void addSubtypes(ClassEntity cls, InstantiationInfo info) {
      if (!info.hasInstantiation) {
        return;
      }
      assert(checkClass(cls));
      if (!validateClass(cls)) {
        failedAt(cls, 'Class "${cls.name}" is not resolved.');
      }

      _updateClassHierarchyNodeForClass(cls,
          directlyInstantiated: info.isDirectlyInstantiated,
          abstractlyInstantiated: info.isAbstractlyInstantiated);

      // Walk through the superclasses, and record the types
      // implemented by that type on the superclasses.
      ClassEntity superclass = getSuperClass(cls);
      while (superclass != null) {
        Set<ClassEntity> typesImplementedBySubclassesOfCls =
            typesImplementedBySubclasses.putIfAbsent(
                superclass, () => new Set<ClassEntity>());
        for (InterfaceType current in getSupertypes(cls)) {
          typesImplementedBySubclassesOfCls.add(current.element);
        }
        superclass = getSuperClass(superclass);
      }
    }

    // Use the [:seenClasses:] set to include non-instantiated
    // classes: if the superclass of these classes require RTI, then
    // they also need RTI, so that a constructor passes the type
    // variables to the super constructor.
    forEachInstantiatedClass(addSubtypes);

    _classHierarchyNodes.keys.toList().forEach(_ensureClassSet);

    return typesImplementedBySubclasses;
  }

  Iterable<MemberEntity> computeAssignedInstanceMembers() {
    Set<MemberEntity> assignedInstanceMembers = new Set<MemberEntity>();
    for (MemberEntity instanceMember in _liveInstanceMembers) {
      if (hasInvokedSetter(instanceMember)) {
        assignedInstanceMembers.add(instanceMember);
      }
    }
    assignedInstanceMembers.addAll(fieldSetters);
    return assignedInstanceMembers;
  }
}

abstract class KernelResolutionWorldBuilderBase
    extends ResolutionWorldBuilderBase {
  KernelToElementMapForImpactImpl get elementMap;

  KernelResolutionWorldBuilderBase(
      CompilerOptions options,
      ElementEnvironment elementEnvironment,
      DartTypes dartTypes,
      CommonElements commonElements,
      ConstantSystem constantSystem,
      NativeBasicData nativeBasicData,
      NativeDataBuilder nativeDataBuilder,
      InterceptorDataBuilder interceptorDataBuilder,
      BackendUsageBuilder backendUsageBuilder,
      RuntimeTypesNeedBuilder rtiNeedBuilder,
      NativeResolutionEnqueuer nativeResolutionEnqueuer,
      SelectorConstraintsStrategy selectorConstraintsStrategy)
      : super(
            options,
            elementEnvironment,
            dartTypes,
            commonElements,
            constantSystem,
            nativeBasicData,
            nativeDataBuilder,
            interceptorDataBuilder,
            backendUsageBuilder,
            rtiNeedBuilder,
            nativeResolutionEnqueuer,
            selectorConstraintsStrategy);

  @override
  ClosedWorld closeWorld() {
    Map<ClassEntity, Set<ClassEntity>> typesImplementedBySubclasses =
        populateHierarchyNodes();
    _classHierarchyNodes.keys.toList().forEach(_ensureClassSet);
    _closed = true;
    assert(
        _classHierarchyNodes.length == _classSets.length,
        "ClassHierarchyNode/ClassSet mismatch: "
        "$_classHierarchyNodes vs $_classSets");
    return _closedWorldCache = new KernelClosedWorld(elementMap,
        options: _options,
        elementEnvironment: _elementEnvironment,
        dartTypes: _dartTypes,
        commonElements: _commonElements,
        nativeData: _nativeDataBuilder.close(),
        interceptorData: _interceptorDataBuilder.close(),
        backendUsage: _backendUsageBuilder.close(),
        resolutionWorldBuilder: this,
        rtiNeedBuilder: _rtiNeedBuilder,
        constantSystem: _constantSystem,
        implementedClasses: _implementedClasses,
        liveNativeClasses: _nativeResolutionEnqueuer.liveNativeClasses,
        liveInstanceMembers: _liveInstanceMembers,
        assignedInstanceMembers: computeAssignedInstanceMembers(),
        allTypedefs: _allTypedefs,
        mixinUses: _mixinUses,
        typesImplementedBySubclasses: typesImplementedBySubclasses,
        classHierarchyNodes: _classHierarchyNodes,
        classSets: _classSets);
  }

  @override
  void registerClass(ClassEntity cls) {
    throw new UnimplementedError('KernelResolutionWorldBuilder.registerClass');
  }
}
