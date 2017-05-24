// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of world_builder;

/// [ResolutionEnqueuerWorldBuilder] based on the [Element] model.
class ElementResolutionWorldBuilder extends ResolutionWorldBuilderBase {
  /// Used for testing the new more precise computation of instantiated types
  /// and classes.
  static bool useInstantiationMap = false;

  final JavaScriptBackend _backend;
  final Resolution _resolution;

  ElementResolutionWorldBuilder(
      this._backend,
      this._resolution,
      NativeBasicData nativeBasicData,
      NativeDataBuilder nativeDataBuilder,
      InterceptorDataBuilder interceptorDataBuilder,
      BackendUsageBuilder backendUsageBuilder,
      SelectorConstraintsStrategy selectorConstraintsStrategy)
      : super(
            _backend.compiler.elementEnvironment,
            _resolution.commonElements,
            nativeBasicData,
            nativeDataBuilder,
            interceptorDataBuilder,
            backendUsageBuilder,
            selectorConstraintsStrategy);

  bool isImplemented(ClassElement cls) {
    return super.isImplemented(cls.declaration);
  }

  void registerTypeInstantiation(
      InterfaceType type, ClassUsedCallback classUsed,
      {ConstructorEntity constructor,
      bool byMirrors: false,
      bool isRedirection: false}) {
    ClassElement cls = type.element;
    cls.ensureResolved(_resolution);
    super.registerTypeInstantiation(type, classUsed,
        constructor: constructor,
        byMirrors: byMirrors,
        isRedirection: isRedirection);
  }

  /// Returns the instantiation map used for computing the closed world.
  ///
  /// If [useInstantiationMap] is `true`, redirections are removed and
  /// redirecting factories are converted to their effective target and type.
  Map<ClassEntity, InstantiationInfo> getInstantiationMap() {
    if (!useInstantiationMap) return _instantiationInfo;

    Map<ClassEntity, InstantiationInfo> instantiationMap =
        <ClassEntity, InstantiationInfo>{};

    InstantiationInfo infoFor(ClassEntity cls) {
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
              ClassElement cls = target.enclosingClass;
              bool isNative = _nativeBasicData.isNativeClass(cls);
              Instantiation kind;
              if (isNative) {
                kind = Instantiation.ABSTRACTLY_INSTANTIATED;
              } else if (cls.isAbstract) {
                kind = Instantiation.UNINSTANTIATED;
              } else {
                kind = Instantiation.DIRECTLY_INSTANTIATED;
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

  void registerIsCheck(ResolutionDartType type) {
    type.computeUnaliased(_resolution);
    type = type.unaliased;
    // Even in checked mode, type annotations for return type and argument
    // types do not imply type checks, so there should never be a check
    // against the type variable of a typedef.
    assert(!type.isTypeVariable || !type.element.enclosingElement.isTypedef);
    super.registerIsCheck(type);
  }

  void registerStaticUse(StaticUse staticUse, MemberUsedCallback memberUsed) {
    Element element = staticUse.element;
    assert(element.isDeclaration,
        failedAt(element, "Element ${element} is not the declaration."));
    super.registerStaticUse(staticUse, memberUsed);
  }

  _ClassUsage _createClassUsage(ClassElement cls) {
    cls.ensureResolved(_resolution);
    _resolution.ensureClassMembers(cls);
    return super._createClassUsage(cls);
  }

  /// Called to add [cls] to the set of known classes.
  ///
  /// This ensures that class hierarchy queries can be performed on [cls] and
  /// classes that extend or implement it.
  void registerClass(ClassElement cls) => _registerClass(cls.declaration);

  void _registerClass(ClassEntity cls, {bool isDirectlyInstantiated: false}) {
    _ensureClassSet(cls);
    if (isDirectlyInstantiated) {
      _updateClassHierarchyNodeForClass(cls, directlyInstantiated: true);
    }
  }

  void _processInstantiatedClassMember(
      ClassEntity cls, MemberElement member, MemberUsedCallback memberUsed) {
    assert(member.isDeclaration, failedAt(member));
    member.computeType(_resolution);
    super._processInstantiatedClassMember(cls, member, memberUsed);
  }

  @override
  ClassEntity getAppliedMixin(ClassElement cls) {
    if (cls.isMixinApplication) {
      MixinApplicationElement mixinApplication = cls;
      // Note: If [mixinApplication] is malformed [mixin] is `null`.
      return mixinApplication.mixin;
    }
    return null;
  }

  @override
  int getHierarchyDepth(ClassElement cls) => cls.hierarchyDepth;

  @override
  bool checkClass(ClassElement cls) => cls.isDeclaration;

  @override
  bool validateClass(ClassElement cls) => cls.isResolved;

  @override
  bool implementsFunction(ClassElement cls) =>
      cls.implementsFunction(_commonElements);

  @override
  ClassEntity getSuperClass(ClassElement cls) => cls.superclass;

  @override
  Iterable<InterfaceType> getSupertypes(ClassElement cls) => cls.allSupertypes;

  ClosedWorld closeWorld() {
    Map<ClassEntity, Set<ClassEntity>> typesImplementedBySubclasses =
        populateHierarchyNodes();
    _closed = true;
    return _closedWorldCache = new ClosedWorldImpl(
        commonElements: _commonElements,
        constantSystem: _backend.constantSystem,
        nativeData: _nativeDataBuilder.close(),
        interceptorData: _interceptorDataBuilder.close(),
        backendUsage: _backendUsageBuilder.close(),
        resolutionWorldBuilder: this,
        functionSet: _allFunctions.close(),
        allTypedefs: _allTypedefs,
        mixinUses: _mixinUses,
        typesImplementedBySubclasses: typesImplementedBySubclasses,
        classHierarchyNodes: _classHierarchyNodes,
        classSets: _classSets);
  }

  @override
  void registerMixinUse(
      MixinApplicationElement mixinApplication, ClassElement mixin) {
    assert(mixin.isDeclaration);
    super.registerMixinUse(mixinApplication, mixin);
  }
}
