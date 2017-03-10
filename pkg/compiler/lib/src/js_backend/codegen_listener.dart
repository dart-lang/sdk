// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(johnniwinther): Make this a library.
part of js_backend.backend;

class CodegenEnqueuerListener extends EnqueuerListenerBase {
  bool _isNoSuchMethodUsed = false;

  CodegenEnqueuerListener(JavaScriptBackend backend) : super(backend);

  // TODO(johnniwinther): Change these to final fields.
  DumpInfoTask get dumpInfoTask => _backend.compiler.dumpInfoTask;

  RuntimeTypesNeed get rtiNeed => _backend.rtiNeed;

  BackendUsage get backendUsage => _backend.backendUsage;

  @override
  WorldImpact registerBoundClosure() {
    return impacts.memberClosure.createImpact(elementEnvironment);
  }

  @override
  WorldImpact registerGetOfStaticFunction() {
    return impacts.staticClosure.createImpact(elementEnvironment);
  }

  WorldImpact _registerComputeSignature() {
    return impacts.computeSignature.createImpact(elementEnvironment);
  }

  @override
  void registerInstantiatedType(ResolutionInterfaceType type,
      {bool isGlobal: false}) {
    lookupMapAnalysis.registerInstantiatedType(type);
  }

  @override
  bool onQueueEmpty(Enqueuer enqueuer, Iterable<ClassEntity> recentClasses) {
    // Add elements used synthetically, that is, through features rather than
    // syntax, for instance custom elements.
    //
    // Return early if any elements are added to avoid counting the elements as
    // due to mirrors.
    enqueuer.applyImpact(customElementsAnalysis.flush(forResolution: false));
    enqueuer.applyImpact(lookupMapAnalysis.flush(forResolution: false));
    enqueuer.applyImpact(typeVariableHandler.flush(forResolution: false));

    if (backendUsage.isNoSuchMethodUsed && !_isNoSuchMethodUsed) {
      enqueuer.applyImpact(
          impacts.noSuchMethodSupport.createImpact(elementEnvironment));
      _isNoSuchMethodUsed = true;
    }

    if (!enqueuer.queueIsEmpty) return false;

    // TODO(johnniwinther): Avoid the need for accessing [_backend].
    _backend._onQueueEmpty(enqueuer, recentClasses);

    mirrorsAnalysis.onQueueEmpty(enqueuer, recentClasses);
    return true;
  }

  @override
  WorldImpact registerUsedElement(MemberElement member) {
    WorldImpactBuilderImpl worldImpact = new WorldImpactBuilderImpl();
    mirrorsData.registerUsedMember(member);
    customElementsAnalysis.registerStaticUse(member, forResolution: false);

    if (member.isFunction && member.isInstanceMember) {
      MethodElement method = member;
      ClassElement cls = method.enclosingClass;
      if (method.name == Identifiers.call &&
          !cls.typeVariables.isEmpty &&
          rtiNeed.methodNeedsRti(method)) {
        worldImpact.addImpact(_registerComputeSignature());
      }
    }

    return worldImpact;
  }

  WorldImpact registerClosureWithFreeTypeVariables(MethodElement closure) {
    if (rtiNeed.methodNeedsRti(closure)) {
      return _registerComputeSignature();
    }
    return const WorldImpact();
  }

  WorldImpact _processClass(ClassElement cls) {
    WorldImpactBuilderImpl impactBuilder = new WorldImpactBuilderImpl();
    if (!cls.typeVariables.isEmpty) {
      typeVariableHandler.registerClassWithTypeVariables(cls,
          forResolution: false);
    }
    if (cls == helpers.closureClass) {
      impacts.closureClass.registerImpact(impactBuilder, elementEnvironment);
    }

    void registerInstantiation(ClassElement cls) {
      impactBuilder.registerTypeUse(
          new TypeUse.instantiation(elementEnvironment.getRawType(cls)));
    }

    if (cls == commonElements.stringClass || cls == helpers.jsStringClass) {
      registerInstantiation(helpers.jsStringClass);
    } else if (cls == commonElements.listClass ||
        cls == helpers.jsArrayClass ||
        cls == helpers.jsFixedArrayClass ||
        cls == helpers.jsExtendableArrayClass ||
        cls == helpers.jsUnmodifiableArrayClass) {
      registerInstantiation(helpers.jsArrayClass);
      registerInstantiation(helpers.jsMutableArrayClass);
      registerInstantiation(helpers.jsFixedArrayClass);
      registerInstantiation(helpers.jsExtendableArrayClass);
      registerInstantiation(helpers.jsUnmodifiableArrayClass);
    } else if (cls == commonElements.intClass || cls == helpers.jsIntClass) {
      registerInstantiation(helpers.jsIntClass);
      registerInstantiation(helpers.jsPositiveIntClass);
      registerInstantiation(helpers.jsUInt32Class);
      registerInstantiation(helpers.jsUInt31Class);
      registerInstantiation(helpers.jsNumberClass);
    } else if (cls == commonElements.doubleClass ||
        cls == helpers.jsDoubleClass) {
      registerInstantiation(helpers.jsDoubleClass);
      registerInstantiation(helpers.jsNumberClass);
    } else if (cls == commonElements.boolClass || cls == helpers.jsBoolClass) {
      registerInstantiation(helpers.jsBoolClass);
    } else if (cls == commonElements.nullClass || cls == helpers.jsNullClass) {
      registerInstantiation(helpers.jsNullClass);
    } else if (cls == commonElements.numClass || cls == helpers.jsNumberClass) {
      registerInstantiation(helpers.jsIntClass);
      registerInstantiation(helpers.jsPositiveIntClass);
      registerInstantiation(helpers.jsUInt32Class);
      registerInstantiation(helpers.jsUInt31Class);
      registerInstantiation(helpers.jsDoubleClass);
      registerInstantiation(helpers.jsNumberClass);
    } else if (cls == helpers.jsJavaScriptObjectClass) {
      registerInstantiation(helpers.jsJavaScriptObjectClass);
    } else if (cls == helpers.jsPlainJavaScriptObjectClass) {
      registerInstantiation(helpers.jsPlainJavaScriptObjectClass);
    } else if (cls == helpers.jsUnknownJavaScriptObjectClass) {
      registerInstantiation(helpers.jsUnknownJavaScriptObjectClass);
    } else if (cls == helpers.jsJavaScriptFunctionClass) {
      registerInstantiation(helpers.jsJavaScriptFunctionClass);
    } else if (cls == helpers.jsIndexingBehaviorInterface) {
      impacts.jsIndexingBehavior
          .registerImpact(impactBuilder, elementEnvironment);
    }

    customElementsAnalysis.registerInstantiatedClass(cls, forResolution: false);
    lookupMapAnalysis.registerInstantiatedClass(cls);
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
