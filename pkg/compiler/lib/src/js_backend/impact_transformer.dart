// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js_backend.backend.impact_transformer;

import '../common.dart';
import '../common/backend_api.dart' show ImpactTransformer;
import '../common/codegen.dart' show CodegenImpact;
import '../common/resolution.dart' show ResolutionImpact;
import '../constants/expressions.dart';
import '../constants/values.dart';
import '../common_elements.dart' show ElementEnvironment;
import '../elements/elements.dart';
import '../elements/resolution_types.dart';
import '../enqueue.dart' show ResolutionEnqueuer;
import '../native/native.dart' as native;
import '../universe/feature.dart';
import '../universe/use.dart'
    show StaticUse, StaticUseKind, TypeUse, TypeUseKind;
import '../universe/world_impact.dart' show TransformedWorldImpact, WorldImpact;
import '../util/util.dart';
import 'backend.dart';
import 'backend_impact.dart';
import 'backend_usage.dart';
import 'checked_mode_helpers.dart';

class JavaScriptImpactTransformer extends ImpactTransformer {
  final JavaScriptBackend backend;

  JavaScriptImpactTransformer(this.backend);

  BackendImpacts get impacts => backend.impacts;

  ElementEnvironment get elementEnvironment =>
      backend.compiler.elementEnvironment;

  @override
  WorldImpact transformResolutionImpact(
      ResolutionEnqueuer enqueuer, ResolutionImpact worldImpact) {
    BackendUsageBuilder backendUsage = backend.backendUsageBuilder;
    TransformedWorldImpact transformed =
        new TransformedWorldImpact(worldImpact);

    void registerImpact(BackendImpact impact) {
      impact.registerImpact(transformed, elementEnvironment);
      backendUsage.processBackendImpact(impact);
    }

    for (Feature feature in worldImpact.features) {
      switch (feature) {
        case Feature.ABSTRACT_CLASS_INSTANTIATION:
          registerImpact(impacts.abstractClassInstantiation);
          break;
        case Feature.ASSERT:
          registerImpact(impacts.assertWithoutMessage);
          break;
        case Feature.ASSERT_WITH_MESSAGE:
          registerImpact(impacts.assertWithMessage);
          break;
        case Feature.ASYNC:
          registerImpact(impacts.asyncBody);
          break;
        case Feature.ASYNC_FOR_IN:
          registerImpact(impacts.asyncForIn);
          break;
        case Feature.ASYNC_STAR:
          registerImpact(impacts.asyncStarBody);
          break;
        case Feature.CATCH_STATEMENT:
          registerImpact(impacts.catchStatement);
          break;
        case Feature.COMPILE_TIME_ERROR:
          if (backend.compiler.options.generateCodeWithCompileTimeErrors) {
            // TODO(johnniwinther): This should have its own uncatchable error.
            registerImpact(impacts.throwRuntimeError);
          }
          break;
        case Feature.FALL_THROUGH_ERROR:
          registerImpact(impacts.fallThroughError);
          break;
        case Feature.FIELD_WITHOUT_INITIALIZER:
        case Feature.LOCAL_WITHOUT_INITIALIZER:
          transformed.registerTypeUse(
              new TypeUse.instantiation(backend.commonElements.nullType));
          registerImpact(impacts.nullLiteral);
          break;
        case Feature.LAZY_FIELD:
          registerImpact(impacts.lazyField);
          break;
        case Feature.STACK_TRACE_IN_CATCH:
          registerImpact(impacts.stackTraceInCatch);
          break;
        case Feature.STRING_INTERPOLATION:
          registerImpact(impacts.stringInterpolation);
          break;
        case Feature.STRING_JUXTAPOSITION:
          registerImpact(impacts.stringJuxtaposition);
          break;
        case Feature.SUPER_NO_SUCH_METHOD:
          registerImpact(impacts.superNoSuchMethod);
          break;
        case Feature.SYMBOL_CONSTRUCTOR:
          registerImpact(impacts.symbolConstructor);
          break;
        case Feature.SYNC_FOR_IN:
          registerImpact(impacts.syncForIn);
          break;
        case Feature.SYNC_STAR:
          registerImpact(impacts.syncStarBody);
          break;
        case Feature.THROW_EXPRESSION:
          registerImpact(impacts.throwExpression);
          break;
        case Feature.THROW_NO_SUCH_METHOD:
          registerImpact(impacts.throwNoSuchMethod);
          break;
        case Feature.THROW_RUNTIME_ERROR:
          registerImpact(impacts.throwRuntimeError);
          break;
        case Feature.TYPE_VARIABLE_BOUNDS_CHECK:
          registerImpact(impacts.typeVariableBoundCheck);
          break;
      }
    }

    bool hasAsCast = false;
    bool hasTypeLiteral = false;
    for (TypeUse typeUse in worldImpact.typeUses) {
      ResolutionDartType type = typeUse.type;
      switch (typeUse.kind) {
        case TypeUseKind.INSTANTIATION:
        case TypeUseKind.MIRROR_INSTANTIATION:
        case TypeUseKind.NATIVE_INSTANTIATION:
          registerRequiredType(type);
          break;
        case TypeUseKind.IS_CHECK:
          onIsCheck(type, transformed);
          break;
        case TypeUseKind.AS_CAST:
          onIsCheck(type, transformed);
          hasAsCast = true;
          break;
        case TypeUseKind.CHECKED_MODE_CHECK:
          if (backend.compiler.options.enableTypeAssertions) {
            onIsCheck(type, transformed);
          }
          break;
        case TypeUseKind.CATCH_TYPE:
          onIsCheck(type, transformed);
          break;
        case TypeUseKind.TYPE_LITERAL:
          backend.customElementsResolutionAnalysis.registerTypeLiteral(type);
          if (type.isTypeVariable && type is! MethodTypeVariableType) {
            // GENERIC_METHODS: The `is!` test above filters away method type
            // variables, because they have the value `dynamic` with the
            // incomplete support for generic methods offered with
            // '--generic-method-syntax'. This must be revised in order to
            // support generic methods fully.
            ClassElement cls = type.element.enclosingClass;
            backend.rtiNeedBuilder
                .registerClassUsingTypeVariableExpression(cls);
            registerImpact(impacts.typeVariableExpression);
          }
          hasTypeLiteral = true;
          break;
      }
    }

    if (hasAsCast) {
      registerImpact(impacts.asCheck);
    }

    if (hasTypeLiteral) {
      transformed.registerTypeUse(
          new TypeUse.instantiation(backend.compiler.commonElements.typeType));
      registerImpact(impacts.typeLiteral);
    }

    for (MapLiteralUse mapLiteralUse in worldImpact.mapLiterals) {
      // TODO(johnniwinther): Use the [isEmpty] property when factory
      // constructors are registered directly.
      if (mapLiteralUse.isConstant) {
        registerImpact(impacts.constantMapLiteral);
      } else {
        transformed
            .registerTypeUse(new TypeUse.instantiation(mapLiteralUse.type));
      }
      ResolutionInterfaceType type = mapLiteralUse.type;
      registerRequiredType(type);
    }

    for (ListLiteralUse listLiteralUse in worldImpact.listLiterals) {
      // TODO(johnniwinther): Use the [isConstant] and [isEmpty] property when
      // factory constructors are registered directly.
      transformed
          .registerTypeUse(new TypeUse.instantiation(listLiteralUse.type));
      ResolutionInterfaceType type = listLiteralUse.type;
      registerRequiredType(type);
    }

    if (worldImpact.constSymbolNames.isNotEmpty) {
      registerImpact(impacts.constSymbol);
      for (String constSymbolName in worldImpact.constSymbolNames) {
        backend.mirrorsData.registerConstSymbol(constSymbolName);
      }
    }

    for (StaticUse staticUse in worldImpact.staticUses) {
      switch (staticUse.kind) {
        case StaticUseKind.CLOSURE:
          registerImpact(impacts.closure);
          LocalFunctionElement closure = staticUse.element;
          if (closure.type.containsTypeVariables) {
            registerImpact(impacts.computeSignature);
          }
          break;
        case StaticUseKind.CONST_CONSTRUCTOR_INVOKE:
        case StaticUseKind.CONSTRUCTOR_INVOKE:
          registerRequiredType(staticUse.type);
          break;
        default:
      }
    }

    for (ConstantExpression constant in worldImpact.constantLiterals) {
      switch (constant.kind) {
        case ConstantExpressionKind.NULL:
          registerImpact(impacts.nullLiteral);
          break;
        case ConstantExpressionKind.BOOL:
          registerImpact(impacts.boolLiteral);
          break;
        case ConstantExpressionKind.INT:
          registerImpact(impacts.intLiteral);
          break;
        case ConstantExpressionKind.DOUBLE:
          registerImpact(impacts.doubleLiteral);
          break;
        case ConstantExpressionKind.STRING:
          registerImpact(impacts.stringLiteral);
          break;
        default:
          assert(invariant(NO_LOCATION_SPANNABLE, false,
              message: "Unexpected constant literal: ${constant.kind}."));
      }
    }

    for (native.NativeBehavior behavior in worldImpact.nativeData) {
      enqueuer.nativeEnqueuer
          .registerNativeBehavior(transformed, behavior, worldImpact);
    }

    return transformed;
  }

  /// Register [type] as required for the runtime type information system.
  void registerRequiredType(ResolutionDartType type) {
    if (!type.isInterfaceType) return;
    // If [argument] has type variables or is a type variable, this method
    // registers a RTI dependency between the class where the type variable is
    // defined (that is the enclosing class of the current element being
    // resolved) and the class of [type]. If the class of [type] requires RTI,
    // then the class of the type variable does too.
    ClassElement contextClass = Types.getClassContext(type);
    if (contextClass != null) {
      backend.rtiNeedBuilder.registerRtiDependency(type.element, contextClass);
    }
  }

  // TODO(johnniwinther): Maybe split this into [onAssertType] and [onTestType].
  void onIsCheck(ResolutionDartType type, TransformedWorldImpact transformed) {
    BackendUsageBuilder backendUsage = backend.backendUsageBuilder;

    void registerImpact(BackendImpact impact) {
      impact.registerImpact(transformed, elementEnvironment);
      backendUsage.processBackendImpact(impact);
    }

    registerRequiredType(type);
    type.computeUnaliased(backend.resolution);
    type = type.unaliased;
    registerImpact(impacts.typeCheck);

    bool inCheckedMode = backend.compiler.options.enableTypeAssertions;
    if (inCheckedMode) {
      registerImpact(impacts.checkedModeTypeCheck);
    }
    if (type.isMalformed) {
      registerImpact(impacts.malformedTypeCheck);
    }
    if (!type.treatAsRaw || type.containsTypeVariables || type.isFunctionType) {
      registerImpact(impacts.genericTypeCheck);
      if (inCheckedMode) {
        registerImpact(impacts.genericCheckedModeTypeCheck);
      }
      if (type.isTypeVariable) {
        registerImpact(impacts.typeVariableTypeCheck);
        if (inCheckedMode) {
          registerImpact(impacts.typeVariableCheckedModeTypeCheck);
        }
      }
    }
    if (type is ResolutionFunctionType) {
      registerImpact(impacts.functionTypeCheck);
    }
    if (type.element != null && backend.isNative(type.element)) {
      registerImpact(impacts.nativeTypeCheck);
    }
  }

  void onIsCheckForCodegen(
      ResolutionDartType type, TransformedWorldImpact transformed) {
    if (type.isDynamic) return;
    type = type.unaliased;
    impacts.typeCheck.registerImpact(transformed, elementEnvironment);

    bool inCheckedMode = backend.compiler.options.enableTypeAssertions;
    // [registerIsCheck] is also called for checked mode checks, so we
    // need to register checked mode helpers.
    if (inCheckedMode) {
      // All helpers are added to resolution queue in enqueueHelpers. These
      // calls to [enqueue] with the resolution enqueuer serve as assertions
      // that the helper was in fact added.
      // TODO(13155): Find a way to enqueue helpers lazily.
      CheckedModeHelper helper = backend.checkedModeHelpers
          .getCheckedModeHelper(type, typeCast: false);
      if (helper != null) {
        StaticUse staticUse = helper.getStaticUse(backend.helpers);
        transformed.registerStaticUse(staticUse);
      }
      // We also need the native variant of the check (for DOM types).
      helper = backend.checkedModeHelpers
          .getNativeCheckedModeHelper(type, typeCast: false);
      if (helper != null) {
        StaticUse staticUse = helper.getStaticUse(backend.helpers);
        transformed.registerStaticUse(staticUse);
      }
    }
    if (!type.treatAsRaw || type.containsTypeVariables) {
      impacts.genericIsCheck.registerImpact(transformed, elementEnvironment);
    }
    if (type.element != null && backend.isNative(type.element)) {
      // We will neeed to add the "$is" and "$as" properties on the
      // JavaScript object prototype, so we make sure
      // [:defineProperty:] is compiled.
      impacts.nativeTypeCheck.registerImpact(transformed, elementEnvironment);
    }
  }

  @override
  WorldImpact transformCodegenImpact(CodegenImpact impact) {
    TransformedWorldImpact transformed = new TransformedWorldImpact(impact);

    for (TypeUse typeUse in impact.typeUses) {
      ResolutionDartType type = typeUse.type;
      switch (typeUse.kind) {
        case TypeUseKind.INSTANTIATION:
          backend.lookupMapAnalysis.registerInstantiatedType(type);
          break;
        case TypeUseKind.IS_CHECK:
          onIsCheckForCodegen(type, transformed);
          break;
        default:
      }
    }

    for (ConstantValue constant in impact.compileTimeConstants) {
      backend.computeImpactForCompileTimeConstant(constant, transformed,
          forResolution: false);
      backend.addCompileTimeConstantForEmission(constant);
    }

    for (Pair<ResolutionDartType, ResolutionDartType> check
        in impact.typeVariableBoundsSubtypeChecks) {
      backend.registerTypeVariableBoundsSubtypeCheck(check.a, check.b);
    }

    for (StaticUse staticUse in impact.staticUses) {
      switch (staticUse.kind) {
        case StaticUseKind.CLOSURE:
          LocalFunctionElement closure = staticUse.element;
          if (backend.rtiNeed.methodNeedsRti(closure)) {
            impacts.computeSignature
                .registerImpact(transformed, elementEnvironment);
          }
          break;
        case StaticUseKind.CONST_CONSTRUCTOR_INVOKE:
        case StaticUseKind.CONSTRUCTOR_INVOKE:
          backend.lookupMapAnalysis.registerInstantiatedType(staticUse.type);
          break;
        default:
      }
    }

    for (String name in impact.constSymbols) {
      backend.mirrorsData.registerConstSymbol(name);
    }

    for (Set<ClassElement> classes in impact.specializedGetInterceptors) {
      backend.oneShotInterceptorData
          .registerSpecializedGetInterceptor(classes, backend.namer);
    }

    if (impact.usesInterceptor) {
      if (backend.codegenEnqueuer.nativeEnqueuer.hasInstantiatedNativeClasses) {
        impacts.interceptorUse.registerImpact(transformed, elementEnvironment);
        // TODO(johnniwinther): Avoid these workarounds.
        backend.backendUsage.needToInitializeIsolateAffinityTag = true;
        backend.backendUsage.needToInitializeDispatchProperty = true;
      }
    }

    for (ClassElement element in impact.typeConstants) {
      backend.customElementsCodegenAnalysis.registerTypeConstant(element);
      backend.lookupMapAnalysis.registerTypeConstant(element);
    }

    for (FunctionElement element in impact.asyncMarkers) {
      switch (element.asyncMarker) {
        case AsyncMarker.ASYNC:
          impacts.asyncBody.registerImpact(transformed, elementEnvironment);
          break;
        case AsyncMarker.SYNC_STAR:
          impacts.syncStarBody.registerImpact(transformed, elementEnvironment);
          break;
        case AsyncMarker.ASYNC_STAR:
          impacts.asyncStarBody.registerImpact(transformed, elementEnvironment);
          break;
      }
    }

    // TODO(johnniwinther): Remove eager registration.
    return transformed;
  }
}
