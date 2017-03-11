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

    // TODO(johnniwinther): Avoid the need for accessing [_backend].
    _backend._onQueueEmpty(enqueuer, recentClasses);

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
