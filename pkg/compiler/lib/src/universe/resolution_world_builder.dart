// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of world_builder;

abstract class ResolutionWorldBuilder implements WorldBuilder, OpenWorld {
  /// Set of all local functions in the program. Used by the mirror tracking
  /// system to find all live closure instances.
  Iterable<LocalFunctionElement> get localFunctions;

  /// Set of (live) local functions (closures) whose signatures reference type
  /// variables.
  ///
  /// A live function is one whose enclosing member function has been enqueued.
  Iterable<LocalFunctionElement> get localFunctionsWithFreeTypeVariables;

  /// Set of methods in instantiated classes that are potentially closurized.
  Iterable<MethodElement> get closurizedMembers;

  /// Set of live closurized members whose signatures reference type variables.
  ///
  /// A closurized method is considered live if the enclosing class has been
  /// instantiated.
  Iterable<MethodElement> get closurizedMembersWithFreeTypeVariables;

  /// Returns `true` if [cls] is considered to be implemented by an
  /// instantiated class, either directly, through subclasses or through
  /// subtypes. The latter case only contains spurious information from
  /// instantiations through factory constructors and mixins.
  bool isImplemented(ClassElement cls);

  /// Set of all fields that are statically known to be written to.
  Iterable<Element> get fieldSetters;

  /// Call [f] for all classes with instantiated types. This includes the
  /// directly and abstractly instantiated classes but also classes whose type
  /// arguments are used in live factory constructors.
  void forEachInstantiatedClass(f(ClassElement cls, InstantiationInfo info));

  /// Returns `true` if [member] is invoked as a setter.
  bool hasInvokedSetter(Element member);

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
  final ResolutionInterfaceType type;
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
  Map<ConstructorElement, Set<Instance>> instantiationMap;

  /// Register [type] as the instantiation [kind] using [constructor].
  void addInstantiation(ConstructorElement constructor,
      ResolutionInterfaceType type, Instantiation kind,
      {bool isRedirection: false}) {
    instantiationMap ??= <ConstructorElement, Set<Instance>>{};
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
          .forEach((ConstructorElement constructor, Set<Instance> set) {
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

/// [ResolutionEnqueuerWorldBuilder] based on the [Element] model.
class ElementResolutionWorldBuilder implements ResolutionEnqueuerWorldBuilder {
  /// Instantiation information for all classes with instantiated types.
  ///
  /// Invariant: Elements are declaration elements.
  final Map<ClassElement, InstantiationInfo> _instantiationInfo =
      <ClassElement, InstantiationInfo>{};

  /// Classes implemented by directly instantiated classes.
  final Set<ClassElement> _implementedClasses = new Set<ClassElement>();

  /// The set of all referenced static fields.
  ///
  /// Invariant: Elements are declaration elements.
  final Set<FieldElement> allReferencedStaticFields = new Set<FieldElement>();

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: Elements are declaration elements.
   */
  final Set<FunctionElement> methodsNeedingSuperGetter =
      new Set<FunctionElement>();
  final Map<String, Map<Selector, SelectorConstraints>> _invokedNames =
      <String, Map<Selector, SelectorConstraints>>{};
  final Map<String, Map<Selector, SelectorConstraints>> _invokedGetters =
      <String, Map<Selector, SelectorConstraints>>{};
  final Map<String, Map<Selector, SelectorConstraints>> _invokedSetters =
      <String, Map<Selector, SelectorConstraints>>{};

  final Map<ClassElement, _ClassUsage> _processedClasses =
      <ClassElement, _ClassUsage>{};

  /// Map of registered usage of static members of live classes.
  final Map<Entity, _StaticMemberUsage> _staticMemberUsage =
      <Entity, _StaticMemberUsage>{};

  /// Map of registered usage of instance members of live classes.
  final Map<MemberEntity, _MemberUsage> _instanceMemberUsage =
      <MemberEntity, _MemberUsage>{};

  /// Map containing instance members of live classes that are not yet live
  /// themselves.
  final Map<String, Set<_MemberUsage>> _instanceMembersByName =
      <String, Set<_MemberUsage>>{};

  /// Map containing instance methods of live classes that are not yet
  /// closurized.
  final Map<String, Set<_MemberUsage>> _instanceFunctionsByName =
      <String, Set<_MemberUsage>>{};

  /// Fields set.
  final Set<Element> fieldSetters = new Set<Element>();
  final Set<ResolutionDartType> isChecks = new Set<ResolutionDartType>();

  /// Set of all closures in the program. Used by the mirror tracking system
  /// to find all live closure instances.
  final Set<LocalFunctionElement> localFunctions =
      new Set<LocalFunctionElement>();

  /// Set of live local functions (closures) whose signatures reference type
  /// variables.
  ///
  /// A local function is considered live if the enclosing member function is
  /// live.
  final Set<LocalFunctionElement> localFunctionsWithFreeTypeVariables =
      new Set<LocalFunctionElement>();

  /// Set of methods in instantiated classes that are potentially closurized.
  final Set<MethodElement> closurizedMembers = new Set<MethodElement>();

  /// Set of live closurized members whose signatures reference type variables.
  ///
  /// A closurized method is considered live if the enclosing class has been
  /// instantiated.
  final Set<MethodElement> closurizedMembersWithFreeTypeVariables =
      new Set<MethodElement>();

  final SelectorConstraintsStrategy selectorConstraintsStrategy;

  bool hasRuntimeTypeSupport = false;
  bool hasIsolateSupport = false;
  bool hasFunctionApplySupport = false;

  /// Used for testing the new more precise computation of instantiated types
  /// and classes.
  static bool useInstantiationMap = false;

  final JavaScriptBackend _backend;
  final Resolution _resolution;
  bool _closed = false;
  ClosedWorld _closedWorldCache;
  FunctionSetBuilder _allFunctions;

  final Set<TypedefElement> _allTypedefs = new Set<TypedefElement>();

  final Map<ClassElement, Set<MixinApplicationElement>> _mixinUses =
      new Map<ClassElement, Set<MixinApplicationElement>>();

  // We keep track of subtype and subclass relationships in four
  // distinct sets to make class hierarchy analysis faster.
  final Map<ClassElement, ClassHierarchyNode> _classHierarchyNodes =
      <ClassElement, ClassHierarchyNode>{};
  final Map<ClassElement, ClassSet> _classSets = <ClassElement, ClassSet>{};

  final Set<ConstantValue> _constantValues = new Set<ConstantValue>();

  bool get isClosed => _closed;

  ElementResolutionWorldBuilder(
      this._backend, this._resolution, this.selectorConstraintsStrategy) {
    _allFunctions = new FunctionSetBuilder();
  }

  Iterable<ClassElement> get processedClasses => _processedClasses.keys
      .where((cls) => _processedClasses[cls].isInstantiated);

  CommonElements get commonElements => _resolution.commonElements;

  ClosedWorld get closedWorldForTesting {
    if (!_closed) {
      throw new SpannableAssertionFailure(
          NO_LOCATION_SPANNABLE, "The world builder has not yet been closed.");
    }
    return _closedWorldCache;
  }

  /// All directly instantiated classes, that is, classes with a generative
  /// constructor that has been called directly and not only through a
  /// super-call.
  // TODO(johnniwinther): Improve semantic precision.
  Iterable<ClassElement> get directlyInstantiatedClasses {
    Set<ClassElement> classes = new Set<ClassElement>();
    getInstantiationMap().forEach((ClassElement cls, InstantiationInfo info) {
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
    Set<ResolutionInterfaceType> types = new Set<ResolutionInterfaceType>();
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

  /// Returns `true` if [cls] is considered to be implemented by an
  /// instantiated class, either directly, through subclasses or through
  /// subtypes. The latter case only contains spurious information from
  /// instantiations through factory constructors and mixins.
  // TODO(johnniwinther): Improve semantic precision.
  bool isImplemented(ClassElement cls) {
    return _implementedClasses.contains(cls.declaration);
  }

  void registerClosurizedMember(MemberElement element) {
    closurizedMembers.add(element);
    if (element.type.containsTypeVariables) {
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
      ResolutionInterfaceType type, ClassUsedCallback classUsed,
      {ConstructorElement constructor,
      bool byMirrors: false,
      bool isRedirection: false}) {
    ClassElement cls = type.element;
    cls.ensureResolved(_resolution);
    InstantiationInfo info =
        _instantiationInfo.putIfAbsent(cls, () => new InstantiationInfo());
    Instantiation kind = Instantiation.UNINSTANTIATED;
    bool isNative = _backend.nativeBasicData.isNativeClass(cls);
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
      cls.allSupertypes.forEach((ResolutionInterfaceType supertype) {
        if (_implementedClasses.add(supertype.element)) {
          classUsed(
              supertype.element, _getClassUsage(supertype.element).implement());
        }
      });
    }
  }

  @override
  void forEachInstantiatedClass(f(ClassElement cls, InstantiationInfo info)) {
    getInstantiationMap().forEach(f);
  }

  bool _hasMatchingSelector(
      Map<Selector, SelectorConstraints> selectors, Element member) {
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
  ///
  /// If [useInstantiationMap] is `true`, redirections are removed and
  /// redirecting factories are converted to their effective target and type.
  Map<ClassElement, InstantiationInfo> getInstantiationMap() {
    if (!useInstantiationMap) return _instantiationInfo;

    Map<ClassElement, InstantiationInfo> instantiationMap =
        <ClassElement, InstantiationInfo>{};

    InstantiationInfo infoFor(ClassElement cls) {
      return instantiationMap.putIfAbsent(cls, () => new InstantiationInfo());
    }

    _instantiationInfo.forEach((cls, info) {
      if (info.instantiationMap != null) {
        info.instantiationMap
            .forEach((ConstructorElement constructor, Set<Instance> set) {
          for (Instance instance in set) {
            if (instance.isRedirection) {
              continue;
            }
            if (constructor == null || !constructor.isRedirectingFactory) {
              infoFor(cls)
                  .addInstantiation(constructor, instance.type, instance.kind);
            } else {
              ConstructorElement target = constructor.effectiveTarget;
              ResolutionInterfaceType targetType =
                  constructor.computeEffectiveTargetType(instance.type);
              Instantiation kind = Instantiation.DIRECTLY_INSTANTIATED;
              if (target.enclosingClass.isAbstract) {
                // If target is a factory constructor on an abstract class.
                kind = Instantiation.UNINSTANTIATED;
              }
              infoFor(targetType.element)
                  .addInstantiation(target, targetType, kind);
            }
          }
        });
      }
    });
    return instantiationMap;
  }

  bool _hasInvocation(Element member) {
    return _hasMatchingSelector(_invokedNames[member.name], member);
  }

  bool _hasInvokedGetter(Element member) {
    return _hasMatchingSelector(_invokedGetters[member.name], member) ||
        member.isFunction && methodsNeedingSuperGetter.contains(member);
  }

  bool hasInvokedSetter(Element member) {
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

  void registerIsCheck(ResolutionDartType type) {
    type.computeUnaliased(_resolution);
    type = type.unaliased;
    // Even in checked mode, type annotations for return type and argument
    // types do not imply type checks, so there should never be a check
    // against the type variable of a typedef.
    assert(!type.isTypeVariable || !type.element.enclosingElement.isTypedef);
    isChecks.add(type);
  }

  bool registerConstantUse(ConstantUse use) {
    return _constantValues.add(use.value);
  }

  void registerStaticUse(StaticUse staticUse, MemberUsedCallback memberUsed) {
    Element element = staticUse.element;
    assert(invariant(element, element.isDeclaration,
        message: "Element ${element} is not the declaration."));
    _StaticMemberUsage usage = _staticMemberUsage.putIfAbsent(element, () {
      if ((element.isStatic || element.isTopLevel) && element.isFunction) {
        return new _StaticFunctionUsage(element);
      } else {
        return new _GeneralStaticMemberUsage(element);
      }
    });
    EnumSet<MemberUse> useSet = new EnumSet<MemberUse>();

    if (Elements.isStaticOrTopLevel(element) && element.isField) {
      allReferencedStaticFields.add(element);
    }
    // TODO(johnniwinther): Avoid this. Currently [FIELD_GET] and
    // [FIELD_SET] contains [BoxFieldElement]s which we cannot enqueue.
    // Also [CLOSURE] contains [LocalFunctionElement] which we cannot
    // enqueue.
    switch (staticUse.kind) {
      case StaticUseKind.FIELD_GET:
        break;
      case StaticUseKind.FIELD_SET:
        fieldSetters.add(element);
        break;
      case StaticUseKind.CLOSURE:
        LocalFunctionElement localFunction = staticUse.element;
        if (localFunction.type.containsTypeVariables) {
          localFunctionsWithFreeTypeVariables.add(localFunction);
        }
        localFunctions.add(element);
        break;
      case StaticUseKind.SUPER_TEAR_OFF:
        useSet.addAll(usage.tearOff());
        methodsNeedingSuperGetter.add(element);
        break;
      case StaticUseKind.SUPER_FIELD_SET:
        fieldSetters.add(element);
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
        invariant(
            element, 'Direct static use is not supported for resolution.');
        break;
      case StaticUseKind.INLINING:
        throw new SpannableAssertionFailure(CURRENT_ELEMENT_SPANNABLE,
            "Static use ${staticUse.kind} is not supported during resolution.");
    }
    if (useSet.isNotEmpty) {
      memberUsed(usage.entity, useSet);
    }
  }

  /// Return the canonical [_ClassUsage] for [cls].
  _ClassUsage _getClassUsage(ClassElement cls) {
    return _processedClasses.putIfAbsent(cls, () {
      cls.ensureResolved(_resolution);
      _ClassUsage usage = new _ClassUsage(cls);
      _resolution.ensureClassMembers(cls);
      return usage;
    });
  }

  /// Register [cls] and all its superclasses as instantiated.
  void _processInstantiatedClass(
      ClassElement cls, ClassUsedCallback classUsed) {
    // Registers [superclass] as instantiated. Returns `true` if it wasn't
    // already instantiated and we therefore have to process its superclass as
    // well.
    bool processClass(ClassElement superclass) {
      _ClassUsage usage = _getClassUsage(superclass);
      if (!usage.isInstantiated) {
        classUsed(usage.cls, usage.instantiate());
        return true;
      }
      return false;
    }

    while (cls != null && processClass(cls)) {
      cls = cls.superclass;
    }
  }

  /// Computes usage for all members declared by [cls]. Calls [membersUsed] with
  /// the usage changes for each member.
  void processClassMembers(ClassElement cls, MemberUsedCallback memberUsed) {
    cls.implementation.forEachMember((ClassElement cls, MemberElement member) {
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

  void _processInstantiatedClassMember(
      ClassElement cls, MemberElement member, MemberUsedCallback memberUsed) {
    assert(invariant(member, member.isDeclaration));
    if (!member.isInstanceMember) return;
    String memberName = member.name;
    member.computeType(_resolution);
    // The obvious thing to test here would be "member.isNative",
    // however, that only works after metadata has been parsed/analyzed,
    // and that may not have happened yet.
    // So instead we use the enclosing class, which we know have had
    // its metadata parsed and analyzed.
    // Note: this assumes that there are no non-native fields on native
    // classes, which may not be the case when a native class is subclassed.
    _instanceMemberUsage.putIfAbsent(member, () {
      bool isNative = _backend.nativeBasicData.isNativeClass(cls);
      _MemberUsage usage = new _MemberUsage(member, isNative: isNative);
      EnumSet<MemberUse> useSet = new EnumSet<MemberUse>();
      useSet.addAll(usage.appliedUse);
      if (member.isField && isNative) {
        registerUsedElement(member);
      }
      if (member.isFunction &&
          member.name == Identifiers.call &&
          !cls.typeVariables.isEmpty) {
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
  Iterable<MixinApplicationElement> allMixinUsesOf(ClassElement cls) {
    Iterable<MixinApplicationElement> uses = _mixinUses[cls];
    return uses != null ? uses : const <MixinApplicationElement>[];
  }

  /// Called to add [cls] to the set of known classes.
  ///
  /// This ensures that class hierarchy queries can be performed on [cls] and
  /// classes that extend or implement it.
  void registerClass(ClassElement cls) => _registerClass(cls);

  void _registerClass(ClassElement cls, {bool isDirectlyInstantiated: false}) {
    _ensureClassSet(cls);
    if (isDirectlyInstantiated) {
      _updateClassHierarchyNodeForClass(cls, directlyInstantiated: true);
    }
  }

  void registerTypedef(TypedefElement typdef) {
    _allTypedefs.add(typdef);
  }

  ClassHierarchyNode _ensureClassHierarchyNode(ClassElement cls) {
    cls = cls.declaration;
    return _classHierarchyNodes.putIfAbsent(cls, () {
      ClassHierarchyNode parentNode;
      if (cls.superclass != null) {
        parentNode = _ensureClassHierarchyNode(cls.superclass);
      }
      return new ClassHierarchyNode(parentNode, cls);
    });
  }

  ClassSet _ensureClassSet(ClassElement cls) {
    cls = cls.declaration;
    return _classSets.putIfAbsent(cls, () {
      ClassHierarchyNode node = _ensureClassHierarchyNode(cls);
      ClassSet classSet = new ClassSet(node);

      for (ResolutionInterfaceType type in cls.allSupertypes) {
        // TODO(johnniwinther): Optimization: Avoid adding [cls] to
        // superclasses.
        ClassSet subtypeSet = _ensureClassSet(type.element);
        subtypeSet.addSubtype(node);
      }
      if (cls.isMixinApplication) {
        // TODO(johnniwinther): Store this in the [ClassSet].
        MixinApplicationElement mixinApplication = cls;
        if (mixinApplication.mixin != null) {
          // If [mixinApplication] is malformed [mixin] is `null`.
          registerMixinUse(mixinApplication, mixinApplication.mixin);
        }
      }

      return classSet;
    });
  }

  void _updateSuperClassHierarchyNodeForClass(ClassHierarchyNode node) {
    // Ensure that classes implicitly implementing `Function` are in its
    // subtype set.
    ClassElement cls = node.cls;
    if (cls != commonElements.functionClass &&
        cls.implementsFunction(commonElements)) {
      ClassSet subtypeSet = _ensureClassSet(commonElements.functionClass);
      subtypeSet.addSubtype(node);
    }
    if (!node.isInstantiated && node.parentNode != null) {
      _updateSuperClassHierarchyNodeForClass(node.parentNode);
    }
  }

  void _updateClassHierarchyNodeForClass(ClassElement cls,
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

  ClosedWorld closeWorld(DiagnosticReporter reporter) {
    Map<ClassElement, Set<ClassElement>> typesImplementedBySubclasses =
        new Map<ClassElement, Set<ClassElement>>();

    /// Updates the `isDirectlyInstantiated` and `isIndirectlyInstantiated`
    /// properties of the [ClassHierarchyNode] for [cls].

    void addSubtypes(ClassElement cls, InstantiationInfo info) {
      if (!info.hasInstantiation) {
        return;
      }
      assert(cls.isDeclaration);
      if (!cls.isResolved) {
        reporter.internalError(cls, 'Class "${cls.name}" is not resolved.');
      }

      _updateClassHierarchyNodeForClass(cls,
          directlyInstantiated: info.isDirectlyInstantiated,
          abstractlyInstantiated: info.isAbstractlyInstantiated);

      // Walk through the superclasses, and record the types
      // implemented by that type on the superclasses.
      ClassElement superclass = cls.superclass;
      while (superclass != null) {
        Set<Element> typesImplementedBySubclassesOfCls =
            typesImplementedBySubclasses.putIfAbsent(
                superclass, () => new Set<ClassElement>());
        for (ResolutionDartType current in cls.allSupertypes) {
          typesImplementedBySubclassesOfCls.add(current.element);
        }
        superclass = superclass.superclass;
      }
    }

    // Use the [:seenClasses:] set to include non-instantiated
    // classes: if the superclass of these classes require RTI, then
    // they also need RTI, so that a constructor passes the type
    // variables to the super constructor.
    forEachInstantiatedClass(addSubtypes);

    _closed = true;
    return _closedWorldCache = new ClosedWorldImpl(
        backend: _backend,
        commonElements: commonElements,
        resolutionWorldBuilder: this,
        functionSetBuilder: _allFunctions,
        allTypedefs: _allTypedefs,
        mixinUses: _mixinUses,
        typesImplementedBySubclasses: typesImplementedBySubclasses,
        classHierarchyNodes: _classHierarchyNodes,
        classSets: _classSets);
  }

  void registerMixinUse(
      MixinApplicationElement mixinApplication, ClassElement mixin) {
    // TODO(johnniwinther): Add map restricted to live classes.
    // We don't support patch classes as mixin.
    assert(mixin.isDeclaration);
    Set<MixinApplicationElement> users =
        _mixinUses.putIfAbsent(mixin, () => new Set<MixinApplicationElement>());
    users.add(mixinApplication);
  }

  void registerUsedElement(MemberElement element) {
    if (element.isInstanceMember && !element.isAbstract) {
      _allFunctions.add(element);
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
}
