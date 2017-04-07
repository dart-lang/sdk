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

  ElementResolutionWorldBuilder(this._backend, this._resolution,
      SelectorConstraintsStrategy selectorConstraintsStrategy)
      : super(_backend.compiler.elementEnvironment, _resolution.commonElements,
            _backend.nativeBasicData, selectorConstraintsStrategy);

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
    if (staticUse.kind == StaticUseKind.CLOSURE) {
      LocalFunctionElement localFunction = staticUse.element;
      if (localFunction.type.containsTypeVariables) {
        localFunctionsWithFreeTypeVariables.add(localFunction);
      }
      localFunctions.add(staticUse.element);
      return;
    }
    MemberElement element = staticUse.element;
    assert(invariant(element, element.isDeclaration,
        message: "Element ${element} is not the declaration."));
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
  void registerClass(ClassEntity cls) => _registerClass(cls);

  void _registerClass(ClassEntity cls, {bool isDirectlyInstantiated: false}) {
    _ensureClassSet(cls);
    if (isDirectlyInstantiated) {
      _updateClassHierarchyNodeForClass(cls, directlyInstantiated: true);
    }
  }

  void _processInstantiatedClassMember(
      ClassEntity cls, MemberElement member, MemberUsedCallback memberUsed) {
    assert(invariant(member, member.isDeclaration));
    member.computeType(_resolution);
    super._processInstantiatedClassMember(cls, member, memberUsed);
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
    if (cls != _commonElements.functionClass &&
        cls.implementsFunction(_commonElements)) {
      ClassSet subtypeSet = _ensureClassSet(_commonElements.functionClass);
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
    Map<ClassEntity, Set<ClassEntity>> typesImplementedBySubclasses =
        new Map<ClassEntity, Set<ClassEntity>>();

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
        Set<ClassEntity> typesImplementedBySubclassesOfCls =
            typesImplementedBySubclasses.putIfAbsent(
                superclass, () => new Set<ClassEntity>());
        for (ResolutionInterfaceType current in cls.allSupertypes) {
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
        commonElements: _commonElements,
        resolutionWorldBuilder: this,
        functionSetBuilder: _allFunctions,
        allTypedefs: _allTypedefs,
        mixinUses: _mixinUses,
        typesImplementedBySubclasses: typesImplementedBySubclasses,
        classHierarchyNodes: _classHierarchyNodes,
        classSets: _classSets);
  }

  void registerUsedElement(MemberElement element) {
    if (element.isInstanceMember && !element.isAbstract) {
      _allFunctions.add(element);
    }
  }

  @override
  void registerMixinUse(
      MixinApplicationElement mixinApplication, ClassElement mixin) {
    assert(mixin.isDeclaration);
    super.registerMixinUse(mixinApplication, mixin);
  }
}
