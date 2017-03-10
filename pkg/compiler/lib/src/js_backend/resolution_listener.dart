// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(johnniwinther): Make this a library.
part of js_backend.backend;

class ResolutionEnqueuerListener extends EnqueuerListenerBase {
  /// True when we enqueue the loadLibrary code.
  bool _isLoadLibraryFunctionResolved = false;

  ResolutionEnqueuerListener(JavaScriptBackend backend) : super(backend);

  // TODO(johnniwinther): Change these to final fields.
  NativeData get nativeData => _backend.nativeData;

  CompilerOptions get options => _backend.compiler.options;

  Resolution get resolution => _backend.resolution;

  InterceptorDataBuilder get interceptorData =>
      _backend._interceptorDataBuilder;

  BackendUsageBuilder get backendUsage => _backend.backendUsageBuilder;

  RuntimeTypesNeedBuilder get rtiNeedBuilder => _backend.rtiNeedBuilder;

  NoSuchMethodRegistry get noSuchMethodRegistry =>
      _backend.noSuchMethodRegistry;

  void registerBackendImpact(WorldImpactBuilder builder, BackendImpact impact) {
    impact.registerImpact(builder, elementEnvironment);
    backendUsage.processBackendImpact(impact);
  }

  void addInterceptors(ClassElement cls, WorldImpactBuilder impactBuilder) {
    cls.ensureResolved(resolution);
    interceptorData.addInterceptors(cls);
    impactBuilder.registerTypeUse(new TypeUse.instantiation(cls.rawType));
    backendUsage.registerBackendUse(cls);
  }

  @override
  WorldImpact registerBoundClosure() {
    backendUsage.processBackendImpact(impacts.memberClosure);
    return impacts.memberClosure.createImpact(elementEnvironment);
  }

  @override
  WorldImpact registerGetOfStaticFunction() {
    backendUsage.processBackendImpact(impacts.staticClosure);
    return impacts.staticClosure.createImpact(elementEnvironment);
  }

  WorldImpact _registerComputeSignature() {
    backendUsage.processBackendImpact(impacts.computeSignature);
    return impacts.computeSignature.createImpact(elementEnvironment);
  }

  @override
  void registerInstantiatedType(ResolutionInterfaceType type,
      {bool isGlobal: false}) {
    if (isGlobal) {
      backendUsage.registerGlobalDependency(type.element);
    }
  }

  @override
  bool onQueueEmpty(Enqueuer enqueuer, Iterable<ClassEntity> recentClasses) {
    // Add elements used synthetically, that is, through features rather than
    // syntax, for instance custom elements.
    //
    // Return early if any elements are added to avoid counting the elements as
    // due to mirrors.
    enqueuer.applyImpact(customElementsAnalysis.flush(forResolution: true));
    enqueuer.applyImpact(lookupMapAnalysis.flush(forResolution: true));
    enqueuer.applyImpact(typeVariableHandler.flush(forResolution: true));

    for (ClassElement cls in recentClasses) {
      Element element = cls.lookupLocalMember(Identifiers.noSuchMethod_);
      if (element != null && element.isInstanceMember && element.isFunction) {
        noSuchMethodRegistry.registerNoSuchMethod(element);
      }
    }
    noSuchMethodRegistry.onQueueEmpty();
    if (!backendUsage.isNoSuchMethodUsed &&
        (noSuchMethodRegistry.hasThrowingNoSuchMethod ||
            noSuchMethodRegistry.hasComplexNoSuchMethod)) {
      backendUsage.processBackendImpact(impacts.noSuchMethodSupport);
      enqueuer.applyImpact(
          impacts.noSuchMethodSupport.createImpact(elementEnvironment));
      backendUsage.isNoSuchMethodUsed = true;
    }

    if (!enqueuer.queueIsEmpty) return false;

    _backend._onQueueEmpty(enqueuer, recentClasses);

    mirrorsAnalysis.onQueueEmpty(enqueuer, recentClasses);
    return true;
  }

  @override
  WorldImpact registerUsedElement(MemberElement member) {
    WorldImpactBuilderImpl worldImpact = new WorldImpactBuilderImpl();
    mirrorsData.registerUsedMember(member);
    customElementsAnalysis.registerStaticUse(member, forResolution: true);

    if (member.isFunction && member.isInstanceMember) {
      MethodElement method = member;
      ClassElement cls = method.enclosingClass;
      if (method.name == Identifiers.call && !cls.typeVariables.isEmpty) {
        worldImpact.addImpact(_registerComputeSignature());
      }
    }
    backendUsage.registerUsedMember(member);

    if (member.isDeferredLoaderGetter) {
      // TODO(sigurdm): Create a function registerLoadLibraryAccess.
      if (!_isLoadLibraryFunctionResolved) {
        _isLoadLibraryFunctionResolved = true;
        registerBackendImpact(worldImpact, impacts.loadLibrary);
      }
    }

    // Enable isolate support if we start using something from the isolate
    // library, or timers for the async library.  We exclude constant fields,
    // which are ending here because their initializing expression is
    // compiled.
    LibraryElement library = member.library;
    if (!backendUsage.isIsolateInUse && !(member.isField && member.isConst)) {
      Uri uri = library.canonicalUri;
      if (uri == Uris.dart_isolate) {
        backendUsage.isIsolateInUse = true;
        worldImpact.addImpact(enableIsolateSupport());
      } else if (uri == Uris.dart_async) {
        if (member.name == '_createTimer' ||
            member.name == '_createPeriodicTimer') {
          // The [:Timer:] class uses the event queue of the isolate
          // library, so we make sure that event queue is generated.
          backendUsage.isIsolateInUse = true;
          worldImpact.addImpact(enableIsolateSupport());
        }
      }
    }

    if (member.isGetter && member.name == Identifiers.runtimeType_) {
      // Enable runtime type support if we discover a getter called
      // runtimeType. We have to enable runtime type before hitting the
      // codegen, so that constructors know whether they need to generate code
      // for runtime type.
      backendUsage.isRuntimeTypeUsed = true;
      // TODO(ahe): Record precise dependency here.
      worldImpact.addImpact(registerRuntimeType());
    }

    return worldImpact;
  }

  WorldImpact enableIsolateSupport() =>
      _backend.enableIsolateSupport(forResolution: true);

  /// Called to register that the `runtimeType` property has been accessed. Any
  /// backend specific [WorldImpact] of this is returned.
  WorldImpact registerRuntimeType() {
    backendUsage.processBackendImpact(impacts.runtimeTypeSupport);
    return impacts.runtimeTypeSupport.createImpact(elementEnvironment);
  }

  WorldImpact registerClosureWithFreeTypeVariables(MethodElement closure) {
    return _registerComputeSignature();
  }

  WorldImpact _processClass(ClassElement cls) {
    WorldImpactBuilderImpl impactBuilder = new WorldImpactBuilderImpl();
    if (!cls.typeVariables.isEmpty) {
      typeVariableHandler.registerClassWithTypeVariables(cls,
          forResolution: true);
    }
    // Register any helper that will be needed by the backend.
    if (cls == commonElements.intClass ||
        cls == commonElements.doubleClass ||
        cls == commonElements.numClass) {
      registerBackendImpact(impactBuilder, impacts.numClasses);
    } else if (cls == commonElements.listClass ||
        cls == commonElements.stringClass) {
      registerBackendImpact(impactBuilder, impacts.listOrStringClasses);
    } else if (cls == commonElements.functionClass) {
      registerBackendImpact(impactBuilder, impacts.functionClass);
    } else if (cls == commonElements.mapClass) {
      registerBackendImpact(impactBuilder, impacts.mapClass);
      // For map literals, the dependency between the implementation class
      // and [Map] is not visible, so we have to add it manually.
      rtiNeedBuilder.registerRtiDependency(helpers.mapLiteralClass, cls);
    } else if (cls == helpers.boundClosureClass) {
      registerBackendImpact(impactBuilder, impacts.boundClosureClass);
    } else if (nativeData.isNativeOrExtendsNative(cls)) {
      registerBackendImpact(impactBuilder, impacts.nativeOrExtendsClass);
    } else if (cls == helpers.mapLiteralClass) {
      registerBackendImpact(impactBuilder, impacts.mapLiteralClass);
    }
    if (cls == helpers.closureClass) {
      registerBackendImpact(impactBuilder, impacts.closureClass);
    }
    if (cls == commonElements.stringClass || cls == helpers.jsStringClass) {
      addInterceptors(helpers.jsStringClass, impactBuilder);
    } else if (cls == commonElements.listClass ||
        cls == helpers.jsArrayClass ||
        cls == helpers.jsFixedArrayClass ||
        cls == helpers.jsExtendableArrayClass ||
        cls == helpers.jsUnmodifiableArrayClass) {
      addInterceptors(helpers.jsArrayClass, impactBuilder);
      addInterceptors(helpers.jsMutableArrayClass, impactBuilder);
      addInterceptors(helpers.jsFixedArrayClass, impactBuilder);
      addInterceptors(helpers.jsExtendableArrayClass, impactBuilder);
      addInterceptors(helpers.jsUnmodifiableArrayClass, impactBuilder);
      registerBackendImpact(impactBuilder, impacts.listClasses);
    } else if (cls == commonElements.intClass || cls == helpers.jsIntClass) {
      addInterceptors(helpers.jsIntClass, impactBuilder);
      addInterceptors(helpers.jsPositiveIntClass, impactBuilder);
      addInterceptors(helpers.jsUInt32Class, impactBuilder);
      addInterceptors(helpers.jsUInt31Class, impactBuilder);
      addInterceptors(helpers.jsNumberClass, impactBuilder);
    } else if (cls == commonElements.doubleClass ||
        cls == helpers.jsDoubleClass) {
      addInterceptors(helpers.jsDoubleClass, impactBuilder);
      addInterceptors(helpers.jsNumberClass, impactBuilder);
    } else if (cls == commonElements.boolClass || cls == helpers.jsBoolClass) {
      addInterceptors(helpers.jsBoolClass, impactBuilder);
    } else if (cls == commonElements.nullClass || cls == helpers.jsNullClass) {
      addInterceptors(helpers.jsNullClass, impactBuilder);
    } else if (cls == commonElements.numClass || cls == helpers.jsNumberClass) {
      addInterceptors(helpers.jsIntClass, impactBuilder);
      addInterceptors(helpers.jsPositiveIntClass, impactBuilder);
      addInterceptors(helpers.jsUInt32Class, impactBuilder);
      addInterceptors(helpers.jsUInt31Class, impactBuilder);
      addInterceptors(helpers.jsDoubleClass, impactBuilder);
      addInterceptors(helpers.jsNumberClass, impactBuilder);
    } else if (cls == helpers.jsJavaScriptObjectClass) {
      addInterceptors(helpers.jsJavaScriptObjectClass, impactBuilder);
    } else if (cls == helpers.jsPlainJavaScriptObjectClass) {
      addInterceptors(helpers.jsPlainJavaScriptObjectClass, impactBuilder);
    } else if (cls == helpers.jsUnknownJavaScriptObjectClass) {
      addInterceptors(helpers.jsUnknownJavaScriptObjectClass, impactBuilder);
    } else if (cls == helpers.jsJavaScriptFunctionClass) {
      addInterceptors(helpers.jsJavaScriptFunctionClass, impactBuilder);
    } else if (nativeData.isNativeOrExtendsNative(cls)) {
      addInterceptorsForNativeClassMembers(cls);
    } else if (cls == helpers.jsIndexingBehaviorInterface) {
      registerBackendImpact(impactBuilder, impacts.jsIndexingBehavior);
    }

    customElementsAnalysis.registerInstantiatedClass(cls, forResolution: true);
    return impactBuilder;
  }

  void addInterceptorsForNativeClassMembers(ClassElement cls) {
    cls.ensureResolved(resolution);
    interceptorData.addInterceptorsForNativeClassMembers(cls);
  }

  @override
  WorldImpact registerImplementedClass(ClassEntity cls) {
    return _processClass(cls);
  }

  @override
  WorldImpact registerInstantiatedClass(ClassEntity cls) {
    return _processClass(cls);
  }

  /// Compute the [WorldImpact] for backend helper methods.
  WorldImpact computeHelpersImpact() {
    assert(helpers.interceptorsLibrary != null);
    WorldImpactBuilderImpl impactBuilder = new WorldImpactBuilderImpl();
    // TODO(ngeoffray): Not enqueuing those two classes currently make
    // the compiler potentially crash. However, any reasonable program
    // will instantiate those two classes.
    addInterceptors(helpers.jsBoolClass, impactBuilder);
    addInterceptors(helpers.jsNullClass, impactBuilder);
    if (options.enableTypeAssertions) {
      registerBackendImpact(impactBuilder, impacts.enableTypeAssertions);
    }

    if (JavaScriptBackend.TRACE_CALLS) {
      registerBackendImpact(impactBuilder, impacts.traceHelper);
    }
    registerBackendImpact(impactBuilder, impacts.assertUnreachable);
    _registerCheckedModeHelpers(impactBuilder);
    return impactBuilder;
  }

  /// Called to register a `noSuchMethod` implementation.
  void registerNoSuchMethod(MethodElement noSuchMethod) {
    noSuchMethodRegistry.registerNoSuchMethod(noSuchMethod);
  }

  void _registerCheckedModeHelpers(WorldImpactBuilder impactBuilder) {
    // We register all the helpers in the resolution queue.
    // TODO(13155): Find a way to register fewer helpers.
    List<Element> staticUses = <Element>[];
    for (CheckedModeHelper helper in CheckedModeHelpers.helpers) {
      staticUses.add(helper.getStaticUse(helpers).element);
    }
    registerBackendImpact(
        impactBuilder, new BackendImpact(globalUses: staticUses));
  }
}
