// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js_backend.backend.codegen_listener;

import 'dart:collection';

import '../common/names.dart' show Identifiers;
import '../common_elements.dart' show CommonElements, ElementEnvironment;
import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import '../enqueue.dart' show Enqueuer, EnqueuerListener;
import '../native/enqueue.dart';
import '../options.dart';
import '../universe/call_structure.dart' show CallStructure;
import '../universe/use.dart' show StaticUse, TypeUse;
import '../universe/world_impact.dart'
    show WorldImpact, WorldImpactBuilder, WorldImpactBuilderImpl;
import 'backend_impact.dart';
import 'backend_usage.dart';
import 'custom_elements_analysis.dart';
import 'runtime_types_resolution.dart';

class CodegenEnqueuerListener extends EnqueuerListener {
  final CompilerOptions _options;
  final ElementEnvironment _elementEnvironment;
  final CommonElements _commonElements;
  final BackendImpacts _impacts;

  final BackendUsage _backendUsage;
  final RuntimeTypesNeed _rtiNeed;

  final CustomElementsCodegenAnalysis _customElementsAnalysis;

  final NativeCodegenEnqueuer _nativeEnqueuer;

  bool _isNoSuchMethodUsed = false;
  bool _isNewRtiUsed = false;

  CodegenEnqueuerListener(
      this._options,
      this._elementEnvironment,
      this._commonElements,
      this._impacts,
      this._backendUsage,
      this._rtiNeed,
      this._customElementsAnalysis,
      this._nativeEnqueuer);

  @override
  WorldImpact registerClosurizedMember(FunctionEntity element) {
    WorldImpactBuilderImpl impactBuilder = new WorldImpactBuilderImpl();
    impactBuilder
        .addImpact(_impacts.memberClosure.createImpact(_elementEnvironment));
    FunctionType type = _elementEnvironment.getFunctionType(element);
    if (type.containsTypeVariables && _rtiNeed.methodNeedsSignature(element)) {
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

  /// Computes the [WorldImpact] of calling [mainMethod] as the entry point.
  WorldImpact _computeMainImpact(FunctionEntity mainMethod) {
    WorldImpactBuilderImpl mainImpact = new WorldImpactBuilderImpl();
    CallStructure callStructure = mainMethod.parameterStructure.callStructure;
    if (callStructure.argumentCount > 0) {
      _impacts.mainWithArguments
          .registerImpact(mainImpact, _elementEnvironment);
      mainImpact.registerStaticUse(
          new StaticUse.staticInvoke(mainMethod, callStructure));
    }
    if (mainMethod.isGetter) {
      mainImpact.registerStaticUse(new StaticUse.staticGet(mainMethod));
    } else {
      mainImpact.registerStaticUse(
          new StaticUse.staticInvoke(mainMethod, CallStructure.NO_ARGS));
    }
    return mainImpact;
  }

  @override
  void onQueueOpen(
      Enqueuer enqueuer, FunctionEntity mainMethod, Iterable<Uri> libraries) {
    enqueuer.applyImpact(_nativeEnqueuer.processNativeClasses(libraries));
    if (mainMethod != null) {
      enqueuer.applyImpact(_computeMainImpact(mainMethod));
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

    if (_backendUsage.isNoSuchMethodUsed && !_isNoSuchMethodUsed) {
      enqueuer.applyImpact(
          _impacts.noSuchMethodSupport.createImpact(_elementEnvironment));
      _isNoSuchMethodUsed = true;
    }

    // TODO(fishythefish): Avoid registering unnecessary impacts.
    if (!_isNewRtiUsed) {
      WorldImpactBuilderImpl newRtiImpact = new WorldImpactBuilderImpl();
      newRtiImpact.registerStaticUse(StaticUse.staticInvoke(
          _commonElements.rtiAddRulesMethod, CallStructure.TWO_ARGS));
      newRtiImpact.registerStaticUse(StaticUse.staticInvoke(
          _commonElements.rtiAddErasedTypesMethod, CallStructure.TWO_ARGS));
      if (_options.enableVariance) {
        newRtiImpact.registerStaticUse(StaticUse.staticInvoke(
            _commonElements.rtiAddTypeParameterVariancesMethod,
            CallStructure.TWO_ARGS));
      }
      enqueuer.applyImpact(newRtiImpact);
      _isNewRtiUsed = true;
    }

    if (!enqueuer.queueIsEmpty) return false;

    return true;
  }

  @override
  void onQueueClosed() {}

  /// Adds the impact of [constant] to [impactBuilder].
  void _computeImpactForCompileTimeConstant(ConstantValue constant,
      WorldImpactBuilder impactBuilder, Set<ConstantValue> visited) {
    if (visited.add(constant)) {
      _computeImpactForCompileTimeConstantInternal(constant, impactBuilder);

      for (ConstantValue dependency in constant.getDependencies()) {
        _computeImpactForCompileTimeConstant(
            dependency, impactBuilder, visited);
      }
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
      if (type.representedType is InterfaceType) {
        InterfaceType representedType = type.representedType;
        _customElementsAnalysis.registerTypeConstant(representedType.element);
      }
    } else if (constant is InstantiationConstantValue) {
      // TODO(johnniwinther): Register these using `BackendImpact`.
      impactBuilder.registerTypeUse(new TypeUse.instantiation(
          _elementEnvironment.getThisType(_commonElements
              .getInstantiationClass(constant.typeArguments.length))));

      impactBuilder.registerStaticUse(StaticUse.staticInvoke(
          _commonElements.instantiatedGenericFunctionTypeNewRti,
          CallStructure.TWO_ARGS));
      impactBuilder.registerStaticUse(StaticUse.staticInvoke(
          _commonElements.closureFunctionType, CallStructure.ONE_ARG));
    }
  }

  void _computeImpactForInstantiatedConstantType(
      DartType type, WorldImpactBuilder impactBuilder) {
    if (type is InterfaceType) {
      impactBuilder.registerTypeUse(new TypeUse.instantiation(type));
      if (_rtiNeed.classNeedsTypeArguments(type.element)) {
        FunctionEntity helper = _commonElements.setRuntimeTypeInfo;
        impactBuilder.registerStaticUse(new StaticUse.staticInvoke(
            helper, helper.parameterStructure.callStructure));
      }
      if (type.element == _commonElements.typeLiteralClass) {
        // If we use a type literal in a constant, the compile time constant
        // emitter will generate a call to a helper so we register the impact
        // that contains that call.
        _impacts.typeLiteral.registerImpact(impactBuilder, _elementEnvironment);
      }
    }
  }

  @override
  WorldImpact registerUsedConstant(ConstantValue constant) {
    WorldImpactBuilderImpl impactBuilder = new WorldImpactBuilderImpl();
    _computeImpactForCompileTimeConstant(
        constant, impactBuilder, new LinkedHashSet.identity());
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
          _rtiNeed.methodNeedsSignature(member)) {
        worldImpact.addImpact(_registerComputeSignature());
      }
    }

    return worldImpact;
  }

  WorldImpact _processClass(ClassEntity cls) {
    WorldImpactBuilderImpl impactBuilder = new WorldImpactBuilderImpl();
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
