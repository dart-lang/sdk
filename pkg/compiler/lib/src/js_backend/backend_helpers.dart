// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_backend.helpers;

import '../common.dart';
import '../common/names.dart' show Identifiers, Uris;
import '../common/resolution.dart' show Resolution;
import '../compiler.dart' show Compiler;
import '../core_types.dart' show CoreClasses;
import '../elements/elements.dart'
    show
        AbstractFieldElement,
        ClassElement,
        ConstructorElement,
        Element,
        EnumClassElement,
        FieldElement,
        FunctionElement,
        LibraryElement,
        MemberElement,
        MethodElement,
        Name,
        PublicName;
import '../library_loader.dart' show LoadedLibraries;
import '../universe/call_structure.dart' show CallStructure;
import '../universe/selector.dart' show Selector;
import 'js_backend.dart';

/// Helper classes and functions for the JavaScript backend.
class BackendHelpers {
  static final Uri DART_JS_HELPER = new Uri(scheme: 'dart', path: '_js_helper');
  static final Uri DART_INTERCEPTORS =
      new Uri(scheme: 'dart', path: '_interceptors');
  static final Uri DART_FOREIGN_HELPER =
      new Uri(scheme: 'dart', path: '_foreign_helper');
  static final Uri DART_JS_MIRRORS =
      new Uri(scheme: 'dart', path: '_js_mirrors');
  static final Uri DART_JS_NAMES = new Uri(scheme: 'dart', path: '_js_names');
  static final Uri DART_EMBEDDED_NAMES =
      new Uri(scheme: 'dart', path: '_js_embedded_names');
  static final Uri DART_ISOLATE_HELPER =
      new Uri(scheme: 'dart', path: '_isolate_helper');
  static final Uri PACKAGE_JS = new Uri(scheme: 'package', path: 'js/js.dart');

  static const String INVOKE_ON = '_getCachedInvocation';
  static const String START_ROOT_ISOLATE = 'startRootIsolate';

  static const String JS = 'JS';
  static const String JS_BUILTIN = 'JS_BUILTIN';
  static const String JS_EMBEDDED_GLOBAL = 'JS_EMBEDDED_GLOBAL';
  static const String JS_INTERCEPTOR_CONSTANT = 'JS_INTERCEPTOR_CONSTANT';

  final Compiler compiler;

  Element cachedCheckConcurrentModificationError;

  BackendHelpers(this.compiler);

  JavaScriptBackend get backend => compiler.backend;

  Resolution get resolution => backend.resolution;

  CoreClasses get coreClasses => compiler.coreClasses;

  DiagnosticReporter get reporter => compiler.reporter;

  MethodElement assertTest;
  MethodElement assertThrow;
  MethodElement assertHelper;

  LibraryElement jsHelperLibrary;
  LibraryElement asyncLibrary;
  LibraryElement interceptorsLibrary;
  LibraryElement foreignLibrary;
  LibraryElement isolateHelperLibrary;

  /// Reference to the internal library to lookup functions to always inline.
  LibraryElement internalLibrary;

  ClassElement closureClass;
  ClassElement boundClosureClass;
  Element assertUnreachableMethod;
  Element invokeOnMethod;

  ClassElement jsInterceptorClass;
  ClassElement jsStringClass;
  ClassElement jsArrayClass;
  ClassElement jsNumberClass;
  ClassElement jsIntClass;
  ClassElement jsDoubleClass;
  ClassElement jsNullClass;
  ClassElement jsBoolClass;
  ClassElement jsPlainJavaScriptObjectClass;
  ClassElement jsUnknownJavaScriptObjectClass;
  ClassElement jsJavaScriptFunctionClass;
  ClassElement jsJavaScriptObjectClass;

  ClassElement jsIndexableClass;
  ClassElement jsMutableIndexableClass;

  ClassElement jsMutableArrayClass;
  ClassElement jsFixedArrayClass;
  ClassElement jsExtendableArrayClass;
  ClassElement jsUnmodifiableArrayClass;
  ClassElement jsPositiveIntClass;
  ClassElement jsUInt32Class;
  ClassElement jsUInt31Class;

  MemberElement jsIndexableLength;
  Element jsArrayTypedConstructor;
  MethodElement jsArrayRemoveLast;
  MethodElement jsArrayAdd;
  MethodElement jsStringSplit;
  Element jsStringToString;
  Element jsStringOperatorAdd;
  Element objectEquals;

  ClassElement typeLiteralClass;
  ClassElement mapLiteralClass;
  ClassElement constMapLiteralClass;
  ClassElement typeVariableClass;

  ClassElement noSideEffectsClass;
  ClassElement noThrowsClass;
  ClassElement noInlineClass;
  ClassElement forceInlineClass;
  ClassElement irRepresentationClass;

  ClassElement jsAnnotationClass;
  ClassElement jsAnonymousClass;

  Element getInterceptorMethod;

  ClassElement jsInvocationMirrorClass;

  ClassElement typedArrayClass;
  ClassElement typedArrayOfIntClass;

  /**
   * Interface used to determine if an object has the JavaScript
   * indexing behavior. The interface is only visible to specific
   * libraries.
   */
  ClassElement jsIndexingBehaviorInterface;

  Element getNativeInterceptorMethod;

  /// Holds the method "getIsolateAffinityTag" when dart:_js_helper has been
  /// loaded.
  FunctionElement getIsolateAffinityTagMarker;

  /// Holds the method "disableTreeShaking" in js_mirrors when
  /// dart:mirrors has been loaded.
  FunctionElement disableTreeShakingMarker;

  /// Holds the method "preserveNames" in js_mirrors when
  /// dart:mirrors has been loaded.
  FunctionElement preserveNamesMarker;

  /// Holds the method "preserveMetadata" in js_mirrors when
  /// dart:mirrors has been loaded.
  FunctionElement preserveMetadataMarker;

  /// Holds the method "preserveUris" in js_mirrors when
  /// dart:mirrors has been loaded.
  FunctionElement preserveUrisMarker;

  /// Holds the method "preserveLibraryNames" in js_mirrors when
  /// dart:mirrors has been loaded.
  FunctionElement preserveLibraryNamesMarker;

  /// Holds the method "requiresPreamble" in _js_helper.
  FunctionElement requiresPreambleMarker;

  /// Holds the class for the [JsGetName] enum.
  EnumClassElement jsGetNameEnum;

  /// Holds the class for the [JsBuiltins] enum.
  EnumClassElement jsBuiltinEnum;

  ClassElement _symbolImplementationClass;
  ClassElement get symbolImplementationClass {
    return _symbolImplementationClass ??= find(internalLibrary, 'Symbol');
  }

  final Selector symbolValidatedConstructorSelector =
      new Selector.call(const PublicName('validated'), CallStructure.ONE_ARG);

  ConstructorElement _symbolValidatedConstructor;

  bool isSymbolValidatedConstructor(Element element) {
    if (_symbolValidatedConstructor != null) {
      return element == _symbolValidatedConstructor;
    }
    return false;
  }

  ConstructorElement get symbolValidatedConstructor {
    return _symbolValidatedConstructor ??= _findConstructor(
        symbolImplementationClass, symbolValidatedConstructorSelector.name);
  }

  // TODO(johnniwinther): Make these private.
  // TODO(johnniwinther): Split into findHelperFunction and findHelperClass and
  // add a check that the element has the expected kind.
  Element findHelper(String name) => find(jsHelperLibrary, name);
  Element findAsyncHelper(String name) => find(asyncLibrary, name);
  Element findInterceptor(String name) => find(interceptorsLibrary, name);
  Element find(LibraryElement library, String name) {
    Element element = library.implementation.findLocal(name);
    assert(invariant(library, element != null,
        message: "Element '$name' not found in '${library.canonicalUri}'."));
    return element;
  }

  Element findCoreHelper(String name) =>
      compiler.commonElements.coreLibrary.implementation.localLookup(name);

  ConstructorElement _findConstructor(ClassElement cls, String name) {
    cls.ensureResolved(resolution);
    ConstructorElement constructor = cls.lookupConstructor(name);
    assert(invariant(cls, constructor != null,
        message: "Constructor '$name' not found in '${cls}'."));
    return constructor;
  }

  void onLibraryCreated(LibraryElement library) {
    Uri uri = library.canonicalUri;
    if (uri == DART_JS_HELPER) {
      jsHelperLibrary = library;
    } else if (uri == Uris.dart_async) {
      asyncLibrary = library;
    } else if (uri == Uris.dart__internal) {
      internalLibrary = library;
    } else if (uri == DART_INTERCEPTORS) {
      interceptorsLibrary = library;
    } else if (uri == DART_FOREIGN_HELPER) {
      foreignLibrary = library;
    } else if (uri == DART_ISOLATE_HELPER) {
      isolateHelperLibrary = library;
    }
  }

  void initializeHelperClasses(DiagnosticReporter reporter) {
    final List missingHelperClasses = [];
    ClassElement lookupHelperClass(String name) {
      ClassElement result = findHelper(name);
      if (result == null) {
        missingHelperClasses.add(name);
      }
      return result;
    }

    jsInvocationMirrorClass = lookupHelperClass('JSInvocationMirror');
    boundClosureClass = lookupHelperClass('BoundClosure');
    closureClass = lookupHelperClass('Closure');
    if (!missingHelperClasses.isEmpty) {
      reporter.internalError(
          jsHelperLibrary,
          'dart:_js_helper library does not contain required classes: '
          '$missingHelperClasses');
    }
  }

  void onLibraryScanned(LibraryElement library) {
    Uri uri = library.canonicalUri;

    FunctionElement findMethod(String name) {
      return find(library, name);
    }

    ClassElement findClass(String name) {
      return find(library, name);
    }

    if (uri == DART_INTERCEPTORS) {
      getInterceptorMethod = findMethod('getInterceptor');
      getNativeInterceptorMethod = findMethod('getNativeInterceptor');
      jsInterceptorClass = findClass('Interceptor');
      jsStringClass = findClass('JSString');
      jsArrayClass = findClass('JSArray');
      // The int class must be before the double class, because the
      // emitter relies on this list for the order of type checks.
      jsIntClass = findClass('JSInt');
      jsPositiveIntClass = findClass('JSPositiveInt');
      jsUInt32Class = findClass('JSUInt32');
      jsUInt31Class = findClass('JSUInt31');
      jsDoubleClass = findClass('JSDouble');
      jsNumberClass = findClass('JSNumber');
      jsNullClass = findClass('JSNull');
      jsBoolClass = findClass('JSBool');
      jsMutableArrayClass = findClass('JSMutableArray');
      jsFixedArrayClass = findClass('JSFixedArray');
      jsExtendableArrayClass = findClass('JSExtendableArray');
      jsUnmodifiableArrayClass = findClass('JSUnmodifiableArray');
      jsPlainJavaScriptObjectClass = findClass('PlainJavaScriptObject');
      jsJavaScriptObjectClass = findClass('JavaScriptObject');
      jsJavaScriptFunctionClass = findClass('JavaScriptFunction');
      jsUnknownJavaScriptObjectClass = findClass('UnknownJavaScriptObject');
      jsIndexableClass = findClass('JSIndexable');
      jsMutableIndexableClass = findClass('JSMutableIndexable');
    } else if (uri == DART_JS_HELPER) {
      initializeHelperClasses(reporter);
      assertTest = findHelper('assertTest');
      assertThrow = findHelper('assertThrow');
      assertHelper = findHelper('assertHelper');
      assertUnreachableMethod = findHelper('assertUnreachable');

      typeLiteralClass = findClass('TypeImpl');
      constMapLiteralClass = findClass('ConstantMap');
      typeVariableClass = findClass('TypeVariable');

      jsIndexingBehaviorInterface = findClass('JavaScriptIndexingBehavior');

      noSideEffectsClass = findClass('NoSideEffects');
      noThrowsClass = findClass('NoThrows');
      noInlineClass = findClass('NoInline');
      forceInlineClass = findClass('ForceInline');
      irRepresentationClass = findClass('IrRepresentation');

      getIsolateAffinityTagMarker = findMethod('getIsolateAffinityTag');

      requiresPreambleMarker = findMethod('requiresPreamble');
    } else if (uri == DART_JS_MIRRORS) {
      disableTreeShakingMarker = find(library, 'disableTreeShaking');
      preserveMetadataMarker = find(library, 'preserveMetadata');
      preserveUrisMarker = find(library, 'preserveUris');
      preserveLibraryNamesMarker = find(library, 'preserveLibraryNames');
    } else if (uri == DART_JS_NAMES) {
      preserveNamesMarker = find(library, 'preserveNames');
    } else if (uri == DART_EMBEDDED_NAMES) {
      jsGetNameEnum = find(library, 'JsGetName');
      jsBuiltinEnum = find(library, 'JsBuiltin');
    } else if (uri == Uris.dart__native_typed_data) {
      typedArrayClass = findClass('NativeTypedArray');
      typedArrayOfIntClass = findClass('NativeTypedArrayOfInt');
    } else if (uri == PACKAGE_JS) {
      jsAnnotationClass = find(library, 'JS');
      jsAnonymousClass = find(library, '_Anonymous');
    }
  }

  void onLibrariesLoaded(LoadedLibraries loadedLibraries) {
    assert(loadedLibraries.containsLibrary(Uris.dart_core));
    assert(loadedLibraries.containsLibrary(DART_INTERCEPTORS));
    assert(loadedLibraries.containsLibrary(DART_JS_HELPER));

    if (jsInvocationMirrorClass != null) {
      jsInvocationMirrorClass.ensureResolved(resolution);
      invokeOnMethod = jsInvocationMirrorClass.lookupLocalMember(INVOKE_ON);
    }

    // [LinkedHashMap] is reexported from dart:collection and can therefore not
    // be loaded from dart:core in [onLibraryScanned].
    mapLiteralClass = compiler.commonElements.coreLibrary.find('LinkedHashMap');
    assert(invariant(
        compiler.commonElements.coreLibrary, mapLiteralClass != null,
        message: "Element 'LinkedHashMap' not found in 'dart:core'."));

    // TODO(kasperl): Some tests do not define the special JSArray
    // subclasses, so we check to see if they are defined before
    // trying to resolve them.
    if (jsFixedArrayClass != null) {
      jsFixedArrayClass.ensureResolved(resolution);
    }
    if (jsExtendableArrayClass != null) {
      jsExtendableArrayClass.ensureResolved(resolution);
    }
    if (jsUnmodifiableArrayClass != null) {
      jsUnmodifiableArrayClass.ensureResolved(resolution);
    }

    jsIndexableClass.ensureResolved(resolution);
    Element jsIndexableLengthElement =
        compiler.lookupElementIn(jsIndexableClass, 'length');
    if (jsIndexableLengthElement != null &&
        jsIndexableLengthElement.isAbstractField) {
      AbstractFieldElement element = jsIndexableLengthElement;
      jsIndexableLength = element.getter;
    } else {
      jsIndexableLength = jsIndexableLengthElement;
    }

    jsArrayClass.ensureResolved(resolution);
    jsArrayTypedConstructor = compiler.lookupElementIn(jsArrayClass, 'typed');
    jsArrayRemoveLast = compiler.lookupElementIn(jsArrayClass, 'removeLast');
    jsArrayAdd = compiler.lookupElementIn(jsArrayClass, 'add');

    jsStringClass.ensureResolved(resolution);
    jsStringSplit = compiler.lookupElementIn(jsStringClass, 'split');
    jsStringOperatorAdd = compiler.lookupElementIn(jsStringClass, '+');
    jsStringToString = compiler.lookupElementIn(jsStringClass, 'toString');

    objectEquals = compiler.lookupElementIn(coreClasses.objectClass, '==');
  }

  ConstructorElement _mapLiteralConstructor;
  ConstructorElement _mapLiteralConstructorEmpty;
  Element _mapLiteralUntypedMaker;
  Element _mapLiteralUntypedEmptyMaker;

  ConstructorElement get mapLiteralConstructor {
    _ensureMapLiteralHelpers();
    return _mapLiteralConstructor;
  }

  ConstructorElement get mapLiteralConstructorEmpty {
    _ensureMapLiteralHelpers();
    return _mapLiteralConstructorEmpty;
  }

  Element get mapLiteralUntypedMaker {
    _ensureMapLiteralHelpers();
    return _mapLiteralUntypedMaker;
  }

  Element get mapLiteralUntypedEmptyMaker {
    _ensureMapLiteralHelpers();
    return _mapLiteralUntypedEmptyMaker;
  }

  void _ensureMapLiteralHelpers() {
    if (_mapLiteralConstructor != null) return;

    // For map literals, the dependency between the implementation class
    // and [Map] is not visible, so we have to add it manually.
    Element getFactory(String name, int arity) {
      // The constructor is on the patch class, but dart2js unit tests don't
      // have a patch class.
      ClassElement implementation = mapLiteralClass.implementation;
      ConstructorElement ctor = implementation.lookupConstructor(name);
      if (ctor == null ||
          (Name.isPrivateName(name) &&
              ctor.library != mapLiteralClass.library)) {
        reporter.internalError(
            mapLiteralClass,
            "Map literal class ${mapLiteralClass} missing "
            "'$name' constructor"
            "  ${mapLiteralClass.constructors}");
      }
      return ctor;
    }

    Element getMember(String name) {
      // The constructor is on the patch class, but dart2js unit tests don't
      // have a patch class.
      ClassElement implementation = mapLiteralClass.implementation;
      Element element = implementation.lookupLocalMember(name);
      if (element == null || !element.isFunction || !element.isStatic) {
        reporter.internalError(
            mapLiteralClass,
            "Map literal class ${mapLiteralClass} missing "
            "'$name' static member function");
      }
      return element;
    }

    _mapLiteralConstructor = getFactory('_literal', 1);
    _mapLiteralConstructorEmpty = getFactory('_empty', 0);
    _mapLiteralUntypedMaker = getMember('_makeLiteral');
    _mapLiteralUntypedEmptyMaker = getMember('_makeEmpty');
  }

  Element get badMain {
    return findHelper('badMain');
  }

  Element get missingMain {
    return findHelper('missingMain');
  }

  Element get mainHasTooManyParameters {
    return findHelper('mainHasTooManyParameters');
  }

  MethodElement get loadLibraryWrapper {
    return findHelper("_loadLibraryWrapper");
  }

  Element get boolConversionCheck {
    return findHelper('boolConversionCheck');
  }

  MethodElement _traceHelper;

  MethodElement get traceHelper {
    return _traceHelper ??= JavaScriptBackend.TRACE_METHOD == 'console'
        ? _consoleTraceHelper
        : _postTraceHelper;
  }

  MethodElement get _consoleTraceHelper {
    return findHelper('consoleTraceHelper');
  }

  MethodElement get _postTraceHelper {
    return findHelper('postTraceHelper');
  }

  FunctionElement get closureFromTearOff {
    return findHelper('closureFromTearOff');
  }

  Element get isJsIndexable {
    return findHelper('isJsIndexable');
  }

  Element get throwIllegalArgumentException {
    return findHelper('iae');
  }

  Element get throwIndexOutOfRangeException {
    return findHelper('ioore');
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

  Element get checkInt => _checkInt ??= findHelper('checkInt');
  Element _checkInt;

  Element get checkNum => _checkNum ??= findHelper('checkNum');
  Element _checkNum;

  Element get checkString => _checkString ??= findHelper('checkString');
  Element _checkString;

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

  Element get genericNoSuchMethod =>
      _genericNoSuchMethod ??= findCoreHelper('_genericNoSuchMethod');
  MethodElement _genericNoSuchMethod;

  Element get unresolvedConstructorError => _unresolvedConstructorError ??=
      findCoreHelper('_unresolvedConstructorError');
  MethodElement _unresolvedConstructorError;

  Element get malformedTypeError =>
      _malformedTypeError ??= findCoreHelper('_malformedTypeError');
  MethodElement _malformedTypeError;

  Element get createRuntimeType {
    return findHelper('createRuntimeType');
  }

  Element get fallThroughError {
    return findHelper("getFallThroughError");
  }

  Element get createInvocationMirror {
    return findHelper('createInvocationMirror');
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

  Element get futureImplementation {
    ClassElement classElement = findAsyncHelper('_Future');
    classElement.ensureResolved(resolution);
    return classElement;
  }

  Element get controllerStream {
    ClassElement classElement = findAsyncHelper("_ControllerStream");
    classElement.ensureResolved(resolution);
    return classElement;
  }

  Element get syncStarIterableConstructor {
    ClassElement classElement = syncStarIterable;
    classElement.ensureResolved(resolution);
    return classElement.lookupConstructor("");
  }

  Element get syncCompleterConstructor {
    ClassElement classElement = find(asyncLibrary, "Completer");
    classElement.ensureResolved(resolution);
    return classElement.lookupConstructor("sync");
  }

  Element get asyncStarController {
    ClassElement classElement = findAsyncHelper("_AsyncStarStreamController");
    classElement.ensureResolved(resolution);
    return classElement;
  }

  Element get asyncStarControllerConstructor {
    ClassElement classElement = asyncStarController;
    return classElement.lookupConstructor("");
  }

  Element get streamIteratorConstructor {
    ClassElement classElement = find(asyncLibrary, "StreamIterator");
    classElement.ensureResolved(resolution);
    return classElement.lookupConstructor("");
  }

  ClassElement get VoidRuntimeType {
    return findHelper('VoidRuntimeType');
  }

  ClassElement get RuntimeType {
    return findHelper('RuntimeType');
  }

  ClassElement get RuntimeFunctionType {
    return findHelper('RuntimeFunctionType');
  }

  ClassElement get RuntimeTypePlain {
    return findHelper('RuntimeTypePlain');
  }

  ClassElement get RuntimeTypeGeneric {
    return findHelper('RuntimeTypeGeneric');
  }

  ClassElement get DynamicRuntimeType {
    return findHelper('DynamicRuntimeType');
  }

  MethodElement get functionTypeTestMetaHelper {
    return findHelper('functionTypeTestMetaHelper');
  }

  MethodElement get defineProperty {
    return findHelper('defineProperty');
  }

  Element get startRootIsolate {
    return find(isolateHelperLibrary, START_ROOT_ISOLATE);
  }

  Element get currentIsolate {
    return find(isolateHelperLibrary, '_currentIsolate');
  }

  Element get callInIsolate {
    return find(isolateHelperLibrary, '_callInIsolate');
  }

  Element get findIndexForNativeSubclassType {
    return findInterceptor('findIndexForNativeSubclassType');
  }

  Element get convertRtiToRuntimeType {
    return findHelper('convertRtiToRuntimeType');
  }

  ClassElement get stackTraceClass {
    return findHelper('_StackTrace');
  }

  MethodElement _objectNoSuchMethod;

  MethodElement get objectNoSuchMethod {
    if (_objectNoSuchMethod == null) {
      _objectNoSuchMethod =
          coreClasses.objectClass.lookupLocalMember(Identifiers.noSuchMethod_);
    }
    return _objectNoSuchMethod;
  }
}
