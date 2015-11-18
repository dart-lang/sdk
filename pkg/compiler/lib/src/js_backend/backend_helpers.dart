// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_backend.helpers;

import '../common/resolution.dart' show
    Resolution;
import '../compiler.dart' show
    Compiler;
import '../elements/elements.dart' show
    ClassElement,
    Element,
    LibraryElement,
    MethodElement;

import 'js_backend.dart';

/// Helper classes and functions for the JavaScript backend.
class BackendHelpers {
  final Compiler compiler;

  Element cachedCheckConcurrentModificationError;

  BackendHelpers(this.compiler);

  JavaScriptBackend get backend => compiler.backend;

  Resolution get resolution => backend.resolution;

  MethodElement assertTest;
  MethodElement assertThrow;
  MethodElement assertHelper;

  Element findHelper(String name) => backend.findHelper(name);
  Element findAsyncHelper(String name) => backend.findAsyncHelper(name);
  Element findInterceptor(String name) => backend.findInterceptor(name);

  Element find(LibraryElement library, String name) {
    return backend.find(library, name);
  }

  Element get exceptionUnwrapper {
    return findHelper('unwrapException');
  }

  Element get throwRuntimeError {
    return findHelper('throwRuntimeError');
  }

  Element get throwTypeError {
    return findHelper('throwTypeError');
  }

  Element get throwAbstractClassInstantiationError {
    return findHelper('throwAbstractClassInstantiationError');
  }

  Element get checkConcurrentModificationError {
    if (cachedCheckConcurrentModificationError == null) {
      cachedCheckConcurrentModificationError =
          findHelper('checkConcurrentModificationError');
    }
    return cachedCheckConcurrentModificationError;
  }

  Element get throwConcurrentModificationError {
    return findHelper('throwConcurrentModificationError');
  }

  Element get throwIndexOutOfBoundsError {
    return findHelper('ioore');
  }

  Element get stringInterpolationHelper {
    return findHelper('S');
  }

  Element get wrapExceptionHelper {
    return findHelper(r'wrapException');
  }

  Element get throwExpressionHelper {
    return findHelper('throwExpression');
  }

  Element get closureConverter {
    return findHelper('convertDartClosureToJS');
  }

  Element get traceFromException {
    return findHelper('getTraceFromException');
  }

  Element get setRuntimeTypeInfo {
    return findHelper('setRuntimeTypeInfo');
  }

  Element get getRuntimeTypeInfo {
    return findHelper('getRuntimeTypeInfo');
  }

  Element get getTypeArgumentByIndex {
    return findHelper('getTypeArgumentByIndex');
  }

  Element get copyTypeArguments {
    return findHelper('copyTypeArguments');
  }

  Element get computeSignature {
    return findHelper('computeSignature');
  }

  Element get getRuntimeTypeArguments {
    return findHelper('getRuntimeTypeArguments');
  }

  Element get getRuntimeTypeArgument {
    return findHelper('getRuntimeTypeArgument');
  }

  Element get runtimeTypeToString {
    return findHelper('runtimeTypeToString');
  }

  Element get assertIsSubtype {
    return findHelper('assertIsSubtype');
  }

  Element get checkSubtype {
    return findHelper('checkSubtype');
  }

  Element get assertSubtype {
    return findHelper('assertSubtype');
  }

  Element get subtypeCast {
    return findHelper('subtypeCast');
  }

  Element get checkSubtypeOfRuntimeType {
    return findHelper('checkSubtypeOfRuntimeType');
  }

  Element get assertSubtypeOfRuntimeType {
    return findHelper('assertSubtypeOfRuntimeType');
  }

  Element get subtypeOfRuntimeTypeCast {
    return findHelper('subtypeOfRuntimeTypeCast');
  }

  Element get checkDeferredIsLoaded {
    return findHelper('checkDeferredIsLoaded');
  }

  Element get throwNoSuchMethod {
    return findHelper('throwNoSuchMethod');
  }

  Element get createRuntimeType {
    return findHelper('createRuntimeType');
  }

  Element get fallThroughError {
    return findHelper("getFallThroughError");
  }

  Element get createInvocationMirror {
    return findHelper(Compiler.CREATE_INVOCATION_MIRROR);
  }

  Element get cyclicThrowHelper {
    return findHelper("throwCyclicInit");
  }

  Element get asyncHelper {
    return findAsyncHelper("_asyncHelper");
  }

  Element get wrapBody {
    return findAsyncHelper("_wrapJsFunctionForAsync");
  }

  Element get yieldStar {
    ClassElement classElement = findAsyncHelper("_IterationMarker");
    classElement.ensureResolved(resolution);
    return classElement.lookupLocalMember("yieldStar");
  }

  Element get yieldSingle {
    ClassElement classElement = findAsyncHelper("_IterationMarker");
    classElement.ensureResolved(resolution);
    return classElement.lookupLocalMember("yieldSingle");
  }

  Element get syncStarUncaughtError {
    ClassElement classElement = findAsyncHelper("_IterationMarker");
    classElement.ensureResolved(resolution);
    return classElement.lookupLocalMember("uncaughtError");
  }

  Element get asyncStarHelper {
    return findAsyncHelper("_asyncStarHelper");
  }

  Element get streamOfController {
    return findAsyncHelper("_streamOfController");
  }

  Element get endOfIteration {
    ClassElement classElement = findAsyncHelper("_IterationMarker");
    classElement.ensureResolved(resolution);
    return classElement.lookupLocalMember("endOfIteration");
  }

  Element get syncStarIterable {
    ClassElement classElement = findAsyncHelper("_SyncStarIterable");
    classElement.ensureResolved(resolution);
    return classElement;
  }

  Element get syncStarIterableConstructor {
    ClassElement classElement = syncStarIterable;
    classElement.ensureResolved(resolution);
    return classElement.lookupConstructor("");
  }

  Element get syncCompleterConstructor {
    ClassElement classElement = find(compiler.asyncLibrary, "Completer");
    classElement.ensureResolved(resolution);
    return classElement.lookupConstructor("sync");
  }

  Element get asyncStarController {
    ClassElement classElement =
        findAsyncHelper("_AsyncStarStreamController");
    classElement.ensureResolved(resolution);
    return classElement;
  }

  Element get asyncStarControllerConstructor {
    ClassElement classElement = asyncStarController;
    return classElement.lookupConstructor("");
  }

  Element get streamIteratorConstructor {
    ClassElement classElement = find(compiler.asyncLibrary, "StreamIterator");
    classElement.ensureResolved(resolution);
    return classElement.lookupConstructor("");
  }

  MethodElement get functionTypeTestMetaHelper {
    return findHelper('functionTypeTestMetaHelper');
  }

  MethodElement get defineProperty {
    return findHelper('defineProperty');
  }
}