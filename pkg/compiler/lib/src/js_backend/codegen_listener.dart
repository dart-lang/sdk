// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js_backend.backend.codegen_listener;

import '../common/names.dart' show Identifiers;
import '../common_elements.dart' show CommonElements, ElementEnvironment;
import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import '../enqueue.dart' show Enqueuer, EnqueuerListener;
import '../native/enqueue.dart';
import '../universe/call_structure.dart' show CallStructure;
import '../universe/use.dart' show StaticUse, TypeUse;
import '../universe/world_impact.dart'
    show WorldImpact, WorldImpactBuilder, WorldImpactBuilderImpl;
import 'backend_impact.dart';
import 'backend_usage.dart';
import 'custom_elements_analysis.dart';
import 'mirrors_analysis.dart';
import 'runtime_types.dart';
import 'type_variable_handler.dart';

class CodegenEnqueuerListener extends EnqueuerListener {
  final ElementEnvironment _elementEnvironment;
  final CommonElements _commonElements;
  final BackendImpacts _impacts;

  final BackendUsage _backendUsage;
  final RuntimeTypesNeed _rtiNeed;

  final CustomElementsCodegenAnalysis _customElementsAnalysis;
  final TypeVariableCodegenAnalysis _typeVariableCodegenAnalysis;
  final MirrorsCodegenAnalysis _mirrorsAnalysis;

  final NativeCodegenEnqueuer _nativeEnqueuer;

  bool _isNoSuchMethodUsed = false;

  CodegenEnqueuerListener(
      this._elementEnvironment,
      this._commonElements,
      this._impacts,
      this._backendUsage,
      this._rtiNeed,
      this._customElementsAnalysis,
      this._typeVariableCodegenAnalysis,
      this._mirrorsAnalysis,
      this._nativeEnqueuer);

  @override
  WorldImpact registerClosurizedMember(FunctionEntity element) {
    WorldImpactBuilderImpl impactBuilder = new WorldImpactBuilderImpl();
    impactBuilder
        .addImpact(_impacts.memberClosure.createImpact(_elementEnvironment));
    FunctionType type = _elementEnvironment.getFunctionType(element);
    if (type.containsTypeVariables && _rtiNeed.methodNeedsRti(element)) {
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
  void registerInstantiatedType(InterfaceType type,
      {bool isGlobal: false, bool nativeUsage: false}) {
    if (nativeUsage) {
      _nativeEnqueuer.onInstantiatedType(type);
    }
  }

  /// Called to enable support for isolates. Any backend specific [WorldImpact]
  /// of this is returned.
  WorldImpact _enableIsolateSupport(FunctionEntity mainMethod) {
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
  WorldImpact _computeMainImpact(FunctionEntity mainMethod) {
    WorldImpactBuilderImpl mainImpact = new WorldImpactBuilderImpl();
    CallStructure callStructure = mainMethod.parameterStructure.callStructure;
    if (callStructure.argumentCount > 0) {
      _impacts.mainWithArguments
          .registerImpact(mainImpact, _elementEnvironment);
      mainImpact.registerStaticUse(
          new StaticUse.staticInvoke(mainMethod, callStructure));
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
      ClassEntity cls = interceptor.cls;
      _computeImpactForInstantiatedConstantType(
          _elementEnvironment.getThisType(cls), impactBuilder);
    } else if (constant.isType) {
      impactBuilder
          .registerTypeUse(new TypeUse.instantiation(_commonElements.typeType));
      // If the type is a web component, we need to ensure the constructors are
      // available to 'upgrade' the native object.
      TypeConstantValue type = constant;
      if (type.representedType.isInterfaceType) {
        InterfaceType representedType = type.representedType;
        _customElementsAnalysis.registerTypeConstant(representedType.element);
      }
    }
  }

  void _computeImpactForInstantiatedConstantType(
      DartType type, WorldImpactBuilder impactBuilder) {
    if (type is InterfaceType) {
      impactBuilder.registerTypeUse(new TypeUse.instantiation(type));
      if (_rtiNeed.classNeedsRtiField(type.element)) {
        impactBuilder.registerStaticUse(new StaticUse.staticInvoke(
            // TODO(johnniwinther): Find the right [CallStructure].
            _commonElements.setRuntimeTypeInfo,
            null));
      }
      if (type.element == _commonElements.typeLiteralClass) {
        // If we use a type literal in a constant, the compile time
        // constant emitter will generate a call to the createRuntimeType
        // helper so we register a use of that.
        impactBuilder.registerStaticUse(new StaticUse.staticInvoke(
            // TODO(johnniwinther): Find the right [CallStructure].
            _commonElements.createRuntimeType,
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
  WorldImpact registerUsedElement(MemberEntity member) {
    WorldImpactBuilderImpl worldImpact = new WorldImpactBuilderImpl();
    _customElementsAnalysis.registerStaticUse(member);

    if (member.isFunction && member.isInstanceMember) {
      ClassEntity cls = member.enclosingClass;
      if (member.name == Identifiers.call &&
          _elementEnvironment.isGenericClass(cls) &&
          _rtiNeed.methodNeedsRti(member)) {
        worldImpact.addImpact(_registerComputeSignature());
      }
    }

    return worldImpact;
  }

  WorldImpact _processClass(ClassEntity cls) {
    WorldImpactBuilderImpl impactBuilder = new WorldImpactBuilderImpl();
    if (_elementEnvironment.isGenericClass(cls)) {
      _typeVariableCodegenAnalysis.registerClassWithTypeVariables(cls);
    }
    if (cls == _commonElements.closureClass) {
      _impacts.closureClass.registerImpact(impactBuilder, _elementEnvironment);
    }

    void registerInstantiation(ClassEntity cls) {
      impactBuilder.registerTypeUse(
          new TypeUse.instantiation(_elementEnvironment.getRawType(cls)));
    }

    if (cls == _commonElements.stringClass ||
        cls == _commonElements.jsStringClass) {
      registerInstantiation(_commonElements.jsStringClass);
    } else if (cls == _commonElements.listClass ||
        cls == _commonElements.jsArrayClass ||
        cls == _commonElements.jsFixedArrayClass ||
        cls == _commonElements.jsExtendableArrayClass ||
        cls == _commonElements.jsUnmodifiableArrayClass) {
      registerInstantiation(_commonElements.jsArrayClass);
      registerInstantiation(_commonElements.jsMutableArrayClass);
      registerInstantiation(_commonElements.jsFixedArrayClass);
      registerInstantiation(_commonElements.jsExtendableArrayClass);
      registerInstantiation(_commonElements.jsUnmodifiableArrayClass);
    } else if (cls == _commonElements.intClass ||
        cls == _commonElements.jsIntClass) {
      registerInstantiation(_commonElements.jsIntClass);
      registerInstantiation(_commonElements.jsPositiveIntClass);
      registerInstantiation(_commonElements.jsUInt32Class);
      registerInstantiation(_commonElements.jsUInt31Class);
      registerInstantiation(_commonElements.jsNumberClass);
    } else if (cls == _commonElements.doubleClass ||
        cls == _commonElements.jsDoubleClass) {
      registerInstantiation(_commonElements.jsDoubleClass);
      registerInstantiation(_commonElements.jsNumberClass);
    } else if (cls == _commonElements.boolClass ||
        cls == _commonElements.jsBoolClass) {
      registerInstantiation(_commonElements.jsBoolClass);
    } else if (cls == _commonElements.nullClass ||
        cls == _commonElements.jsNullClass) {
      registerInstantiation(_commonElements.jsNullClass);
    } else if (cls == _commonElements.numClass ||
        cls == _commonElements.jsNumberClass) {
      registerInstantiation(_commonElements.jsIntClass);
      registerInstantiation(_commonElements.jsPositiveIntClass);
      registerInstantiation(_commonElements.jsUInt32Class);
      registerInstantiation(_commonElements.jsUInt31Class);
      registerInstantiation(_commonElements.jsDoubleClass);
      registerInstantiation(_commonElements.jsNumberClass);
    } else if (cls == _commonElements.jsJavaScriptObjectClass) {
      registerInstantiation(_commonElements.jsJavaScriptObjectClass);
    } else if (cls == _commonElements.jsPlainJavaScriptObjectClass) {
      registerInstantiation(_commonElements.jsPlainJavaScriptObjectClass);
    } else if (cls == _commonElements.jsUnknownJavaScriptObjectClass) {
      registerInstantiation(_commonElements.jsUnknownJavaScriptObjectClass);
    } else if (cls == _commonElements.jsJavaScriptFunctionClass) {
      registerInstantiation(_commonElements.jsJavaScriptFunctionClass);
    } else if (cls == _commonElements.jsIndexingBehaviorInterface) {
      _impacts.jsIndexingBehavior
          .registerImpact(impactBuilder, _elementEnvironment);
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

  @override
  void logSummary(void log(String message)) {
    _nativeEnqueuer.logSummary(log);
  }
}
