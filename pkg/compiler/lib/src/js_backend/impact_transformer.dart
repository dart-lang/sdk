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
import '../constants/expressions.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import '../native/enqueue.dart';
import '../native/behavior.dart';
import '../options.dart';
import '../universe/feature.dart';
import '../universe/use.dart'
    show StaticUse, StaticUseKind, TypeUse, TypeUseKind;
import '../universe/world_impact.dart' show TransformedWorldImpact, WorldImpact;
import '../util/util.dart';
import 'backend_impact.dart';
import 'backend_usage.dart';
import 'custom_elements_analysis.dart';
import 'interceptor_data.dart';
import 'namer.dart';
import 'native_data.dart';
import 'runtime_types.dart';

class JavaScriptImpactTransformer extends ImpactTransformer {
  final CompilerOptions _options;
  final ElementEnvironment _elementEnvironment;
  final CommonElements _commonElements;
  final BackendImpacts _impacts;
  final NativeBasicData _nativeBasicData;
  final NativeResolutionEnqueuer _nativeResolutionEnqueuer;
  final BackendUsageBuilder _backendUsageBuilder;
  final CustomElementsResolutionAnalysis _customElementsResolutionAnalysis;
  final RuntimeTypesNeedBuilder _rtiNeedBuilder;
  final ClassHierarchyBuilder _classHierarchyBuilder;

  JavaScriptImpactTransformer(
      this._options,
      this._elementEnvironment,
      this._commonElements,
      this._impacts,
      this._nativeBasicData,
      this._nativeResolutionEnqueuer,
      this._backendUsageBuilder,
      this._customElementsResolutionAnalysis,
      this._rtiNeedBuilder,
      this._classHierarchyBuilder);

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
        case Feature.ABSTRACT_CLASS_INSTANTIATION:
          registerImpact(_impacts.abstractClassInstantiation);
          break;
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
        case Feature.COMPILE_TIME_ERROR:
          if (_options.generateCodeWithCompileTimeErrors) {
            // TODO(johnniwinther): This should have its own uncatchable error.
            registerImpact(_impacts.throwRuntimeError);
          }
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
        case TypeUseKind.NATIVE_INSTANTIATION:
          break;
        case TypeUseKind.IS_CHECK:
          onIsCheck(type, transformed);
          break;
        case TypeUseKind.AS_CAST:
          if (!_options.omitAsCasts) {
            onIsCheck(type, transformed);
            hasAsCast = true;
          }
          break;
        case TypeUseKind.IMPLICIT_CAST:
          if (_options.implicitDowncastCheckPolicy.isEmitted) {
            onIsCheck(type, transformed);
          }
          break;
        case TypeUseKind.PARAMETER_CHECK:
          if (_options.parameterCheckPolicy.isEmitted) {
            onIsCheck(type, transformed);
          }
          break;
        case TypeUseKind.CATCH_TYPE:
          onIsCheck(type, transformed);
          break;
        case TypeUseKind.TYPE_LITERAL:
          _customElementsResolutionAnalysis.registerTypeLiteral(type);
          if (type.isTypeVariable) {
            TypeVariableType typeVariable = type;
            Entity typeDeclaration = typeVariable.element.typeDeclaration;
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

    for (ConstantExpression constant in worldImpact.constantLiterals) {
      switch (constant.kind) {
        case ConstantExpressionKind.NULL:
          registerImpact(_impacts.nullLiteral);
          break;
        case ConstantExpressionKind.BOOL:
          registerImpact(_impacts.boolLiteral);
          break;
        case ConstantExpressionKind.INT:
          registerImpact(_impacts.intLiteral);
          break;
        case ConstantExpressionKind.DOUBLE:
          registerImpact(_impacts.doubleLiteral);
          break;
        case ConstantExpressionKind.STRING:
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

    type = _elementEnvironment.getUnaliasedType(type);
    registerImpact(_impacts.typeCheck);

    if (!type.treatAsRaw || type.containsTypeVariables || type.isFunctionType) {
      registerImpact(_impacts.genericTypeCheck);
      if (type.isTypeVariable) {
        registerImpact(_impacts.typeVariableTypeCheck);
      }
    }
    if (type is FunctionType) {
      registerImpact(_impacts.functionTypeCheck);
    }
    if (type is InterfaceType && _nativeBasicData.isNativeClass(type.element)) {
      registerImpact(_impacts.nativeTypeCheck);
    }
    if (type is FutureOrType) {
      registerImpact(_impacts.futureOrTypeCheck);
    }
  }
}

class CodegenImpactTransformer {
  final CompilerOptions _options;
  final ElementEnvironment _elementEnvironment;
  final CommonElements _commonElements;
  final BackendImpacts _impacts;
  final NativeData _nativeData;
  final BackendUsage _backendUsage;
  final RuntimeTypesNeed _rtiNeed;
  final NativeCodegenEnqueuer _nativeCodegenEnqueuer;
  final Namer _namer;
  final OneShotInterceptorData _oneShotInterceptorData;
  final RuntimeTypesChecksBuilder _rtiChecksBuilder;

  CodegenImpactTransformer(
      this._options,
      this._elementEnvironment,
      this._commonElements,
      this._impacts,
      this._nativeData,
      this._backendUsage,
      this._rtiNeed,
      this._nativeCodegenEnqueuer,
      this._namer,
      this._oneShotInterceptorData,
      this._rtiChecksBuilder);

  void onIsCheckForCodegen(DartType type, TransformedWorldImpact transformed) {
    if (type.isDynamic) return;
    if (type.isVoid) return;
    type = type.unaliased;
    _impacts.typeCheck.registerImpact(transformed, _elementEnvironment);

    if (!type.treatAsRaw || type.containsTypeVariables) {
      _impacts.genericIsCheck.registerImpact(transformed, _elementEnvironment);
    }
    if (type is InterfaceType && _nativeData.isNativeClass(type.element)) {
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

    for (Pair<DartType, DartType> check
        in impact.typeVariableBoundsSubtypeChecks) {
      _rtiChecksBuilder.registerTypeVariableBoundsSubtypeCheck(
          check.a, check.b);
    }

    for (StaticUse staticUse in impact.staticUses) {
      if (staticUse.kind == StaticUseKind.CALL_METHOD) {
        FunctionEntity callMethod = staticUse.element;
        if (_rtiNeed.methodNeedsSignature(callMethod)) {
          _impacts.computeSignature
              .registerImpact(transformed, _elementEnvironment);
        }
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

    // TODO(johnniwinther): Remove eager registration.
    return transformed;
  }
}
