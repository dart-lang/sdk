// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_helpers.impact;

import '../common/names.dart' show
    Identifiers;
import '../compiler.dart' show
    Compiler;
import '../dart_types.dart' show
    InterfaceType;
import '../elements/elements.dart' show
    ClassElement,
    Element;

import 'backend_helpers.dart';
import 'constant_system_javascript.dart';
import 'js_backend.dart';

/// A set of JavaScript backend dependencies.
class BackendImpact {
  final List<Element> staticUses;
  final List<InterfaceType> instantiatedTypes;
  final List<ClassElement> instantiatedClasses;
  final List<BackendImpact> otherImpacts;

  BackendImpact({this.staticUses: const <Element>[],
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

  BackendImpact get getRuntimeTypeArgument => new BackendImpact(
      staticUses: [
        helpers.getRuntimeTypeArgument,
        helpers.getTypeArgumentByIndex,
        helpers.copyTypeArguments]);

  BackendImpact get computeSignature => new BackendImpact(
      staticUses: [
        helpers.setRuntimeTypeInfo,
        helpers.getRuntimeTypeInfo,
        helpers.computeSignature,
        helpers.getRuntimeTypeArguments],
      instantiatedClasses: [
        compiler.listClass]);

  BackendImpact get asyncBody => new BackendImpact(
      staticUses: [
        helpers.asyncHelper,
        helpers.syncCompleterConstructor,
        helpers.streamIteratorConstructor,
        helpers.wrapBody]);

  BackendImpact get syncStarBody => new BackendImpact(
      staticUses: [
        helpers.syncStarIterableConstructor,
        helpers.endOfIteration,
        helpers.yieldStar,
        helpers.syncStarUncaughtError],
      instantiatedClasses: [
        helpers.syncStarIterable]);

  BackendImpact get asyncStarBody => new BackendImpact(
      staticUses: [
        helpers.asyncStarHelper,
        helpers.streamOfController,
        helpers.yieldSingle,
        helpers.yieldStar,
        helpers.asyncStarControllerConstructor,
        helpers.streamIteratorConstructor,
        helpers.wrapBody],
      instantiatedClasses: [
        helpers.asyncStarController]);

  BackendImpact get typeVariableBoundCheck => new BackendImpact(
      staticUses: [
        helpers.throwTypeError,
        helpers.assertIsSubtype]);

  BackendImpact get abstractClassInstantiation => new BackendImpact(
      staticUses: [
        helpers.throwAbstractClassInstantiationError],
      otherImpacts: [
        needsString('Needed to encode the message.')]);

  BackendImpact get fallThroughError => new BackendImpact(
      staticUses: [
        helpers.fallThroughError]);

  BackendImpact get asCheck => new BackendImpact(
      staticUses: [
        helpers.throwRuntimeError]);

  BackendImpact get throwNoSuchMethod => new BackendImpact(
      staticUses: [
        helpers.throwNoSuchMethod],
      otherImpacts: [
        // Also register the types of the arguments passed to this method.
        needsList(
            'Needed to encode the arguments for throw NoSuchMethodError.'),
        needsString(
            'Needed to encode the name for throw NoSuchMethodError.')]);

  BackendImpact get throwRuntimeError => new BackendImpact(
      staticUses: [
        helpers.throwRuntimeError],
      // Also register the types of the arguments passed to this method.
      instantiatedClasses: [
        helpers.compiler.stringClass]);

  BackendImpact get superNoSuchMethod => new BackendImpact(
      staticUses: [
        helpers.createInvocationMirror,
        helpers.compiler.objectClass.lookupLocalMember(
            Identifiers.noSuchMethod_)],
      otherImpacts: [
        needsInt(
            'Needed to encode the invocation kind of super.noSuchMethod.'),
        needsList(
            'Needed to encode the arguments of super.noSuchMethod.'),
        needsString(
            'Needed to encode the name of super.noSuchMethod.')]);

  BackendImpact get constantMapLiteral {

    ClassElement find(String name) {
      return helpers.find(backend.jsHelperLibrary, name);
    }

    return new BackendImpact(
      instantiatedClasses: [
        find(JavaScriptMapConstant.DART_CLASS),
        find(JavaScriptMapConstant.DART_PROTO_CLASS),
        find(JavaScriptMapConstant.DART_STRING_CLASS),
        find(JavaScriptMapConstant.DART_GENERAL_CLASS)]);
  }

  BackendImpact get symbolConstructor => new BackendImpact(
      staticUses: [
        helpers.compiler.symbolValidatedConstructor]);


  BackendImpact get incDecOperation =>
      needsInt('Needed for the `+ 1` or `- 1` operation of ++/--.');

  /// Helper for registering that `int` is needed.
  BackendImpact needsInt(String reason) {
    // TODO(johnniwinther): Register [reason] for use in dump-info.
    return new BackendImpact(
        instantiatedClasses: [helpers.compiler.intClass]);
  }

  /// Helper for registering that `List` is needed.
  BackendImpact needsList(String reason) {
    // TODO(johnniwinther): Register [reason] for use in dump-info.
    return new BackendImpact(
        instantiatedClasses: [helpers.compiler.listClass]);
  }

  /// Helper for registering that `String` is needed.
  BackendImpact needsString(String reason) {
    // TODO(johnniwinther): Register [reason] for use in dump-info.
    return new BackendImpact(
        instantiatedClasses: [
          helpers.compiler.stringClass]);
  }

  BackendImpact get assertWithoutMessage => new BackendImpact(
      staticUses: [
        helpers.assertHelper]);

  BackendImpact get assertWithMessage => new BackendImpact(
      staticUses: [
        helpers.assertTest,
        helpers.assertThrow]);

  BackendImpact get asyncForIn => new BackendImpact(
      staticUses: [
        helpers.streamIteratorConstructor]);

  BackendImpact get stringInterpolation => new BackendImpact(
      staticUses: [
        helpers.stringInterpolationHelper]);

  BackendImpact get catchStatement => new BackendImpact(
      staticUses: [
        helpers.exceptionUnwrapper],
      instantiatedClasses: [
        backend.jsPlainJavaScriptObjectClass,
        backend.jsUnknownJavaScriptObjectClass]);

  BackendImpact get throwExpression => new BackendImpact(
      // We don't know ahead of time whether we will need the throw in a
      // statement context or an expression context, so we register both
      // here, even though we may not need the throwExpression helper.
      staticUses: [
        helpers.wrapExceptionHelper,
        helpers.throwExpressionHelper]);

  BackendImpact get lazyField => new BackendImpact(
      staticUses: [
        helpers.cyclicThrowHelper]);

  BackendImpact get typeLiteral => new BackendImpact(
      instantiatedClasses: [
        backend.typeImplementation],
      staticUses: [
        helpers.createRuntimeType]);

  BackendImpact get stackTraceInCatch => new BackendImpact(
      staticUses: [
        helpers.traceFromException]);

  BackendImpact get syncForIn => new BackendImpact(
      // The SSA builder recognizes certain for-in loops and can generate calls
      // to throwConcurrentModificationError.
      staticUses: [
        helpers.checkConcurrentModificationError]);

  BackendImpact get typeVariableExpression => new BackendImpact(
      staticUses: [
        helpers.setRuntimeTypeInfo,
        helpers.getRuntimeTypeInfo,
        helpers.runtimeTypeToString,
        helpers.createRuntimeType],
      instantiatedClasses: [
        helpers.compiler.listClass],
      otherImpacts: [
        getRuntimeTypeArgument,
        needsInt('Needed for accessing a type variable literal on this.')]);

  BackendImpact get typeCheck => new BackendImpact(
      instantiatedClasses: [
        helpers.compiler.boolClass]);

  BackendImpact get checkedModeTypeCheck => new BackendImpact(
      staticUses: [
        helpers.throwRuntimeError]);

  BackendImpact get malformedTypeCheck => new BackendImpact(
      staticUses: [
        helpers.throwTypeError]);

  BackendImpact get genericTypeCheck => new BackendImpact(
      staticUses: [
        helpers.checkSubtype,
        // TODO(johnniwinther): Investigate why this is needed.
        helpers.setRuntimeTypeInfo,
        helpers.getRuntimeTypeInfo],
      instantiatedClasses: [
        helpers.compiler.listClass],
      otherImpacts: [
        getRuntimeTypeArgument]);

  BackendImpact get genericCheckedModeTypeCheck => new BackendImpact(
      staticUses: [
        helpers.assertSubtype]);

  BackendImpact get typeVariableTypeCheck => new BackendImpact(
      staticUses: [
        helpers.checkSubtypeOfRuntimeType]);

  BackendImpact get typeVariableCheckedModeTypeCheck => new BackendImpact(
      staticUses: [
        helpers.assertSubtypeOfRuntimeType]);

  BackendImpact get functionTypeCheck => new BackendImpact(
      staticUses: [
        helpers.functionTypeTestMetaHelper]);

  BackendImpact get nativeTypeCheck => new BackendImpact(
      staticUses: [
        // We will neeed to add the "$is" and "$as" properties on the
        // JavaScript object prototype, so we make sure
        // [:defineProperty:] is compiled.
        helpers.defineProperty]);
}