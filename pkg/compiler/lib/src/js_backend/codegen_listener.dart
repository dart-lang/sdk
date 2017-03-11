// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(johnniwinther): Make this a library.
part of js_backend.backend;

class CodegenEnqueuerListener extends EnqueuerListener {
  // TODO(johnniwinther): Avoid the need for accessing through [_backend].
  final JavaScriptBackend _backend;

  final ElementEnvironment _elementEnvironment;
  final CommonElements _commonElements;
  final BackendHelpers _helpers;
  final BackendImpacts _impacts;

  final MirrorsData _mirrorsData;

  final CustomElementsAnalysis _customElementsAnalysis;
  final TypeVariableHandler _typeVariableHandler;
  final LookupMapAnalysis _lookupMapAnalysis;
  final MirrorsAnalysis _mirrorsAnalysis;

  bool _isNoSuchMethodUsed = false;

  CodegenEnqueuerListener(
      this._backend,
      this._elementEnvironment,
      this._commonElements,
      this._helpers,
      this._impacts,
      this._mirrorsData,
      this._customElementsAnalysis,
      this._typeVariableHandler,
      this._lookupMapAnalysis,
      this._mirrorsAnalysis);

  // TODO(johnniwinther): Change these to final fields.
  DumpInfoTask get _dumpInfoTask => _backend.compiler.dumpInfoTask;
  RuntimeTypesNeed get _rtiNeed => _backend._rtiNeed;
  BackendUsage get _backendUsage => _backend.backendUsage;

  @override
  WorldImpact registerBoundClosure() {
    return _impacts.memberClosure.createImpact(_elementEnvironment);
  }

  @override
  WorldImpact registerGetOfStaticFunction() {
    return _impacts.staticClosure.createImpact(_elementEnvironment);
  }

  WorldImpact _registerComputeSignature() {
    return _impacts.computeSignature.createImpact(_elementEnvironment);
  }

  @override
  void registerInstantiatedType(ResolutionInterfaceType type,
      {bool isGlobal: false}) {
    _lookupMapAnalysis.registerInstantiatedType(type);
  }

  /// Called to enable support for isolates. Any backend specific [WorldImpact]
  /// of this is returned.
  WorldImpact _enableIsolateSupport(MethodElement mainMethod) {
    WorldImpactBuilderImpl impactBuilder = new WorldImpactBuilderImpl();
    // TODO(floitsch): We should also ensure that the class IsolateMessage is
    // instantiated. Currently, just enabling isolate support works.
    if (mainMethod != null) {
      // The JavaScript backend implements [Isolate.spawn] by looking up
      // top-level functions by name. So all top-level function tear-off
      // closures have a private name field.
      //
      // The JavaScript backend of [Isolate.spawnUri] uses the same internal
      // implementation as [Isolate.spawn], and fails if it cannot look main up
      // by name.
      impactBuilder.registerStaticUse(new StaticUse.staticTearOff(mainMethod));
    }
    _impacts.isolateSupport.registerImpact(impactBuilder, _elementEnvironment);
    return impactBuilder;
  }

  /// Computes the [WorldImpact] of calling [mainMethod] as the entry point.
  WorldImpact _computeMainImpact(MethodElement mainMethod) {
    WorldImpactBuilderImpl mainImpact = new WorldImpactBuilderImpl();
    if (mainMethod.parameters.isNotEmpty) {
      _impacts.mainWithArguments
          .registerImpact(mainImpact, _elementEnvironment);
      mainImpact.registerStaticUse(
          new StaticUse.staticInvoke(mainMethod, CallStructure.TWO_ARGS));
      // If the main method takes arguments, this compilation could be the
      // target of Isolate.spawnUri. Strictly speaking, that can happen also if
      // main takes no arguments, but in this case the spawned isolate can't
      // communicate with the spawning isolate.
      mainImpact.addImpact(_enableIsolateSupport(mainMethod));
    }
    mainImpact.registerStaticUse(
        new StaticUse.staticInvoke(mainMethod, CallStructure.NO_ARGS));
    return mainImpact;
  }

  @override
  void onQueueOpen(Enqueuer enqueuer, FunctionEntity mainMethod,
      Iterable<LibraryEntity> libraries) {
    enqueuer
        .applyImpact(enqueuer.nativeEnqueuer.processNativeClasses(libraries));
    if (mainMethod != null) {
      enqueuer.applyImpact(_computeMainImpact(mainMethod));
    }
    if (_backendUsage.isIsolateInUse) {
      enqueuer.applyImpact(_enableIsolateSupport(mainMethod));
    }
  }

  @override
  bool onQueueEmpty(Enqueuer enqueuer, Iterable<ClassEntity> recentClasses) {
    // Add elements used synthetically, that is, through features rather than
    // syntax, for instance custom elements.
    //
    // Return early if any elements are added to avoid counting the elements as
    // due to mirrors.
    enqueuer.applyImpact(_customElementsAnalysis.flush(forResolution: false));
    enqueuer.applyImpact(_lookupMapAnalysis.flush(forResolution: false));
    enqueuer.applyImpact(_typeVariableHandler.flush(forResolution: false));

    if (_backendUsage.isNoSuchMethodUsed && !_isNoSuchMethodUsed) {
      enqueuer.applyImpact(
          _impacts.noSuchMethodSupport.createImpact(_elementEnvironment));
      _isNoSuchMethodUsed = true;
    }

    if (!enqueuer.queueIsEmpty) return false;

    _mirrorsAnalysis.onQueueEmpty(enqueuer, recentClasses);
    return true;
  }

  @override
  WorldImpact registerUsedElement(MemberElement member) {
    WorldImpactBuilderImpl worldImpact = new WorldImpactBuilderImpl();
    _mirrorsData.registerUsedMember(member);
    _customElementsAnalysis.registerStaticUse(member, forResolution: false);

    if (member.isFunction && member.isInstanceMember) {
      MethodElement method = member;
      ClassElement cls = method.enclosingClass;
      if (method.name == Identifiers.call &&
          !cls.typeVariables.isEmpty &&
          _rtiNeed.methodNeedsRti(method)) {
        worldImpact.addImpact(_registerComputeSignature());
      }
    }

    return worldImpact;
  }

  WorldImpact registerClosureWithFreeTypeVariables(MethodElement closure) {
    if (_rtiNeed.methodNeedsRti(closure)) {
      return _registerComputeSignature();
    }
    return const WorldImpact();
  }

  WorldImpact _processClass(ClassElement cls) {
    WorldImpactBuilderImpl impactBuilder = new WorldImpactBuilderImpl();
    if (!cls.typeVariables.isEmpty) {
      _typeVariableHandler.registerClassWithTypeVariables(cls,
          forResolution: false);
    }
    if (cls == _helpers.closureClass) {
      _impacts.closureClass.registerImpact(impactBuilder, _elementEnvironment);
    }

    void registerInstantiation(ClassElement cls) {
      impactBuilder.registerTypeUse(
          new TypeUse.instantiation(_elementEnvironment.getRawType(cls)));
    }

    if (cls == _commonElements.stringClass || cls == _helpers.jsStringClass) {
      registerInstantiation(_helpers.jsStringClass);
    } else if (cls == _commonElements.listClass ||
        cls == _helpers.jsArrayClass ||
        cls == _helpers.jsFixedArrayClass ||
        cls == _helpers.jsExtendableArrayClass ||
        cls == _helpers.jsUnmodifiableArrayClass) {
      registerInstantiation(_helpers.jsArrayClass);
      registerInstantiation(_helpers.jsMutableArrayClass);
      registerInstantiation(_helpers.jsFixedArrayClass);
      registerInstantiation(_helpers.jsExtendableArrayClass);
      registerInstantiation(_helpers.jsUnmodifiableArrayClass);
    } else if (cls == _commonElements.intClass || cls == _helpers.jsIntClass) {
      registerInstantiation(_helpers.jsIntClass);
      registerInstantiation(_helpers.jsPositiveIntClass);
      registerInstantiation(_helpers.jsUInt32Class);
      registerInstantiation(_helpers.jsUInt31Class);
      registerInstantiation(_helpers.jsNumberClass);
    } else if (cls == _commonElements.doubleClass ||
        cls == _helpers.jsDoubleClass) {
      registerInstantiation(_helpers.jsDoubleClass);
      registerInstantiation(_helpers.jsNumberClass);
    } else if (cls == _commonElements.boolClass ||
        cls == _helpers.jsBoolClass) {
      registerInstantiation(_helpers.jsBoolClass);
    } else if (cls == _commonElements.nullClass ||
        cls == _helpers.jsNullClass) {
      registerInstantiation(_helpers.jsNullClass);
    } else if (cls == _commonElements.numClass ||
        cls == _helpers.jsNumberClass) {
      registerInstantiation(_helpers.jsIntClass);
      registerInstantiation(_helpers.jsPositiveIntClass);
      registerInstantiation(_helpers.jsUInt32Class);
      registerInstantiation(_helpers.jsUInt31Class);
      registerInstantiation(_helpers.jsDoubleClass);
      registerInstantiation(_helpers.jsNumberClass);
    } else if (cls == _helpers.jsJavaScriptObjectClass) {
      registerInstantiation(_helpers.jsJavaScriptObjectClass);
    } else if (cls == _helpers.jsPlainJavaScriptObjectClass) {
      registerInstantiation(_helpers.jsPlainJavaScriptObjectClass);
    } else if (cls == _helpers.jsUnknownJavaScriptObjectClass) {
      registerInstantiation(_helpers.jsUnknownJavaScriptObjectClass);
    } else if (cls == _helpers.jsJavaScriptFunctionClass) {
      registerInstantiation(_helpers.jsJavaScriptFunctionClass);
    } else if (cls == _helpers.jsIndexingBehaviorInterface) {
      _impacts.jsIndexingBehavior
          .registerImpact(impactBuilder, _elementEnvironment);
    }

    _customElementsAnalysis.registerInstantiatedClass(cls,
        forResolution: false);
    _lookupMapAnalysis.registerInstantiatedClass(cls);
    return impactBuilder;
  }

  @override
  WorldImpact registerImplementedClass(ClassEntity cls) {
    return _processClass(cls);
  }

  @override
  WorldImpact registerInstantiatedClass(ClassEntity cls) {
    return _processClass(cls);
  }
}
