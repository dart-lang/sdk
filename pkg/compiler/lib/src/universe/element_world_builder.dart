// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of world_builder;

/// [ResolutionEnqueuerWorldBuilder] based on the [Element] model.
class ElementResolutionWorldBuilder extends ResolutionWorldBuilderBase {
  /// Used for testing the new more precise computation of instantiated types
  /// and classes.
  static bool useInstantiationMap = false;

  final Resolution _resolution;

  ElementResolutionWorldBuilder(
      JavaScriptBackend backend,
      this._resolution,
      NativeBasicData nativeBasicData,
      NativeDataBuilder nativeDataBuilder,
      InterceptorDataBuilder interceptorDataBuilder,
      BackendUsageBuilder backendUsageBuilder,
      RuntimeTypesNeedBuilder rtiNeedBuilder,
      NativeResolutionEnqueuer nativeResolutionEnqueuer,
      SelectorConstraintsStrategy selectorConstraintsStrategy,
      ClassHierarchyBuilder classHierarchyBuilder,
      ClassQueries classQueries)
      : super(
            backend.compiler.options,
            _resolution.elementEnvironment,
            _resolution.types,
            _resolution.commonElements,
            backend.constantSystem,
            nativeBasicData,
            nativeDataBuilder,
            interceptorDataBuilder,
            backendUsageBuilder,
            rtiNeedBuilder,
            nativeResolutionEnqueuer,
            selectorConstraintsStrategy,
            classHierarchyBuilder,
            classQueries);

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
        info.instantiationMap.forEach((_constructor, Set<Instance> set) {
          ConstructorElement constructor = _constructor;
          for (Instance instance in set) {
            if (instance.isRedirection) {
              continue;
            }
            if (constructor == null || !constructor.isRedirectingFactory) {
              infoFor(cls)
                  .addInstantiation(constructor, instance.type, instance.kind);
            } else {
              ConstructorElement target = constructor.effectiveTarget;
              ResolutionDartType targetType =
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
              if (targetType is ResolutionInterfaceType) {
                infoFor(targetType.element)
                    .addInstantiation(target, targetType, kind);
              }
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

  void _processInstantiatedClassMember(
      ClassEntity cls, MemberElement member, MemberUsedCallback memberUsed) {
    assert(member.isDeclaration, failedAt(member));
    member.computeType(_resolution);
    super._processInstantiatedClassMember(cls, member, memberUsed);
  }

  ClosedWorld closeWorld() {
    Map<ClassEntity, Set<ClassEntity>> typesImplementedBySubclasses =
        populateHierarchyNodes();
    _closed = true;

    return _closedWorldCache = new ClosedWorldImpl(
        options: _options,
        elementEnvironment: _elementEnvironment,
        dartTypes: _dartTypes,
        commonElements: _commonElements,
        constantSystem: _constantSystem,
        nativeData: _nativeDataBuilder.close(),
        interceptorData: _interceptorDataBuilder.close(),
        backendUsage: _backendUsageBuilder.close(),
        resolutionWorldBuilder: this,
        rtiNeedBuilder: _rtiNeedBuilder,
        implementedClasses: _implementedClasses,
        liveNativeClasses: _nativeResolutionEnqueuer.liveNativeClasses,
        liveInstanceMembers: _liveInstanceMembers,
        assignedInstanceMembers: computeAssignedInstanceMembers(),
        processedMembers: _processedMembers,
        allTypedefs: _allTypedefs,
        mixinUses: classHierarchyBuilder.mixinUses,
        typesImplementedBySubclasses: typesImplementedBySubclasses,
        classHierarchyNodes: classHierarchyBuilder.classHierarchyNodes,
        classSets: classHierarchyBuilder.classSets);
  }

  @override
  void forEachLocalFunction(void f(MemberEntity member, Local localFunction)) {
    for (LocalFunctionElement local in localFunctions) {
      f(local.memberContext, local);
    }
  }
}
