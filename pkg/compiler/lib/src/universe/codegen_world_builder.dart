// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of world_builder;

/// World builder specific to codegen.
///
/// This adds additional access to liveness of selectors and elements.
abstract class CodegenWorldBuilder implements WorldBuilder {
  /// Calls [f] with every instance field, together with its declarer, in an
  /// instance of [cls].
  void forEachInstanceField(
      ClassEntity cls, void f(ClassEntity declarer, FieldEntity field));

  /// Calls [f] for each parameter of [function] providing the type and name of
  /// the parameter and the [defaultValue] if the parameter is optional.
  void forEachParameter(FunctionEntity function,
      void f(DartType type, String name, ConstantValue defaultValue));

  void forEachInvokedName(
      f(String name, Map<Selector, SelectorConstraints> selectors));

  void forEachInvokedGetter(
      f(String name, Map<Selector, SelectorConstraints> selectors));

  void forEachInvokedSetter(
      f(String name, Map<Selector, SelectorConstraints> selectors));

  /// Returns `true` if [field] has a constant initializer.
  bool hasConstantFieldInitializer(FieldEntity field);

  /// Returns the constant initializer for [field].
  ConstantValue getConstantFieldInitializer(FieldEntity field);

  /// Returns `true` if [member] is invoked as a setter.
  bool hasInvokedSetter(MemberEntity member, ClosedWorld world);

  bool hasInvokedGetter(MemberEntity member, ClosedWorld world);

  Map<Selector, SelectorConstraints> invocationsByName(String name);

  Map<Selector, SelectorConstraints> getterInvocationsByName(String name);

  Map<Selector, SelectorConstraints> setterInvocationsByName(String name);

  Iterable<FunctionEntity> get staticFunctionsNeedingGetter;
  Iterable<FunctionEntity> get methodsNeedingSuperGetter;

  /// The set of all referenced static fields.
  ///
  /// Invariant: Elements are declaration elements.
  Iterable<FieldEntity> get allReferencedStaticFields;

  /// Set of methods in instantiated classes that are potentially closurized.
  Iterable<FunctionEntity> get closurizedMembers;

  /// Register [constant] as needed for emission.
  void addCompileTimeConstantForEmission(ConstantValue constant);

  /// Returns a list of constants topologically sorted so that dependencies
  /// appear before the dependent constant.
  ///
  /// [preSortCompare] is a comparator function that gives the constants a
  /// consistent order prior to the topological sort which gives the constants
  /// an ordering that is less sensitive to perturbations in the source code.
  List<ConstantValue> getConstantsForEmission(
      [Comparator<ConstantValue> preSortCompare]);
}

abstract class CodegenWorldBuilderImpl implements CodegenWorldBuilder {
  final ElementEnvironment _elementEnvironment;
  final NativeBasicData _nativeBasicData;
  final ClosedWorld _world;

  /// The set of all directly instantiated classes, that is, classes with a
  /// generative constructor that has been called directly and not only through
  /// a super-call.
  ///
  /// Invariant: Elements are declaration elements.
  // TODO(johnniwinther): [_directlyInstantiatedClasses] and
  // [_instantiatedTypes] sets should be merged.
  final Set<ClassEntity> _directlyInstantiatedClasses = new Set<ClassEntity>();

  /// The set of all directly instantiated types, that is, the types of the
  /// directly instantiated classes.
  ///
  /// See [_directlyInstantiatedClasses].
  final Set<InterfaceType> _instantiatedTypes = new Set<InterfaceType>();

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
  final Set<FunctionEntity> staticFunctionsNeedingGetter =
      new Set<FunctionEntity>();
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

  final Set<DartType> isChecks = new Set<DartType>();

  final SelectorConstraintsStrategy selectorConstraintsStrategy;

  final Set<ConstantValue> _constantValues = new Set<ConstantValue>();

  /// Set of methods in instantiated classes that are potentially closurized.
  final Set<FunctionEntity> closurizedMembers = new Set<FunctionEntity>();

  CodegenWorldBuilderImpl(this._elementEnvironment, this._nativeBasicData,
      this._world, this.selectorConstraintsStrategy);

  Iterable<ClassEntity> get processedClasses => _processedClasses.keys
      .where((cls) => _processedClasses[cls].isInstantiated);

  /// All directly instantiated classes, that is, classes with a generative
  /// constructor that has been called directly and not only through a
  /// super-call.
  // TODO(johnniwinther): Improve semantic precision.
  Iterable<ClassEntity> get directlyInstantiatedClasses {
    return _directlyInstantiatedClasses;
  }

  /// All directly instantiated types, that is, the types of the directly
  /// instantiated classes.
  ///
  /// See [directlyInstantiatedClasses].
  // TODO(johnniwinther): Improve semantic precision.
  Iterable<InterfaceType> get instantiatedTypes => _instantiatedTypes;

  /// Register [type] as (directly) instantiated.
  ///
  /// If [byMirrors] is `true`, the instantiation is through mirrors.
  // TODO(johnniwinther): Fully enforce the separation between exact, through
  // subclass and through subtype instantiated types/classes.
  // TODO(johnniwinther): Support unknown type arguments for generic types.
  void registerTypeInstantiation(
      InterfaceType type, ClassUsedCallback classUsed,
      {bool byMirrors: false}) {
    ClassEntity cls = type.element;
    bool isNative = _nativeBasicData.isNativeClass(cls);
    _instantiatedTypes.add(type);
    if (!cls.isAbstract
        // We can't use the closed-world assumption with native abstract
        // classes; a native abstract class may have non-abstract subclasses
        // not declared to the program.  Instances of these classes are
        // indistinguishable from the abstract class.
        ||
        isNative
        // Likewise, if this registration comes from the mirror system,
        // all bets are off.
        // TODO(herhut): Track classes required by mirrors separately.
        ||
        byMirrors) {
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
      MemberEntity member, ClosedWorld world) {
    if (selectors == null) return false;
    for (Selector selector in selectors.keys) {
      if (selector.appliesUnnamed(member)) {
        SelectorConstraints masks = selectors[selector];
        if (masks.applies(member, selector, world)) {
          return true;
        }
      }
    }
    return false;
  }

  bool hasInvocation(MemberEntity member, ClosedWorld world) {
    return _hasMatchingSelector(_invokedNames[member.name], member, world);
  }

  bool hasInvokedGetter(MemberEntity member, ClosedWorld world) {
    return _hasMatchingSelector(_invokedGetters[member.name], member, world) ||
        member.isFunction && methodsNeedingSuperGetter.contains(member);
  }

  bool hasInvokedSetter(MemberEntity member, ClosedWorld world) {
    return _hasMatchingSelector(_invokedSetters[member.name], member, world);
  }

  bool registerDynamicUse(
      DynamicUse dynamicUse, MemberUsedCallback memberUsed) {
    Selector selector = dynamicUse.selector;
    String methodName = selector.name;

    void _process(Map<String, Set<_MemberUsage>> memberMap,
        EnumSet<MemberUse> action(_MemberUsage usage)) {
      _processSet(memberMap, methodName, (_MemberUsage usage) {
        if (dynamicUse.appliesUnnamed(usage.entity, _world)) {
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
          return true;
        }
        break;
      case DynamicUseKind.GET:
        if (_registerNewSelector(dynamicUse, _invokedGetters)) {
          _process(_instanceMembersByName, (m) => m.read());
          _process(_instanceFunctionsByName, (m) => m.read());
          return true;
        }
        break;
      case DynamicUseKind.SET:
        if (_registerNewSelector(dynamicUse, _invokedSetters)) {
          _process(_instanceMembersByName, (m) => m.write());
          return true;
        }
        break;
    }
    return false;
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

  Map<Selector, SelectorConstraints> _asUnmodifiable(
      Map<Selector, SelectorConstraints> map) {
    if (map == null) return null;
    return new UnmodifiableMapView(map);
  }

  Map<Selector, SelectorConstraints> invocationsByName(String name) {
    return _asUnmodifiable(_invokedNames[name]);
  }

  Map<Selector, SelectorConstraints> getterInvocationsByName(String name) {
    return _asUnmodifiable(_invokedGetters[name]);
  }

  Map<Selector, SelectorConstraints> setterInvocationsByName(String name) {
    return _asUnmodifiable(_invokedSetters[name]);
  }

  void forEachInvokedName(
      f(String name, Map<Selector, SelectorConstraints> selectors)) {
    _invokedNames.forEach(f);
  }

  void forEachInvokedGetter(
      f(String name, Map<Selector, SelectorConstraints> selectors)) {
    _invokedGetters.forEach(f);
  }

  void forEachInvokedSetter(
      f(String name, Map<Selector, SelectorConstraints> selectors)) {
    _invokedSetters.forEach(f);
  }

  void registerIsCheck(DartType type) {
    isChecks.add(type.unaliased);
  }

  void _registerStaticUse(StaticUse staticUse) {
    if (staticUse.element is FieldEntity) {
      FieldEntity field = staticUse.element;
      if (field.isTopLevel || field.isStatic) {
        allReferencedStaticFields.add(field);
      }
    }
    switch (staticUse.kind) {
      case StaticUseKind.STATIC_TEAR_OFF:
        staticFunctionsNeedingGetter.add(staticUse.element);
        break;
      case StaticUseKind.SUPER_TEAR_OFF:
        methodsNeedingSuperGetter.add(staticUse.element);
        break;
      case StaticUseKind.SUPER_FIELD_SET:
      case StaticUseKind.FIELD_SET:
      case StaticUseKind.GENERAL:
      case StaticUseKind.DIRECT_USE:
      case StaticUseKind.CLOSURE:
      case StaticUseKind.FIELD_GET:
      case StaticUseKind.CONSTRUCTOR_INVOKE:
      case StaticUseKind.CONST_CONSTRUCTOR_INVOKE:
      case StaticUseKind.REDIRECTION:
      case StaticUseKind.DIRECT_INVOKE:
      case StaticUseKind.INLINING:
        break;
    }
  }

  void registerStaticUse(StaticUse staticUse, MemberUsedCallback memberUsed) {
    Entity element = staticUse.element;
    _registerStaticUse(staticUse);
    _StaticMemberUsage usage = _staticMemberUsage.putIfAbsent(element, () {
      if (element is MemberEntity &&
          (element.isStatic || element.isTopLevel) &&
          element.isFunction) {
        return new _StaticFunctionUsage(element);
      } else {
        return new _GeneralStaticMemberUsage(element);
      }
    });
    EnumSet<MemberUse> useSet = new EnumSet<MemberUse>();
    switch (staticUse.kind) {
      case StaticUseKind.STATIC_TEAR_OFF:
        useSet.addAll(usage.tearOff());
        break;
      case StaticUseKind.FIELD_GET:
      case StaticUseKind.FIELD_SET:
      case StaticUseKind.CLOSURE:
        // TODO(johnniwinther): Avoid this. Currently [FIELD_GET] and
        // [FIELD_SET] contains [BoxFieldElement]s which we cannot enqueue.
        // Also [CLOSURE] contains [LocalFunctionElement] which we cannot
        // enqueue.
        break;
      case StaticUseKind.SUPER_FIELD_SET:
      case StaticUseKind.SUPER_TEAR_OFF:
      case StaticUseKind.GENERAL:
      case StaticUseKind.DIRECT_USE:
        useSet.addAll(usage.normalUse());
        break;
      case StaticUseKind.CONSTRUCTOR_INVOKE:
      case StaticUseKind.CONST_CONSTRUCTOR_INVOKE:
      case StaticUseKind.REDIRECTION:
        useSet.addAll(usage.normalUse());
        break;
      case StaticUseKind.DIRECT_INVOKE:
        _MemberUsage instanceUsage =
            _getMemberUsage(staticUse.element, memberUsed);
        memberUsed(instanceUsage.entity, instanceUsage.invoke());
        _instanceMembersByName[instanceUsage.entity.name]
            ?.remove(instanceUsage);
        useSet.addAll(usage.normalUse());
        break;
      case StaticUseKind.INLINING:
        break;
    }
    if (useSet.isNotEmpty) {
      memberUsed(usage.entity, useSet);
    }
  }

  /// Registers that [element] has been closurized.
  void registerClosurizedMember(MemberEntity element) {
    closurizedMembers.add(element);
  }

  void processClassMembers(ClassEntity cls, MemberUsedCallback memberUsed) {
    _elementEnvironment.forEachClassMember(cls,
        (ClassEntity cls, MemberEntity member) {
      _processInstantiatedClassMember(cls, member, memberUsed);
    });
  }

  void _processInstantiatedClassMember(
      ClassEntity cls, MemberEntity member, MemberUsedCallback memberUsed) {
    if (!member.isInstanceMember) return;
    _getMemberUsage(member, memberUsed);
  }

  _MemberUsage _getMemberUsage(
      MemberEntity member, MemberUsedCallback memberUsed) {
    return _instanceMemberUsage.putIfAbsent(member, () {
      String memberName = member.name;
      ClassEntity cls = member.enclosingClass;
      bool isNative = _nativeBasicData.isNativeClass(cls);
      _MemberUsage usage = new _MemberUsage(member, isNative: isNative);
      EnumSet<MemberUse> useSet = new EnumSet<MemberUse>();
      useSet.addAll(usage.appliedUse);
      if (hasInvokedGetter(member, _world)) {
        useSet.addAll(usage.read());
      }
      if (hasInvokedSetter(member, _world)) {
        useSet.addAll(usage.write());
      }
      if (hasInvocation(member, _world)) {
        useSet.addAll(usage.invoke());
      }

      if (usage.pendingUse.contains(MemberUse.CLOSURIZE_INSTANCE)) {
        // Store the member in [instanceFunctionsByName] to catch
        // getters on the function.
        _instanceFunctionsByName
            .putIfAbsent(usage.entity.name, () => new Set<_MemberUsage>())
            .add(usage);
      }
      if (usage.pendingUse.contains(MemberUse.NORMAL)) {
        // The element is not yet used. Add it to the list of instance
        // members to still be processed.
        _instanceMembersByName
            .putIfAbsent(memberName, () => new Set<_MemberUsage>())
            .add(usage);
      }
      memberUsed(member, useSet);
      return usage;
    });
  }

  void _processSet(Map<String, Set<_MemberUsage>> map, String memberName,
      bool f(_MemberUsage e)) {
    Set<_MemberUsage> members = map[memberName];
    if (members == null) return;
    // [f] might add elements to [: map[memberName] :] during the loop below
    // so we create a new list for [: map[memberName] :] and prepend the
    // [remaining] members after the loop.
    map[memberName] = new Set<_MemberUsage>();
    Set<_MemberUsage> remaining = new Set<_MemberUsage>();
    for (_MemberUsage member in members) {
      if (!f(member)) remaining.add(member);
    }
    map[memberName].addAll(remaining);
  }

  /// Return the canonical [_ClassUsage] for [cls].
  _ClassUsage _getClassUsage(ClassEntity cls) {
    return _processedClasses.putIfAbsent(cls, () => new _ClassUsage(cls));
  }

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

  /// Set of all registered compiled constants.
  final Set<ConstantValue> compiledConstants = new Set<ConstantValue>();

  @override
  void addCompileTimeConstantForEmission(ConstantValue constant) {
    compiledConstants.add(constant);
  }

  @override
  List<ConstantValue> getConstantsForEmission(
      [Comparator<ConstantValue> preSortCompare]) {
    // We must emit dependencies before their uses.
    Set<ConstantValue> seenConstants = new Set<ConstantValue>();
    List<ConstantValue> result = new List<ConstantValue>();

    void addConstant(ConstantValue constant) {
      if (!seenConstants.contains(constant)) {
        constant.getDependencies().forEach(addConstant);
        assert(!seenConstants.contains(constant));
        result.add(constant);
        seenConstants.add(constant);
      }
    }

    List<ConstantValue> sorted = compiledConstants.toList();
    if (preSortCompare != null) {
      sorted.sort(preSortCompare);
    }
    sorted.forEach(addConstant);
    return result;
  }

  /// Register the constant [use] with this world builder. Returns `true` if
  /// the constant use was new to the world.
  bool registerConstantUse(ConstantUse use) {
    if (use.kind == ConstantUseKind.DIRECT) {
      addCompileTimeConstantForEmission(use.value);
    }
    return _constantValues.add(use.value);
  }
}

class ElementCodegenWorldBuilderImpl extends CodegenWorldBuilderImpl {
  final JavaScriptConstantCompiler _constants;

  ElementCodegenWorldBuilderImpl(
      this._constants,
      ElementEnvironment elementEnvironment,
      NativeBasicData nativeBasicData,
      ClosedWorld world,
      SelectorConstraintsStrategy selectorConstraintsStrategy)
      : super(elementEnvironment, nativeBasicData, world,
            selectorConstraintsStrategy);

  @override
  bool hasConstantFieldInitializer(FieldElement field) {
    return field.constant != null;
  }

  @override
  ConstantValue getConstantFieldInitializer(FieldElement field) {
    assert(field.constant != null,
        failedAt(field, "Field $field doesn't have a constant initial value."));
    return _constants.getConstantValue(field.constant);
  }

  /// Calls [f] with every instance field, together with its declarer, in an
  /// instance of [cls].
  void forEachInstanceField(
      ClassElement cls, void f(ClassEntity declarer, FieldEntity field)) {
    cls.implementation
        .forEachInstanceField(f, includeSuperAndInjectedMembers: true);
  }

  @override
  void forEachParameter(MethodElement function,
      void f(DartType type, String name, ConstantValue defaultValue)) {
    FunctionSignature parameters = function.functionSignature;
    parameters.forEachParameter((_parameter) {
      ParameterElement parameter = _parameter;
      ConstantValue value;
      if (parameter.constant != null) {
        value = _constants.getConstantValue(parameter.constant);
      } else {
        value = new NullConstantValue();
      }
      f(parameter.type, parameter.name, value);
    });
  }

  @override
  void _processInstantiatedClassMember(
      ClassEntity cls, MemberElement member, MemberUsedCallback memberUsed) {
    assert(member.isDeclaration, failedAt(member));
    if (member.isMalformed) return;
    super._processInstantiatedClassMember(cls, member, memberUsed);
  }

  @override
  _MemberUsage _getMemberUsage(
      MemberElement member, MemberUsedCallback memberUsed) {
    assert(member.isDeclaration, failedAt(member));
    return super._getMemberUsage(member, memberUsed);
  }

  void registerStaticUse(StaticUse staticUse, MemberUsedCallback memberUsed) {
    Element element = staticUse.element;
    assert(element.isDeclaration,
        failedAt(element, "Element ${element} is not the declaration."));
    super.registerStaticUse(staticUse, memberUsed);
  }

  void registerIsCheck(ResolutionDartType type) {
    // Even in checked mode, type annotations for return type and argument
    // types do not imply type checks, so there should never be a check
    // against the type variable of a typedef.
    assert(!type.isTypeVariable || !type.element.enclosingElement.isTypedef);
    super.registerIsCheck(type);
  }
}

class KernelCodegenWorldBuilder extends CodegenWorldBuilderImpl {
  KernelToElementMapImpl _elementMap;

  KernelCodegenWorldBuilder(
      this._elementMap,
      ElementEnvironment elementEnvironment,
      NativeBasicData nativeBasicData,
      ClosedWorld world,
      SelectorConstraintsStrategy selectorConstraintsStrategy)
      : super(elementEnvironment, nativeBasicData, world,
            selectorConstraintsStrategy);

  @override
  bool hasConstantFieldInitializer(FieldEntity field) {
    return _elementMap.hasConstantFieldInitializer(field);
  }

  @override
  ConstantValue getConstantFieldInitializer(FieldEntity field) {
    return _elementMap.getConstantFieldInitializer(field);
  }

  @override
  void forEachParameter(FunctionEntity function,
      void f(DartType type, String name, ConstantValue defaultValue)) {
    _elementMap.forEachParameter(function, f);
  }

  @override
  void forEachInstanceField(
      ClassEntity cls, void f(ClassEntity declarer, FieldEntity field)) {
    _elementEnvironment.forEachClassMember(cls,
        (ClassEntity declarer, MemberEntity member) {
      if (member.isField && member.isInstanceMember) f(declarer, member);
    });
  }
}
