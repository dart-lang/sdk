// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library;

import 'dart:collection';

import '../common/elements.dart' show CommonElements, ElementEnvironment;
import '../common/names.dart' show Identifiers;
import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import '../enqueue.dart' show Enqueuer, EnqueuerListener;
import '../js_model/records.dart';
import '../native/enqueue.dart';
import '../options.dart';
import '../universe/call_structure.dart' show CallStructure;
import '../universe/codegen_world_builder.dart';
import '../universe/use.dart' show ConditionalUse, StaticUse, TypeUse;
import '../universe/world_impact.dart'
    show WorldImpact, WorldImpactBuilder, WorldImpactBuilderImpl;
import 'backend_impact.dart';
import 'backend_usage.dart';
import 'custom_elements_analysis.dart';
import 'native_data.dart' show NativeData;
import 'records_codegen.dart';
import 'runtime_types_resolution.dart';

class CodegenEnqueuerListener extends EnqueuerListener {
  final CompilerOptions _options;
  final ElementEnvironment _elementEnvironment;
  final CommonElements _commonElements;
  final BackendImpacts _impacts;

  final BackendUsage _backendUsage;
  final RuntimeTypesNeed _rtiNeed;
  final RecordData _recordData;

  final CustomElementsCodegenAnalysis _customElementsAnalysis;
  final RecordsCodegen _recordsCodegen;

  final NativeData _nativeData;
  final NativeCodegenEnqueuer _nativeEnqueuer;
  final CodegenWorldBuilder _worldBuilder;

  bool _isNoSuchMethodUsed = false;
  bool _isRtiUsed = false;

  CodegenEnqueuerListener(
    this._options,
    this._elementEnvironment,
    this._commonElements,
    this._impacts,
    this._backendUsage,
    this._rtiNeed,
    this._recordData,
    this._customElementsAnalysis,
    this._recordsCodegen,
    this._nativeData,
    this._nativeEnqueuer,
    this._worldBuilder,
  );

  @override
  WorldImpact registerClosurizedMember(FunctionEntity element) {
    WorldImpactBuilderImpl impactBuilder = WorldImpactBuilderImpl();
    impactBuilder.addImpact(
      _impacts.memberClosure.createImpact(_elementEnvironment),
    );
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
  void registerInstantiatedType(
    InterfaceType type, {
    bool isGlobal = false,
    bool nativeUsage = false,
  }) {
    if (nativeUsage) {
      _nativeEnqueuer.onInstantiatedType(type);
    }
  }

  /// Computes the [WorldImpact] of calling [mainMethod] as the entry point.
  WorldImpact _computeMainImpact(FunctionEntity mainMethod) {
    WorldImpactBuilderImpl mainImpact = WorldImpactBuilderImpl();
    CallStructure callStructure = mainMethod.parameterStructure.callStructure;
    if (callStructure.argumentCount > 0) {
      _impacts.mainWithArguments.registerImpact(
        mainImpact,
        _elementEnvironment,
      );
      mainImpact.registerStaticUse(
        StaticUse.staticInvoke(mainMethod, callStructure),
      );
    }
    if (mainMethod.isGetter) {
      mainImpact.registerStaticUse(StaticUse.staticGet(mainMethod));
    } else {
      mainImpact.registerStaticUse(
        StaticUse.staticInvoke(mainMethod, CallStructure.noArgs),
      );
    }
    return mainImpact;
  }

  @override
  void onQueueOpen(
    Enqueuer enqueuer,
    FunctionEntity? mainMethod,
    Iterable<Uri> libraries,
  ) {
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

    enqueuer.applyImpact(_recordsCodegen.flush(recentClasses));

    if (_backendUsage.isNoSuchMethodUsed && !_isNoSuchMethodUsed) {
      enqueuer.applyImpact(
        _impacts.noSuchMethodSupport.createImpact(_elementEnvironment),
      );
      _isNoSuchMethodUsed = true;
    }

    // TODO(fishythefish): Avoid registering unnecessary impacts.
    if (!_isRtiUsed) {
      WorldImpactBuilderImpl rtiImpact = WorldImpactBuilderImpl();
      rtiImpact.registerStaticUse(
        StaticUse.staticInvoke(
          _commonElements.rtiAddRulesMethod,
          CallStructure.twoArgs,
        ),
      );
      rtiImpact.registerStaticUse(
        StaticUse.staticInvoke(
          _commonElements.rtiAddErasedTypesMethod,
          CallStructure.twoArgs,
        ),
      );
      if (_options.enableVariance) {
        rtiImpact.registerStaticUse(
          StaticUse.staticInvoke(
            _commonElements.rtiAddTypeParameterVariancesMethod,
            CallStructure.twoArgs,
          ),
        );
      }
      enqueuer.applyImpact(rtiImpact);
      _isRtiUsed = true;
    }

    if (_nativeData.isAllowInteropUsed) {
      enqueuer.applyImpact(
        _impacts.allowInterop.createImpact(_elementEnvironment),
      );
    }

    final newParameterStubs = _worldBuilder.generateParameterStubs();
    final impactBuilder = WorldImpactBuilderImpl();
    for (final stub in newParameterStubs) {
      impactBuilder.registerStaticUse(StaticUse.implicitInvoke(stub));
    }
    enqueuer.applyImpact(impactBuilder);

    if (!enqueuer.queueIsEmpty) return false;

    return true;
  }

  @override
  void onQueueClosed() {}

  /// Adds the impact of [constant] to [impactBuilder].
  void _computeImpactForCompileTimeConstant(
    ConstantValue constant,
    WorldImpactBuilder impactBuilder,
    Set<ConstantValue> visited,
  ) {
    if (visited.add(constant)) {
      _computeImpactForCompileTimeConstantInternal(constant, impactBuilder);

      for (ConstantValue dependency in constant.getDependencies()) {
        _computeImpactForCompileTimeConstant(
          dependency,
          impactBuilder,
          visited,
        );
      }
    }
  }

  void _computeImpactForCompileTimeConstantInternal(
    ConstantValue constant,
    WorldImpactBuilder impactBuilder,
  ) {
    DartType type = constant.getType(_commonElements);
    _computeImpactForInstantiatedConstantType(type, impactBuilder);

    if (constant is FunctionConstantValue) {
      impactBuilder.registerStaticUse(
        StaticUse.staticTearOff(constant.element),
      );
    } else if (constant is InterceptorConstantValue) {
      // An interceptor constant references the class's prototype chain.
      ClassEntity cls = constant.cls;
      _computeImpactForInstantiatedConstantType(
        _elementEnvironment.getThisType(cls),
        impactBuilder,
      );
    } else if (constant is TypeConstantValue) {
      impactBuilder.registerTypeUse(
        TypeUse.instantiation(_commonElements.typeType),
      );
      // If the type is a web component, we need to ensure the constructors are
      // available to 'upgrade' the native object.
      final representedType = constant.representedType;
      if (representedType is InterfaceType) {
        _customElementsAnalysis.registerTypeConstant(representedType.element);
      }
    } else if (constant is InstantiationConstantValue) {
      // TODO(johnniwinther): Register these using `BackendImpact`.
      impactBuilder.registerTypeUse(
        TypeUse.instantiation(
          _elementEnvironment.getThisType(
            _commonElements.getInstantiationClass(
              constant.typeArguments.length,
            ),
          ),
        ),
      );

      impactBuilder.registerStaticUse(
        StaticUse.staticInvoke(
          _commonElements.instantiatedGenericFunctionType,
          CallStructure.twoArgs,
        ),
      );
      impactBuilder.registerStaticUse(
        StaticUse.staticInvoke(
          _commonElements.closureFunctionType,
          CallStructure.oneArg,
        ),
      );
    }
  }

  void _computeImpactForInstantiatedConstantType(
    DartType type,
    WorldImpactBuilder impactBuilder,
  ) {
    if (type is InterfaceType) {
      impactBuilder.registerTypeUse(TypeUse.instantiation(type));
      if (_rtiNeed.classNeedsTypeArguments(type.element)) {
        FunctionEntity helper = _commonElements.setArrayType;
        impactBuilder.registerStaticUse(
          StaticUse.staticInvoke(
            helper,
            helper.parameterStructure.callStructure,
          ),
        );
      }
      if (type.element == _commonElements.typeLiteralClass) {
        // If we use a type literal in a constant, the compile time constant
        // emitter will generate a call to a helper so we register the impact
        // that contains that call.
        _impacts.typeLiteral.registerImpact(impactBuilder, _elementEnvironment);
      }
    }
    if (type is RecordType) {
      final representation = _recordData.representationForStaticType(type);
      impactBuilder.registerTypeUse(
        TypeUse.instantiation(
          _commonElements.dartTypes.interfaceType(representation.cls, const []),
        ),
      );
    }
  }

  @override
  WorldImpact registerUsedConstant(ConstantValue constant) {
    WorldImpactBuilderImpl impactBuilder = WorldImpactBuilderImpl();
    _computeImpactForCompileTimeConstant(
      constant,
      impactBuilder,
      LinkedHashSet.identity(),
    );
    return impactBuilder;
  }

  @override
  WorldImpact registerUsedElement(MemberEntity member) {
    WorldImpactBuilderImpl worldImpact = WorldImpactBuilderImpl();
    _customElementsAnalysis.registerStaticUse(member);

    if (member.isFunction && member.isInstanceMember) {
      ClassEntity cls = member.enclosingClass!;
      if (member.name == Identifiers.call &&
          _elementEnvironment.isGenericClass(cls) &&
          _rtiNeed.methodNeedsSignature(member as FunctionEntity)) {
        worldImpact.addImpact(_registerComputeSignature());
      }
    }

    return worldImpact;
  }

  WorldImpact _processClass(ClassEntity cls) {
    WorldImpactBuilderImpl impactBuilder = WorldImpactBuilderImpl();
    if (cls == _commonElements.closureClass) {
      _impacts.closureClass.registerImpact(impactBuilder, _elementEnvironment);
    }

    void registerInstantiation(ClassEntity cls) {
      impactBuilder.registerTypeUse(
        TypeUse.instantiation(_elementEnvironment.getRawType(cls)),
      );
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
    } else if (cls == _commonElements.jsNumNotIntClass) {
      registerInstantiation(_commonElements.jsNumNotIntClass);
      registerInstantiation(_commonElements.jsNumberClass);
    } else if (cls == _commonElements.boolClass ||
        cls == _commonElements.jsBoolClass) {
      registerInstantiation(_commonElements.jsBoolClass);
    } else if (cls == _commonElements.nullClass ||
        cls == _commonElements.jsNullClass) {
      registerInstantiation(_commonElements.jsNullClass);
    } else if (cls == _commonElements.doubleClass ||
        cls == _commonElements.numClass ||
        cls == _commonElements.jsNumberClass) {
      registerInstantiation(_commonElements.jsIntClass);
      registerInstantiation(_commonElements.jsPositiveIntClass);
      registerInstantiation(_commonElements.jsUInt32Class);
      registerInstantiation(_commonElements.jsUInt31Class);
      registerInstantiation(_commonElements.jsNumNotIntClass);
      registerInstantiation(_commonElements.jsNumberClass);
    } else if (cls == _commonElements.jsJavaScriptObjectClass) {
      registerInstantiation(_commonElements.jsJavaScriptObjectClass);
    } else if (cls == _commonElements.jsLegacyJavaScriptObjectClass) {
      registerInstantiation(_commonElements.jsLegacyJavaScriptObjectClass);
    } else if (cls == _commonElements.jsPlainJavaScriptObjectClass) {
      registerInstantiation(_commonElements.jsPlainJavaScriptObjectClass);
    } else if (cls == _commonElements.jsUnknownJavaScriptObjectClass) {
      registerInstantiation(_commonElements.jsUnknownJavaScriptObjectClass);
    } else if (cls == _commonElements.jsJavaScriptBigIntClass) {
      registerInstantiation(_commonElements.jsJavaScriptBigIntClass);
    } else if (cls == _commonElements.jsJavaScriptFunctionClass) {
      registerInstantiation(_commonElements.jsJavaScriptFunctionClass);
    } else if (cls == _commonElements.jsJavaScriptSymbolClass) {
      registerInstantiation(_commonElements.jsJavaScriptSymbolClass);
    } else if (cls == _commonElements.jsIndexingBehaviorInterface) {
      _impacts.jsIndexingBehavior.registerImpact(
        impactBuilder,
        _elementEnvironment,
      );
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
  void logSummary(void Function(String message) log) {
    _nativeEnqueuer.logSummary(log);
  }

  @override
  WorldImpact registerConditionalUse(ConditionalUse use) {
    throw UnsupportedError(
      'Codegen enqueuer does not support conditional impacts.',
    );
  }
}
