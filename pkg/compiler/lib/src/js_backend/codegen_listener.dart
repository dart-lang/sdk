// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js_backend.backend.codegen_listener;

import '../common.dart';
import '../common/backend_api.dart';
import '../common/names.dart' show Identifiers;
import '../common_elements.dart' show CommonElements, ElementEnvironment;
import '../constants/values.dart';
import '../dump_info.dart' show DumpInfoTask;
import '../elements/elements.dart';
import '../elements/entities.dart';
import '../elements/resolution_types.dart';
import '../enqueue.dart' show Enqueuer, EnqueuerListener;
import '../native/enqueue.dart';
import '../universe/call_structure.dart' show CallStructure;
import '../universe/use.dart' show StaticUse, TypeUse;
import '../universe/world_impact.dart'
    show WorldImpact, WorldImpactBuilder, WorldImpactBuilderImpl;
import 'backend.dart';
import 'backend_helpers.dart';
import 'backend_impact.dart';
import 'backend_usage.dart';
import 'constant_handler_javascript.dart';
import 'custom_elements_analysis.dart';
import 'lookup_map_analysis.dart' show LookupMapAnalysis;
import 'mirrors_analysis.dart';
import 'mirrors_data.dart';
import 'type_variable_handler.dart';

class CodegenEnqueuerListener extends EnqueuerListener {
  final ElementEnvironment _elementEnvironment;
  final CommonElements _commonElements;
  final BackendHelpers _helpers;
  final BackendImpacts _impacts;
  final BackendClasses _backendClasses;

  final BackendUsage _backendUsage;
  final RuntimeTypesNeed _rtiNeed;

  final CustomElementsCodegenAnalysis _customElementsAnalysis;
  final TypeVariableCodegenAnalysis _typeVariableCodegenAnalysis;
  final LookupMapAnalysis _lookupMapAnalysis;
  final MirrorsCodegenAnalysis _mirrorsAnalysis;

  final NativeCodegenEnqueuer _nativeEnqueuer;

  bool _isNoSuchMethodUsed = false;

  CodegenEnqueuerListener(
      this._elementEnvironment,
      this._commonElements,
      this._helpers,
      this._impacts,
      this._backendClasses,
      this._backendUsage,
      this._rtiNeed,
      this._customElementsAnalysis,
      this._typeVariableCodegenAnalysis,
      this._lookupMapAnalysis,
      this._mirrorsAnalysis,
      this._nativeEnqueuer);

  @override
  WorldImpact registerClosurizedMember(MemberElement element) {
    WorldImpactBuilderImpl impactBuilder = new WorldImpactBuilderImpl();
    impactBuilder
        .addImpact(_impacts.memberClosure.createImpact(_elementEnvironment));
    if (element.type.containsTypeVariables &&
        _rtiNeed.methodNeedsRti(element)) {
      impactBuilder.addImpact(_registerComputeSignature());
    }
    return impactBuilder;
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
      {bool isGlobal: false, bool nativeUsage: false}) {
    if (nativeUsage) {
      _nativeEnqueuer.onInstantiatedType(type);
    }
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
    enqueuer.applyImpact(_nativeEnqueuer.processNativeClasses(libraries));
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
    enqueuer.applyImpact(_customElementsAnalysis.flush());
    enqueuer.applyImpact(_lookupMapAnalysis.flush());
    enqueuer.applyImpact(_typeVariableCodegenAnalysis.flush());

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
  void onQueueClosed() {
    _lookupMapAnalysis.onQueueClosed();
  }

  /// Adds the impact of [constant] to [impactBuilder].
  void _computeImpactForCompileTimeConstant(
      ConstantValue constant, WorldImpactBuilder impactBuilder) {
    _computeImpactForCompileTimeConstantInternal(constant, impactBuilder);

    if (_lookupMapAnalysis.isLookupMap(constant)) {
      // Note: internally, this registration will temporarily remove the
      // constant dependencies and add them later on-demand.
      _lookupMapAnalysis.registerLookupMapReference(constant);
    }

    for (ConstantValue dependency in constant.getDependencies()) {
      _computeImpactForCompileTimeConstant(dependency, impactBuilder);
    }
  }

  void _computeImpactForCompileTimeConstantInternal(
      ConstantValue constant, WorldImpactBuilder impactBuilder) {
    ResolutionDartType type = constant.getType(_commonElements);
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
      impactBuilder
          .registerTypeUse(new TypeUse.instantiation(_backendClasses.typeType));
      // If the type is a web component, we need to ensure the constructors are
      // available to 'upgrade' the native object.
      TypeConstantValue type = constant;
      if (type.representedType.isInterfaceType) {
        ResolutionInterfaceType representedType = type.representedType;
        _customElementsAnalysis.registerTypeConstant(representedType.element);
        _lookupMapAnalysis.registerTypeConstant(representedType.element);
      }
    }
    _lookupMapAnalysis.registerConstantKey(constant);
  }

  void _computeImpactForInstantiatedConstantType(
      ResolutionDartType type, WorldImpactBuilder impactBuilder) {
    if (type is ResolutionInterfaceType) {
      impactBuilder.registerTypeUse(new TypeUse.instantiation(type));
      if (_rtiNeed.classNeedsRtiField(type.element)) {
        impactBuilder.registerStaticUse(new StaticUse.staticInvoke(
            // TODO(johnniwinther): Find the right [CallStructure].
            _helpers.setRuntimeTypeInfo,
            null));
      }
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
    _customElementsAnalysis.registerStaticUse(member);

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

  WorldImpact _processClass(ClassElement cls) {
    WorldImpactBuilderImpl impactBuilder = new WorldImpactBuilderImpl();
    if (!cls.typeVariables.isEmpty) {
      _typeVariableCodegenAnalysis.registerClassWithTypeVariables(cls);
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

    _customElementsAnalysis.registerInstantiatedClass(cls);
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

  @override
  void logSummary(void log(String message)) {
    _lookupMapAnalysis.logSummary(log);
    _nativeEnqueuer.logSummary(log);
  }
}
