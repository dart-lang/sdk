// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_backend.helpers;

import '../common.dart';
import '../common/names.dart' show Identifiers, Uris;
import '../common_elements.dart' show CommonElements, ElementEnvironment;
import '../elements/elements.dart' show PublicName;
import '../elements/entities.dart';
import '../library_loader.dart' show LoadedLibraries;
import '../universe/call_structure.dart' show CallStructure;
import '../universe/selector.dart' show Selector;
import 'constant_system_javascript.dart';
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

  final ElementEnvironment _env;

  final CommonElements commonElements;

  BackendHelpers(this._env, this.commonElements);

  ClassEntity _findInterceptorsClass(String name) =>
      _findClass(interceptorsLibrary, name);

  FunctionEntity _findInterceptorsFunction(String name) =>
      _findLibraryMember(interceptorsLibrary, name);

  ClassEntity _findHelperClass(String name) =>
      _findClass(jsHelperLibrary, name);

  // TODO(johnniwinther): Avoid the need for this (from [CheckedModeHelper]).
  FunctionEntity findHelperFunction(String name) => _findHelperFunction(name);

  FunctionEntity _findHelperFunction(String name) =>
      _findLibraryMember(jsHelperLibrary, name);

  ClassEntity _findAsyncHelperClass(String name) =>
      _findClass(asyncLibrary, name);

  FunctionEntity _findAsyncHelperFunction(String name) =>
      _findLibraryMember(asyncLibrary, name);

  FunctionEntity _findMirrorsFunction(String name) {
    LibraryEntity library = _env.lookupLibrary(DART_JS_MIRRORS);
    if (library == null) return null;
    return _env.lookupLibraryMember(library, name, required: true);
  }

  ClassEntity _findClass(LibraryEntity library, String name) {
    return _env.lookupClass(library, name, required: true);
  }

  MemberEntity _findClassMember(ClassEntity cls, String name) {
    return _env.lookupClassMember(cls, name, required: true);
  }

  MemberEntity _findLibraryMember(LibraryEntity library, String name) {
    return _env.lookupLibraryMember(library, name, required: true);
  }

  FunctionEntity findCoreHelper(String name) => _env
      .lookupLibraryMember(commonElements.coreLibrary, name, required: true);

  ConstructorEntity _findConstructor(ClassEntity cls, String name) =>
      _env.lookupConstructor(cls, name, required: true);

  void onLibrariesLoaded(LoadedLibraries loadedLibraries) {
    assert(loadedLibraries.containsLibrary(Uris.dart_core));
    assert(loadedLibraries.containsLibrary(DART_INTERCEPTORS));
    assert(loadedLibraries.containsLibrary(DART_JS_HELPER));
  }

  void onResolutionStart() {
    // TODO(johnniwinther): Avoid these. Currently needed to ensure resolution
    // of the classes for various queries in native behavior computation,
    // inference and codegen.
    _env.getThisType(jsArrayClass);
    _env.getThisType(jsExtendableArrayClass);
  }

  LibraryEntity _jsHelperLibrary;
  LibraryEntity get jsHelperLibrary =>
      _jsHelperLibrary ??= _env.lookupLibrary(DART_JS_HELPER);

  LibraryEntity _asyncLibrary;
  LibraryEntity get asyncLibrary =>
      _asyncLibrary ??= _env.lookupLibrary(Uris.dart_async);

  LibraryEntity _interceptorsLibrary;
  LibraryEntity get interceptorsLibrary =>
      _interceptorsLibrary ??= _env.lookupLibrary(DART_INTERCEPTORS);

  LibraryEntity _foreignLibrary;
  LibraryEntity get foreignLibrary =>
      _foreignLibrary ??= _env.lookupLibrary(DART_FOREIGN_HELPER);

  LibraryEntity _isolateHelperLibrary;
  LibraryEntity get isolateHelperLibrary =>
      _isolateHelperLibrary ??= _env.lookupLibrary(DART_ISOLATE_HELPER);

  /// Reference to the internal library to lookup functions to always inline.
  LibraryEntity _internalLibrary;
  LibraryEntity get internalLibrary =>
      _internalLibrary ??= _env.lookupLibrary(Uris.dart__internal);

  FunctionEntity _assertTest;
  FunctionEntity get assertTest =>
      _assertTest ??= _findHelperFunction('assertTest');

  FunctionEntity _assertThrow;
  FunctionEntity get assertThrow =>
      _assertThrow ??= _findHelperFunction('assertThrow');

  FunctionEntity _assertHelper;
  FunctionEntity get assertHelper =>
      _assertHelper ??= _findHelperFunction('assertHelper');

  FunctionEntity _assertUnreachableMethod;
  FunctionEntity get assertUnreachableMethod =>
      _assertUnreachableMethod ??= _findHelperFunction('assertUnreachable');

  ClassEntity _closureClass;
  ClassEntity get closureClass => _closureClass ??= _findHelperClass('Closure');

  ClassEntity _boundClosureClass;
  ClassEntity get boundClosureClass =>
      _boundClosureClass ??= _findHelperClass('BoundClosure');

  FunctionEntity _invokeOnMethod;
  FunctionEntity get invokeOnMethod => _invokeOnMethod ??=
      _env.lookupClassMember(jsInvocationMirrorClass, INVOKE_ON);

  ClassEntity _jsInterceptorClass;
  ClassEntity get jsInterceptorClass =>
      _jsInterceptorClass ??= _findInterceptorsClass('Interceptor');

  ClassEntity _jsStringClass;
  ClassEntity get jsStringClass =>
      _jsStringClass ??= _findInterceptorsClass('JSString');

  ClassEntity _jsArrayClass;
  ClassEntity get jsArrayClass =>
      _jsArrayClass ??= _findInterceptorsClass('JSArray');

  ClassEntity _jsNumberClass;
  ClassEntity get jsNumberClass =>
      _jsNumberClass ??= _findInterceptorsClass('JSNumber');

  ClassEntity _jsIntClass;
  ClassEntity get jsIntClass => _jsIntClass ??= _findInterceptorsClass('JSInt');

  ClassEntity _jsDoubleClass;
  ClassEntity get jsDoubleClass =>
      _jsDoubleClass ??= _findInterceptorsClass('JSDouble');

  ClassEntity _jsNullClass;
  ClassEntity get jsNullClass =>
      _jsNullClass ??= _findInterceptorsClass('JSNull');

  ClassEntity _jsBoolClass;
  ClassEntity get jsBoolClass =>
      _jsBoolClass ??= _findInterceptorsClass('JSBool');

  ClassEntity _jsPlainJavaScriptObjectClass;
  ClassEntity get jsPlainJavaScriptObjectClass =>
      _jsPlainJavaScriptObjectClass ??=
          _findInterceptorsClass('PlainJavaScriptObject');

  ClassEntity _jsUnknownJavaScriptObjectClass;
  ClassEntity get jsUnknownJavaScriptObjectClass =>
      _jsUnknownJavaScriptObjectClass ??=
          _findInterceptorsClass('UnknownJavaScriptObject');

  ClassEntity _jsJavaScriptFunctionClass;
  ClassEntity get jsJavaScriptFunctionClass => _jsJavaScriptFunctionClass ??=
      _findInterceptorsClass('JavaScriptFunction');

  ClassEntity _jsJavaScriptObjectClass;
  ClassEntity get jsJavaScriptObjectClass =>
      _jsJavaScriptObjectClass ??= _findInterceptorsClass('JavaScriptObject');

  ClassEntity _jsIndexableClass;
  ClassEntity get jsIndexableClass =>
      _jsIndexableClass ??= _findInterceptorsClass('JSIndexable');

  ClassEntity _jsMutableIndexableClass;
  ClassEntity get jsMutableIndexableClass =>
      _jsMutableIndexableClass ??= _findInterceptorsClass('JSMutableIndexable');

  ClassEntity _jsMutableArrayClass;
  ClassEntity get jsMutableArrayClass =>
      _jsMutableArrayClass ??= _findInterceptorsClass('JSMutableArray');

  ClassEntity _jsFixedArrayClass;
  ClassEntity get jsFixedArrayClass =>
      _jsFixedArrayClass ??= _findInterceptorsClass('JSFixedArray');

  ClassEntity _jsExtendableArrayClass;
  ClassEntity get jsExtendableArrayClass =>
      _jsExtendableArrayClass ??= _findInterceptorsClass('JSExtendableArray');

  ClassEntity _jsUnmodifiableArrayClass;
  ClassEntity get jsUnmodifiableArrayClass => _jsUnmodifiableArrayClass ??=
      _findInterceptorsClass('JSUnmodifiableArray');

  ClassEntity _jsPositiveIntClass;
  ClassEntity get jsPositiveIntClass =>
      _jsPositiveIntClass ??= _findInterceptorsClass('JSPositiveInt');

  ClassEntity _jsUInt32Class;
  ClassEntity get jsUInt32Class =>
      _jsUInt32Class ??= _findInterceptorsClass('JSUInt32');

  ClassEntity _jsUInt31Class;
  ClassEntity get jsUInt31Class =>
      _jsUInt31Class ??= _findInterceptorsClass('JSUInt31');

  MemberEntity _jsIndexableLength;
  MemberEntity get jsIndexableLength =>
      _jsIndexableLength ??= _findClassMember(jsIndexableClass, 'length');

  ConstructorEntity _jsArrayTypedConstructor;
  ConstructorEntity get jsArrayTypedConstructor =>
      _jsArrayTypedConstructor ??= _findConstructor(jsArrayClass, 'typed');

  FunctionEntity _jsArrayRemoveLast;
  FunctionEntity get jsArrayRemoveLast =>
      _jsArrayRemoveLast ??= _findClassMember(jsArrayClass, 'removeLast');

  FunctionEntity _jsArrayAdd;
  FunctionEntity get jsArrayAdd =>
      _jsArrayAdd ??= _findClassMember(jsArrayClass, 'add');

  FunctionEntity _jsStringSplit;
  FunctionEntity get jsStringSplit =>
      _jsStringSplit ??= _findClassMember(jsStringClass, 'split');

  FunctionEntity _jsStringToString;
  FunctionEntity get jsStringToString =>
      _jsStringToString ??= _findClassMember(jsStringClass, 'toString');

  FunctionEntity _jsStringOperatorAdd;
  FunctionEntity get jsStringOperatorAdd =>
      _jsStringOperatorAdd ??= _findClassMember(jsStringClass, '+');

  FunctionEntity _objectEquals;
  FunctionEntity get objectEquals =>
      _objectEquals ??= _findClassMember(commonElements.objectClass, '==');

  ClassEntity _typeLiteralClass;
  ClassEntity get typeLiteralClass =>
      _typeLiteralClass ??= _findHelperClass('TypeImpl');

  ClassEntity _mapLiteralClass;
  ClassEntity get mapLiteralClass {
    if (_mapLiteralClass == null) {
      _mapLiteralClass =
          _env.lookupClass(commonElements.coreLibrary, 'LinkedHashMap');
      if (_mapLiteralClass == null) {
        _mapLiteralClass = _findClass(
            _env.lookupLibrary(Uris.dart_collection), 'LinkedHashMap');
      }
    }
    return _mapLiteralClass;
  }

  ClassEntity _constMapLiteralClass;
  ClassEntity get constMapLiteralClass =>
      _constMapLiteralClass ??= _findHelperClass('ConstantMap');

  ClassEntity _typeVariableClass;
  ClassEntity get typeVariableClass =>
      _typeVariableClass ??= _findHelperClass('TypeVariable');

  ConstructorEntity _typeVariableConstructor;
  ConstructorEntity get typeVariableConstructor => _typeVariableConstructor ??=
      _env.lookupConstructor(typeVariableClass, '');

  ClassEntity _noSideEffectsClass;
  ClassEntity get noSideEffectsClass =>
      _noSideEffectsClass ??= _findHelperClass('NoSideEffects');

  ClassEntity _noThrowsClass;
  ClassEntity get noThrowsClass =>
      _noThrowsClass ??= _findHelperClass('NoThrows');

  ClassEntity _noInlineClass;
  ClassEntity get noInlineClass =>
      _noInlineClass ??= _findHelperClass('NoInline');

  ClassEntity _forceInlineClass;
  ClassEntity get forceInlineClass =>
      _forceInlineClass ??= _findHelperClass('ForceInline');

  ClassEntity _irRepresentationClass;
  ClassEntity get irRepresentationClass =>
      _irRepresentationClass ??= _findHelperClass('IrRepresentation');

  ClassEntity _jsAnnotationClass;
  ClassEntity get jsAnnotationClass {
    if (_jsAnnotationClass == null) {
      LibraryEntity library = _env.lookupLibrary(PACKAGE_JS);
      if (library == null) return null;
      _jsAnnotationClass = _findClass(library, 'JS');
    }
    return _jsAnnotationClass;
  }

  ClassEntity _jsAnonymousClass;
  ClassEntity get jsAnonymousClass {
    if (_jsAnonymousClass == null) {
      LibraryEntity library = _env.lookupLibrary(PACKAGE_JS);
      if (library == null) return null;
      _jsAnonymousClass = _findClass(library, '_Anonymous');
    }
    return _jsAnonymousClass;
  }

  FunctionEntity _getInterceptorMethod;
  FunctionEntity get getInterceptorMethod =>
      _getInterceptorMethod ??= _findInterceptorsFunction('getInterceptor');

  ClassEntity _jsInvocationMirrorClass;
  ClassEntity get jsInvocationMirrorClass =>
      _jsInvocationMirrorClass ??= _findHelperClass('JSInvocationMirror');

  ClassEntity _typedArrayClass;
  ClassEntity get typedArrayClass => _typedArrayClass ??= _findClass(
      _env.lookupLibrary(Uris.dart__native_typed_data, required: true),
      'NativeTypedArray');

  ClassEntity _typedArrayOfIntClass;
  ClassEntity get typedArrayOfIntClass => _typedArrayOfIntClass ??= _findClass(
      _env.lookupLibrary(Uris.dart__native_typed_data, required: true),
      'NativeTypedArrayOfInt');

  /**
   * Interface used to determine if an object has the JavaScript
   * indexing behavior. The interface is only visible to specific
   * libraries.
   */
  ClassEntity _jsIndexingBehaviorInterface;
  ClassEntity get jsIndexingBehaviorInterface =>
      _jsIndexingBehaviorInterface ??=
          _findHelperClass('JavaScriptIndexingBehavior');

  FunctionEntity _getNativeInterceptorMethod;
  FunctionEntity get getNativeInterceptorMethod =>
      _getNativeInterceptorMethod ??=
          _findInterceptorsFunction('getNativeInterceptor');

  /// Holds the method "getIsolateAffinityTag" when dart:_js_helper has been
  /// loaded.
  FunctionEntity _getIsolateAffinityTagMarker;
  FunctionEntity get getIsolateAffinityTagMarker =>
      _getIsolateAffinityTagMarker ??=
          _findHelperFunction('getIsolateAffinityTag');

  /// Holds the method "disableTreeShaking" in js_mirrors when
  /// dart:mirrors has been loaded.
  FunctionEntity _disableTreeShakingMarker;
  FunctionEntity get disableTreeShakingMarker =>
      _disableTreeShakingMarker ??= _findMirrorsFunction('disableTreeShaking');

  /// Holds the method "preserveNames" in js_mirrors when
  /// dart:mirrors has been loaded.
  FunctionEntity _preserveNamesMarker;
  FunctionEntity get preserveNamesMarker {
    if (_preserveNamesMarker == null) {
      LibraryEntity library = _env.lookupLibrary(DART_JS_NAMES);
      if (library != null) {
        _preserveNamesMarker = _findLibraryMember(library, 'preserveNames');
      }
    }
    return _preserveNamesMarker;
  }

  /// Holds the method "preserveMetadata" in js_mirrors when
  /// dart:mirrors has been loaded.
  FunctionEntity _preserveMetadataMarker;
  FunctionEntity get preserveMetadataMarker =>
      _preserveMetadataMarker ??= _findMirrorsFunction('preserveMetadata');

  /// Holds the method "preserveUris" in js_mirrors when
  /// dart:mirrors has been loaded.
  FunctionEntity _preserveUrisMarker;
  FunctionEntity get preserveUrisMarker =>
      _preserveUrisMarker ??= _findMirrorsFunction('preserveUris');

  /// Holds the method "preserveLibraryNames" in js_mirrors when
  /// dart:mirrors has been loaded.
  FunctionEntity _preserveLibraryNamesMarker;
  FunctionEntity get preserveLibraryNamesMarker =>
      _preserveLibraryNamesMarker ??=
          _findMirrorsFunction('preserveLibraryNames');

  /// Holds the method "requiresPreamble" in _js_helper.
  FunctionEntity _requiresPreambleMarker;
  FunctionEntity get requiresPreambleMarker =>
      _requiresPreambleMarker ??= _findHelperFunction('requiresPreamble');

  /// Holds the class for the [JsGetName] enum.
  ClassEntity _jsGetNameEnum;
  ClassEntity get jsGetNameEnum => _jsGetNameEnum ??= _findClass(
      _env.lookupLibrary(DART_EMBEDDED_NAMES, required: true), 'JsGetName');

  /// Holds the class for the [JsBuiltins] enum.
  ClassEntity _jsBuiltinEnum;
  ClassEntity get jsBuiltinEnum => _jsBuiltinEnum ??= _findClass(
      _env.lookupLibrary(DART_EMBEDDED_NAMES, required: true), 'JsBuiltin');

  final Selector symbolValidatedConstructorSelector =
      new Selector.call(const PublicName('validated'), CallStructure.ONE_ARG);

  ConstructorEntity get symbolValidatedConstructor =>
      _symbolValidatedConstructor ??= _findConstructor(
          symbolImplementationClass, symbolValidatedConstructorSelector.name);

  ClassEntity _symbolImplementationClass;
  ClassEntity get symbolImplementationClass =>
      _symbolImplementationClass ??= _findClass(internalLibrary, 'Symbol');

  FieldEntity _symbolImplementationField;

  /// Returns the field that holds the internal name in the implementation class
  /// for `Symbol`.
  FieldEntity get symbolImplementationField => _symbolImplementationField ??=
      _env.lookupClassMember(symbolImplementationClass, '_name',
          required: true);

  ConstructorEntity _symbolValidatedConstructor;

  bool isSymbolValidatedConstructor(ConstructorEntity element) {
    if (_symbolValidatedConstructor != null) {
      return element == _symbolValidatedConstructor;
    }
    return false;
  }

  ConstructorEntity _mapLiteralConstructor;
  ConstructorEntity _mapLiteralConstructorEmpty;
  FunctionEntity _mapLiteralUntypedMaker;
  FunctionEntity _mapLiteralUntypedEmptyMaker;

  ConstructorEntity get mapLiteralConstructor {
    _ensureMapLiteralHelpers();
    return _mapLiteralConstructor;
  }

  ConstructorEntity get mapLiteralConstructorEmpty {
    _ensureMapLiteralHelpers();
    return _mapLiteralConstructorEmpty;
  }

  FunctionEntity get mapLiteralUntypedMaker {
    _ensureMapLiteralHelpers();
    return _mapLiteralUntypedMaker;
  }

  FunctionEntity get mapLiteralUntypedEmptyMaker {
    _ensureMapLiteralHelpers();
    return _mapLiteralUntypedEmptyMaker;
  }

  void _ensureMapLiteralHelpers() {
    if (_mapLiteralConstructor != null) return;

    _mapLiteralConstructor =
        _env.lookupConstructor(mapLiteralClass, '_literal');
    _mapLiteralConstructorEmpty =
        _env.lookupConstructor(mapLiteralClass, '_empty');
    _mapLiteralUntypedMaker =
        _env.lookupClassMember(mapLiteralClass, '_makeLiteral');
    _mapLiteralUntypedEmptyMaker =
        _env.lookupClassMember(mapLiteralClass, '_makeEmpty');
  }

  FunctionEntity get badMain {
    return _findHelperFunction('badMain');
  }

  FunctionEntity get missingMain {
    return _findHelperFunction('missingMain');
  }

  FunctionEntity get mainHasTooManyParameters {
    return _findHelperFunction('mainHasTooManyParameters');
  }

  FunctionEntity get loadLibraryWrapper {
    return _findHelperFunction("_loadLibraryWrapper");
  }

  FunctionEntity get boolConversionCheck {
    return _findHelperFunction('boolConversionCheck');
  }

  FunctionEntity _traceHelper;

  FunctionEntity get traceHelper {
    return _traceHelper ??= JavaScriptBackend.TRACE_METHOD == 'console'
        ? _consoleTraceHelper
        : _postTraceHelper;
  }

  FunctionEntity get _consoleTraceHelper =>
      _findHelperFunction('consoleTraceHelper');

  FunctionEntity get _postTraceHelper => _findHelperFunction('postTraceHelper');

  FunctionEntity get closureFromTearOff =>
      _findHelperFunction('closureFromTearOff');

  FunctionEntity get isJsIndexable => _findHelperFunction('isJsIndexable');

  FunctionEntity get throwIllegalArgumentException =>
      _findHelperFunction('iae');

  FunctionEntity get throwIndexOutOfRangeException =>
      _findHelperFunction('ioore');

  FunctionEntity get exceptionUnwrapper =>
      _findHelperFunction('unwrapException');

  FunctionEntity get throwRuntimeError =>
      _findHelperFunction('throwRuntimeError');

  FunctionEntity get throwTypeError => _findHelperFunction('throwTypeError');

  FunctionEntity get throwAbstractClassInstantiationError =>
      _findHelperFunction('throwAbstractClassInstantiationError');

  FunctionEntity _cachedCheckConcurrentModificationError;
  FunctionEntity get checkConcurrentModificationError =>
      _cachedCheckConcurrentModificationError ??=
          _findHelperFunction('checkConcurrentModificationError');

  FunctionEntity get throwConcurrentModificationError =>
      _findHelperFunction('throwConcurrentModificationError');

  FunctionEntity _checkInt;
  FunctionEntity get checkInt => _checkInt ??= _findHelperFunction('checkInt');

  FunctionEntity _checkNum;
  FunctionEntity get checkNum => _checkNum ??= _findHelperFunction('checkNum');

  FunctionEntity _checkString;
  FunctionEntity get checkString =>
      _checkString ??= _findHelperFunction('checkString');

  FunctionEntity get stringInterpolationHelper => _findHelperFunction('S');

  FunctionEntity get wrapExceptionHelper =>
      _findHelperFunction('wrapException');

  FunctionEntity get throwExpressionHelper =>
      _findHelperFunction('throwExpression');

  FunctionEntity get closureConverter =>
      _findHelperFunction('convertDartClosureToJS');

  FunctionEntity get traceFromException =>
      _findHelperFunction('getTraceFromException');

  FunctionEntity get setRuntimeTypeInfo =>
      _findHelperFunction('setRuntimeTypeInfo');

  FunctionEntity get getRuntimeTypeInfo =>
      _findHelperFunction('getRuntimeTypeInfo');

  FunctionEntity get getTypeArgumentByIndex =>
      _findHelperFunction('getTypeArgumentByIndex');

  FunctionEntity get computeSignature =>
      _findHelperFunction('computeSignature');

  FunctionEntity get getRuntimeTypeArguments =>
      _findHelperFunction('getRuntimeTypeArguments');

  FunctionEntity get getRuntimeTypeArgument =>
      _findHelperFunction('getRuntimeTypeArgument');

  FunctionEntity get runtimeTypeToString =>
      _findHelperFunction('runtimeTypeToString');

  FunctionEntity get assertIsSubtype => _findHelperFunction('assertIsSubtype');

  FunctionEntity get checkSubtype => _findHelperFunction('checkSubtype');

  FunctionEntity get assertSubtype => _findHelperFunction('assertSubtype');

  FunctionEntity get subtypeCast => _findHelperFunction('subtypeCast');

  FunctionEntity get functionTypeTest =>
      _findHelperFunction('functionTypeTest');

  FunctionEntity get checkSubtypeOfRuntimeType =>
      _findHelperFunction('checkSubtypeOfRuntimeType');

  FunctionEntity get assertSubtypeOfRuntimeType =>
      _findHelperFunction('assertSubtypeOfRuntimeType');

  FunctionEntity get subtypeOfRuntimeTypeCast =>
      _findHelperFunction('subtypeOfRuntimeTypeCast');

  FunctionEntity get checkDeferredIsLoaded =>
      _findHelperFunction('checkDeferredIsLoaded');

  FunctionEntity get throwNoSuchMethod =>
      _findHelperFunction('throwNoSuchMethod');

  FunctionEntity get malformedTypeError =>
      _cachedCoreHelper('_malformedTypeError');
  FunctionEntity get genericNoSuchMethod =>
      _cachedCoreHelper('_genericNoSuchMethod');
  FunctionEntity get unresolvedConstructorError =>
      _cachedCoreHelper('_unresolvedConstructorError');
  FunctionEntity get unresolvedStaticGetterError =>
      _cachedCoreHelper('_unresolvedStaticGetterError');
  FunctionEntity get unresolvedStaticSetterError =>
      _cachedCoreHelper('_unresolvedStaticSetterError');
  FunctionEntity get unresolvedStaticMethodError =>
      _cachedCoreHelper('_unresolvedStaticMethodError');
  FunctionEntity get unresolvedTopLevelGetterError =>
      _cachedCoreHelper('_unresolvedTopLevelGetterError');
  FunctionEntity get unresolvedTopLevelSetterError =>
      _cachedCoreHelper('_unresolvedTopLevelSetterError');
  FunctionEntity get unresolvedTopLevelMethodError =>
      _cachedCoreHelper('_unresolvedTopLevelMethodError');

  Map<String, FunctionEntity> _cachedCoreHelpers = <String, FunctionEntity>{};
  FunctionEntity _cachedCoreHelper(String name) =>
      _cachedCoreHelpers[name] ??= findCoreHelper(name);

  FunctionEntity get createRuntimeType =>
      _findHelperFunction('createRuntimeType');

  FunctionEntity get fallThroughError =>
      _findHelperFunction("getFallThroughError");

  FunctionEntity get createInvocationMirror =>
      _findHelperFunction('createInvocationMirror');

  FunctionEntity get cyclicThrowHelper =>
      _findHelperFunction("throwCyclicInit");

  FunctionEntity get asyncHelper => _findAsyncHelperFunction("_asyncHelper");

  FunctionEntity get wrapBody =>
      _findAsyncHelperFunction("_wrapJsFunctionForAsync");

  FunctionEntity get yieldStar => _env.lookupClassMember(
      _findAsyncHelperClass("_IterationMarker"), "yieldStar");

  FunctionEntity get yieldSingle => _env.lookupClassMember(
      _findAsyncHelperClass("_IterationMarker"), "yieldSingle");

  FunctionEntity get syncStarUncaughtError => _env.lookupClassMember(
      _findAsyncHelperClass("_IterationMarker"), "uncaughtError");

  FunctionEntity get asyncStarHelper =>
      _findAsyncHelperFunction("_asyncStarHelper");

  FunctionEntity get streamOfController =>
      _findAsyncHelperFunction("_streamOfController");

  FunctionEntity get endOfIteration => _env.lookupClassMember(
      _findAsyncHelperClass("_IterationMarker"), "endOfIteration");

  ClassEntity get syncStarIterable =>
      _findAsyncHelperClass("_SyncStarIterable");

  ClassEntity get futureImplementation => _findAsyncHelperClass('_Future');

  ClassEntity get controllerStream =>
      _findAsyncHelperClass("_ControllerStream");

  ConstructorEntity get syncStarIterableConstructor =>
      _env.lookupConstructor(syncStarIterable, "");

  ConstructorEntity get syncCompleterConstructor =>
      _env.lookupConstructor(_findAsyncHelperClass("Completer"), "sync");

  ClassEntity get asyncStarController =>
      _findAsyncHelperClass("_AsyncStarStreamController");

  ConstructorEntity get asyncStarControllerConstructor =>
      _env.lookupConstructor(asyncStarController, "", required: true);

  ConstructorEntity get streamIteratorConstructor =>
      _env.lookupConstructor(_findAsyncHelperClass("StreamIterator"), "");

  ClassEntity get VoidRuntimeType => _findHelperClass('VoidRuntimeType');

  FunctionEntity get defineProperty => _findHelperFunction('defineProperty');

  FunctionEntity get startRootIsolate =>
      _findLibraryMember(isolateHelperLibrary, START_ROOT_ISOLATE);

  FunctionEntity get currentIsolate =>
      _findLibraryMember(isolateHelperLibrary, '_currentIsolate');

  FunctionEntity get callInIsolate =>
      _findLibraryMember(isolateHelperLibrary, '_callInIsolate');

  FunctionEntity _findIndexForNativeSubclassType;
  FunctionEntity get findIndexForNativeSubclassType =>
      _findIndexForNativeSubclassType ??= _findLibraryMember(
          interceptorsLibrary, 'findIndexForNativeSubclassType');

  FunctionEntity get convertRtiToRuntimeType =>
      _findHelperFunction('convertRtiToRuntimeType');

  ClassEntity get stackTraceClass => _findHelperClass('_StackTrace');

  FunctionEntity _objectNoSuchMethod;
  FunctionEntity get objectNoSuchMethod {
    return _objectNoSuchMethod ??= _env.lookupClassMember(
        commonElements.objectClass, Identifiers.noSuchMethod_);
  }

  bool isDefaultNoSuchMethodImplementation(FunctionEntity element) {
    ClassEntity classElement = element.enclosingClass;
    return classElement == commonElements.objectClass ||
        classElement == jsInterceptorClass ||
        classElement == jsNullClass;
  }

  ClassEntity get constantMapClass =>
      _findHelperClass(JavaScriptMapConstant.DART_CLASS);
  ClassEntity get constantStringMapClass =>
      _findHelperClass(JavaScriptMapConstant.DART_STRING_CLASS);
  ClassEntity get constantProtoMapClass =>
      _findHelperClass(JavaScriptMapConstant.DART_PROTO_CLASS);
  ClassEntity get generalConstantMapClass =>
      _findHelperClass(JavaScriptMapConstant.DART_GENERAL_CLASS);

  ClassEntity get annotationCreatesClass => _findHelperClass('Creates');

  ClassEntity get annotationReturnsClass => _findHelperClass('Returns');

  ClassEntity get annotationJSNameClass => _findHelperClass('JSName');

  FunctionEntity get toStringForNativeObject =>
      _findHelperFunction('toStringForNativeObject');

  FunctionEntity get hashCodeForNativeObject =>
      _findHelperFunction('hashCodeForNativeObject');

  ClassEntity _patchAnnotationClass;

  /// The class for patch annotations defined in dart:_js_helper.
  ClassEntity get patchAnnotationClass =>
      _patchAnnotationClass ??= _findHelperClass('_Patch');

  ClassEntity _nativeAnnotationClass;

  /// The class for native annotations defined in dart:_js_helper.
  ClassEntity get nativeAnnotationClass =>
      _nativeAnnotationClass ??= _findHelperClass('Native');
}
