// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_helpers.impact;

import '../common/elements.dart' show CommonElements, ElementEnvironment;
import '../common/names.dart';
import '../elements/types.dart' show InterfaceType;
import '../elements/entities.dart';
import '../universe/selector.dart';
import '../universe/world_impact.dart'
    show WorldImpact, WorldImpactBuilder, WorldImpactBuilderImpl;
import '../universe/use.dart';
import '../util/enumset.dart';
import '../options.dart';

/// Backend specific features required by a backend impact.
enum BackendFeature {
  needToInitializeIsolateAffinityTag,
  needToInitializeDispatchProperty,
}

/// A set of JavaScript backend dependencies.
class BackendImpact {
  final List<FunctionEntity> staticUses;
  final List<FunctionEntity> globalUses;
  final List<Selector> dynamicUses;
  final List<InterfaceType> instantiatedTypes;
  final List<ClassEntity> instantiatedClasses;
  final List<ClassEntity> globalClasses;
  final List<BackendImpact> otherImpacts;
  final EnumSet<BackendFeature> _features;

  const BackendImpact(
      {this.staticUses = const [],
      this.globalUses = const [],
      this.dynamicUses = const [],
      this.instantiatedTypes = const [],
      this.instantiatedClasses = const [],
      this.globalClasses = const [],
      this.otherImpacts = const [],
      EnumSet<BackendFeature> features = const EnumSet.fixed(0)})
      : this._features = features;

  Iterable<BackendFeature> get features =>
      _features.iterable(BackendFeature.values);

  WorldImpact createImpact(ElementEnvironment elementEnvironment) {
    WorldImpactBuilderImpl impactBuilder = WorldImpactBuilderImpl();
    registerImpact(impactBuilder, elementEnvironment);
    return impactBuilder;
  }

  /// Register this backend impact to the [worldImpactBuilder].
  void registerImpact(WorldImpactBuilder worldImpactBuilder,
      ElementEnvironment elementEnvironment) {
    for (FunctionEntity staticUse in staticUses) {
      worldImpactBuilder.registerStaticUse(StaticUse.implicitInvoke(staticUse));
    }
    for (FunctionEntity staticUse in globalUses) {
      worldImpactBuilder.registerStaticUse(StaticUse.implicitInvoke(staticUse));
    }
    for (Selector selector in dynamicUses) {
      worldImpactBuilder
          .registerDynamicUse(DynamicUse(selector, null, const []));
    }
    for (InterfaceType instantiatedType in instantiatedTypes) {
      worldImpactBuilder
          .registerTypeUse(TypeUse.instantiation(instantiatedType));
    }
    for (ClassEntity cls in instantiatedClasses) {
      worldImpactBuilder.registerTypeUse(
          TypeUse.instantiation(elementEnvironment.getRawType(cls)));
    }
    for (ClassEntity cls in globalClasses) {
      worldImpactBuilder.registerTypeUse(
          TypeUse.instantiation(elementEnvironment.getRawType(cls)));
    }
    for (BackendImpact otherImpact in otherImpacts) {
      otherImpact.registerImpact(worldImpactBuilder, elementEnvironment);
    }
  }
}

/// The JavaScript backend dependencies for various features.
class BackendImpacts {
  final CommonElements _commonElements;
  final CompilerOptions _options;

  BackendImpacts(this._commonElements, this._options);

  late final BackendImpact getRuntimeTypeArgument = BackendImpact(
    globalUses: [],
    otherImpacts: [newRtiImpact],
  );

  late final BackendImpact computeSignature = BackendImpact(
    globalUses: [
      _commonElements.setArrayType,
    ],
    otherImpacts: [listValues],
  );

  late final BackendImpact mainWithArguments = BackendImpact(
    globalUses: [_commonElements.convertMainArgumentList],
    instantiatedClasses: [
      _commonElements.jsArrayClass,
      _commonElements.jsStringClass
    ],
  );

  late final BackendImpact awaitExpression = BackendImpact(
    staticUses: [
      _commonElements.futureValueConstructor!,
    ],
  );

  late final BackendImpact asyncBody = BackendImpact(
    staticUses: [
      _commonElements.asyncHelperAwait,
      _commonElements.asyncHelperReturn,
      _commonElements.asyncHelperRethrow,
      _commonElements.streamIteratorConstructor,
      _commonElements.wrapBody,
      _commonElements.asyncHelperStartSync
    ],
  );

  late final BackendImpact syncStarBody = BackendImpact(
    // The transformed JavaScript code for the sync* body has direct assignments
    // to the properties for the instance fields of `_SyncStarIterator`.
    // BackendImpact cannot model direct field assigments, so instead the
    // impacts are modeled by a call to `_SyncStarIterator._modelGeneratedCode`
    // in `moveNext()`.
    dynamicUses: [
      Selector.fromElement(_commonElements.syncStarIteratorYieldStarMethod),
    ],
  );

  late final BackendImpact asyncStarBody = BackendImpact(
    staticUses: [
      _commonElements.asyncStarHelper,
      _commonElements.streamOfController,
      _commonElements.yieldSingle,
      _commonElements.yieldStar,
      _commonElements.streamIteratorConstructor,
      _commonElements.wrapBody,
    ],
  );

  late final BackendImpact typeVariableBoundCheck = BackendImpact(
    staticUses: [
      _commonElements.checkTypeBound,
    ],
  );

  late final BackendImpact asCheck = BackendImpact(
    staticUses: [],
    otherImpacts: [
      newRtiImpact,
    ],
  );

  late final BackendImpact stringValues = BackendImpact(
    instantiatedClasses: [_commonElements.jsStringClass],
  );

  late final BackendImpact numValues = BackendImpact(
    instantiatedClasses: [
      _commonElements.jsIntClass,
      _commonElements.jsPositiveIntClass,
      _commonElements.jsUInt32Class,
      _commonElements.jsUInt31Class,
      _commonElements.jsNumberClass,
      _commonElements.jsNumNotIntClass,
    ],
  );

  BackendImpact get intValues => numValues;

  BackendImpact get doubleValues => numValues;

  late final BackendImpact boolValues = BackendImpact(
    instantiatedClasses: [_commonElements.jsBoolClass],
  );

  late final BackendImpact nullValue = BackendImpact(
    instantiatedClasses: [_commonElements.jsNullClass],
  );

  late final BackendImpact listValues = BackendImpact(
    globalClasses: [
      _commonElements.jsArrayClass,
      _commonElements.jsMutableArrayClass,
      _commonElements.jsFixedArrayClass,
      _commonElements.jsExtendableArrayClass,
      _commonElements.jsUnmodifiableArrayClass
    ],
  );

  late final BackendImpact throwUnsupportedError = BackendImpact(
    staticUses: [_commonElements.throwUnsupportedError],
    otherImpacts: [
      // Also register the types of the arguments passed to this method.
      stringValues
    ],
  );

  late final BackendImpact superNoSuchMethod = BackendImpact(
    staticUses: [
      _commonElements.createInvocationMirror,
      _commonElements.objectNoSuchMethod!
    ],
    otherImpacts: [
      _needsInt('Needed to encode the invocation kind of super.noSuchMethod.'),
      _needsList('Needed to encode the arguments of super.noSuchMethod.'),
      _needsString('Needed to encode the name of super.noSuchMethod.')
    ],
  );

  late final BackendImpact constantMapLiteral = BackendImpact(
    instantiatedClasses: [
      _commonElements.constantMapClass,
      _commonElements.constantStringMapClass,
      _commonElements.generalConstantMapClass,
    ],
  );

  late final BackendImpact constantSetLiteral = BackendImpact(
    instantiatedClasses: [
      _commonElements.constantStringSetClass,
      _commonElements.generalConstantSetClass,
    ],
  );

  late final BackendImpact constSymbol = BackendImpact(
    instantiatedClasses: [_commonElements.symbolImplementationClass],
    staticUses: [_commonElements.symbolConstructorTarget],
  );

  /// Helper for registering that `int` is needed.
  BackendImpact _needsInt(String reason) {
    // TODO(johnniwinther): Register [reason] for use in dump-info.
    return intValues;
  }

  /// Helper for registering that `List` is needed.
  BackendImpact _needsList(String reason) {
    // TODO(johnniwinther): Register [reason] for use in dump-info.
    return listValues;
  }

  /// Helper for registering that `String` is needed.
  BackendImpact _needsString(String reason) {
    // TODO(johnniwinther): Register [reason] for use in dump-info.
    return stringValues;
  }

  late final BackendImpact assertWithoutMessage = BackendImpact(
    staticUses: [_commonElements.assertHelper],
  );

  late final BackendImpact assertWithMessage = BackendImpact(
    staticUses: [_commonElements.assertTest, _commonElements.assertThrow],
  );

  late final BackendImpact asyncForIn = BackendImpact(
    staticUses: [_commonElements.streamIteratorConstructor],
  );

  late final BackendImpact stringInterpolation = BackendImpact(
    dynamicUses: [Selectors.toString_],
    staticUses: [_commonElements.stringInterpolationHelper],
    otherImpacts: [_needsString('Strings are created.')],
  );

  late final BackendImpact stringJuxtaposition =
      _needsString('String.concat is used.');

  BackendImpact get nullLiteral => nullValue;

  BackendImpact get boolLiteral => boolValues;

  BackendImpact get intLiteral => intValues;

  BackendImpact get doubleLiteral => doubleValues;

  BackendImpact get stringLiteral => stringValues;

  late final BackendImpact catchStatement = BackendImpact(
    staticUses: [_commonElements.exceptionUnwrapper],
    instantiatedClasses: [
      _commonElements.jsPlainJavaScriptObjectClass,
      _commonElements.jsUnknownJavaScriptObjectClass
    ],
  );

  late final BackendImpact throwExpression = BackendImpact(
    // We don't know ahead of time whether we will need the throw in a statement
    // context or an expression context, so we register both here, even though
    // we may not need the throwExpression helper.
    staticUses: [
      _commonElements.wrapExceptionHelper,
      _commonElements.throwExpressionHelper
    ],
  );

  late final BackendImpact lazyField = BackendImpact(
    staticUses: [
      _commonElements.cyclicThrowHelper,
      _commonElements.throwLateFieldADI,
    ],
  );

  late final BackendImpact typeLiteral = BackendImpact(
    instantiatedClasses: [_commonElements.typeLiteralClass],
    staticUses: [
      _commonElements.createRuntimeType,
      _commonElements.typeLiteralMaker,
    ],
  );

  late final BackendImpact stackTraceInCatch = BackendImpact(
    instantiatedClasses: [_commonElements.stackTraceHelperClass],
    staticUses: [_commonElements.traceFromException],
  );

  late final BackendImpact syncForIn = BackendImpact(
    // The SSA builder recognizes certain for-in loops and can generate
    // calls to throwConcurrentModificationError.
    staticUses: [_commonElements.checkConcurrentModificationError],
  );

  late final BackendImpact typeVariableExpression = BackendImpact(
    staticUses: [
      _commonElements.setArrayType,
      _commonElements.createRuntimeType
    ],
    otherImpacts: [
      listValues,
      getRuntimeTypeArgument,
      _needsInt('Needed for accessing a type variable literal on this.')
    ],
  );

  late final BackendImpact typeCheck =
      BackendImpact(otherImpacts: [boolValues, newRtiImpact]);

  late final BackendImpact genericTypeCheck = BackendImpact(
    staticUses: [
      // TODO(johnniwinther): Investigate why this is needed.
      _commonElements.setArrayType,
    ],
    otherImpacts: [
      listValues,
      getRuntimeTypeArgument,
      newRtiImpact,
    ],
  );

  late final BackendImpact genericIsCheck =
      BackendImpact(otherImpacts: [intValues, newRtiImpact]);

  late final BackendImpact typeVariableTypeCheck =
      BackendImpact(staticUses: [], otherImpacts: [newRtiImpact]);

  late final BackendImpact functionTypeCheck = BackendImpact(
    staticUses: [/*helpers.functionTypeTestMetaHelper*/],
    otherImpacts: [newRtiImpact],
  );

  late final BackendImpact futureOrTypeCheck = BackendImpact(
    staticUses: [],
    otherImpacts: [newRtiImpact],
  );

  late final BackendImpact nativeTypeCheck = BackendImpact(
    staticUses: [
      // We will need to add the "$is" and "$as" properties on the
      // JavaScript object prototype, so we make sure
      // [:defineProperty:] is compiled.
      _commonElements.defineProperty
    ],
    otherImpacts: [newRtiImpact],
  );

  late final BackendImpact closure = BackendImpact(
    instantiatedClasses: [_commonElements.functionClass],
  );

  late final BackendImpact interceptorUse = BackendImpact(
    staticUses: [_commonElements.getNativeInterceptorMethod],
    instantiatedClasses: [
      _commonElements.jsJavaScriptObjectClass,
      _commonElements.jsLegacyJavaScriptObjectClass,
      _commonElements.jsPlainJavaScriptObjectClass,
      _commonElements.jsJavaScriptFunctionClass
    ],
    features: EnumSet<BackendFeature>.fromValues([
      BackendFeature.needToInitializeDispatchProperty,
      BackendFeature.needToInitializeIsolateAffinityTag
    ], fixed: true),
  );

  late final BackendImpact allowInterop = BackendImpact(
    staticUses: [
      _commonElements.jsAllowInterop!,
    ],
    features: EnumSet<BackendFeature>.fromValues([
      BackendFeature.needToInitializeIsolateAffinityTag,
    ], fixed: true),
  );

  late final BackendImpact numClasses = BackendImpact(
    // The backend will try to optimize number operations and use the
    // `iae` helper directly.
    globalUses: [_commonElements.throwIllegalArgumentException],
  );

  late final BackendImpact listOrStringClasses = BackendImpact(
    // The backend will try to optimize array and string access and use the
    // `ioore` and `iae` _commonElements directly.
    globalUses: [
      _commonElements.throwIndexOutOfRangeException,
      _commonElements.throwIllegalArgumentException
    ],
  );

  late final BackendImpact functionClass = BackendImpact(
    globalClasses: [
      _commonElements.closureClass,
      _commonElements.closureClass0Args,
      _commonElements.closureClass2Args,
    ],
  );

  late final BackendImpact mapClass = BackendImpact(
    // The backend will use a literal list to initialize the entries of the map.
    globalClasses: [_commonElements.listClass, _commonElements.mapLiteralClass],
  );

  late final BackendImpact setClass = BackendImpact(
    globalClasses: [
      // The backend will use a literal list to initialize the entries of the
      // set.
      _commonElements.listClass,
      _commonElements.setLiteralClass,
    ],
  );

  late final BackendImpact boundClosureClass = BackendImpact(
    globalClasses: [_commonElements.boundClosureClass],
  );

  late final BackendImpact nativeOrExtendsClass = BackendImpact(
    globalUses: [_commonElements.getNativeInterceptorMethod],
    globalClasses: [
      _commonElements.jsInterceptorClass,
      _commonElements.jsJavaScriptObjectClass,
      _commonElements.jsLegacyJavaScriptObjectClass,
      _commonElements.jsPlainJavaScriptObjectClass,
      _commonElements.jsJavaScriptFunctionClass
    ],
  );

  late final BackendImpact mapLiteralClass = BackendImpact(
    globalUses: [
      _commonElements.mapLiteralConstructor,
      _commonElements.mapLiteralConstructorEmpty,
      _commonElements.mapLiteralUntypedMaker,
      _commonElements.mapLiteralUntypedEmptyMaker
    ],
  );

  late final BackendImpact setLiteralClass = BackendImpact(
    globalUses: [
      _commonElements.setLiteralConstructor,
      _commonElements.setLiteralConstructorEmpty,
      _commonElements.setLiteralUntypedMaker,
      _commonElements.setLiteralUntypedEmptyMaker,
    ],
  );

  late final BackendImpact closureClass = BackendImpact(
    globalUses: [_commonElements.closureFromTearOff],
  );

  late final BackendImpact listClasses = BackendImpact(
    // Literal lists can be translated into calls to these functions:
    globalUses: [
      _commonElements.jsArrayTypedConstructor,
      _commonElements.setArrayType,
    ],
  );

  late final BackendImpact jsIndexingBehavior = BackendImpact(
    // These two _commonElements are used by the emitter and the codegen.
    // Because we cannot enqueue elements at the time of emission,
    // we make sure they are always generated.
    globalUses: [_commonElements.isJsIndexable],
  );

  late final BackendImpact traceHelper = BackendImpact(
    globalUses: [_commonElements.traceHelper],
  );

  late final BackendImpact assertUnreachable = BackendImpact(
    globalUses: [_commonElements.assertUnreachableMethod],
  );

  late final BackendImpact runtimeTypeSupport = BackendImpact(
    globalClasses: [_commonElements.listClass],
    globalUses: [
      _commonElements.setArrayType,
    ],
    otherImpacts: [getRuntimeTypeArgument, computeSignature],
  );

  late final BackendImpact deferredLoading = BackendImpact(
    globalUses: [_commonElements.checkDeferredIsLoaded],
    // Also register the types of the arguments passed to this method.
    globalClasses: [_commonElements.stringClass],
  );

  late final BackendImpact noSuchMethodSupport = BackendImpact(
    globalUses: [
      _commonElements.createInvocationMirror,
      _commonElements.createUnmangledInvocationMirror
    ],
    dynamicUses: [Selectors.noSuchMethod_],
  );

  /// Backend impact for accessing a `loadLibrary` function on a deferred
  /// prefix.
  late final BackendImpact loadLibrary = BackendImpact(
    globalUses: [
      _commonElements.loadDeferredLibrary,
    ],
  );

  /// Backend impact for performing member closurization.
  late final BackendImpact memberClosure =
      BackendImpact(globalClasses: [_commonElements.boundClosureClass]);

  /// Backend impact for performing closurization of a top-level or static
  /// function.
  late final BackendImpact staticClosure =
      BackendImpact(globalClasses: [_commonElements.closureClass]);

  final Map<int, BackendImpact> _genericInstantiation = {};

  BackendImpact getGenericInstantiation(int typeArgumentCount) =>
      _genericInstantiation[typeArgumentCount] ??= BackendImpact(
        staticUses: [
          _commonElements.getInstantiateFunction(typeArgumentCount),
          _commonElements.instantiatedGenericFunctionTypeNewRti,
          _commonElements.closureFunctionType,
        ],
        instantiatedClasses: [
          _commonElements.getInstantiationClass(typeArgumentCount),
        ],
      );

  // TODO(sra): Split into refined impacts.
  late final BackendImpact newRtiImpact = BackendImpact(
    staticUses: [
      _commonElements.findType,
      _commonElements.instanceType,
      _commonElements.arrayInstanceType,
      _commonElements.simpleInstanceType,
      _commonElements.rtiEvalMethod,
      _commonElements.rtiBindMethod,
      _commonElements.installSpecializedIsTest,
      _commonElements.generalIsTestImplementation,
      _commonElements.generalAsCheckImplementation,
      _commonElements.installSpecializedAsCheck,
      _commonElements.generalNullableIsTestImplementation,
      _commonElements.generalNullableAsCheckImplementation,
      // Specialized checks.
      _commonElements.specializedIsBool,
      _commonElements.specializedAsBool,
      _commonElements.specializedAsBoolLegacy,
      _commonElements.specializedAsBoolNullable,
      // no specializedIsDouble.
      _commonElements.specializedAsDouble,
      _commonElements.specializedAsDoubleLegacy,
      _commonElements.specializedAsDoubleNullable,
      _commonElements.specializedIsInt,
      _commonElements.specializedAsInt,
      _commonElements.specializedAsIntLegacy,
      _commonElements.specializedAsIntNullable,
      _commonElements.specializedIsNum,
      _commonElements.specializedAsNum,
      _commonElements.specializedAsNumLegacy,
      _commonElements.specializedAsNumNullable,
      _commonElements.specializedIsString,
      _commonElements.specializedAsString,
      _commonElements.specializedAsStringLegacy,
      _commonElements.specializedAsStringNullable,
      _commonElements.specializedIsTop,
      _commonElements.specializedAsTop,
      _commonElements.specializedIsObject,
      _commonElements.specializedAsObject,
    ],
    globalClasses: [
      _commonElements.closureClass, // instanceOrFunctionType uses this.
    ],
  );

  // TODO(fishythefish): Split into refined impacts.
  late final BackendImpact rtiAddRules = BackendImpact(
    globalUses: [
      _commonElements.rtiAddRulesMethod,
      _commonElements.rtiAddErasedTypesMethod,
      if (_options.enableVariance)
        _commonElements.rtiAddTypeParameterVariancesMethod,
    ],
    otherImpacts: [_needsString('Needed to encode the new RTI ruleset.')],
  );

  late final BackendImpact lateFieldReadCheck = BackendImpact(
    globalUses: [
      _commonElements.throwUnnamedLateFieldNI,
      _commonElements.throwLateFieldNI,
    ],
  );

  late final BackendImpact lateFieldWriteOnceCheck = BackendImpact(
    globalUses: [
      _commonElements.throwUnnamedLateFieldAI,
      _commonElements.throwLateFieldAI,
    ],
  );

  late final BackendImpact lateFieldInitializeOnceCheck = BackendImpact(
    globalUses: [
      _commonElements.throwUnnamedLateFieldADI,
      _commonElements.throwLateFieldADI,
    ],
  );

  late final BackendImpact recordInstantiation = BackendImpact(
    globalUses: [
      _commonElements.recordImpactModel,
    ],
  );
}
