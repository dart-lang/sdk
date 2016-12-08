// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_helpers.impact;

import '../common/names.dart';
import '../compiler.dart' show Compiler;
import '../core_types.dart' show CommonElements;
import '../dart_types.dart' show InterfaceType;
import '../elements/elements.dart' show ClassElement, Element;
import '../universe/selector.dart';
import '../util/enumset.dart';
import 'backend_helpers.dart';
import 'constant_system_javascript.dart';
import 'js_backend.dart';

/// Backend specific features required by a backend impact.
enum BackendFeature {
  needToInitializeIsolateAffinityTag,
  needToInitializeDispatchProperty,
}

/// A set of JavaScript backend dependencies.
class BackendImpact {
  final List<Element> staticUses;
  final List<Element> globalUses;
  final List<Selector> dynamicUses;
  final List<InterfaceType> instantiatedTypes;
  final List<ClassElement> instantiatedClasses;
  final List<ClassElement> globalClasses;
  final List<BackendImpact> otherImpacts;
  final EnumSet<BackendFeature> _features;

  const BackendImpact(
      {this.staticUses: const <Element>[],
      this.globalUses: const <Element>[],
      this.dynamicUses: const <Selector>[],
      this.instantiatedTypes: const <InterfaceType>[],
      this.instantiatedClasses: const <ClassElement>[],
      this.globalClasses: const <ClassElement>[],
      this.otherImpacts: const <BackendImpact>[],
      EnumSet<BackendFeature> features: const EnumSet<BackendFeature>.fixed(0)})
      : this._features = features;

  Iterable<BackendFeature> get features =>
      _features.iterable(BackendFeature.values);
}

/// The JavaScript backend dependencies for various features.
class BackendImpacts {
  final Compiler compiler;

  BackendImpacts(this.compiler);

  JavaScriptBackend get backend => compiler.backend;

  BackendHelpers get helpers => backend.helpers;

  CommonElements get commonElements => compiler.commonElements;

  BackendImpact _getRuntimeTypeArgument;

  BackendImpact get getRuntimeTypeArgument {
    return _getRuntimeTypeArgument ??= new BackendImpact(globalUses: [
      helpers.getRuntimeTypeArgument,
      helpers.getTypeArgumentByIndex,
    ]);
  }

  BackendImpact _computeSignature;

  BackendImpact get computeSignature {
    return _computeSignature ??= new BackendImpact(globalUses: [
      helpers.setRuntimeTypeInfo,
      helpers.getRuntimeTypeInfo,
      helpers.computeSignature,
      helpers.getRuntimeTypeArguments
    ], otherImpacts: [
      listValues
    ]);
  }

  BackendImpact _mainWithArguments;

  BackendImpact get mainWithArguments {
    return _mainWithArguments ??= new BackendImpact(
        instantiatedClasses: [helpers.jsArrayClass, helpers.jsStringClass]);
  }

  BackendImpact _asyncBody;

  BackendImpact get asyncBody {
    return _asyncBody ??= new BackendImpact(staticUses: [
      helpers.asyncHelper,
      helpers.syncCompleterConstructor,
      helpers.streamIteratorConstructor,
      helpers.wrapBody
    ]);
  }

  BackendImpact _syncStarBody;

  BackendImpact get syncStarBody {
    return _syncStarBody ??= new BackendImpact(staticUses: [
      helpers.syncStarIterableConstructor,
      helpers.endOfIteration,
      helpers.yieldStar,
      helpers.syncStarUncaughtError
    ], instantiatedClasses: [
      helpers.syncStarIterable
    ]);
  }

  BackendImpact _asyncStarBody;

  BackendImpact get asyncStarBody {
    return _asyncStarBody ??= new BackendImpact(staticUses: [
      helpers.asyncStarHelper,
      helpers.streamOfController,
      helpers.yieldSingle,
      helpers.yieldStar,
      helpers.asyncStarControllerConstructor,
      helpers.streamIteratorConstructor,
      helpers.wrapBody
    ], instantiatedClasses: [
      helpers.asyncStarController
    ]);
  }

  BackendImpact _typeVariableBoundCheck;

  BackendImpact get typeVariableBoundCheck {
    return _typeVariableBoundCheck ??= new BackendImpact(
        staticUses: [helpers.throwTypeError, helpers.assertIsSubtype]);
  }

  BackendImpact _abstractClassInstantiation;

  BackendImpact get abstractClassInstantiation {
    return _abstractClassInstantiation ??= new BackendImpact(
        staticUses: [helpers.throwAbstractClassInstantiationError],
        otherImpacts: [_needsString('Needed to encode the message.')]);
  }

  BackendImpact _fallThroughError;

  BackendImpact get fallThroughError {
    return _fallThroughError ??=
        new BackendImpact(staticUses: [helpers.fallThroughError]);
  }

  BackendImpact _asCheck;

  BackendImpact get asCheck {
    return _asCheck ??=
        new BackendImpact(staticUses: [helpers.throwRuntimeError]);
  }

  BackendImpact _throwNoSuchMethod;

  BackendImpact get throwNoSuchMethod {
    return _throwNoSuchMethod ??= new BackendImpact(
        instantiatedClasses: compiler.options.useKernel
            ? [
                commonElements.symbolClass,
              ]
            : [],
        staticUses: compiler.options.useKernel
            ? [
                helpers.genericNoSuchMethod,
                helpers.unresolvedConstructorError,
                commonElements.symbolConstructor.declaration,
              ]
            : [
                helpers.throwNoSuchMethod,
              ],
        otherImpacts: [
          // Also register the types of the arguments passed to this method.
          _needsList(
              'Needed to encode the arguments for throw NoSuchMethodError.'),
          _needsString('Needed to encode the name for throw NoSuchMethodError.')
        ]);
  }

  BackendImpact _stringValues;

  BackendImpact get stringValues {
    return _stringValues ??=
        new BackendImpact(instantiatedClasses: [helpers.jsStringClass]);
  }

  BackendImpact _numValues;

  BackendImpact get numValues {
    return _numValues ??= new BackendImpact(instantiatedClasses: [
      helpers.jsIntClass,
      helpers.jsPositiveIntClass,
      helpers.jsUInt32Class,
      helpers.jsUInt31Class,
      helpers.jsNumberClass,
      helpers.jsDoubleClass
    ]);
  }

  BackendImpact get intValues => numValues;

  BackendImpact get doubleValues => numValues;

  BackendImpact _boolValues;

  BackendImpact get boolValues {
    return _boolValues ??=
        new BackendImpact(instantiatedClasses: [helpers.jsBoolClass]);
  }

  BackendImpact _nullValue;

  BackendImpact get nullValue {
    return _nullValue ??=
        new BackendImpact(instantiatedClasses: [helpers.jsNullClass]);
  }

  BackendImpact _listValues;

  BackendImpact get listValues {
    return _listValues ??= new BackendImpact(globalClasses: [
      helpers.jsArrayClass,
      helpers.jsMutableArrayClass,
      helpers.jsFixedArrayClass,
      helpers.jsExtendableArrayClass,
      helpers.jsUnmodifiableArrayClass
    ]);
  }

  BackendImpact _throwRuntimeError;

  BackendImpact get throwRuntimeError {
    return _throwRuntimeError ??= new BackendImpact(
        staticUses: compiler.options.useKernel
            ? [
                // TODO(sra): Refactor impacts so that we know which of these
                // are called.
                helpers.malformedTypeError,
                helpers.throwRuntimeError,
              ]
            : [
                helpers.throwRuntimeError,
              ],
        otherImpacts: [
          // Also register the types of the arguments passed to this method.
          stringValues
        ]);
  }

  BackendImpact _superNoSuchMethod;

  BackendImpact get superNoSuchMethod {
    return _superNoSuchMethod ??= new BackendImpact(staticUses: [
      helpers.createInvocationMirror,
      helpers.objectNoSuchMethod
    ], otherImpacts: [
      _needsInt('Needed to encode the invocation kind of super.noSuchMethod.'),
      _needsList('Needed to encode the arguments of super.noSuchMethod.'),
      _needsString('Needed to encode the name of super.noSuchMethod.')
    ]);
  }

  BackendImpact _constantMapLiteral;

  BackendImpact get constantMapLiteral {
    if (_constantMapLiteral == null) {
      ClassElement find(String name) {
        return helpers.find(helpers.jsHelperLibrary, name);
      }

      _constantMapLiteral = new BackendImpact(instantiatedClasses: [
        find(JavaScriptMapConstant.DART_CLASS),
        find(JavaScriptMapConstant.DART_PROTO_CLASS),
        find(JavaScriptMapConstant.DART_STRING_CLASS),
        find(JavaScriptMapConstant.DART_GENERAL_CLASS)
      ]);
    }
    return _constantMapLiteral;
  }

  BackendImpact _symbolConstructor;

  BackendImpact get symbolConstructor {
    return _symbolConstructor ??=
        new BackendImpact(staticUses: [helpers.symbolValidatedConstructor]);
  }

  BackendImpact _constSymbol;

  BackendImpact get constSymbol {
    return _constSymbol ??= new BackendImpact(
        instantiatedClasses: [commonElements.symbolClass],
        staticUses: [commonElements.symbolConstructor.declaration]);
  }

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

  BackendImpact _assertWithoutMessage;

  BackendImpact get assertWithoutMessage {
    return _assertWithoutMessage ??=
        new BackendImpact(staticUses: [helpers.assertHelper]);
  }

  BackendImpact _assertWithMessage;

  BackendImpact get assertWithMessage {
    return _assertWithMessage ??= new BackendImpact(
        staticUses: [helpers.assertTest, helpers.assertThrow]);
  }

  BackendImpact _asyncForIn;

  BackendImpact get asyncForIn {
    return _asyncForIn ??=
        new BackendImpact(staticUses: [helpers.streamIteratorConstructor]);
  }

  BackendImpact _stringInterpolation;

  BackendImpact get stringInterpolation {
    return _stringInterpolation ??= new BackendImpact(
        dynamicUses: [Selectors.toString_],
        staticUses: [helpers.stringInterpolationHelper],
        otherImpacts: [_needsString('Strings are created.')]);
  }

  BackendImpact _stringJuxtaposition;

  BackendImpact get stringJuxtaposition {
    return _stringJuxtaposition ??= _needsString('String.concat is used.');
  }

  BackendImpact get nullLiteral => nullValue;

  BackendImpact get boolLiteral => boolValues;

  BackendImpact get intLiteral => intValues;

  BackendImpact get doubleLiteral => doubleValues;

  BackendImpact get stringLiteral => stringValues;

  BackendImpact _catchStatement;

  BackendImpact get catchStatement {
    return _catchStatement ??= new BackendImpact(staticUses: [
      helpers.exceptionUnwrapper
    ], instantiatedClasses: [
      helpers.jsPlainJavaScriptObjectClass,
      helpers.jsUnknownJavaScriptObjectClass
    ]);
  }

  BackendImpact _throwExpression;

  BackendImpact get throwExpression {
    return _throwExpression ??= new BackendImpact(
        // We don't know ahead of time whether we will need the throw in a
        // statement context or an expression context, so we register both
        // here, even though we may not need the throwExpression helper.
        staticUses: [
          helpers.wrapExceptionHelper,
          helpers.throwExpressionHelper
        ]);
  }

  BackendImpact _lazyField;

  BackendImpact get lazyField {
    return _lazyField ??=
        new BackendImpact(staticUses: [helpers.cyclicThrowHelper]);
  }

  BackendImpact _typeLiteral;

  BackendImpact get typeLiteral {
    return _typeLiteral ??= new BackendImpact(
        instantiatedClasses: [backend.backendClasses.typeImplementation],
        staticUses: [helpers.createRuntimeType]);
  }

  BackendImpact _stackTraceInCatch;

  BackendImpact get stackTraceInCatch {
    return _stackTraceInCatch ??= new BackendImpact(
        instantiatedClasses: [helpers.stackTraceClass],
        staticUses: [helpers.traceFromException]);
  }

  BackendImpact _syncForIn;

  BackendImpact get syncForIn {
    return _syncForIn ??= new BackendImpact(
        // The SSA builder recognizes certain for-in loops and can generate
        // calls to throwConcurrentModificationError.
        staticUses: [helpers.checkConcurrentModificationError]);
  }

  BackendImpact _typeVariableExpression;

  BackendImpact get typeVariableExpression {
    return _typeVariableExpression ??= new BackendImpact(staticUses: [
      helpers.setRuntimeTypeInfo,
      helpers.getRuntimeTypeInfo,
      helpers.runtimeTypeToString,
      helpers.createRuntimeType
    ], otherImpacts: [
      listValues,
      getRuntimeTypeArgument,
      _needsInt('Needed for accessing a type variable literal on this.')
    ]);
  }

  BackendImpact _typeCheck;

  BackendImpact get typeCheck {
    return _typeCheck ??= new BackendImpact(otherImpacts: [boolValues]);
  }

  BackendImpact _checkedModeTypeCheck;

  BackendImpact get checkedModeTypeCheck {
    return _checkedModeTypeCheck ??=
        new BackendImpact(staticUses: [helpers.throwRuntimeError]);
  }

  BackendImpact _malformedTypeCheck;

  BackendImpact get malformedTypeCheck {
    return _malformedTypeCheck ??= new BackendImpact(
        staticUses: compiler.options.useKernel
            ? [
                helpers.malformedTypeError,
              ]
            : [
                helpers.throwTypeError,
              ]);
  }

  BackendImpact _genericTypeCheck;

  BackendImpact get genericTypeCheck {
    return _genericTypeCheck ??= new BackendImpact(staticUses: [
      helpers.checkSubtype,
      // TODO(johnniwinther): Investigate why this is needed.
      helpers.setRuntimeTypeInfo,
      helpers.getRuntimeTypeInfo
    ], otherImpacts: [
      listValues,
      getRuntimeTypeArgument
    ]);
  }

  BackendImpact _genericIsCheck;

  BackendImpact get genericIsCheck {
    return _genericIsCheck ??= new BackendImpact(otherImpacts: [intValues]);
  }

  BackendImpact _genericCheckedModeTypeCheck;

  BackendImpact get genericCheckedModeTypeCheck {
    return _genericCheckedModeTypeCheck ??=
        new BackendImpact(staticUses: [helpers.assertSubtype]);
  }

  BackendImpact _typeVariableTypeCheck;

  BackendImpact get typeVariableTypeCheck {
    return _typeVariableTypeCheck ??=
        new BackendImpact(staticUses: [helpers.checkSubtypeOfRuntimeType]);
  }

  BackendImpact _typeVariableCheckedModeTypeCheck;

  BackendImpact get typeVariableCheckedModeTypeCheck {
    return _typeVariableCheckedModeTypeCheck ??=
        new BackendImpact(staticUses: [helpers.assertSubtypeOfRuntimeType]);
  }

  BackendImpact _functionTypeCheck;

  BackendImpact get functionTypeCheck {
    return _functionTypeCheck ??=
        new BackendImpact(staticUses: [helpers.functionTypeTestMetaHelper]);
  }

  BackendImpact _nativeTypeCheck;

  BackendImpact get nativeTypeCheck {
    return _nativeTypeCheck ??= new BackendImpact(staticUses: [
      // We will neeed to add the "$is" and "$as" properties on the
      // JavaScript object prototype, so we make sure
      // [:defineProperty:] is compiled.
      helpers.defineProperty
    ]);
  }

  BackendImpact _closure;

  BackendImpact get closure {
    return _closure ??=
        new BackendImpact(instantiatedClasses: [commonElements.functionClass]);
  }

  BackendImpact _interceptorUse;

  BackendImpact get interceptorUse {
    return _interceptorUse ??= new BackendImpact(
        staticUses: [
          helpers.getNativeInterceptorMethod
        ],
        instantiatedClasses: [
          helpers.jsJavaScriptObjectClass,
          helpers.jsPlainJavaScriptObjectClass,
          helpers.jsJavaScriptFunctionClass
        ],
        features: new EnumSet<BackendFeature>.fromValues([
          BackendFeature.needToInitializeDispatchProperty,
          BackendFeature.needToInitializeIsolateAffinityTag
        ], fixed: true));
  }

  BackendImpact _numClasses;

  BackendImpact get numClasses {
    return _numClasses ??= new BackendImpact(
        // The backend will try to optimize number operations and use the
        // `iae` helper directly.
        globalUses: [helpers.throwIllegalArgumentException]);
  }

  BackendImpact _listOrStringClasses;

  BackendImpact get listOrStringClasses {
    return _listOrStringClasses ??= new BackendImpact(
        // The backend will try to optimize array and string access and use the
        // `ioore` and `iae` helpers directly.
        globalUses: [
          helpers.throwIndexOutOfRangeException,
          helpers.throwIllegalArgumentException
        ]);
  }

  BackendImpact _functionClass;

  BackendImpact get functionClass {
    return _functionClass ??=
        new BackendImpact(globalClasses: [helpers.closureClass]);
  }

  BackendImpact _mapClass;

  BackendImpact get mapClass {
    return _mapClass ??= new BackendImpact(
        // The backend will use a literal list to initialize the entries
        // of the map.
        globalClasses: [
          helpers.coreClasses.listClass,
          helpers.mapLiteralClass
        ]);
  }

  BackendImpact _boundClosureClass;

  BackendImpact get boundClosureClass {
    return _boundClosureClass ??=
        new BackendImpact(globalClasses: [helpers.boundClosureClass]);
  }

  BackendImpact _nativeOrExtendsClass;

  BackendImpact get nativeOrExtendsClass {
    return _nativeOrExtendsClass ??= new BackendImpact(globalUses: [
      helpers.getNativeInterceptorMethod
    ], globalClasses: [
      helpers.jsInterceptorClass,
      helpers.jsJavaScriptObjectClass,
      helpers.jsPlainJavaScriptObjectClass,
      helpers.jsJavaScriptFunctionClass
    ]);
  }

  BackendImpact _mapLiteralClass;

  BackendImpact get mapLiteralClass {
    return _mapLiteralClass ??= new BackendImpact(globalUses: [
      helpers.mapLiteralConstructor,
      helpers.mapLiteralConstructorEmpty,
      helpers.mapLiteralUntypedMaker,
      helpers.mapLiteralUntypedEmptyMaker
    ]);
  }

  BackendImpact _closureClass;

  BackendImpact get closureClass {
    return _closureClass ??=
        new BackendImpact(globalUses: [helpers.closureFromTearOff]);
  }

  BackendImpact _listClasses;

  BackendImpact get listClasses {
    return _listClasses ??= new BackendImpact(
        // Literal lists can be translated into calls to these functions:
        globalUses: [
          helpers.jsArrayTypedConstructor,
          helpers.setRuntimeTypeInfo,
          helpers.getTypeArgumentByIndex
        ]);
  }

  BackendImpact _jsIndexingBehavior;

  BackendImpact get jsIndexingBehavior {
    return _jsIndexingBehavior ??= new BackendImpact(
        // These two helpers are used by the emitter and the codegen.
        // Because we cannot enqueue elements at the time of emission,
        // we make sure they are always generated.
        globalUses: [helpers.isJsIndexable]);
  }

  BackendImpact _enableTypeAssertions;

  BackendImpact get enableTypeAssertions {
    return _enableTypeAssertions ??= new BackendImpact(
        // Register the helper that checks if the expression in an if/while/for
        // is a boolean.
        // TODO(johnniwinther): Should this be registered through a [Feature]
        // instead?
        globalUses: [helpers.boolConversionCheck]);
  }

  BackendImpact _traceHelper;

  BackendImpact get traceHelper {
    return _traceHelper ??=
        new BackendImpact(globalUses: [helpers.traceHelper]);
  }

  BackendImpact _assertUnreachable;

  BackendImpact get assertUnreachable {
    return _assertUnreachable ??=
        new BackendImpact(globalUses: [helpers.assertUnreachableMethod]);
  }

  BackendImpact _runtimeTypeSupport;

  BackendImpact get runtimeTypeSupport {
    return _runtimeTypeSupport ??= new BackendImpact(
        globalClasses: [helpers.coreClasses.listClass],
        globalUses: [helpers.setRuntimeTypeInfo, helpers.getRuntimeTypeInfo],
        otherImpacts: [getRuntimeTypeArgument, computeSignature]);
  }

  BackendImpact _deferredLoading;

  BackendImpact get deferredLoading {
    return _deferredLoading ??=
        new BackendImpact(globalUses: [helpers.checkDeferredIsLoaded],
            // Also register the types of the arguments passed to this method.
            globalClasses: [helpers.coreClasses.stringClass]);
  }

  BackendImpact _noSuchMethodSupport;

  BackendImpact get noSuchMethodSupport {
    return _noSuchMethodSupport ??= new BackendImpact(
        staticUses: [helpers.createInvocationMirror],
        dynamicUses: [Selectors.noSuchMethod_]);
  }

  BackendImpact _isolateSupport;

  /// Backend impact for isolate support.
  BackendImpact get isolateSupport {
    return _isolateSupport ??=
        new BackendImpact(globalUses: [helpers.startRootIsolate]);
  }

  BackendImpact _isolateSupportForResolution;

  /// Additional backend impact for isolate support in resolution.
  BackendImpact get isolateSupportForResolution {
    return _isolateSupportForResolution ??= new BackendImpact(
        globalUses: [helpers.currentIsolate, helpers.callInIsolate]);
  }

  BackendImpact _loadLibrary;

  /// Backend impact for accessing a `loadLibrary` function on a deferred
  /// prefix.
  BackendImpact get loadLibrary {
    return _loadLibrary ??=
        new BackendImpact(globalUses: [helpers.loadLibraryWrapper]);
  }

  BackendImpact _memberClosure;

  /// Backend impact for performing member closurization.
  BackendImpact get memberClosure {
    return _memberClosure ??=
        new BackendImpact(globalClasses: [helpers.boundClosureClass]);
  }

  BackendImpact _staticClosure;

  /// Backend impact for performing closurization of a top-level or static
  /// function.
  BackendImpact get staticClosure {
    return _staticClosure ??=
        new BackendImpact(globalClasses: [helpers.closureClass]);
  }
}
