// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_helpers.impact;

import '../compiler.dart' show Compiler;
import '../core_types.dart' show CoreClasses;
import '../dart_types.dart' show InterfaceType;
import '../elements/elements.dart' show ClassElement, Element;
import 'backend_helpers.dart';
import 'constant_system_javascript.dart';
import 'js_backend.dart';

/// A set of JavaScript backend dependencies.
class BackendImpact {
  final List<Element> staticUses;
  final List<InterfaceType> instantiatedTypes;
  final List<ClassElement> instantiatedClasses;
  final List<BackendImpact> otherImpacts;

  BackendImpact(
      {this.staticUses: const <Element>[],
      this.instantiatedTypes: const <InterfaceType>[],
      this.instantiatedClasses: const <ClassElement>[],
      this.otherImpacts: const <BackendImpact>[]});
}

/// The JavaScript backend dependencies for various features.
class BackendImpacts {
  final Compiler compiler;

  BackendImpacts(this.compiler);

  JavaScriptBackend get backend => compiler.backend;

  BackendHelpers get helpers => backend.helpers;

  CoreClasses get coreClasses => compiler.coreClasses;

  BackendImpact _getRuntimeTypeArgument;

  BackendImpact get getRuntimeTypeArgument {
    if (_getRuntimeTypeArgument == null) {
      _getRuntimeTypeArgument = new BackendImpact(staticUses: [
        helpers.getRuntimeTypeArgument,
        helpers.getTypeArgumentByIndex,
        helpers.copyTypeArguments
      ]);
    }
    return _getRuntimeTypeArgument;
  }

  BackendImpact _computeSignature;

  BackendImpact get computeSignature {
    if (_computeSignature == null) {
      _computeSignature = new BackendImpact(staticUses: [
        helpers.setRuntimeTypeInfo,
        helpers.getRuntimeTypeInfo,
        helpers.computeSignature,
        helpers.getRuntimeTypeArguments
      ], otherImpacts: [
        listValues
      ]);
    }
    return _computeSignature;
  }

  BackendImpact _asyncBody;

  BackendImpact get asyncBody {
    if (_asyncBody == null) {
      _asyncBody = new BackendImpact(staticUses: [
        helpers.asyncHelper,
        helpers.syncCompleterConstructor,
        helpers.streamIteratorConstructor,
        helpers.wrapBody
      ]);
    }
    return _asyncBody;
  }

  BackendImpact _syncStarBody;

  BackendImpact get syncStarBody {
    if (_syncStarBody == null) {
      _syncStarBody = new BackendImpact(staticUses: [
        helpers.syncStarIterableConstructor,
        helpers.endOfIteration,
        helpers.yieldStar,
        helpers.syncStarUncaughtError
      ], instantiatedClasses: [
        helpers.syncStarIterable
      ]);
    }
    return _syncStarBody;
  }

  BackendImpact _asyncStarBody;

  BackendImpact get asyncStarBody {
    if (_asyncStarBody == null) {
      _asyncStarBody = new BackendImpact(staticUses: [
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
    return _asyncStarBody;
  }

  BackendImpact _typeVariableBoundCheck;

  BackendImpact get typeVariableBoundCheck {
    if (_typeVariableBoundCheck == null) {
      _typeVariableBoundCheck = new BackendImpact(
          staticUses: [helpers.throwTypeError, helpers.assertIsSubtype]);
    }
    return _typeVariableBoundCheck;
  }

  BackendImpact _abstractClassInstantiation;

  BackendImpact get abstractClassInstantiation {
    if (_abstractClassInstantiation == null) {
      _abstractClassInstantiation = new BackendImpact(
          staticUses: [helpers.throwAbstractClassInstantiationError],
          otherImpacts: [_needsString('Needed to encode the message.')]);
    }
    return _abstractClassInstantiation;
  }

  BackendImpact _fallThroughError;

  BackendImpact get fallThroughError {
    if (_fallThroughError == null) {
      _fallThroughError =
          new BackendImpact(staticUses: [helpers.fallThroughError]);
    }
    return _fallThroughError;
  }

  BackendImpact _asCheck;

  BackendImpact get asCheck {
    if (_asCheck == null) {
      _asCheck = new BackendImpact(staticUses: [helpers.throwRuntimeError]);
    }
    return _asCheck;
  }

  BackendImpact _throwNoSuchMethod;

  BackendImpact get throwNoSuchMethod {
    if (_throwNoSuchMethod == null) {
      _throwNoSuchMethod = new BackendImpact(staticUses: [
        helpers.throwNoSuchMethod
      ], otherImpacts: [
        // Also register the types of the arguments passed to this method.
        _needsList(
            'Needed to encode the arguments for throw NoSuchMethodError.'),
        _needsString('Needed to encode the name for throw NoSuchMethodError.')
      ]);
    }
    return _throwNoSuchMethod;
  }

  BackendImpact _stringValues;

  BackendImpact get stringValues {
    if (_stringValues == null) {
      _stringValues =
          new BackendImpact(instantiatedClasses: [helpers.jsStringClass]);
    }
    return _stringValues;
  }

  BackendImpact _numValues;

  BackendImpact get numValues {
    if (_numValues == null) {
      _numValues = new BackendImpact(instantiatedClasses: [
        helpers.jsIntClass,
        helpers.jsPositiveIntClass,
        helpers.jsUInt32Class,
        helpers.jsUInt31Class,
        helpers.jsNumberClass,
        helpers.jsDoubleClass
      ]);
    }
    return _numValues;
  }

  BackendImpact get intValues => numValues;

  BackendImpact get doubleValues => numValues;

  BackendImpact _boolValues;

  BackendImpact get boolValues {
    if (_boolValues == null) {
      _boolValues =
          new BackendImpact(instantiatedClasses: [helpers.jsBoolClass]);
    }
    return _boolValues;
  }

  BackendImpact _nullValue;

  BackendImpact get nullValue {
    if (_nullValue == null) {
      _nullValue =
          new BackendImpact(instantiatedClasses: [helpers.jsNullClass]);
    }
    return _nullValue;
  }

  BackendImpact _listValues;

  BackendImpact get listValues {
    if (_listValues == null) {
      _listValues = new BackendImpact(instantiatedClasses: [
        helpers.jsArrayClass,
        helpers.jsMutableArrayClass,
        helpers.jsFixedArrayClass,
        helpers.jsExtendableArrayClass,
        helpers.jsUnmodifiableArrayClass
      ]);
    }
    return _listValues;
  }

  BackendImpact _throwRuntimeError;

  BackendImpact get throwRuntimeError {
    if (_throwRuntimeError == null) {
      _throwRuntimeError = new BackendImpact(staticUses: [
        helpers.throwRuntimeError
      ], otherImpacts: [
        // Also register the types of the arguments passed to this method.
        stringValues
      ]);
    }
    return _throwRuntimeError;
  }

  BackendImpact _superNoSuchMethod;

  BackendImpact get superNoSuchMethod {
    if (_superNoSuchMethod == null) {
      _superNoSuchMethod = new BackendImpact(staticUses: [
        helpers.createInvocationMirror,
        helpers.objectNoSuchMethod
      ], otherImpacts: [
        _needsInt(
            'Needed to encode the invocation kind of super.noSuchMethod.'),
        _needsList('Needed to encode the arguments of super.noSuchMethod.'),
        _needsString('Needed to encode the name of super.noSuchMethod.')
      ]);
    }
    return _superNoSuchMethod;
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
    if (_symbolConstructor == null) {
      _symbolConstructor =
          new BackendImpact(staticUses: [helpers.symbolValidatedConstructor]);
    }
    return _symbolConstructor;
  }

  BackendImpact _constSymbol;

  BackendImpact get constSymbol {
    if (_constSymbol == null) {
      _constSymbol = new BackendImpact(
          instantiatedClasses: [coreClasses.symbolClass],
          staticUses: [compiler.symbolConstructor.declaration]);
    }
    return _constSymbol;
  }

  BackendImpact _incDecOperation;

  BackendImpact get incDecOperation {
    if (_incDecOperation == null) {
      _incDecOperation =
          _needsInt('Needed for the `+ 1` or `- 1` operation of ++/--.');
    }
    return _incDecOperation;
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
    if (_assertWithoutMessage == null) {
      _assertWithoutMessage =
          new BackendImpact(staticUses: [helpers.assertHelper]);
    }
    return _assertWithoutMessage;
  }

  BackendImpact _assertWithMessage;

  BackendImpact get assertWithMessage {
    if (_assertWithMessage == null) {
      _assertWithMessage = new BackendImpact(
          staticUses: [helpers.assertTest, helpers.assertThrow]);
    }
    return _assertWithMessage;
  }

  BackendImpact _asyncForIn;

  BackendImpact get asyncForIn {
    if (_asyncForIn == null) {
      _asyncForIn =
          new BackendImpact(staticUses: [helpers.streamIteratorConstructor]);
    }
    return _asyncForIn;
  }

  BackendImpact _stringInterpolation;

  BackendImpact get stringInterpolation {
    if (_stringInterpolation == null) {
      _stringInterpolation = new BackendImpact(
          staticUses: [helpers.stringInterpolationHelper],
          otherImpacts: [_needsString('Strings are created.')]);
    }
    return _stringInterpolation;
  }

  BackendImpact _stringJuxtaposition;

  BackendImpact get stringJuxtaposition {
    if (_stringJuxtaposition == null) {
      _stringJuxtaposition = _needsString('String.concat is used.');
    }
    return _stringJuxtaposition;
  }

  BackendImpact get nullLiteral => nullValue;

  BackendImpact get boolLiteral => boolValues;

  BackendImpact get intLiteral => intValues;

  BackendImpact get doubleLiteral => doubleValues;

  BackendImpact get stringLiteral => stringValues;

  BackendImpact _catchStatement;

  BackendImpact get catchStatement {
    if (_catchStatement == null) {
      _catchStatement = new BackendImpact(staticUses: [
        helpers.exceptionUnwrapper
      ], instantiatedClasses: [
        helpers.jsPlainJavaScriptObjectClass,
        helpers.jsUnknownJavaScriptObjectClass
      ]);
    }
    return _catchStatement;
  }

  BackendImpact _throwExpression;

  BackendImpact get throwExpression {
    if (_throwExpression == null) {
      _throwExpression = new BackendImpact(
          // We don't know ahead of time whether we will need the throw in a
          // statement context or an expression context, so we register both
          // here, even though we may not need the throwExpression helper.
          staticUses: [
            helpers.wrapExceptionHelper,
            helpers.throwExpressionHelper
          ]);
    }
    return _throwExpression;
  }

  BackendImpact _lazyField;

  BackendImpact get lazyField {
    if (_lazyField == null) {
      _lazyField = new BackendImpact(staticUses: [helpers.cyclicThrowHelper]);
    }
    return _lazyField;
  }

  BackendImpact _typeLiteral;

  BackendImpact get typeLiteral {
    if (_typeLiteral == null) {
      _typeLiteral = new BackendImpact(
          instantiatedClasses: [backend.typeImplementation],
          staticUses: [helpers.createRuntimeType]);
    }
    return _typeLiteral;
  }

  BackendImpact _stackTraceInCatch;

  BackendImpact get stackTraceInCatch {
    if (_stackTraceInCatch == null) {
      _stackTraceInCatch = new BackendImpact(
          instantiatedClasses: [helpers.stackTraceClass],
          staticUses: [helpers.traceFromException]);
    }
    return _stackTraceInCatch;
  }

  BackendImpact _syncForIn;

  BackendImpact get syncForIn {
    if (_syncForIn == null) {
      _syncForIn = new BackendImpact(
          // The SSA builder recognizes certain for-in loops and can generate
          // calls to throwConcurrentModificationError.
          staticUses: [helpers.checkConcurrentModificationError]);
    }
    return _syncForIn;
  }

  BackendImpact _typeVariableExpression;

  BackendImpact get typeVariableExpression {
    if (_typeVariableExpression == null) {
      _typeVariableExpression = new BackendImpact(staticUses: [
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
    return _typeVariableExpression;
  }

  BackendImpact _typeCheck;

  BackendImpact get typeCheck {
    if (_typeCheck == null) {
      _typeCheck = new BackendImpact(otherImpacts: [boolValues]);
    }
    return _typeCheck;
  }

  BackendImpact _checkedModeTypeCheck;

  BackendImpact get checkedModeTypeCheck {
    if (_checkedModeTypeCheck == null) {
      _checkedModeTypeCheck =
          new BackendImpact(staticUses: [helpers.throwRuntimeError]);
    }
    return _checkedModeTypeCheck;
  }

  BackendImpact _malformedTypeCheck;

  BackendImpact get malformedTypeCheck {
    if (_malformedTypeCheck == null) {
      _malformedTypeCheck =
          new BackendImpact(staticUses: [helpers.throwTypeError]);
    }
    return _malformedTypeCheck;
  }

  BackendImpact _genericTypeCheck;

  BackendImpact get genericTypeCheck {
    if (_genericTypeCheck == null) {
      _genericTypeCheck = new BackendImpact(staticUses: [
        helpers.checkSubtype,
        // TODO(johnniwinther): Investigate why this is needed.
        helpers.setRuntimeTypeInfo,
        helpers.getRuntimeTypeInfo
      ], otherImpacts: [
        listValues,
        getRuntimeTypeArgument
      ]);
    }
    return _genericTypeCheck;
  }

  BackendImpact _genericIsCheck;

  BackendImpact get genericIsCheck {
    if (_genericIsCheck == null) {
      _genericIsCheck = new BackendImpact(otherImpacts: [intValues]);
    }
    return _genericIsCheck;
  }

  BackendImpact _genericCheckedModeTypeCheck;

  BackendImpact get genericCheckedModeTypeCheck {
    if (_genericCheckedModeTypeCheck == null) {
      _genericCheckedModeTypeCheck =
          new BackendImpact(staticUses: [helpers.assertSubtype]);
    }
    return _genericCheckedModeTypeCheck;
  }

  BackendImpact _typeVariableTypeCheck;

  BackendImpact get typeVariableTypeCheck {
    if (_typeVariableTypeCheck == null) {
      _typeVariableTypeCheck =
          new BackendImpact(staticUses: [helpers.checkSubtypeOfRuntimeType]);
    }
    return _typeVariableTypeCheck;
  }

  BackendImpact _typeVariableCheckedModeTypeCheck;

  BackendImpact get typeVariableCheckedModeTypeCheck {
    if (_typeVariableCheckedModeTypeCheck == null) {
      _typeVariableCheckedModeTypeCheck =
          new BackendImpact(staticUses: [helpers.assertSubtypeOfRuntimeType]);
    }
    return _typeVariableCheckedModeTypeCheck;
  }

  BackendImpact _functionTypeCheck;

  BackendImpact get functionTypeCheck {
    if (_functionTypeCheck == null) {
      _functionTypeCheck =
          new BackendImpact(staticUses: [helpers.functionTypeTestMetaHelper]);
    }
    return _functionTypeCheck;
  }

  BackendImpact _nativeTypeCheck;

  BackendImpact get nativeTypeCheck {
    if (_nativeTypeCheck == null) {
      _nativeTypeCheck = new BackendImpact(staticUses: [
        // We will neeed to add the "$is" and "$as" properties on the
        // JavaScript object prototype, so we make sure
        // [:defineProperty:] is compiled.
        helpers.defineProperty
      ]);
    }
    return _nativeTypeCheck;
  }

  BackendImpact _closure;

  BackendImpact get closure {
    if (_closure == null) {
      _closure =
          new BackendImpact(instantiatedClasses: [coreClasses.functionClass]);
    }
    return _closure;
  }
}
