// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js_backend.backend.resolution_listener;

import '../common/backend_api.dart';
import '../common/names.dart' show Identifiers, Uris;
import '../common_elements.dart' show CommonElements, ElementEnvironment;
import '../constants/values.dart';
import '../elements/elements.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import '../enqueue.dart' show Enqueuer, EnqueuerListener;
import '../kernel/task.dart';
import '../native/enqueue.dart';
import '../options.dart' show CompilerOptions;
import '../universe/call_structure.dart' show CallStructure;
import '../universe/use.dart' show StaticUse, TypeUse;
import '../universe/world_impact.dart'
    show WorldImpact, WorldImpactBuilder, WorldImpactBuilderImpl;
import 'backend.dart';
import 'backend_helpers.dart';
import 'backend_impact.dart';
import 'backend_usage.dart';
import 'checked_mode_helpers.dart';
import 'custom_elements_analysis.dart';
import 'interceptor_data.dart';
import 'lookup_map_analysis.dart' show LookupMapResolutionAnalysis;
import 'mirrors_analysis.dart';
import 'mirrors_data.dart';
import 'native_data.dart' show NativeBasicData;
import 'no_such_method_registry.dart';
import 'type_variable_handler.dart';

class ResolutionEnqueuerListener extends EnqueuerListener {
  // TODO(johnniwinther): Avoid the need for this.
  final KernelTask _kernelTask;

  final CompilerOptions _options;
  final ElementEnvironment _elementEnvironment;
  final CommonElements _commonElements;
  final BackendHelpers _helpers;
  final BackendImpacts _impacts;
  final BackendClasses _backendClasses;

  final NativeBasicData _nativeData;
  final InterceptorDataBuilder _interceptorData;
  final BackendUsageBuilder _backendUsage;
  final RuntimeTypesNeedBuilder _rtiNeedBuilder;
  final MirrorsDataBuilder _mirrorsDataBuilder;

  final NoSuchMethodRegistry _noSuchMethodRegistry;
  final CustomElementsResolutionAnalysis _customElementsAnalysis;
  final LookupMapResolutionAnalysis _lookupMapResolutionAnalysis;
  final MirrorsResolutionAnalysis _mirrorsAnalysis;
  final TypeVariableResolutionAnalysis _typeVariableResolutionAnalysis;

  final NativeResolutionEnqueuer _nativeEnqueuer;

  /// True when we enqueue the loadLibrary code.
  bool _isLoadLibraryFunctionResolved = false;

  ResolutionEnqueuerListener(
      this._options,
      this._elementEnvironment,
      this._commonElements,
      this._helpers,
      this._impacts,
      this._backendClasses,
      this._nativeData,
      this._interceptorData,
      this._backendUsage,
      this._rtiNeedBuilder,
      this._mirrorsDataBuilder,
      this._noSuchMethodRegistry,
      this._customElementsAnalysis,
      this._lookupMapResolutionAnalysis,
      this._mirrorsAnalysis,
      this._typeVariableResolutionAnalysis,
      this._nativeEnqueuer,
      [this._kernelTask]);

  void _registerBackendImpact(
      WorldImpactBuilder builder, BackendImpact impact) {
    impact.registerImpact(builder, _elementEnvironment);
    _backendUsage.processBackendImpact(impact);
  }

  void _addInterceptors(ClassElement cls, WorldImpactBuilder impactBuilder) {
    _interceptorData.addInterceptors(cls);
    impactBuilder.registerTypeUse(new TypeUse.instantiation(cls.rawType));
    _backendUsage.registerBackendClassUse(cls);
  }

  @override
  WorldImpact registerClosurizedMember(MemberElement element) {
    WorldImpactBuilderImpl impactBuilder = new WorldImpactBuilderImpl();
    _backendUsage.processBackendImpact(_impacts.memberClosure);
    impactBuilder
        .addImpact(_impacts.memberClosure.createImpact(_elementEnvironment));
    if (element.type.containsTypeVariables) {
      impactBuilder.addImpact(_registerComputeSignature());
    }
    return impactBuilder;
  }

  @override
  WorldImpact registerGetOfStaticFunction() {
    _backendUsage.processBackendImpact(_impacts.staticClosure);
    return _impacts.staticClosure.createImpact(_elementEnvironment);
  }

  WorldImpact _registerComputeSignature() {
    _backendUsage.processBackendImpact(_impacts.computeSignature);
    return _impacts.computeSignature.createImpact(_elementEnvironment);
  }

  @override
  void registerInstantiatedType(InterfaceType type,
      {bool isGlobal: false, bool nativeUsage: false}) {
    if (isGlobal) {
      _backendUsage.registerGlobalClassDependency(type.element);
    }
    if (nativeUsage) {
      _nativeEnqueuer.onInstantiatedType(type);
    }
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
    _backendUsage.processBackendImpact(_impacts.isolateSupport);
    _impacts.isolateSupportForResolution
        .registerImpact(impactBuilder, _elementEnvironment);
    _backendUsage.processBackendImpact(_impacts.isolateSupportForResolution);
    return impactBuilder;
  }

  /// Computes the [WorldImpact] of calling [mainMethod] as the entry point.
  WorldImpact _computeMainImpact(MethodElement mainMethod) {
    WorldImpactBuilderImpl mainImpact = new WorldImpactBuilderImpl();
    if (mainMethod.parameters.isNotEmpty) {
      _impacts.mainWithArguments
          .registerImpact(mainImpact, _elementEnvironment);
      _backendUsage.processBackendImpact(_impacts.mainWithArguments);
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
    enqueuer.applyImpact(_nativeEnqueuer.processNativeClasses(libraries));
    if (mainMethod != null) {
      enqueuer.applyImpact(_computeMainImpact(mainMethod));
    }
    // Elements required by enqueueHelpers are global dependencies
    // that are not pulled in by a particular element.
    enqueuer.applyImpact(computeHelpersImpact());
  }

  @override
  bool onQueueEmpty(Enqueuer enqueuer, Iterable<ClassEntity> recentClasses) {
    // Add elements used synthetically, that is, through features rather than
    // syntax, for instance custom elements.
    //
    // Return early if any elements are added to avoid counting the elements as
    // due to mirrors.
    enqueuer.applyImpact(_customElementsAnalysis.flush());
    enqueuer.applyImpact(_lookupMapResolutionAnalysis.flush());
    enqueuer.applyImpact(_typeVariableResolutionAnalysis.flush());

    for (ClassEntity cls in recentClasses) {
      MemberEntity element =
          _elementEnvironment.lookupClassMember(cls, Identifiers.noSuchMethod_);
      if (element != null && element.isInstanceMember && element.isFunction) {
        _noSuchMethodRegistry.registerNoSuchMethod(element);
      }
    }
    _noSuchMethodRegistry.onQueueEmpty();
    if (!_backendUsage.isNoSuchMethodUsed &&
        (_noSuchMethodRegistry.hasThrowingNoSuchMethod ||
            _noSuchMethodRegistry.hasComplexNoSuchMethod)) {
      _backendUsage.processBackendImpact(_impacts.noSuchMethodSupport);
      enqueuer.applyImpact(
          _impacts.noSuchMethodSupport.createImpact(_elementEnvironment));
      _backendUsage.isNoSuchMethodUsed = true;
    }

    if (!enqueuer.queueIsEmpty) return false;

    if (_options.useKernel) {
      _kernelTask?.buildKernelIr();
    }

    _mirrorsAnalysis.onQueueEmpty(enqueuer, recentClasses);
    return true;
  }

  @override
  void onQueueClosed() {}

  /// Adds the impact of [constant] to [impactBuilder].
  void _computeImpactForCompileTimeConstant(
      ConstantValue constant, WorldImpactBuilder impactBuilder) {
    _computeImpactForCompileTimeConstantInternal(constant, impactBuilder);

    for (ConstantValue dependency in constant.getDependencies()) {
      _computeImpactForCompileTimeConstant(dependency, impactBuilder);
    }
  }

  void _computeImpactForCompileTimeConstantInternal(
      ConstantValue constant, WorldImpactBuilder impactBuilder) {
    DartType type = constant.getType(_commonElements);
    _computeImpactForInstantiatedConstantType(type, impactBuilder);

    if (constant.isFunction) {
      FunctionConstantValue function = constant;
      impactBuilder
          .registerStaticUse(new StaticUse.staticTearOff(function.element));
    } else if (constant.isInterceptor) {
      // An interceptor constant references the class's prototype chain.
      InterceptorConstantValue interceptor = constant;
      ClassElement cls = interceptor.cls;
      _computeImpactForInstantiatedConstantType(cls.thisType, impactBuilder);
    } else if (constant.isType) {
      MethodElement helper = _helpers.createRuntimeType;
      impactBuilder.registerStaticUse(new StaticUse.staticInvoke(
          // TODO(johnniwinther): Find the right [CallStructure].
          helper,
          null));
      _backendUsage.registerBackendFunctionUse(helper);
      impactBuilder
          .registerTypeUse(new TypeUse.instantiation(_backendClasses.typeType));
    }
  }

  void _computeImpactForInstantiatedConstantType(
      DartType type, WorldImpactBuilder impactBuilder) {
    if (type is InterfaceType) {
      impactBuilder.registerTypeUse(new TypeUse.instantiation(type));
      if (type.element == _backendClasses.typeClass) {
        // If we use a type literal in a constant, the compile time
        // constant emitter will generate a call to the createRuntimeType
        // helper so we register a use of that.
        impactBuilder.registerStaticUse(new StaticUse.staticInvoke(
            // TODO(johnniwinther): Find the right [CallStructure].
            _helpers.createRuntimeType,
            null));
      }
    }
  }

  @override
  WorldImpact registerUsedConstant(ConstantValue constant) {
    WorldImpactBuilderImpl impactBuilder = new WorldImpactBuilderImpl();
    _computeImpactForCompileTimeConstant(constant, impactBuilder);
    return impactBuilder;
  }

  @override
  WorldImpact registerUsedElement(MemberElement member) {
    WorldImpactBuilderImpl worldImpact = new WorldImpactBuilderImpl();
    _mirrorsDataBuilder.registerUsedMember(member);
    _customElementsAnalysis.registerStaticUse(member);

    if (member.isFunction && member.isInstanceMember) {
      MethodElement method = member;
      ClassElement cls = method.enclosingClass;
      if (method.name == Identifiers.call && !cls.typeVariables.isEmpty) {
        worldImpact.addImpact(_registerComputeSignature());
      }
    }
    _backendUsage.registerUsedMember(member);

    if (member.isDeferredLoaderGetter) {
      // TODO(sigurdm): Create a function registerLoadLibraryAccess.
      if (!_isLoadLibraryFunctionResolved) {
        _isLoadLibraryFunctionResolved = true;
        _registerBackendImpact(worldImpact, _impacts.loadLibrary);
      }
    }

    // Enable isolate support if we start using something from the isolate
    // library, or timers for the async library.  We exclude constant fields,
    // which are ending here because their initializing expression is
    // compiled.
    LibraryElement library = member.library;
    if (!_backendUsage.isIsolateInUse && !(member.isField && member.isConst)) {
      Uri uri = library.canonicalUri;
      if (uri == Uris.dart_isolate) {
        _backendUsage.isIsolateInUse = true;
        worldImpact
            .addImpact(_enableIsolateSupport(_elementEnvironment.mainFunction));
      } else if (uri == Uris.dart_async) {
        if (member.name == '_createTimer' ||
            member.name == '_createPeriodicTimer') {
          // The [:Timer:] class uses the event queue of the isolate
          // library, so we make sure that event queue is generated.
          _backendUsage.isIsolateInUse = true;
          worldImpact.addImpact(
              _enableIsolateSupport(_elementEnvironment.mainFunction));
        }
      }
    }

    if (member.isGetter && member.name == Identifiers.runtimeType_) {
      // Enable runtime type support if we discover a getter called
      // runtimeType. We have to enable runtime type before hitting the
      // codegen, so that constructors know whether they need to generate code
      // for runtime type.
      _backendUsage.isRuntimeTypeUsed = true;
      // TODO(ahe): Record precise dependency here.
      worldImpact.addImpact(_registerRuntimeType());
    }

    return worldImpact;
  }

  /// Called to register that the `runtimeType` property has been accessed. Any
  /// backend specific [WorldImpact] of this is returned.
  WorldImpact _registerRuntimeType() {
    _backendUsage.processBackendImpact(_impacts.runtimeTypeSupport);
    return _impacts.runtimeTypeSupport.createImpact(_elementEnvironment);
  }

  WorldImpact _processClass(ClassElement cls) {
    WorldImpactBuilderImpl impactBuilder = new WorldImpactBuilderImpl();
    if (!cls.typeVariables.isEmpty) {
      _typeVariableResolutionAnalysis.registerClassWithTypeVariables(cls);
    }
    // TODO(johnniwinther): Extract an `implementationClassesOf(...)` function
    // for these into [BackendHelpers] or [BackendImpacts].
    // Register any helper that will be needed by the backend.
    if (cls == _commonElements.intClass ||
        cls == _commonElements.doubleClass ||
        cls == _commonElements.numClass) {
      _registerBackendImpact(impactBuilder, _impacts.numClasses);
    } else if (cls == _commonElements.listClass ||
        cls == _commonElements.stringClass) {
      _registerBackendImpact(impactBuilder, _impacts.listOrStringClasses);
    } else if (cls == _commonElements.functionClass) {
      _registerBackendImpact(impactBuilder, _impacts.functionClass);
    } else if (cls == _commonElements.mapClass) {
      _registerBackendImpact(impactBuilder, _impacts.mapClass);
      // For map literals, the dependency between the implementation class
      // and [Map] is not visible, so we have to add it manually.
      _rtiNeedBuilder.registerRtiDependency(_helpers.mapLiteralClass, cls);
    } else if (cls == _helpers.boundClosureClass) {
      _registerBackendImpact(impactBuilder, _impacts.boundClosureClass);
    } else if (_nativeData.isNativeOrExtendsNative(cls)) {
      _registerBackendImpact(impactBuilder, _impacts.nativeOrExtendsClass);
    } else if (cls == _helpers.mapLiteralClass) {
      _registerBackendImpact(impactBuilder, _impacts.mapLiteralClass);
    }
    if (cls == _helpers.closureClass) {
      _registerBackendImpact(impactBuilder, _impacts.closureClass);
    }
    if (cls == _commonElements.stringClass || cls == _helpers.jsStringClass) {
      _addInterceptors(_helpers.jsStringClass, impactBuilder);
    } else if (cls == _commonElements.listClass ||
        cls == _helpers.jsArrayClass ||
        cls == _helpers.jsFixedArrayClass ||
        cls == _helpers.jsExtendableArrayClass ||
        cls == _helpers.jsUnmodifiableArrayClass) {
      _addInterceptors(_helpers.jsArrayClass, impactBuilder);
      _addInterceptors(_helpers.jsMutableArrayClass, impactBuilder);
      _addInterceptors(_helpers.jsFixedArrayClass, impactBuilder);
      _addInterceptors(_helpers.jsExtendableArrayClass, impactBuilder);
      _addInterceptors(_helpers.jsUnmodifiableArrayClass, impactBuilder);
      _registerBackendImpact(impactBuilder, _impacts.listClasses);
    } else if (cls == _commonElements.intClass || cls == _helpers.jsIntClass) {
      _addInterceptors(_helpers.jsIntClass, impactBuilder);
      _addInterceptors(_helpers.jsPositiveIntClass, impactBuilder);
      _addInterceptors(_helpers.jsUInt32Class, impactBuilder);
      _addInterceptors(_helpers.jsUInt31Class, impactBuilder);
      _addInterceptors(_helpers.jsNumberClass, impactBuilder);
    } else if (cls == _commonElements.doubleClass ||
        cls == _helpers.jsDoubleClass) {
      _addInterceptors(_helpers.jsDoubleClass, impactBuilder);
      _addInterceptors(_helpers.jsNumberClass, impactBuilder);
    } else if (cls == _commonElements.boolClass ||
        cls == _helpers.jsBoolClass) {
      _addInterceptors(_helpers.jsBoolClass, impactBuilder);
    } else if (cls == _commonElements.nullClass ||
        cls == _helpers.jsNullClass) {
      _addInterceptors(_helpers.jsNullClass, impactBuilder);
    } else if (cls == _commonElements.numClass ||
        cls == _helpers.jsNumberClass) {
      _addInterceptors(_helpers.jsIntClass, impactBuilder);
      _addInterceptors(_helpers.jsPositiveIntClass, impactBuilder);
      _addInterceptors(_helpers.jsUInt32Class, impactBuilder);
      _addInterceptors(_helpers.jsUInt31Class, impactBuilder);
      _addInterceptors(_helpers.jsDoubleClass, impactBuilder);
      _addInterceptors(_helpers.jsNumberClass, impactBuilder);
    } else if (cls == _helpers.jsJavaScriptObjectClass) {
      _addInterceptors(_helpers.jsJavaScriptObjectClass, impactBuilder);
    } else if (cls == _helpers.jsPlainJavaScriptObjectClass) {
      _addInterceptors(_helpers.jsPlainJavaScriptObjectClass, impactBuilder);
    } else if (cls == _helpers.jsUnknownJavaScriptObjectClass) {
      _addInterceptors(_helpers.jsUnknownJavaScriptObjectClass, impactBuilder);
    } else if (cls == _helpers.jsJavaScriptFunctionClass) {
      _addInterceptors(_helpers.jsJavaScriptFunctionClass, impactBuilder);
    } else if (_nativeData.isNativeOrExtendsNative(cls)) {
      _interceptorData.addInterceptorsForNativeClassMembers(cls);
    } else if (cls == _helpers.jsIndexingBehaviorInterface) {
      _registerBackendImpact(impactBuilder, _impacts.jsIndexingBehavior);
    }

    _customElementsAnalysis.registerInstantiatedClass(cls);
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

  /// Compute the [WorldImpact] for backend helper methods.
  WorldImpact computeHelpersImpact() {
    assert(_helpers.interceptorsLibrary != null);
    WorldImpactBuilderImpl impactBuilder = new WorldImpactBuilderImpl();
    // TODO(ngeoffray): Not enqueuing those two classes currently make
    // the compiler potentially crash. However, any reasonable program
    // will instantiate those two classes.
    _addInterceptors(_helpers.jsBoolClass, impactBuilder);
    _addInterceptors(_helpers.jsNullClass, impactBuilder);
    if (_options.enableTypeAssertions) {
      _registerBackendImpact(impactBuilder, _impacts.enableTypeAssertions);
    }

    if (JavaScriptBackend.TRACE_CALLS) {
      _registerBackendImpact(impactBuilder, _impacts.traceHelper);
    }
    _registerBackendImpact(impactBuilder, _impacts.assertUnreachable);
    _registerCheckedModeHelpers(impactBuilder);
    return impactBuilder;
  }

  void _registerCheckedModeHelpers(WorldImpactBuilder impactBuilder) {
    // We register all the _helpers in the resolution queue.
    // TODO(13155): Find a way to register fewer _helpers.
    List<FunctionEntity> staticUses = <FunctionEntity>[];
    for (CheckedModeHelper helper in CheckedModeHelpers.helpers) {
      staticUses.add(helper.getStaticUse(_helpers).element);
    }
    _registerBackendImpact(
        impactBuilder, new BackendImpact(globalUses: staticUses));
  }

  @override
  void logSummary(void log(String message)) {
    _nativeEnqueuer.logSummary(log);
  }
}
