// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js_backend.backend.impact_transformer;

import '../universe/class_hierarchy.dart' show ClassHierarchyBuilder;

import '../common.dart';
import '../common_elements.dart';
import '../common/backend_api.dart' show ImpactTransformer;
import '../common/codegen.dart' show CodegenImpact;
import '../common/resolution.dart' show ResolutionImpact;
import '../common_elements.dart' show ElementEnvironment;
import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import '../js_emitter/native_emitter.dart';
import '../native/enqueue.dart';
import '../native/behavior.dart';
import '../universe/call_structure.dart';
import '../universe/feature.dart';
import '../universe/selector.dart';
import '../universe/use.dart';
import '../universe/world_impact.dart' show TransformedWorldImpact, WorldImpact;
import '../util/util.dart';
import '../world.dart';
import 'annotations.dart';
import 'backend_impact.dart';
import 'backend_usage.dart';
import 'custom_elements_analysis.dart';
import 'interceptor_data.dart';
import 'namer.dart';
import 'native_data.dart';
import 'runtime_types.dart';
import 'runtime_types_resolution.dart';

class JavaScriptImpactTransformer extends ImpactTransformer {
  final ElementEnvironment _elementEnvironment;
  final CommonElements _commonElements;
  final BackendImpacts _impacts;
  final NativeBasicData _nativeBasicData;
  final NativeResolutionEnqueuer _nativeResolutionEnqueuer;
  final BackendUsageBuilder _backendUsageBuilder;
  final CustomElementsResolutionAnalysis _customElementsResolutionAnalysis;
  final RuntimeTypesNeedBuilder _rtiNeedBuilder;
  final ClassHierarchyBuilder _classHierarchyBuilder;
  final AnnotationsData _annotationsData;

  JavaScriptImpactTransformer(
      this._elementEnvironment,
      this._commonElements,
      this._impacts,
      this._nativeBasicData,
      this._nativeResolutionEnqueuer,
      this._backendUsageBuilder,
      this._customElementsResolutionAnalysis,
      this._rtiNeedBuilder,
      this._classHierarchyBuilder,
      this._annotationsData);

  DartTypes get _dartTypes => _commonElements.dartTypes;

  @override
  WorldImpact transformResolutionImpact(ResolutionImpact worldImpact) {
    TransformedWorldImpact transformed =
        new TransformedWorldImpact(worldImpact);

    void registerImpact(BackendImpact impact) {
      impact.registerImpact(transformed, _elementEnvironment);
      _backendUsageBuilder.processBackendImpact(impact);
    }

    for (Feature feature in worldImpact.features) {
      switch (feature) {
        case Feature.ASSERT:
          registerImpact(_impacts.assertWithoutMessage);
          break;
        case Feature.ASSERT_WITH_MESSAGE:
          registerImpact(_impacts.assertWithMessage);
          break;
        case Feature.ASYNC:
          registerImpact(_impacts.asyncBody);
          break;
        case Feature.ASYNC_FOR_IN:
          registerImpact(_impacts.asyncForIn);
          break;
        case Feature.ASYNC_STAR:
          registerImpact(_impacts.asyncStarBody);
          break;
        case Feature.CATCH_STATEMENT:
          registerImpact(_impacts.catchStatement);
          break;
        case Feature.FALL_THROUGH_ERROR:
          registerImpact(_impacts.fallThroughError);
          break;
        case Feature.FIELD_WITHOUT_INITIALIZER:
        case Feature.LOCAL_WITHOUT_INITIALIZER:
          transformed.registerTypeUse(
              new TypeUse.instantiation(_commonElements.nullType));
          registerImpact(_impacts.nullLiteral);
          break;
        case Feature.LAZY_FIELD:
          registerImpact(_impacts.lazyField);
          break;
        case Feature.STACK_TRACE_IN_CATCH:
          registerImpact(_impacts.stackTraceInCatch);
          break;
        case Feature.STRING_INTERPOLATION:
          registerImpact(_impacts.stringInterpolation);
          break;
        case Feature.STRING_JUXTAPOSITION:
          registerImpact(_impacts.stringJuxtaposition);
          break;
        case Feature.SUPER_NO_SUCH_METHOD:
          registerImpact(_impacts.superNoSuchMethod);
          break;
        case Feature.SYMBOL_CONSTRUCTOR:
          registerImpact(_impacts.symbolConstructor);
          break;
        case Feature.SYNC_FOR_IN:
          registerImpact(_impacts.syncForIn);
          break;
        case Feature.SYNC_STAR:
          registerImpact(_impacts.syncStarBody);
          break;
        case Feature.THROW_EXPRESSION:
          registerImpact(_impacts.throwExpression);
          break;
        case Feature.THROW_NO_SUCH_METHOD:
          registerImpact(_impacts.throwNoSuchMethod);
          break;
        case Feature.THROW_RUNTIME_ERROR:
          registerImpact(_impacts.throwRuntimeError);
          break;
        case Feature.THROW_UNSUPPORTED_ERROR:
          registerImpact(_impacts.throwUnsupportedError);
          break;
        case Feature.TYPE_VARIABLE_BOUNDS_CHECK:
          registerImpact(_impacts.typeVariableBoundCheck);
          break;
        case Feature.LOAD_LIBRARY:
          registerImpact(_impacts.loadLibrary);
          break;
      }
    }

    bool hasAsCast = false;
    bool hasTypeLiteral = false;
    for (TypeUse typeUse in worldImpact.typeUses) {
      DartType type = typeUse.type;
      switch (typeUse.kind) {
        case TypeUseKind.INSTANTIATION:
        case TypeUseKind.CONST_INSTANTIATION:
        case TypeUseKind.NATIVE_INSTANTIATION:
          break;
        case TypeUseKind.IS_CHECK:
        case TypeUseKind.CATCH_TYPE:
          onIsCheck(type, transformed);
          break;
        case TypeUseKind.AS_CAST:
          if (_annotationsData
              .getExplicitCastCheckPolicy(worldImpact.member)
              .isEmitted) {
            onIsCheck(type, transformed);
            hasAsCast = true;
          }
          break;
        case TypeUseKind.IMPLICIT_CAST:
          if (_annotationsData
              .getImplicitDowncastCheckPolicy(worldImpact.member)
              .isEmitted) {
            onIsCheck(type, transformed);
          }
          break;
        case TypeUseKind.PARAMETER_CHECK:
        case TypeUseKind.TYPE_VARIABLE_BOUND_CHECK:
          if (_annotationsData
              .getParameterCheckPolicy(worldImpact.member)
              .isEmitted) {
            onIsCheck(type, transformed);
          }
          break;
        case TypeUseKind.TYPE_LITERAL:
          _customElementsResolutionAnalysis.registerTypeLiteral(type);
          var typeWithoutNullability = type.withoutNullability;
          if (typeWithoutNullability is TypeVariableType) {
            Entity typeDeclaration =
                typeWithoutNullability.element.typeDeclaration;
            if (typeDeclaration is ClassEntity) {
              _rtiNeedBuilder
                  .registerClassUsingTypeVariableLiteral(typeDeclaration);
            } else if (typeDeclaration is FunctionEntity) {
              _rtiNeedBuilder
                  .registerMethodUsingTypeVariableLiteral(typeDeclaration);
            } else if (typeDeclaration is Local) {
              _rtiNeedBuilder.registerLocalFunctionUsingTypeVariableLiteral(
                  typeDeclaration);
            }
            registerImpact(_impacts.typeVariableExpression);
          }
          hasTypeLiteral = true;
          break;
        case TypeUseKind.RTI_VALUE:
        case TypeUseKind.TYPE_ARGUMENT:
        case TypeUseKind.NAMED_TYPE_VARIABLE_NEW_RTI:
        case TypeUseKind.CONSTRUCTOR_REFERENCE:
          failedAt(CURRENT_ELEMENT_SPANNABLE, "Unexpected type use: $typeUse.");
          break;
      }
    }

    if (hasAsCast) {
      registerImpact(_impacts.asCheck);
    }

    if (hasTypeLiteral) {
      transformed
          .registerTypeUse(new TypeUse.instantiation(_commonElements.typeType));
      registerImpact(_impacts.typeLiteral);
    }

    for (MapLiteralUse mapLiteralUse in worldImpact.mapLiterals) {
      // TODO(johnniwinther): Use the [isEmpty] property when factory
      // constructors are registered directly.
      if (mapLiteralUse.isConstant) {
        registerImpact(_impacts.constantMapLiteral);
      } else {
        transformed
            .registerTypeUse(new TypeUse.instantiation(mapLiteralUse.type));
      }
    }

    for (SetLiteralUse setLiteralUse in worldImpact.setLiterals) {
      if (setLiteralUse.isConstant) {
        registerImpact(_impacts.constantSetLiteral);
      } else {
        transformed
            .registerTypeUse(new TypeUse.instantiation(setLiteralUse.type));
      }
    }

    for (ListLiteralUse listLiteralUse in worldImpact.listLiterals) {
      // TODO(johnniwinther): Use the [isConstant] and [isEmpty] property when
      // factory constructors are registered directly.
      transformed
          .registerTypeUse(new TypeUse.instantiation(listLiteralUse.type));
    }

    for (RuntimeTypeUse runtimeTypeUse in worldImpact.runtimeTypeUses) {
      // Enable runtime type support if we discover a getter called
      // runtimeType. We have to enable runtime type before hitting the
      // codegen, so that constructors know whether they need to generate code
      // for runtime type.
      _backendUsageBuilder.registerRuntimeTypeUse(runtimeTypeUse);
    }

    if (worldImpact.constSymbolNames.isNotEmpty) {
      registerImpact(_impacts.constSymbol);
    }

    for (StaticUse staticUse in worldImpact.staticUses) {
      switch (staticUse.kind) {
        case StaticUseKind.CLOSURE:
          registerImpact(_impacts.closure);
          Local closure = staticUse.element;
          FunctionType type = _elementEnvironment.getLocalFunctionType(closure);
          if (type.containsTypeVariables ||
              // TODO(johnniwinther): Can we avoid the need for signatures in
              // Dart 2?
              true) {
            registerImpact(_impacts.computeSignature);
          }
          break;
        default:
      }
    }

    for (ConstantValue constant in worldImpact.constantLiterals) {
      switch (constant.kind) {
        case ConstantValueKind.NULL:
          registerImpact(_impacts.nullLiteral);
          break;
        case ConstantValueKind.BOOL:
          registerImpact(_impacts.boolLiteral);
          break;
        case ConstantValueKind.INT:
          registerImpact(_impacts.intLiteral);
          break;
        case ConstantValueKind.DOUBLE:
          registerImpact(_impacts.doubleLiteral);
          break;
        case ConstantValueKind.STRING:
          registerImpact(_impacts.stringLiteral);
          break;
        default:
          assert(
              false,
              failedAt(NO_LOCATION_SPANNABLE,
                  "Unexpected constant literal: ${constant.kind}."));
      }
    }

    for (NativeBehavior behavior in worldImpact.nativeData) {
      _nativeResolutionEnqueuer.registerNativeBehavior(
          transformed, behavior, worldImpact);
    }

    for (ClassEntity classEntity in worldImpact.seenClasses) {
      _classHierarchyBuilder.registerClass(classEntity);
    }

    if (worldImpact.genericInstantiations.isNotEmpty) {
      for (GenericInstantiation instantiation
          in worldImpact.genericInstantiations) {
        registerImpact(_impacts
            .getGenericInstantiation(instantiation.typeArguments.length));
        _rtiNeedBuilder.registerGenericInstantiation(instantiation);
      }
    }

    return transformed;
  }

  // TODO(johnniwinther): Maybe split this into [onAssertType] and [onTestType].
  void onIsCheck(DartType type, TransformedWorldImpact transformed) {
    void registerImpact(BackendImpact impact) {
      impact.registerImpact(transformed, _elementEnvironment);
      _backendUsageBuilder.processBackendImpact(impact);
    }

    registerImpact(_impacts.typeCheck);

    var typeWithoutNullability = type.withoutNullability;
    if (!_dartTypes.treatAsRawType(typeWithoutNullability) ||
        typeWithoutNullability.containsTypeVariables ||
        typeWithoutNullability is FunctionType) {
      registerImpact(_impacts.genericTypeCheck);
      if (typeWithoutNullability is TypeVariableType) {
        registerImpact(_impacts.typeVariableTypeCheck);
      }
    }
    if (typeWithoutNullability is FunctionType) {
      registerImpact(_impacts.functionTypeCheck);
    }
    if (typeWithoutNullability is InterfaceType &&
        _nativeBasicData.isNativeClass(typeWithoutNullability.element)) {
      registerImpact(_impacts.nativeTypeCheck);
    }
    if (typeWithoutNullability is FutureOrType) {
      registerImpact(_impacts.futureOrTypeCheck);
    }
  }
}

class CodegenImpactTransformer {
  final JClosedWorld _closedWorld;
  final ElementEnvironment _elementEnvironment;
  final BackendImpacts _impacts;
  final NativeData _nativeData;
  final BackendUsage _backendUsage;
  final RuntimeTypesNeed _rtiNeed;
  final NativeCodegenEnqueuer _nativeCodegenEnqueuer;
  final Namer _namer;
  final OneShotInterceptorData _oneShotInterceptorData;
  final RuntimeTypesChecksBuilder _rtiChecksBuilder;
  final NativeEmitter _nativeEmitter;

  CodegenImpactTransformer(
      this._closedWorld,
      this._elementEnvironment,
      this._impacts,
      this._nativeData,
      this._backendUsage,
      this._rtiNeed,
      this._nativeCodegenEnqueuer,
      this._namer,
      this._oneShotInterceptorData,
      this._rtiChecksBuilder,
      this._nativeEmitter);

  DartTypes get _dartTypes => _closedWorld.dartTypes;

  void onIsCheckForCodegen(DartType type, TransformedWorldImpact transformed) {
    if (_dartTypes.isTopType(type)) return;

    _impacts.typeCheck.registerImpact(transformed, _elementEnvironment);

    var typeWithoutNullability = type.withoutNullability;
    if (!_dartTypes.treatAsRawType(typeWithoutNullability) ||
        typeWithoutNullability.containsTypeVariables) {
      _impacts.genericIsCheck.registerImpact(transformed, _elementEnvironment);
    }
    if (typeWithoutNullability is InterfaceType &&
        _nativeData.isNativeClass(typeWithoutNullability.element)) {
      // We will neeed to add the "$is" and "$as" properties on the
      // JavaScript object prototype, so we make sure
      // [:defineProperty:] is compiled.
      _impacts.nativeTypeCheck.registerImpact(transformed, _elementEnvironment);
    }
  }

  WorldImpact transformCodegenImpact(CodegenImpact impact) {
    TransformedWorldImpact transformed = new TransformedWorldImpact(impact);

    for (TypeUse typeUse in impact.typeUses) {
      DartType type = typeUse.type;
      if (typeUse.kind == TypeUseKind.IS_CHECK) {
        onIsCheckForCodegen(type, transformed);
      }
    }

    for (ConstantUse constantUse in impact.constantUses) {
      switch (constantUse.value.kind) {
        case ConstantValueKind.SET:
        case ConstantValueKind.MAP:
        case ConstantValueKind.CONSTRUCTED:
        case ConstantValueKind.INSTANTIATION:
        case ConstantValueKind.LIST:
          transformed.registerStaticUse(StaticUse.staticInvoke(
              _closedWorld.commonElements.findType, CallStructure.ONE_ARG));
          break;
        case ConstantValueKind.DEFERRED_GLOBAL:
          _closedWorld.outputUnitData
              .registerConstantDeferredUse(constantUse.value);
          break;
        default:
          break;
      }
    }

    for (Pair<DartType, DartType> check
        in impact.typeVariableBoundsSubtypeChecks) {
      _rtiChecksBuilder.registerTypeVariableBoundsSubtypeCheck(
          check.a, check.b);
    }

    for (StaticUse staticUse in impact.staticUses) {
      switch (staticUse.kind) {
        case StaticUseKind.CALL_METHOD:
          FunctionEntity callMethod = staticUse.element;
          if (_rtiNeed.methodNeedsSignature(callMethod)) {
            _impacts.computeSignature
                .registerImpact(transformed, _elementEnvironment);
          }
          break;
        case StaticUseKind.STATIC_TEAR_OFF:
        case StaticUseKind.INSTANCE_FIELD_GET:
        case StaticUseKind.INSTANCE_FIELD_SET:
        case StaticUseKind.SUPER_INVOKE:
        case StaticUseKind.STATIC_INVOKE:
        case StaticUseKind.SUPER_FIELD_SET:
        case StaticUseKind.SUPER_SETTER_SET:
        case StaticUseKind.STATIC_SET:
        case StaticUseKind.SUPER_TEAR_OFF:
        case StaticUseKind.SUPER_GET:
        case StaticUseKind.STATIC_GET:
        case StaticUseKind.FIELD_INIT:
        case StaticUseKind.FIELD_CONSTANT_INIT:
        case StaticUseKind.CONSTRUCTOR_INVOKE:
        case StaticUseKind.CONST_CONSTRUCTOR_INVOKE:
        case StaticUseKind.DIRECT_INVOKE:
        case StaticUseKind.INLINING:
        case StaticUseKind.CLOSURE:
        case StaticUseKind.CLOSURE_CALL:
          break;
      }
    }

    for (Set<ClassEntity> classes in impact.specializedGetInterceptors) {
      _oneShotInterceptorData.registerSpecializedGetInterceptor(
          classes, _namer);
    }

    if (impact.usesInterceptor) {
      if (_nativeCodegenEnqueuer.hasInstantiatedNativeClasses) {
        _impacts.interceptorUse
            .registerImpact(transformed, _elementEnvironment);
        // TODO(johnniwinther): Avoid these workarounds.
        _backendUsage.needToInitializeIsolateAffinityTag = true;
        _backendUsage.needToInitializeDispatchProperty = true;
      }
    }

    for (AsyncMarker asyncMarker in impact.asyncMarkers) {
      switch (asyncMarker) {
        case AsyncMarker.ASYNC:
          _impacts.asyncBody.registerImpact(transformed, _elementEnvironment);
          break;
        case AsyncMarker.SYNC_STAR:
          _impacts.syncStarBody
              .registerImpact(transformed, _elementEnvironment);
          break;
        case AsyncMarker.ASYNC_STAR:
          _impacts.asyncStarBody
              .registerImpact(transformed, _elementEnvironment);
          break;
      }
    }

    for (GenericInstantiation instantiation in impact.genericInstantiations) {
      _rtiChecksBuilder.registerGenericInstantiation(instantiation);
    }

    for (NativeBehavior behavior in impact.nativeBehaviors) {
      _nativeCodegenEnqueuer.registerNativeBehavior(
          transformed, behavior, impact);
    }

    for (FunctionEntity function in impact.nativeMethods) {
      _nativeEmitter.nativeMethods.add(function);
    }

    for (Selector selector in impact.oneShotInterceptors) {
      _oneShotInterceptorData.registerOneShotInterceptor(
          selector, _namer, _closedWorld);
    }

    // TODO(johnniwinther): Remove eager registration.
    return transformed;
  }
}
