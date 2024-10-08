// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js_backend.backend.impact_transformer;

import '../common/elements.dart';
import '../common/codegen.dart' show CodegenImpact;
import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import '../js_emitter/native_emitter.dart';
import '../js_model/js_world.dart';
import '../native/enqueue.dart';
import '../native/behavior.dart';
import '../universe/call_structure.dart';
import '../universe/feature.dart';
import '../universe/selector.dart';
import '../universe/use.dart';
import '../universe/world_impact.dart' show TransformedWorldImpact, WorldImpact;
import 'backend_impact.dart';
import 'backend_usage.dart';
import 'interceptor_data.dart';
import 'namer.dart';
import 'native_data.dart';
import 'runtime_types.dart';
import 'runtime_types_resolution.dart';

class CodegenImpactTransformer {
  final JClosedWorld _closedWorld;
  final ElementEnvironment _elementEnvironment;
  final BackendImpacts _impacts;
  final NativeData _nativeData;
  final BackendUsage _backendUsage;
  final RuntimeTypesNeed _rtiNeed;
  final NativeCodegenEnqueuer _nativeCodegenEnqueuer;
  final Namer _namer;
  final OneShotInterceptorData oneShotInterceptorData;
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
      this.oneShotInterceptorData,
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
      // We will need to add the "$is" and "$as" properties on the
      // JavaScript object prototype, so we make sure
      // [:defineProperty:] is compiled.
      _impacts.nativeTypeCheck.registerImpact(transformed, _elementEnvironment);
    }
  }

  WorldImpact transformCodegenImpact(CodegenImpact impact) {
    TransformedWorldImpact transformed = TransformedWorldImpact(impact);

    for (TypeUse typeUse in impact.typeUses) {
      DartType type = typeUse.type;
      if (typeUse.kind == TypeUseKind.IS_CHECK) {
        onIsCheckForCodegen(type, transformed);
      }
    }

    for (ConstantUse constantUse in impact.constantUses) {
      switch (constantUse.value.kind) {
        case ConstantValueKind.MAP:
        case ConstantValueKind.SET:
        case ConstantValueKind.CONSTRUCTED:
        case ConstantValueKind.LIST:
          transformed.registerStaticUse(StaticUse.staticInvoke(
              _closedWorld.commonElements.findType, CallStructure.ONE_ARG));
          break;
        case ConstantValueKind.INSTANTIATION:
          transformed.registerStaticUse(StaticUse.staticInvoke(
              _closedWorld.commonElements.findType, CallStructure.ONE_ARG));
          final instantiation = constantUse.value as InstantiationConstantValue;
          _rtiChecksBuilder.registerGenericInstantiation(GenericInstantiation(
              instantiation.function.type, instantiation.typeArguments));
          break;
        case ConstantValueKind.DEFERRED_GLOBAL:
          _closedWorld.outputUnitData.registerConstantDeferredUse(
              constantUse.value as DeferredGlobalConstantValue);
          break;
        case ConstantValueKind.BOOL:
        case ConstantValueKind.DOUBLE:
        case ConstantValueKind.DUMMY_INTERCEPTOR:
        case ConstantValueKind.FUNCTION:
        case ConstantValueKind.INT:
        case ConstantValueKind.INTERCEPTOR:
        case ConstantValueKind.JAVASCRIPT_OBJECT:
        case ConstantValueKind.JS_NAME:
        case ConstantValueKind.LATE_SENTINEL:
        case ConstantValueKind.NULL:
        case ConstantValueKind.RECORD:
        case ConstantValueKind.STRING:
        case ConstantValueKind.TYPE:
        case ConstantValueKind.UNREACHABLE:
          break;
      }
    }

    for ((DartType, DartType) check in impact.typeVariableBoundsSubtypeChecks) {
      _rtiChecksBuilder.registerTypeVariableBoundsSubtypeCheck(
          check.$1, check.$2);
    }

    for (StaticUse staticUse in impact.staticUses) {
      switch (staticUse.kind) {
        case StaticUseKind.CALL_METHOD:
          final callMethod = staticUse.element as FunctionEntity;
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
        case StaticUseKind.WEAK_STATIC_TEAR_OFF:
          break;
      }
    }

    for (Set<ClassEntity> classes in impact.specializedGetInterceptors) {
      oneShotInterceptorData.registerSpecializedGetInterceptor(classes);
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
        case AsyncMarker.SYNC:
          // No implicit impacts.
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
      oneShotInterceptorData.registerOneShotInterceptor(
          selector, _namer, _closedWorld);
    }

    // TODO(johnniwinther): Remove eager registration.
    return transformed;
  }
}
