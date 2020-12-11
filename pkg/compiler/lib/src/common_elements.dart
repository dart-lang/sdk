// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(sigmund): rename and move to common/elements.dart
library dart2js.type_system;

import 'common.dart';
import 'common/names.dart' show Identifiers, Uris;
import 'constants/constant_system.dart' as constant_system;
import 'constants/values.dart';
import 'elements/entities.dart';
import 'elements/types.dart';
import 'inferrer/abstract_value_domain.dart';
import 'js_backend/native_data.dart' show NativeBasicData;
import 'js_model/locals.dart';
import 'kernel/dart2js_target.dart';
import 'universe/selector.dart' show Selector;

/// The common elements and types in Dart.
abstract class CommonElements {
  DartTypes get dartTypes;

  /// The `Object` class defined in 'dart:core'.
  ClassEntity get objectClass;

  /// The `bool` class defined in 'dart:core'.
  ClassEntity get boolClass;

  /// The `num` class defined in 'dart:core'.
  ClassEntity get numClass;

  /// The `int` class defined in 'dart:core'.
  ClassEntity get intClass;

  /// The `double` class defined in 'dart:core'.
  ClassEntity get doubleClass;

  /// The `String` class defined in 'dart:core'.
  ClassEntity get stringClass;

  /// The `Function` class defined in 'dart:core'.
  ClassEntity get functionClass;

  /// The `Resource` class defined in 'dart:core'.
  ClassEntity get resourceClass;

  /// The `Symbol` class defined in 'dart:core'.
  ClassEntity get symbolClass;

  /// The `Null` class defined in 'dart:core'.
  ClassEntity get nullClass;

  /// The `Type` class defined in 'dart:core'.
  ClassEntity get typeClass;

  /// The `StackTrace` class defined in 'dart:core';
  ClassEntity get stackTraceClass;

  /// The `List` class defined in 'dart:core';
  ClassEntity get listClass;

  /// The `Set` class defined in 'dart:core';
  ClassEntity get setClass;

  /// The `Map` class defined in 'dart:core';
  ClassEntity get mapClass;

  /// The `Set` class defined in 'dart:core';
  ClassEntity get unmodifiableSetClass;

  /// The `Iterable` class defined in 'dart:core';
  ClassEntity get iterableClass;

  /// The `Future` class defined in 'async';.
  ClassEntity get futureClass;

  /// The `Stream` class defined in 'async';
  ClassEntity get streamClass;

  /// The dart:core library.
  LibraryEntity get coreLibrary;

  /// The dart:async library.
  LibraryEntity get asyncLibrary;

  /// The dart:mirrors library.
  LibraryEntity get mirrorsLibrary;

  /// The dart:typed_data library.
  LibraryEntity get typedDataLibrary;

  /// The dart:_js_helper library.
  LibraryEntity get jsHelperLibrary;

  /// The dart:_interceptors library.
  LibraryEntity get interceptorsLibrary;

  /// The dart:_foreign_helper library.
  LibraryEntity get foreignLibrary;

  /// The dart:_internal library.
  LibraryEntity get rtiLibrary;

  /// The dart:_internal library.
  LibraryEntity get internalLibrary;

  /// The dart:js library.
  LibraryEntity get dartJsLibrary;

  /// The package:js library.
  LibraryEntity get packageJsLibrary;

  /// The dart:_js_annotations library.
  LibraryEntity get dartJsAnnotationsLibrary;

  /// The `NativeTypedData` class from dart:typed_data.
  ClassEntity get typedDataClass;

  /// Constructor of the `Symbol` class in dart:internal.
  ///
  /// This getter will ensure that `Symbol` is resolved and lookup the
  /// constructor on demand.
  ConstructorEntity get symbolConstructorTarget;

  /// Whether [element] is the same as [symbolConstructor].
  ///
  /// Used to check for the constructor without computing it until it is likely
  /// to be seen.
  bool isSymbolConstructor(ConstructorEntity element);

  /// The function `identical` in dart:core.
  FunctionEntity get identicalFunction;

  /// Whether [element] is the `Function.apply` method.
  ///
  /// This will not resolve the apply method if it hasn't been seen yet during
  /// compilation.
  bool isFunctionApplyMethod(MemberEntity element);

  /// The `dynamic` type.
  DynamicType get dynamicType;

  /// The `Object` type defined in 'dart:core'.
  InterfaceType get objectType;

  /// The `bool` type defined in 'dart:core'.
  InterfaceType get boolType;

  /// The `num` type defined in 'dart:core'.
  InterfaceType get numType;

  /// The `int` type defined in 'dart:core'.
  InterfaceType get intType;

  /// The `double` type defined in 'dart:core'.
  InterfaceType get doubleType;

  /// The `String` type defined in 'dart:core'.
  InterfaceType get stringType;

  /// The `Symbol` type defined in 'dart:core'.
  InterfaceType get symbolType;

  /// The `Function` type defined in 'dart:core'.
  InterfaceType get functionType;

  /// The `Null` type defined in 'dart:core'.
  InterfaceType get nullType;

  /// The `Type` type defined in 'dart:core'.
  InterfaceType get typeType;

  InterfaceType get typeLiteralType;

  /// The `StackTrace` type defined in 'dart:core';
  InterfaceType get stackTraceType;

  /// Returns an instance of the `List` type defined in 'dart:core' with
  /// [elementType] as its type argument.
  ///
  /// If no type argument is provided, the canonical raw type is returned.
  InterfaceType listType([DartType elementType]);

  /// Returns an instance of the `Set` type defined in 'dart:core' with
  /// [elementType] as its type argument.
  ///
  /// If no type argument is provided, the canonical raw type is returned.
  InterfaceType setType([DartType elementType]);

  /// Returns an instance of the `Map` type defined in 'dart:core' with
  /// [keyType] and [valueType] as its type arguments.
  ///
  /// If no type arguments are provided, the canonical raw type is returned.
  InterfaceType mapType([DartType keyType, DartType valueType]);

  /// Returns an instance of the `Iterable` type defined in 'dart:core' with
  /// [elementType] as its type argument.
  ///
  /// If no type argument is provided, the canonical raw type is returned.
  InterfaceType iterableType([DartType elementType]);

  /// Returns an instance of the `Future` type defined in 'dart:async' with
  /// [elementType] as its type argument.
  ///
  /// If no type argument is provided, the canonical raw type is returned.
  InterfaceType futureType([DartType elementType]);

  /// Returns an instance of the `Stream` type defined in 'dart:async' with
  /// [elementType] as its type argument.
  ///
  /// If no type argument is provided, the canonical raw type is returned.
  InterfaceType streamType([DartType elementType]);

  InterfaceType getConstantListTypeFor(InterfaceType sourceType);

  InterfaceType getConstantMapTypeFor(InterfaceType sourceType,
      {bool hasProtoKey: false, bool onlyStringKeys: false});

  InterfaceType getConstantSetTypeFor(InterfaceType sourceType);

  FieldEntity get symbolField;

  InterfaceType get symbolImplementationType;

  // From dart:core
  ClassEntity get mapLiteralClass;
  ConstructorEntity get mapLiteralConstructor;
  ConstructorEntity get mapLiteralConstructorEmpty;
  FunctionEntity get mapLiteralUntypedMaker;
  FunctionEntity get mapLiteralUntypedEmptyMaker;

  ClassEntity get setLiteralClass;
  ConstructorEntity get setLiteralConstructor;
  ConstructorEntity get setLiteralConstructorEmpty;
  FunctionEntity get setLiteralUntypedMaker;
  FunctionEntity get setLiteralUntypedEmptyMaker;

  FunctionEntity get objectNoSuchMethod;

  bool isDefaultNoSuchMethodImplementation(FunctionEntity element);

  // From dart:async
  FunctionEntity get asyncHelperStartSync;
  FunctionEntity get asyncHelperAwait;
  FunctionEntity get asyncHelperReturn;
  FunctionEntity get asyncHelperRethrow;

  FunctionEntity get wrapBody;

  FunctionEntity get yieldStar;

  FunctionEntity get yieldSingle;

  FunctionEntity get syncStarUncaughtError;

  FunctionEntity get asyncStarHelper;

  FunctionEntity get streamOfController;

  FunctionEntity get endOfIteration;

  ClassEntity get syncStarIterable;

  ClassEntity get futureImplementation;

  ClassEntity get controllerStream;

  ClassEntity get streamIterator;

  ConstructorEntity get streamIteratorConstructor;

  FunctionEntity get syncStarIterableFactory;

  FunctionEntity get asyncAwaitCompleterFactory;

  FunctionEntity get asyncStarStreamControllerFactory;

  ClassEntity get jsInterceptorClass;

  ClassEntity get jsStringClass;

  ClassEntity get jsArrayClass;

  ClassEntity get jsNumberClass;

  ClassEntity get jsIntClass;

  ClassEntity get jsDoubleClass;

  ClassEntity get jsNullClass;

  ClassEntity get jsBoolClass;

  ClassEntity get jsPlainJavaScriptObjectClass;

  ClassEntity get jsUnknownJavaScriptObjectClass;

  ClassEntity get jsJavaScriptFunctionClass;

  InterfaceType get jsJavaScriptFunctionType;

  ClassEntity get jsJavaScriptObjectClass;

  ClassEntity get jsIndexableClass;

  ClassEntity get jsMutableIndexableClass;

  ClassEntity get jsMutableArrayClass;

  ClassEntity get jsFixedArrayClass;

  ClassEntity get jsExtendableArrayClass;

  ClassEntity get jsUnmodifiableArrayClass;

  ClassEntity get jsPositiveIntClass;

  ClassEntity get jsUInt32Class;

  ClassEntity get jsUInt31Class;

  /// Returns `true` member is the 'findIndexForNativeSubclassType' method
  /// declared in `dart:_interceptors`.
  bool isFindIndexForNativeSubclassType(MemberEntity member);

  FunctionEntity get getNativeInterceptorMethod;

  ConstructorEntity get jsArrayTypedConstructor;

  // From dart:_js_helper
  // TODO(johnniwinther): Avoid the need for this (from [CheckedModeHelper]).
  FunctionEntity findHelperFunction(String name);

  ClassEntity get closureClass;

  ClassEntity get boundClosureClass;

  ClassEntity get typeLiteralClass;

  ClassEntity get constMapLiteralClass;

  ClassEntity get constSetLiteralClass;

  ClassEntity get jsInvocationMirrorClass;

  ClassEntity get requiredSentinelClass;

  InterfaceType get requiredSentinelType;

  MemberEntity get invocationTypeArgumentGetter;

  /// Interface used to determine if an object has the JavaScript
  /// indexing behavior. The interface is only visible to specific libraries.
  ClassEntity get jsIndexingBehaviorInterface;

  ClassEntity get stackTraceHelperClass;

  ClassEntity get constantMapClass;
  ClassEntity get constantStringMapClass;
  ClassEntity get constantProtoMapClass;
  ClassEntity get generalConstantMapClass;

  ClassEntity get annotationCreatesClass;

  ClassEntity get annotationReturnsClass;

  ClassEntity get annotationJSNameClass;

  /// The class for native annotations defined in dart:_js_helper.
  ClassEntity get nativeAnnotationClass;

  FunctionEntity get assertTest;

  FunctionEntity get assertThrow;

  FunctionEntity get assertHelper;

  FunctionEntity get assertUnreachableMethod;

  /// Holds the method "getIsolateAffinityTag" when dart:_js_helper has been
  /// loaded.
  FunctionEntity get getIsolateAffinityTagMarker;

  /// Holds the method "requiresPreamble" in _js_helper.
  FunctionEntity get requiresPreambleMarker;

  FunctionEntity get loadLibraryWrapper;

  FunctionEntity get loadDeferredLibrary;

  FunctionEntity get boolConversionCheck;

  FunctionEntity get traceHelper;

  FunctionEntity get closureFromTearOff;

  FunctionEntity get isJsIndexable;

  FunctionEntity get throwIllegalArgumentException;

  FunctionEntity get throwIndexOutOfRangeException;

  FunctionEntity get exceptionUnwrapper;

  FunctionEntity get throwUnsupportedError;

  FunctionEntity get throwTypeError;

  /// Recognizes the `checkConcurrentModificationError` helper without needing
  /// it to be resolved.
  bool isCheckConcurrentModificationError(MemberEntity member);

  FunctionEntity get checkConcurrentModificationError;

  FunctionEntity get throwConcurrentModificationError;

  FunctionEntity get stringInterpolationHelper;

  FunctionEntity get wrapExceptionHelper;

  FunctionEntity get throwExpressionHelper;

  FunctionEntity get closureConverter;

  FunctionEntity get traceFromException;

  FunctionEntity get checkDeferredIsLoaded;

  FunctionEntity get throwNoSuchMethod;

  FunctionEntity get createRuntimeType;

  FunctionEntity get fallThroughError;

  FunctionEntity get createInvocationMirror;

  FunctionEntity get createUnmangledInvocationMirror;

  FunctionEntity get cyclicThrowHelper;

  FunctionEntity get defineProperty;

  FunctionEntity get throwLateInitializationError;

  bool isExtractTypeArguments(FunctionEntity member);

  ClassEntity getInstantiationClass(int typeArgumentCount);

  FunctionEntity getInstantiateFunction(int typeArgumentCount);

  FunctionEntity get convertMainArgumentList;

  // From dart:_rti

  FunctionEntity get setRuntimeTypeInfo;

  FunctionEntity get findType;
  FunctionEntity get instanceType;
  FunctionEntity get arrayInstanceType;
  FunctionEntity get simpleInstanceType;
  FunctionEntity get typeLiteralMaker;
  FunctionEntity get checkTypeBound;
  FieldEntity get rtiAsField;
  FieldEntity get rtiIsField;
  FieldEntity get rtiRestField;
  FieldEntity get rtiPrecomputed1Field;
  FunctionEntity get rtiEvalMethod;
  FunctionEntity get rtiBindMethod;
  FunctionEntity get rtiAddRulesMethod;
  FunctionEntity get rtiAddErasedTypesMethod;
  FunctionEntity get rtiAddTypeParameterVariancesMethod;

  FunctionEntity get installSpecializedIsTest;
  FunctionEntity get installSpecializedAsCheck;
  FunctionEntity get generalIsTestImplementation;
  FunctionEntity get generalAsCheckImplementation;
  FunctionEntity get generalNullableIsTestImplementation;
  FunctionEntity get generalNullableAsCheckImplementation;

  FunctionEntity get specializedIsObject;
  FunctionEntity get specializedAsObject;
  FunctionEntity get specializedIsTop;
  FunctionEntity get specializedAsTop;
  FunctionEntity get specializedIsBool;
  FunctionEntity get specializedAsBool;
  FunctionEntity get specializedAsBoolLegacy;
  FunctionEntity get specializedAsBoolNullable;
  FunctionEntity get specializedAsDouble;
  FunctionEntity get specializedAsDoubleLegacy;
  FunctionEntity get specializedAsDoubleNullable;
  FunctionEntity get specializedIsInt;
  FunctionEntity get specializedAsInt;
  FunctionEntity get specializedAsIntLegacy;
  FunctionEntity get specializedAsIntNullable;
  FunctionEntity get specializedIsNum;
  FunctionEntity get specializedAsNum;
  FunctionEntity get specializedAsNumLegacy;
  FunctionEntity get specializedAsNumNullable;
  FunctionEntity get specializedIsString;
  FunctionEntity get specializedAsString;
  FunctionEntity get specializedAsStringLegacy;
  FunctionEntity get specializedAsStringNullable;

  FunctionEntity get instantiatedGenericFunctionTypeNewRti;
  FunctionEntity get closureFunctionType;

  // From dart:_internal

  ClassEntity get symbolImplementationClass;

  /// Used to annotate items that have the keyword "native".
  ClassEntity get externalNameClass;

  InterfaceType get externalNameType;

  ConstructorEntity get symbolValidatedConstructor;

  // From dart:_js_embedded_names

  /// Holds the class for the [JsGetName] enum.
  ClassEntity get jsGetNameEnum;

  /// Returns `true` if [member] is a "foreign helper", that is, a member whose
  /// semantics is defined synthetically and not through Dart code.
  ///
  /// Most foreign helpers are located in the `dart:_foreign_helper` library.
  bool isForeignHelper(MemberEntity member);

  ClassEntity getDefaultSuperclass(
      ClassEntity cls, NativeBasicData nativeBasicData);

  // From package:js
  FunctionEntity get jsAllowInterop1;

  // From dart:_js_annotations;
  FunctionEntity get jsAllowInterop2;

  /// Returns `true` if [function] is `allowInterop`.
  ///
  /// This function can come from either `package:js` or `dart:_js_annotations`.
  bool isJsAllowInterop(FunctionEntity function);
}

abstract class KCommonElements implements CommonElements {
  // From package:js
  ClassEntity get jsAnnotationClass1;
  ClassEntity get jsAnonymousClass1;

  // From dart:_js_annotations
  ClassEntity get jsAnnotationClass2;
  ClassEntity get jsAnonymousClass2;

  /// Returns `true` if [cls] is a @JS() annotation.
  ///
  /// The class can come from either `package:js` or `dart:_js_annotations`.
  bool isJsAnnotationClass(ClassEntity cls);

  /// Returns `true` if [cls] is an @anonymous annotation.
  ///
  /// The class can come from either `package:js` or `dart:_js_annotations`.
  bool isJsAnonymousClass(ClassEntity cls);

  ClassEntity get pragmaClass;
  FieldEntity get pragmaClassNameField;
  FieldEntity get pragmaClassOptionsField;

  bool isCreateInvocationMirrorHelper(MemberEntity member);

  bool isSymbolValidatedConstructor(ConstructorEntity element);

  ClassEntity get metaNoInlineClass;

  ClassEntity get metaTryInlineClass;

  /// Returns `true` if [function] is allowed to be external.
  ///
  /// This returns `true` for foreign helpers, from environment constructors and
  /// members of libraries that support native.
  ///
  /// This returns `false` for JS interop members which therefore must be
  /// allowed to be external through the JS interop annotation handling.
  bool isExternalAllowed(FunctionEntity function);
}

abstract class JCommonElements implements CommonElements {
  /// Returns `true` if [element] is the unnamed constructor of `List`.
  ///
  /// This will not resolve the constructor if it hasn't been seen yet during
  /// compilation.
  bool isUnnamedListConstructor(ConstructorEntity element);

  /// Returns `true` if [element] is the named constructor of `List`,
  /// e.g. `List.of`.
  ///
  /// This will not resolve the constructor if it hasn't been seen yet during
  /// compilation.
  bool isNamedListConstructor(String name, ConstructorEntity element);

  /// Returns `true` if [element] is the named constructor of `JSArray`,
  /// e.g. `JSArray.fixed`.
  ///
  /// This will not resolve the constructor if it hasn't been seen yet during
  /// compilation.
  bool isNamedJSArrayConstructor(String name, ConstructorEntity element);

  bool isDefaultEqualityImplementation(MemberEntity element);

  /// Returns `true` if [selector] applies to `JSIndexable.length`.
  bool appliesToJsIndexableLength(Selector selector);

  FunctionEntity get jsArrayRemoveLast;

  FunctionEntity get jsArrayAdd;

  bool isJsStringSplit(MemberEntity member);

  /// Returns `true` if [selector] applies to `JSString.split` on [receiver]
  /// in the given [world].
  ///
  /// Returns `false` if `JSString.split` is not available.
  bool appliesToJsStringSplit(Selector selector, AbstractValue receiver,
      AbstractValueDomain abstractValueDomain);

  FunctionEntity get jsStringSplit;

  FunctionEntity get jsStringToString;

  FunctionEntity get jsStringOperatorAdd;

  ClassEntity get jsConstClass;

  /// Return `true` if [member] is the 'checkInt' function defined in
  /// dart:_js_helpers.
  bool isCheckInt(MemberEntity member);

  /// Return `true` if [member] is the 'checkNum' function defined in
  /// dart:_js_helpers.
  bool isCheckNum(MemberEntity member);

  /// Return `true` if [member] is the 'checkString' function defined in
  /// dart:_js_helpers.
  bool isCheckString(MemberEntity member);

  bool isInstantiationClass(ClassEntity cls);

  // From dart:_native_typed_data

  ClassEntity get typedArrayOfIntClass;

  ClassEntity get typedArrayOfDoubleClass;

  /// Holds the class for the [JsBuiltins] enum.
  ClassEntity get jsBuiltinEnum;

  bool isForeign(MemberEntity element);

  /// Returns `true` if the implementation of the 'operator ==' [function] is
  /// known to handle `null` as argument.
  bool operatorEqHandlesNullArgument(FunctionEntity function);
}

class CommonElementsImpl
    implements CommonElements, KCommonElements, JCommonElements {
  @override
  final DartTypes dartTypes;
  final ElementEnvironment _env;

  CommonElementsImpl(this.dartTypes, this._env);

  ClassEntity _objectClass;
  @override
  ClassEntity get objectClass =>
      _objectClass ??= _findClass(coreLibrary, 'Object');

  ClassEntity _boolClass;
  @override
  ClassEntity get boolClass => _boolClass ??= _findClass(coreLibrary, 'bool');

  ClassEntity _numClass;
  @override
  ClassEntity get numClass => _numClass ??= _findClass(coreLibrary, 'num');

  ClassEntity _intClass;
  @override
  ClassEntity get intClass => _intClass ??= _findClass(coreLibrary, 'int');

  ClassEntity _doubleClass;
  @override
  ClassEntity get doubleClass =>
      _doubleClass ??= _findClass(coreLibrary, 'double');

  ClassEntity _stringClass;
  @override
  ClassEntity get stringClass =>
      _stringClass ??= _findClass(coreLibrary, 'String');

  ClassEntity _functionClass;
  @override
  ClassEntity get functionClass =>
      _functionClass ??= _findClass(coreLibrary, 'Function');

  ClassEntity _resourceClass;
  @override
  ClassEntity get resourceClass =>
      _resourceClass ??= _findClass(coreLibrary, 'Resource');

  ClassEntity _symbolClass;
  @override
  ClassEntity get symbolClass =>
      _symbolClass ??= _findClass(coreLibrary, 'Symbol');

  ClassEntity _nullClass;
  @override
  ClassEntity get nullClass => _nullClass ??= _findClass(coreLibrary, 'Null');

  ClassEntity _typeClass;
  @override
  ClassEntity get typeClass => _typeClass ??= _findClass(coreLibrary, 'Type');

  ClassEntity _stackTraceClass;
  @override
  ClassEntity get stackTraceClass =>
      _stackTraceClass ??= _findClass(coreLibrary, 'StackTrace');

  ClassEntity _listClass;
  @override
  ClassEntity get listClass => _listClass ??= _findClass(coreLibrary, 'List');

  ClassEntity _setClass;
  @override
  ClassEntity get setClass => _setClass ??= _findClass(coreLibrary, 'Set');

  ClassEntity _mapClass;
  @override
  ClassEntity get mapClass => _mapClass ??= _findClass(coreLibrary, 'Map');

  ClassEntity _unmodifiableSetClass;
  @override
  ClassEntity get unmodifiableSetClass => _unmodifiableSetClass ??=
      _findClass(_env.lookupLibrary(Uris.dart_collection), '_UnmodifiableSet');

  ClassEntity _iterableClass;
  @override
  ClassEntity get iterableClass =>
      _iterableClass ??= _findClass(coreLibrary, 'Iterable');

  ClassEntity _futureClass;
  @override
  ClassEntity get futureClass =>
      _futureClass ??= _findClass(asyncLibrary, 'Future');

  ClassEntity _streamClass;
  @override
  ClassEntity get streamClass =>
      _streamClass ??= _findClass(asyncLibrary, 'Stream');

  LibraryEntity _coreLibrary;
  @override
  LibraryEntity get coreLibrary =>
      _coreLibrary ??= _env.lookupLibrary(Uris.dart_core, required: true);

  LibraryEntity _asyncLibrary;
  @override
  LibraryEntity get asyncLibrary =>
      _asyncLibrary ??= _env.lookupLibrary(Uris.dart_async);

  /// The dart:mirrors library.
  ///
  /// Null if the program doesn't access dart:mirrors.
  LibraryEntity _mirrorsLibrary;
  @override
  LibraryEntity get mirrorsLibrary =>
      _mirrorsLibrary ??= _env.lookupLibrary(Uris.dart_mirrors);

  LibraryEntity _typedDataLibrary;
  @override
  LibraryEntity get typedDataLibrary =>
      _typedDataLibrary ??= _env.lookupLibrary(Uris.dart__native_typed_data);

  LibraryEntity _jsHelperLibrary;
  @override
  LibraryEntity get jsHelperLibrary =>
      _jsHelperLibrary ??= _env.lookupLibrary(Uris.dart__js_helper);

  LibraryEntity _interceptorsLibrary;
  @override
  LibraryEntity get interceptorsLibrary =>
      _interceptorsLibrary ??= _env.lookupLibrary(Uris.dart__interceptors);

  LibraryEntity _foreignLibrary;
  @override
  LibraryEntity get foreignLibrary =>
      _foreignLibrary ??= _env.lookupLibrary(Uris.dart__foreign_helper);

  LibraryEntity _rtiLibrary;
  @override
  LibraryEntity get rtiLibrary =>
      _rtiLibrary ??= _env.lookupLibrary(Uris.dart__rti, required: true);

  /// Reference to the internal library to lookup functions to always inline.
  LibraryEntity _internalLibrary;
  @override
  LibraryEntity get internalLibrary => _internalLibrary ??=
      _env.lookupLibrary(Uris.dart__internal, required: true);

  LibraryEntity _dartJsLibrary;
  @override
  LibraryEntity get dartJsLibrary =>
      _dartJsLibrary ??= _env.lookupLibrary(Uris.dart_js);

  LibraryEntity _packageJsLibrary;
  @override
  LibraryEntity get packageJsLibrary =>
      _packageJsLibrary ??= _env.lookupLibrary(Uris.package_js);

  LibraryEntity _dartJsAnnotationsLibrary;
  @override
  LibraryEntity get dartJsAnnotationsLibrary => _dartJsAnnotationsLibrary ??=
      _env.lookupLibrary(Uris.dart__js_annotations);

  ClassEntity _typedDataClass;
  @override
  ClassEntity get typedDataClass =>
      _typedDataClass ??= _findClass(typedDataLibrary, 'NativeTypedData');

  ConstructorEntity _symbolConstructorTarget;
  @override
  ConstructorEntity get symbolConstructorTarget {
    // TODO(johnniwinther): Kernel does not include redirecting factories
    // so this cannot be found in kernel. Find a consistent way to handle
    // this and similar cases.
    return _symbolConstructorTarget ??=
        _findConstructor(symbolImplementationClass, '');
  }

  bool _computedSymbolConstructorDependencies = false;
  ConstructorEntity _symbolConstructorImplementationTarget;

  void _ensureSymbolConstructorDependencies() {
    if (_computedSymbolConstructorDependencies) return;
    _computedSymbolConstructorDependencies = true;
    if (_symbolConstructorTarget == null) {
      if (_symbolImplementationClass == null) {
        _symbolImplementationClass =
            _findClass(internalLibrary, 'Symbol', required: false);
      }
      if (_symbolImplementationClass != null) {
        _symbolConstructorTarget =
            _findConstructor(_symbolImplementationClass, '', required: false);
      }
    }
    if (_symbolClass == null) {
      _symbolClass = _findClass(coreLibrary, 'Symbol', required: false);
    }
    if (_symbolClass == null) {
      return;
    }
    _symbolConstructorImplementationTarget =
        _findConstructor(symbolClass, '', required: false);
  }

  @override
  bool isSymbolConstructor(ConstructorEntity element) {
    assert(element != null);
    _ensureSymbolConstructorDependencies();
    return element == _symbolConstructorImplementationTarget ||
        element == _symbolConstructorTarget;
  }

  FunctionEntity _identicalFunction;
  @override
  FunctionEntity get identicalFunction =>
      _identicalFunction ??= _findLibraryMember(coreLibrary, 'identical');

  @override
  bool isFunctionApplyMethod(MemberEntity element) =>
      element.name == 'apply' && element.enclosingClass == functionClass;

  /// Returns `true` if [element] is the unnamed constructor of `List`.
  ///
  /// This will not resolve the constructor if it hasn't been seen yet during
  /// compilation.
  @override
  bool isUnnamedListConstructor(ConstructorEntity element) =>
      (element.name == '' && element.enclosingClass == listClass) ||
      (element.name == 'list' && element.enclosingClass == jsArrayClass);

  /// Returns `true` if [element] is the 'filled' constructor of `List`.
  ///
  /// This will not resolve the constructor if it hasn't been seen yet during
  /// compilation.
  @override
  bool isNamedListConstructor(String name, ConstructorEntity element) =>
      element.name == name && element.enclosingClass == listClass;

  /// Returns `true` if [element] is the [name]d constructor of `JSArray`.
  ///
  /// This will not resolve the constructor if it hasn't been seen yet during
  /// compilation.
  @override
  bool isNamedJSArrayConstructor(String name, ConstructorEntity element) =>
      element.name == name && element.enclosingClass == jsArrayClass;

  @override
  DynamicType get dynamicType => _env.dynamicType;

  @override
  InterfaceType get objectType => _getRawType(objectClass);

  @override
  InterfaceType get boolType => _getRawType(boolClass);

  @override
  InterfaceType get numType => _getRawType(numClass);

  @override
  InterfaceType get intType => _getRawType(intClass);

  @override
  InterfaceType get doubleType => _getRawType(doubleClass);

  @override
  InterfaceType get stringType => _getRawType(stringClass);

  @override
  InterfaceType get symbolType => _getRawType(symbolClass);

  @override
  InterfaceType get functionType => _getRawType(functionClass);

  @override
  InterfaceType get nullType => _getRawType(nullClass);

  @override
  InterfaceType get typeType => _getRawType(typeClass);

  @override
  InterfaceType get typeLiteralType => _getRawType(typeLiteralClass);

  @override
  InterfaceType get stackTraceType => _getRawType(stackTraceClass);

  @override
  InterfaceType listType([DartType elementType]) {
    if (elementType == null) {
      return _getRawType(listClass);
    }
    return _createInterfaceType(listClass, [elementType]);
  }

  @override
  InterfaceType setType([DartType elementType]) {
    if (elementType == null) {
      return _getRawType(setClass);
    }
    return _createInterfaceType(setClass, [elementType]);
  }

  @override
  InterfaceType mapType([DartType keyType, DartType valueType]) {
    if (keyType == null && valueType == null) {
      return _getRawType(mapClass);
    } else if (keyType == null) {
      keyType = dynamicType;
    } else if (valueType == null) {
      valueType = dynamicType;
    }
    return _createInterfaceType(mapClass, [keyType, valueType]);
  }

  @override
  InterfaceType iterableType([DartType elementType]) {
    if (elementType == null) {
      return _getRawType(iterableClass);
    }
    return _createInterfaceType(iterableClass, [elementType]);
  }

  @override
  InterfaceType futureType([DartType elementType]) {
    if (elementType == null) {
      return _getRawType(futureClass);
    }
    return _createInterfaceType(futureClass, [elementType]);
  }

  @override
  InterfaceType streamType([DartType elementType]) {
    if (elementType == null) {
      return _getRawType(streamClass);
    }
    return _createInterfaceType(streamClass, [elementType]);
  }

  ClassEntity _findClass(LibraryEntity library, String name,
      {bool required: true}) {
    if (library == null) return null;
    return _env.lookupClass(library, name, required: required);
  }

  MemberEntity _findLibraryMember(LibraryEntity library, String name,
      {bool setter: false, bool required: true}) {
    if (library == null) return null;
    return _env.lookupLibraryMember(library, name,
        setter: setter, required: required);
  }

  MemberEntity _findClassMember(ClassEntity cls, String name,
      {bool setter: false, bool required: true}) {
    return _env.lookupLocalClassMember(cls, name,
        setter: setter, required: required);
  }

  ConstructorEntity _findConstructor(ClassEntity cls, String name,
      {bool required: true}) {
    return _env.lookupConstructor(cls, name, required: required);
  }

  /// Return the raw type of [cls].
  InterfaceType _getRawType(ClassEntity cls) {
    return _env.getRawType(cls);
  }

  /// Create the instantiation of [cls] with the given [typeArguments] and
  /// [nullability].
  InterfaceType _createInterfaceType(
      ClassEntity cls, List<DartType> typeArguments) {
    return _env.createInterfaceType(cls, typeArguments);
  }

  @override
  InterfaceType getConstantListTypeFor(InterfaceType sourceType) =>
      dartTypes.treatAsRawType(sourceType)
          ? _env.getRawType(jsArrayClass)
          : _env.createInterfaceType(jsArrayClass, sourceType.typeArguments);

  @override
  InterfaceType getConstantMapTypeFor(InterfaceType sourceType,
      {bool hasProtoKey: false, bool onlyStringKeys: false}) {
    ClassEntity classElement = onlyStringKeys
        ? (hasProtoKey ? constantProtoMapClass : constantStringMapClass)
        : generalConstantMapClass;
    if (dartTypes.treatAsRawType(sourceType)) {
      return _env.getRawType(classElement);
    } else {
      return _env.createInterfaceType(classElement, sourceType.typeArguments);
    }
  }

  @override
  InterfaceType getConstantSetTypeFor(InterfaceType sourceType) =>
      dartTypes.treatAsRawType(sourceType)
          ? _env.getRawType(constSetLiteralClass)
          : _env.createInterfaceType(
              constSetLiteralClass, sourceType.typeArguments);

  @override
  FieldEntity get symbolField => symbolImplementationField;

  @override
  InterfaceType get symbolImplementationType =>
      _env.getRawType(symbolImplementationClass);

  @override
  bool isDefaultEqualityImplementation(MemberEntity element) {
    assert(element.name == '==');
    ClassEntity classElement = element.enclosingClass;
    return classElement == objectClass ||
        classElement == jsInterceptorClass ||
        classElement == jsNullClass;
  }

  // From dart:core

  ClassEntity _mapLiteralClass;
  @override
  ClassEntity get mapLiteralClass {
    if (_mapLiteralClass == null) {
      _mapLiteralClass = _env.lookupClass(coreLibrary, 'LinkedHashMap');
      if (_mapLiteralClass == null) {
        _mapLiteralClass = _findClass(
            _env.lookupLibrary(Uris.dart_collection), 'LinkedHashMap');
      }
    }
    return _mapLiteralClass;
  }

  ConstructorEntity _mapLiteralConstructor;
  ConstructorEntity _mapLiteralConstructorEmpty;
  FunctionEntity _mapLiteralUntypedMaker;
  FunctionEntity _mapLiteralUntypedEmptyMaker;
  void _ensureMapLiteralHelpers() {
    if (_mapLiteralConstructor != null) return;

    _mapLiteralConstructor =
        _env.lookupConstructor(mapLiteralClass, '_literal');
    _mapLiteralConstructorEmpty =
        _env.lookupConstructor(mapLiteralClass, '_empty');
    _mapLiteralUntypedMaker =
        _env.lookupLocalClassMember(mapLiteralClass, '_makeLiteral');
    _mapLiteralUntypedEmptyMaker =
        _env.lookupLocalClassMember(mapLiteralClass, '_makeEmpty');
  }

  @override
  ConstructorEntity get mapLiteralConstructor {
    _ensureMapLiteralHelpers();
    return _mapLiteralConstructor;
  }

  @override
  ConstructorEntity get mapLiteralConstructorEmpty {
    _ensureMapLiteralHelpers();
    return _mapLiteralConstructorEmpty;
  }

  @override
  FunctionEntity get mapLiteralUntypedMaker {
    _ensureMapLiteralHelpers();
    return _mapLiteralUntypedMaker;
  }

  @override
  FunctionEntity get mapLiteralUntypedEmptyMaker {
    _ensureMapLiteralHelpers();
    return _mapLiteralUntypedEmptyMaker;
  }

  ClassEntity _setLiteralClass;
  @override
  ClassEntity get setLiteralClass => _setLiteralClass ??=
      _findClass(_env.lookupLibrary(Uris.dart_collection), 'LinkedHashSet');

  ConstructorEntity _setLiteralConstructor;
  ConstructorEntity _setLiteralConstructorEmpty;
  FunctionEntity _setLiteralUntypedMaker;
  FunctionEntity _setLiteralUntypedEmptyMaker;

  void _ensureSetLiteralHelpers() {
    if (_setLiteralConstructor != null) return;

    _setLiteralConstructor =
        _env.lookupConstructor(setLiteralClass, '_literal');
    _setLiteralConstructorEmpty =
        _env.lookupConstructor(setLiteralClass, '_empty');
    _setLiteralUntypedMaker =
        _env.lookupLocalClassMember(setLiteralClass, '_makeLiteral');
    _setLiteralUntypedEmptyMaker =
        _env.lookupLocalClassMember(setLiteralClass, '_makeEmpty');
  }

  @override
  ConstructorEntity get setLiteralConstructor {
    _ensureSetLiteralHelpers();
    return _setLiteralConstructor;
  }

  @override
  ConstructorEntity get setLiteralConstructorEmpty {
    _ensureSetLiteralHelpers();
    return _setLiteralConstructorEmpty;
  }

  @override
  FunctionEntity get setLiteralUntypedMaker {
    _ensureSetLiteralHelpers();
    return _setLiteralUntypedMaker;
  }

  @override
  FunctionEntity get setLiteralUntypedEmptyMaker {
    _ensureSetLiteralHelpers();
    return _setLiteralUntypedEmptyMaker;
  }

  FunctionEntity _objectNoSuchMethod;
  @override
  FunctionEntity get objectNoSuchMethod {
    return _objectNoSuchMethod ??=
        _env.lookupLocalClassMember(objectClass, Identifiers.noSuchMethod_);
  }

  @override
  bool isDefaultNoSuchMethodImplementation(FunctionEntity element) {
    ClassEntity classElement = element.enclosingClass;
    return classElement == objectClass ||
        classElement == jsInterceptorClass ||
        classElement == jsNullClass;
  }

  // From dart:async
  ClassEntity _findAsyncHelperClass(String name) =>
      _findClass(asyncLibrary, name);

  FunctionEntity _findAsyncHelperFunction(String name) =>
      _findLibraryMember(asyncLibrary, name);

  @override
  FunctionEntity get asyncHelperStartSync =>
      _findAsyncHelperFunction("_asyncStartSync");
  @override
  FunctionEntity get asyncHelperAwait =>
      _findAsyncHelperFunction("_asyncAwait");
  @override
  FunctionEntity get asyncHelperReturn =>
      _findAsyncHelperFunction("_asyncReturn");
  @override
  FunctionEntity get asyncHelperRethrow =>
      _findAsyncHelperFunction("_asyncRethrow");

  @override
  FunctionEntity get wrapBody =>
      _findAsyncHelperFunction("_wrapJsFunctionForAsync");

  @override
  FunctionEntity get yieldStar => _env.lookupLocalClassMember(
      _findAsyncHelperClass("_IterationMarker"), "yieldStar");

  @override
  FunctionEntity get yieldSingle => _env.lookupLocalClassMember(
      _findAsyncHelperClass("_IterationMarker"), "yieldSingle");

  @override
  FunctionEntity get syncStarUncaughtError => _env.lookupLocalClassMember(
      _findAsyncHelperClass("_IterationMarker"), "uncaughtError");

  @override
  FunctionEntity get asyncStarHelper =>
      _findAsyncHelperFunction("_asyncStarHelper");

  @override
  FunctionEntity get streamOfController =>
      _findAsyncHelperFunction("_streamOfController");

  @override
  FunctionEntity get endOfIteration => _env.lookupLocalClassMember(
      _findAsyncHelperClass("_IterationMarker"), "endOfIteration");

  @override
  ClassEntity get syncStarIterable =>
      _findAsyncHelperClass("_SyncStarIterable");

  @override
  ClassEntity get futureImplementation => _findAsyncHelperClass('_Future');

  @override
  ClassEntity get controllerStream =>
      _findAsyncHelperClass("_ControllerStream");

  @override
  ClassEntity get streamIterator => _findAsyncHelperClass("StreamIterator");

  @override
  ConstructorEntity get streamIteratorConstructor =>
      _env.lookupConstructor(streamIterator, "");

  FunctionEntity _syncStarIterableFactory;
  @override
  FunctionEntity get syncStarIterableFactory => _syncStarIterableFactory ??=
      _findAsyncHelperFunction('_makeSyncStarIterable');

  FunctionEntity _asyncAwaitCompleterFactory;
  @override
  FunctionEntity get asyncAwaitCompleterFactory =>
      _asyncAwaitCompleterFactory ??=
          _findAsyncHelperFunction('_makeAsyncAwaitCompleter');

  FunctionEntity _asyncStarStreamControllerFactory;
  @override
  FunctionEntity get asyncStarStreamControllerFactory =>
      _asyncStarStreamControllerFactory ??=
          _findAsyncHelperFunction('_makeAsyncStarStreamController');

  // From dart:_interceptors
  ClassEntity _findInterceptorsClass(String name) =>
      _findClass(interceptorsLibrary, name);

  FunctionEntity _findInterceptorsFunction(String name) =>
      _findLibraryMember(interceptorsLibrary, name);

  ClassEntity _jsInterceptorClass;
  @override
  ClassEntity get jsInterceptorClass =>
      _jsInterceptorClass ??= _findInterceptorsClass('Interceptor');

  ClassEntity _jsStringClass;
  @override
  ClassEntity get jsStringClass =>
      _jsStringClass ??= _findInterceptorsClass('JSString');

  ClassEntity _jsArrayClass;
  @override
  ClassEntity get jsArrayClass =>
      _jsArrayClass ??= _findInterceptorsClass('JSArray');

  ClassEntity _jsNumberClass;
  @override
  ClassEntity get jsNumberClass =>
      _jsNumberClass ??= _findInterceptorsClass('JSNumber');

  ClassEntity _jsIntClass;
  @override
  ClassEntity get jsIntClass => _jsIntClass ??= _findInterceptorsClass('JSInt');

  ClassEntity _jsDoubleClass;
  @override
  ClassEntity get jsDoubleClass =>
      _jsDoubleClass ??= _findInterceptorsClass('JSDouble');

  ClassEntity _jsNullClass;
  @override
  ClassEntity get jsNullClass =>
      _jsNullClass ??= _findInterceptorsClass('JSNull');

  ClassEntity _jsBoolClass;
  @override
  ClassEntity get jsBoolClass =>
      _jsBoolClass ??= _findInterceptorsClass('JSBool');

  ClassEntity _jsPlainJavaScriptObjectClass;
  @override
  ClassEntity get jsPlainJavaScriptObjectClass =>
      _jsPlainJavaScriptObjectClass ??=
          _findInterceptorsClass('PlainJavaScriptObject');

  ClassEntity _jsUnknownJavaScriptObjectClass;
  @override
  ClassEntity get jsUnknownJavaScriptObjectClass =>
      _jsUnknownJavaScriptObjectClass ??=
          _findInterceptorsClass('UnknownJavaScriptObject');

  ClassEntity _jsJavaScriptFunctionClass;
  @override
  ClassEntity get jsJavaScriptFunctionClass => _jsJavaScriptFunctionClass ??=
      _findInterceptorsClass('JavaScriptFunction');

  @override
  InterfaceType get jsJavaScriptFunctionType =>
      _getRawType(jsJavaScriptFunctionClass);

  ClassEntity _jsJavaScriptObjectClass;
  @override
  ClassEntity get jsJavaScriptObjectClass =>
      _jsJavaScriptObjectClass ??= _findInterceptorsClass('JavaScriptObject');

  ClassEntity _jsIndexableClass;
  @override
  ClassEntity get jsIndexableClass =>
      _jsIndexableClass ??= _findInterceptorsClass('JSIndexable');

  ClassEntity _jsMutableIndexableClass;
  @override
  ClassEntity get jsMutableIndexableClass =>
      _jsMutableIndexableClass ??= _findInterceptorsClass('JSMutableIndexable');

  ClassEntity _jsMutableArrayClass;
  @override
  ClassEntity get jsMutableArrayClass =>
      _jsMutableArrayClass ??= _findInterceptorsClass('JSMutableArray');

  ClassEntity _jsFixedArrayClass;
  @override
  ClassEntity get jsFixedArrayClass =>
      _jsFixedArrayClass ??= _findInterceptorsClass('JSFixedArray');

  ClassEntity _jsExtendableArrayClass;
  @override
  ClassEntity get jsExtendableArrayClass =>
      _jsExtendableArrayClass ??= _findInterceptorsClass('JSExtendableArray');

  ClassEntity _jsUnmodifiableArrayClass;
  @override
  ClassEntity get jsUnmodifiableArrayClass => _jsUnmodifiableArrayClass ??=
      _findInterceptorsClass('JSUnmodifiableArray');

  ClassEntity _jsPositiveIntClass;
  @override
  ClassEntity get jsPositiveIntClass =>
      _jsPositiveIntClass ??= _findInterceptorsClass('JSPositiveInt');

  ClassEntity _jsUInt32Class;
  @override
  ClassEntity get jsUInt32Class =>
      _jsUInt32Class ??= _findInterceptorsClass('JSUInt32');

  ClassEntity _jsUInt31Class;
  @override
  ClassEntity get jsUInt31Class =>
      _jsUInt31Class ??= _findInterceptorsClass('JSUInt31');

  @override
  bool isFindIndexForNativeSubclassType(MemberEntity member) {
    return member.name == 'findIndexForNativeSubclassType' &&
        member.isTopLevel &&
        member.library == interceptorsLibrary;
  }

  FunctionEntity _getNativeInterceptorMethod;
  @override
  FunctionEntity get getNativeInterceptorMethod =>
      _getNativeInterceptorMethod ??=
          _findInterceptorsFunction('getNativeInterceptor');

  @override
  bool appliesToJsIndexableLength(Selector selector) {
    return selector.name == 'length' && (selector.isGetter || selector.isCall);
  }

  ConstructorEntity _jsArrayTypedConstructor;
  @override
  ConstructorEntity get jsArrayTypedConstructor =>
      _jsArrayTypedConstructor ??= _findConstructor(jsArrayClass, 'typed');

  FunctionEntity _jsArrayRemoveLast;
  @override
  FunctionEntity get jsArrayRemoveLast =>
      _jsArrayRemoveLast ??= _findClassMember(jsArrayClass, 'removeLast');

  FunctionEntity _jsArrayAdd;
  @override
  FunctionEntity get jsArrayAdd =>
      _jsArrayAdd ??= _findClassMember(jsArrayClass, 'add');

  bool _isJsStringClass(ClassEntity cls) {
    return cls.name == 'JSString' && cls.library == interceptorsLibrary;
  }

  @override
  bool isJsStringSplit(MemberEntity member) {
    return member.name == 'split' &&
        member.isInstanceMember &&
        _isJsStringClass(member.enclosingClass);
  }

  @override
  bool appliesToJsStringSplit(Selector selector, AbstractValue receiver,
      AbstractValueDomain abstractValueDomain) {
    if (_jsStringSplit == null) {
      ClassEntity cls =
          _findClass(interceptorsLibrary, 'JSString', required: false);
      if (cls == null) return false;
      _jsStringSplit = _findClassMember(cls, 'split', required: false);
      if (_jsStringSplit == null) return false;
    }
    return selector.applies(_jsStringSplit) &&
        (receiver == null ||
            abstractValueDomain
                .isTargetingMember(receiver, jsStringSplit, selector.memberName)
                .isPotentiallyTrue);
  }

  FunctionEntity _jsStringSplit;
  @override
  FunctionEntity get jsStringSplit =>
      _jsStringSplit ??= _findClassMember(jsStringClass, 'split');

  FunctionEntity _jsStringToString;
  @override
  FunctionEntity get jsStringToString =>
      _jsStringToString ??= _findClassMember(jsStringClass, 'toString');

  FunctionEntity _jsStringOperatorAdd;
  @override
  FunctionEntity get jsStringOperatorAdd =>
      _jsStringOperatorAdd ??= _findClassMember(jsStringClass, '+');

  ClassEntity _jsConstClass;
  @override
  ClassEntity get jsConstClass =>
      _jsConstClass ??= _findClass(foreignLibrary, 'JS_CONST');

  // From dart:js
  FunctionEntity _jsAllowInterop1;
  @override
  FunctionEntity get jsAllowInterop1 => _jsAllowInterop1 ??=
      _findLibraryMember(dartJsLibrary, 'allowInterop', required: false);

  // From dart:_js_annotations
  FunctionEntity _jsAllowInterop2;
  @override
  FunctionEntity get jsAllowInterop2 => _jsAllowInterop2 ??= _findLibraryMember(
      dartJsAnnotationsLibrary, 'allowInterop',
      required: false);

  @override
  bool isJsAllowInterop(FunctionEntity function) {
    return function == jsAllowInterop1 || function == jsAllowInterop2;
  }

  // From package:js
  ClassEntity _jsAnnotationClass1;
  @override
  ClassEntity get jsAnnotationClass1 => _jsAnnotationClass1 ??=
      _findClass(packageJsLibrary, 'JS', required: false);

  // From dart:_js_annotations
  ClassEntity _jsAnnotationClass2;
  @override
  ClassEntity get jsAnnotationClass2 => _jsAnnotationClass2 ??=
      _findClass(dartJsAnnotationsLibrary, 'JS', required: false);

  @override
  bool isJsAnnotationClass(ClassEntity cls) {
    return cls == jsAnnotationClass1 || cls == jsAnnotationClass2;
  }

  // From dart:js
  ClassEntity _jsAnonymousClass1;
  @override
  ClassEntity get jsAnonymousClass1 => _jsAnonymousClass1 ??=
      _findClass(packageJsLibrary, '_Anonymous', required: false);

  // From dart:_js_annotations
  ClassEntity _jsAnonymousClass2;
  @override
  ClassEntity get jsAnonymousClass2 => _jsAnonymousClass2 ??=
      _findClass(dartJsAnnotationsLibrary, '_Anonymous', required: false);

  @override
  bool isJsAnonymousClass(ClassEntity cls) {
    return cls == jsAnonymousClass1 || cls == jsAnonymousClass2;
  }

  @override
  FunctionEntity findHelperFunction(String name) => _findHelperFunction(name);

  FunctionEntity _findHelperFunction(String name) =>
      _findLibraryMember(jsHelperLibrary, name);

  ClassEntity _findHelperClass(String name) =>
      _findClass(jsHelperLibrary, name);

  ClassEntity _closureClass;
  @override
  ClassEntity get closureClass => _closureClass ??= _findHelperClass('Closure');

  ClassEntity _boundClosureClass;
  @override
  ClassEntity get boundClosureClass =>
      _boundClosureClass ??= _findHelperClass('BoundClosure');

  ClassEntity _typeLiteralClass;
  @override
  ClassEntity get typeLiteralClass =>
      _typeLiteralClass ??= _findRtiClass('_Type');

  ClassEntity _constMapLiteralClass;
  @override
  ClassEntity get constMapLiteralClass =>
      _constMapLiteralClass ??= _findHelperClass('ConstantMap');

  // TODO(fishythefish): Implement a `ConstantSet` class and update the backend
  // impacts + constant emitter accordingly.
  ClassEntity _constSetLiteralClass;
  @override
  ClassEntity get constSetLiteralClass =>
      _constSetLiteralClass ??= unmodifiableSetClass;

  ClassEntity _pragmaClass;
  @override
  ClassEntity get pragmaClass =>
      _pragmaClass ??= _findClass(coreLibrary, 'pragma');

  FieldEntity _pragmaClassNameField;
  @override
  FieldEntity get pragmaClassNameField =>
      _pragmaClassNameField ??= _findClassMember(pragmaClass, 'name');

  FieldEntity _pragmaClassOptionsField;
  @override
  FieldEntity get pragmaClassOptionsField =>
      _pragmaClassOptionsField ??= _findClassMember(pragmaClass, 'options');

  ClassEntity _jsInvocationMirrorClass;
  @override
  ClassEntity get jsInvocationMirrorClass =>
      _jsInvocationMirrorClass ??= _findHelperClass('JSInvocationMirror');

  ClassEntity _requiredSentinelClass;
  @override
  ClassEntity get requiredSentinelClass =>
      _requiredSentinelClass ??= _findHelperClass('_Required');
  @override
  InterfaceType get requiredSentinelType => _getRawType(requiredSentinelClass);

  MemberEntity _invocationTypeArgumentGetter;
  @override
  MemberEntity get invocationTypeArgumentGetter =>
      _invocationTypeArgumentGetter ??=
          _findClassMember(jsInvocationMirrorClass, 'typeArguments');

  ClassEntity _jsIndexingBehaviorInterface;
  @override
  ClassEntity get jsIndexingBehaviorInterface =>
      _jsIndexingBehaviorInterface ??=
          _findHelperClass('JavaScriptIndexingBehavior');

  @override
  ClassEntity get stackTraceHelperClass => _findHelperClass('_StackTrace');

  @override
  ClassEntity get constantMapClass =>
      _findHelperClass(constant_system.JavaScriptMapConstant.DART_CLASS);
  @override
  ClassEntity get constantStringMapClass =>
      _findHelperClass(constant_system.JavaScriptMapConstant.DART_STRING_CLASS);
  @override
  ClassEntity get constantProtoMapClass =>
      _findHelperClass(constant_system.JavaScriptMapConstant.DART_PROTO_CLASS);
  @override
  ClassEntity get generalConstantMapClass => _findHelperClass(
      constant_system.JavaScriptMapConstant.DART_GENERAL_CLASS);

  @override
  ClassEntity get annotationCreatesClass => _findHelperClass('Creates');

  @override
  ClassEntity get annotationReturnsClass => _findHelperClass('Returns');

  @override
  ClassEntity get annotationJSNameClass => _findHelperClass('JSName');

  ClassEntity _nativeAnnotationClass;
  @override
  ClassEntity get nativeAnnotationClass =>
      _nativeAnnotationClass ??= _findHelperClass('Native');

  FunctionEntity _assertTest;
  @override
  FunctionEntity get assertTest =>
      _assertTest ??= _findHelperFunction('assertTest');

  FunctionEntity _assertThrow;
  @override
  FunctionEntity get assertThrow =>
      _assertThrow ??= _findHelperFunction('assertThrow');

  FunctionEntity _assertHelper;
  @override
  FunctionEntity get assertHelper =>
      _assertHelper ??= _findHelperFunction('assertHelper');

  FunctionEntity _assertUnreachableMethod;
  @override
  FunctionEntity get assertUnreachableMethod =>
      _assertUnreachableMethod ??= _findHelperFunction('assertUnreachable');

  FunctionEntity _getIsolateAffinityTagMarker;
  @override
  FunctionEntity get getIsolateAffinityTagMarker =>
      _getIsolateAffinityTagMarker ??=
          _findHelperFunction('getIsolateAffinityTag');

  FunctionEntity _requiresPreambleMarker;
  @override
  FunctionEntity get requiresPreambleMarker =>
      _requiresPreambleMarker ??= _findHelperFunction('requiresPreamble');

  @override
  FunctionEntity get loadLibraryWrapper =>
      _findHelperFunction("_loadLibraryWrapper");

  @override
  FunctionEntity get loadDeferredLibrary =>
      _findHelperFunction("loadDeferredLibrary");

  @override
  FunctionEntity get boolConversionCheck =>
      _findHelperFunction('boolConversionCheck');

  @override
  FunctionEntity get traceHelper => _findHelperFunction('traceHelper');

  @override
  FunctionEntity get closureFromTearOff =>
      _findHelperFunction('closureFromTearOff');

  @override
  FunctionEntity get isJsIndexable => _findHelperFunction('isJsIndexable');

  @override
  FunctionEntity get throwIllegalArgumentException =>
      _findHelperFunction('iae');

  @override
  FunctionEntity get throwIndexOutOfRangeException =>
      _findHelperFunction('ioore');

  @override
  FunctionEntity get exceptionUnwrapper =>
      _findHelperFunction('unwrapException');

  @override
  FunctionEntity get throwUnsupportedError =>
      _findHelperFunction('throwUnsupportedError');

  @override
  FunctionEntity get throwTypeError => _findRtiFunction('throwTypeError');

  @override
  bool isCheckConcurrentModificationError(MemberEntity member) {
    return member.name == 'checkConcurrentModificationError' &&
        member.isFunction &&
        member.isTopLevel &&
        member.library == jsHelperLibrary;
  }

  FunctionEntity _cachedCheckConcurrentModificationError;
  @override
  FunctionEntity get checkConcurrentModificationError =>
      _cachedCheckConcurrentModificationError ??=
          _findHelperFunction('checkConcurrentModificationError');

  @override
  FunctionEntity get throwConcurrentModificationError =>
      _findHelperFunction('throwConcurrentModificationError');

  @override
  bool isCheckInt(MemberEntity member) {
    return member.isFunction &&
        member.isTopLevel &&
        member.library == jsHelperLibrary &&
        member.name == 'checkInt';
  }

  @override
  bool isCheckNum(MemberEntity member) {
    return member.isFunction &&
        member.isTopLevel &&
        member.library == jsHelperLibrary &&
        member.name == 'checkNum';
  }

  @override
  bool isCheckString(MemberEntity member) {
    return member.isFunction &&
        member.isTopLevel &&
        member.library == jsHelperLibrary &&
        member.name == 'checkString';
  }

  @override
  FunctionEntity get stringInterpolationHelper => _findHelperFunction('S');

  @override
  FunctionEntity get wrapExceptionHelper =>
      _findHelperFunction('wrapException');

  @override
  FunctionEntity get throwExpressionHelper =>
      _findHelperFunction('throwExpression');

  @override
  FunctionEntity get closureConverter =>
      _findHelperFunction('convertDartClosureToJS');

  @override
  FunctionEntity get traceFromException =>
      _findHelperFunction('getTraceFromException');

  @override
  FunctionEntity get checkDeferredIsLoaded =>
      _findHelperFunction('checkDeferredIsLoaded');

  @override
  FunctionEntity get throwNoSuchMethod =>
      _findHelperFunction('throwNoSuchMethod');

  @override
  FunctionEntity get createRuntimeType => _findRtiFunction('createRuntimeType');

  @override
  FunctionEntity get fallThroughError =>
      _findHelperFunction("getFallThroughError");

  @override
  FunctionEntity get createInvocationMirror =>
      _findHelperFunction('createInvocationMirror');

  @override
  bool isCreateInvocationMirrorHelper(MemberEntity member) {
    return member.isTopLevel &&
        member.name == '_createInvocationMirror' &&
        member.library == coreLibrary;
  }

  @override
  FunctionEntity get createUnmangledInvocationMirror =>
      _findHelperFunction('createUnmangledInvocationMirror');

  @override
  FunctionEntity get cyclicThrowHelper =>
      _findHelperFunction("throwCyclicInit");

  @override
  FunctionEntity get defineProperty => _findHelperFunction('defineProperty');

  @override
  FunctionEntity get throwLateInitializationError =>
      _findHelperFunction('throwLateInitializationError');

  @override
  bool isExtractTypeArguments(FunctionEntity member) {
    return member.name == 'extractTypeArguments' &&
        member.library == internalLibrary;
  }

  // TODO(johnniwinther,sra): Support arbitrary type argument count.
  void _checkTypeArgumentCount(int typeArgumentCount) {
    assert(typeArgumentCount > 0);
    if (typeArgumentCount > 20) {
      failedAt(
          NO_LOCATION_SPANNABLE,
          "Unsupported instantiation argument count: "
          "${typeArgumentCount}");
    }
  }

  @override
  ClassEntity getInstantiationClass(int typeArgumentCount) {
    _checkTypeArgumentCount(typeArgumentCount);
    return _findHelperClass('Instantiation$typeArgumentCount');
  }

  @override
  FunctionEntity getInstantiateFunction(int typeArgumentCount) {
    _checkTypeArgumentCount(typeArgumentCount);
    return _findHelperFunction('instantiate$typeArgumentCount');
  }

  @override
  bool isInstantiationClass(ClassEntity cls) {
    return cls.library == _jsHelperLibrary &&
        cls.name != 'Instantiation' &&
        cls.name.startsWith('Instantiation');
  }

  @override
  FunctionEntity get convertMainArgumentList =>
      _findHelperFunction('convertMainArgumentList');

  // From dart:_rti

  ClassEntity _findRtiClass(String name) => _findClass(rtiLibrary, name);

  FunctionEntity _findRtiFunction(String name) =>
      _findLibraryMember(rtiLibrary, name);

  FunctionEntity _setRuntimeTypeInfo;
  @override
  FunctionEntity get setRuntimeTypeInfo =>
      _setRuntimeTypeInfo ??= _findRtiFunction('setRuntimeTypeInfo');

  FunctionEntity _findType;
  @override
  FunctionEntity get findType => _findType ??= _findRtiFunction('findType');

  FunctionEntity _instanceType;
  @override
  FunctionEntity get instanceType =>
      _instanceType ??= _findRtiFunction('instanceType');

  FunctionEntity _arrayInstanceType;
  @override
  FunctionEntity get arrayInstanceType =>
      _arrayInstanceType ??= _findRtiFunction('_arrayInstanceType');

  FunctionEntity _simpleInstanceType;
  @override
  FunctionEntity get simpleInstanceType =>
      _simpleInstanceType ??= _findRtiFunction('_instanceType');

  FunctionEntity _typeLiteralMaker;
  @override
  FunctionEntity get typeLiteralMaker =>
      _typeLiteralMaker ??= _findRtiFunction('typeLiteral');

  FunctionEntity _checkTypeBound;
  @override
  FunctionEntity get checkTypeBound =>
      _checkTypeBound ??= _findRtiFunction('checkTypeBound');

  ClassEntity get _rtiImplClass => _findClass(rtiLibrary, 'Rti');
  ClassEntity get _rtiUniverseClass => _findClass(rtiLibrary, '_Universe');
  FieldEntity _findRtiClassField(String name) =>
      _findClassMember(_rtiImplClass, name);

  FieldEntity _rtiAsField;
  @override
  FieldEntity get rtiAsField => _rtiAsField ??= _findRtiClassField('_as');

  FieldEntity _rtiIsField;
  @override
  FieldEntity get rtiIsField => _rtiIsField ??= _findRtiClassField('_is');

  FieldEntity _rtiRestField;
  @override
  FieldEntity get rtiRestField => _rtiRestField ??= _findRtiClassField('_rest');

  FieldEntity _rtiPrecomputed1Field;
  @override
  FieldEntity get rtiPrecomputed1Field =>
      _rtiPrecomputed1Field ??= _findRtiClassField('_precomputed1');

  FunctionEntity _rtiEvalMethod;
  @override
  FunctionEntity get rtiEvalMethod =>
      _rtiEvalMethod ??= _findClassMember(_rtiImplClass, '_eval');

  FunctionEntity _rtiBindMethod;
  @override
  FunctionEntity get rtiBindMethod =>
      _rtiBindMethod ??= _findClassMember(_rtiImplClass, '_bind');

  FunctionEntity _rtiAddRulesMethod;
  @override
  FunctionEntity get rtiAddRulesMethod =>
      _rtiAddRulesMethod ??= _findClassMember(_rtiUniverseClass, 'addRules');

  FunctionEntity _rtiAddErasedTypesMethod;
  @override
  FunctionEntity get rtiAddErasedTypesMethod => _rtiAddErasedTypesMethod ??=
      _findClassMember(_rtiUniverseClass, 'addErasedTypes');

  FunctionEntity _rtiAddTypeParameterVariancesMethod;
  @override
  FunctionEntity get rtiAddTypeParameterVariancesMethod =>
      _rtiAddTypeParameterVariancesMethod ??=
          _findClassMember(_rtiUniverseClass, 'addTypeParameterVariances');

  @override
  FunctionEntity get installSpecializedIsTest =>
      _findRtiFunction('_installSpecializedIsTest');

  @override
  FunctionEntity get installSpecializedAsCheck =>
      _findRtiFunction('_installSpecializedAsCheck');

  FunctionEntity _generalIsTestImplementation;
  @override
  FunctionEntity get generalIsTestImplementation =>
      _generalIsTestImplementation ??=
          _findRtiFunction('_generalIsTestImplementation');

  FunctionEntity _generalNullableIsTestImplementation;
  @override
  FunctionEntity get generalNullableIsTestImplementation =>
      _generalNullableIsTestImplementation ??=
          _findRtiFunction('_generalNullableIsTestImplementation');

  FunctionEntity _generalAsCheckImplementation;
  @override
  FunctionEntity get generalAsCheckImplementation =>
      _generalAsCheckImplementation ??=
          _findRtiFunction('_generalAsCheckImplementation');

  FunctionEntity _generalNullableAsCheckImplementation;
  @override
  FunctionEntity get generalNullableAsCheckImplementation =>
      _generalNullableAsCheckImplementation ??=
          _findRtiFunction('_generalNullableAsCheckImplementation');

  FunctionEntity _specializedIsObject;
  @override
  FunctionEntity get specializedIsObject =>
      _specializedIsObject ??= _findRtiFunction('_isObject');

  FunctionEntity _specializedAsObject;
  @override
  FunctionEntity get specializedAsObject =>
      _specializedAsObject ??= _findRtiFunction('_asObject');

  @override
  FunctionEntity get specializedIsTop => _findRtiFunction('_isTop');

  @override
  FunctionEntity get specializedAsTop => _findRtiFunction('_asTop');

  @override
  FunctionEntity get specializedIsBool => _findRtiFunction('_isBool');

  @override
  FunctionEntity get specializedAsBool => _findRtiFunction('_asBool');

  @override
  FunctionEntity get specializedAsBoolLegacy => _findRtiFunction('_asBoolS');

  @override
  FunctionEntity get specializedAsBoolNullable => _findRtiFunction('_asBoolQ');

  @override
  FunctionEntity get specializedAsDouble => _findRtiFunction('_asDouble');

  @override
  FunctionEntity get specializedAsDoubleLegacy =>
      _findRtiFunction('_asDoubleS');

  @override
  FunctionEntity get specializedAsDoubleNullable =>
      _findRtiFunction('_asDoubleQ');

  @override
  FunctionEntity get specializedIsInt => _findRtiFunction('_isInt');

  @override
  FunctionEntity get specializedAsInt => _findRtiFunction('_asInt');

  @override
  FunctionEntity get specializedAsIntLegacy => _findRtiFunction('_asIntS');

  @override
  FunctionEntity get specializedAsIntNullable => _findRtiFunction('_asIntQ');

  @override
  FunctionEntity get specializedIsNum => _findRtiFunction('_isNum');

  @override
  FunctionEntity get specializedAsNum => _findRtiFunction('_asNum');

  @override
  FunctionEntity get specializedAsNumLegacy => _findRtiFunction('_asNumS');

  @override
  FunctionEntity get specializedAsNumNullable => _findRtiFunction('_asNumQ');

  @override
  FunctionEntity get specializedIsString => _findRtiFunction('_isString');

  @override
  FunctionEntity get specializedAsString => _findRtiFunction('_asString');

  @override
  FunctionEntity get specializedAsStringLegacy =>
      _findRtiFunction('_asStringS');

  @override
  FunctionEntity get specializedAsStringNullable =>
      _findRtiFunction('_asStringQ');

  @override
  FunctionEntity get instantiatedGenericFunctionTypeNewRti =>
      _findRtiFunction('instantiatedGenericFunctionType');

  @override
  FunctionEntity get closureFunctionType =>
      _findRtiFunction('closureFunctionType');

  // From dart:_internal

  ClassEntity _symbolImplementationClass;
  @override
  ClassEntity get symbolImplementationClass =>
      _symbolImplementationClass ??= _findClass(internalLibrary, 'Symbol');

  ClassEntity _externalNameClass;
  @override
  ClassEntity get externalNameClass =>
      _externalNameClass ??= _findClass(internalLibrary, 'ExternalName');
  @override
  InterfaceType get externalNameType => _getRawType(externalNameClass);

  @override
  ConstructorEntity get symbolValidatedConstructor =>
      _symbolValidatedConstructor ??=
          _findConstructor(symbolImplementationClass, 'validated');

  /// Returns the field that holds the internal name in the implementation class
  /// for `Symbol`.
  FieldEntity _symbolImplementationField;
  FieldEntity get symbolImplementationField => _symbolImplementationField ??=
      _env.lookupLocalClassMember(symbolImplementationClass, '_name',
          required: true);

  ConstructorEntity _symbolValidatedConstructor;
  @override
  bool isSymbolValidatedConstructor(ConstructorEntity element) {
    if (_symbolValidatedConstructor != null) {
      return element == _symbolValidatedConstructor;
    }
    return false;
  }

  // From dart:_native_typed_data

  ClassEntity _typedArrayOfIntClass;
  @override
  ClassEntity get typedArrayOfIntClass => _typedArrayOfIntClass ??= _findClass(
      _env.lookupLibrary(Uris.dart__native_typed_data, required: true),
      'NativeTypedArrayOfInt');

  ClassEntity _typedArrayOfDoubleClass;
  @override
  ClassEntity get typedArrayOfDoubleClass =>
      _typedArrayOfDoubleClass ??= _findClass(
          _env.lookupLibrary(Uris.dart__native_typed_data, required: true),
          'NativeTypedArrayOfDouble');

  // From dart:_js_embedded_names

  ClassEntity _jsGetNameEnum;
  @override
  ClassEntity get jsGetNameEnum => _jsGetNameEnum ??= _findClass(
      _env.lookupLibrary(Uris.dart__js_embedded_names, required: true),
      'JsGetName');

  ClassEntity _jsBuiltinEnum;
  @override
  ClassEntity get jsBuiltinEnum => _jsBuiltinEnum ??= _findClass(
      _env.lookupLibrary(Uris.dart__js_embedded_names, required: true),
      'JsBuiltin');

  bool _metaAnnotationChecked = false;
  ClassEntity _metaNoInlineClass;
  ClassEntity _metaTryInlineClass;

  void _ensureMetaAnnotations() {
    if (!_metaAnnotationChecked) {
      _metaAnnotationChecked = true;
      LibraryEntity library = _env.lookupLibrary(Uris.package_meta_dart2js);
      if (library != null) {
        _metaNoInlineClass = _env.lookupClass(library, '_NoInline');
        _metaTryInlineClass = _env.lookupClass(library, '_TryInline');
        if (_metaNoInlineClass == null || _metaTryInlineClass == null) {
          // This is not the package you're looking for.
          _metaNoInlineClass = null;
          _metaTryInlineClass = null;
        }
      }
    }
  }

  @override
  ClassEntity get metaNoInlineClass {
    _ensureMetaAnnotations();
    return _metaNoInlineClass;
  }

  @override
  ClassEntity get metaTryInlineClass {
    _ensureMetaAnnotations();
    return _metaTryInlineClass;
  }

  @override
  bool isForeign(MemberEntity element) => element.library == foreignLibrary;

  @override
  bool isForeignHelper(MemberEntity member) {
    return member.library == foreignLibrary ||
        isCreateInvocationMirrorHelper(member);
  }

  @override
  bool isExternalAllowed(FunctionEntity function) {
    return isForeignHelper(function) ||
        (function is ConstructorEntity &&
            function.isFromEnvironmentConstructor) ||
        maybeEnableNative(function.library.canonicalUri) ||
        // TODO(johnniwinther): Remove this when importing dart:mirrors is
        // a compile-time error.
        function.library.canonicalUri == Uris.dart_mirrors;
  }

  @override
  bool operatorEqHandlesNullArgument(FunctionEntity function) {
    assert(function.name == '==',
        failedAt(function, "Unexpected function $function."));
    ClassEntity cls = function.enclosingClass;
    return cls == objectClass ||
        cls == jsInterceptorClass ||
        cls == jsNullClass;
  }

  @override
  ClassEntity getDefaultSuperclass(
      ClassEntity cls, NativeBasicData nativeBasicData) {
    if (nativeBasicData.isJsInteropClass(cls)) {
      return jsJavaScriptObjectClass;
    }
    // Native classes inherit from Interceptor.
    return nativeBasicData.isNativeClass(cls)
        ? jsInterceptorClass
        : objectClass;
  }
}

/// Interface for accessing libraries, classes and members.
///
/// The element environment makes private and injected members directly
/// available and should therefore not be used to determine scopes.
///
/// The properties exposed are Dart-centric and should therefore, long-term, not
/// be used during codegen, expect for mirrors.
// TODO(johnniwinther): Split this into an element environment and a type query
// interface, the first should only be used during resolution and the latter in
// both resolution and codegen.
abstract class ElementEnvironment {
  /// Returns the main library for the compilation.
  LibraryEntity get mainLibrary;

  /// Returns the main method for the compilation.
  FunctionEntity get mainFunction;

  /// Returns all known libraries.
  Iterable<LibraryEntity> get libraries;

  /// Returns the library name of [library] or '' if the library is unnamed.
  String getLibraryName(LibraryEntity library);

  /// Lookup the library with the canonical [uri], fail if the library is
  /// missing and [required];
  LibraryEntity lookupLibrary(Uri uri, {bool required: false});

  /// Calls [f] for every class declared in [library].
  void forEachClass(LibraryEntity library, void f(ClassEntity cls));

  /// Lookup the class [name] in [library], fail if the class is missing and
  /// [required].
  ClassEntity lookupClass(LibraryEntity library, String name,
      {bool required: false});

  /// Calls [f] for every top level member in [library].
  void forEachLibraryMember(LibraryEntity library, void f(MemberEntity member));

  /// Lookup the member [name] in [library], fail if the class is missing and
  /// [required].
  MemberEntity lookupLibraryMember(LibraryEntity library, String name,
      {bool setter: false, bool required: false});

  /// Lookup the member [name] in [cls], fail if the class is missing and
  /// [required].
  MemberEntity lookupLocalClassMember(ClassEntity cls, String name,
      {bool setter: false, bool required: false});

  /// Lookup the member [name] in [cls] and its superclasses.
  ///
  /// Return `null` if the member is not found in the class or any superclass.
  MemberEntity lookupClassMember(ClassEntity cls, String name,
      {bool setter: false}) {
    var entity = lookupLocalClassMember(cls, name, setter: setter);
    if (entity != null) return entity;

    var superclass = getSuperClass(cls);
    if (superclass == null) return null;

    return lookupClassMember(superclass, name, setter: setter);
  }

  /// Lookup the constructor [name] in [cls], fail if the class is missing and
  /// [required].
  ConstructorEntity lookupConstructor(ClassEntity cls, String name,
      {bool required: false});

  /// Calls [f] for each class member declared in [cls].
  void forEachLocalClassMember(ClassEntity cls, void f(MemberEntity member));

  /// Calls [f] for each class member declared or inherited in [cls] together
  /// with the class that declared the member.
  ///
  /// TODO(johnniwinther): This should not include static members of
  /// superclasses.
  void forEachClassMember(
      ClassEntity cls, void f(ClassEntity declarer, MemberEntity member));

  /// Calls [f] for every constructor declared in [cls].
  ///
  /// Will ensure that the class and all constructors are resolved if
  /// [ensureResolved] is `true`.
  void forEachConstructor(
      ClassEntity cls, void f(ConstructorEntity constructor));

  /// Returns the superclass of [cls].
  ///
  /// If [skipUnnamedMixinApplications] is `true`, unnamed mixin applications
  /// are excluded, for instance for these classes
  ///
  ///     class S {}
  ///     class M {}
  ///     class C extends S with M {}
  ///
  /// the result of `getSuperClass(C)` is the unnamed mixin application
  /// typically named `S+M` and `getSuperClass(S+M)` is `S`, whereas
  /// the result of `getSuperClass(C, skipUnnamedMixinApplications: false)` is
  /// `S`.
  ClassEntity getSuperClass(ClassEntity cls,
      {bool skipUnnamedMixinApplications: false});

  /// Calls [f] for each supertype of [cls].
  void forEachSupertype(ClassEntity cls, void f(InterfaceType supertype));

  /// Calls [f] for each SuperClass of [cls].
  void forEachSuperClass(ClassEntity cls, void f(ClassEntity superClass)) {
    for (var superClass = getSuperClass(cls);
        superClass != null;
        superClass = getSuperClass(superClass)) {
      f(superClass);
    }
  }

  /// Create the instantiation of [cls] with the given [typeArguments] and
  /// [nullability].
  InterfaceType createInterfaceType(
      ClassEntity cls, List<DartType> typeArguments);

  /// Returns the `dynamic` type.
  DartType get dynamicType;

  /// Returns the 'raw type' of [cls]. That is, the instantiation of [cls]
  /// where all types arguments are `dynamic`.
  InterfaceType getRawType(ClassEntity cls);

  /// Returns the 'JS-interop type' of [cls]; that is, the instantiation of
  /// [cls] where all type arguments are 'any'.
  InterfaceType getJsInteropType(ClassEntity cls);

  /// Returns the 'this type' of [cls]. That is, the instantiation of [cls]
  /// where the type arguments are the type variables of [cls].
  InterfaceType getThisType(ClassEntity cls);

  /// Returns the instantiation of [cls] to bounds.
  InterfaceType getClassInstantiationToBounds(ClassEntity cls);

  /// Returns `true` if [cls] is generic.
  bool isGenericClass(ClassEntity cls);

  /// Returns `true` if [cls] is a mixin application (named or unnamed).
  bool isMixinApplication(ClassEntity cls);

  /// Returns `true` if [cls] is an unnamed mixin application.
  bool isUnnamedMixinApplication(ClassEntity cls);

  /// The upper bound on the [typeVariable]. If not explicitly declared, this is
  /// `Object`.
  DartType getTypeVariableBound(TypeVariableEntity typeVariable);

  /// Returns the variances for each type parameter in [cls].
  List<Variance> getTypeVariableVariances(ClassEntity cls);

  /// Returns the type of [function].
  FunctionType getFunctionType(FunctionEntity function);

  /// Returns the function type variables defined on [function].
  List<TypeVariableType> getFunctionTypeVariables(FunctionEntity function);

  /// Returns the type of the [local] function.
  FunctionType getLocalFunctionType(Local local);

  /// Returns the type of [field].
  DartType getFieldType(FieldEntity field);

  /// Returns `true` if [cls] is a Dart enum class.
  bool isEnumClass(ClassEntity cls);

  /// Returns the 'effective' mixin class if [cls] is a mixin application, and
  /// `null` otherwise.
  ///
  /// The 'effective' mixin class is the class from which members are mixed in.
  /// Normally this is the mixin class itself, but not if the mixin class itself
  /// is a mixin application.
  ///
  /// Consider this hierarchy:
  ///
  ///     class A {}
  ///     class B = Object with A {}
  ///     class C = Object with B {}
  ///
  /// The mixin classes of `B` and `C` are `A` and `B`, respectively, but the
  /// _effective_ mixin class of both is `A`.
  ClassEntity getEffectiveMixinClass(ClassEntity cls);
}

abstract class KElementEnvironment extends ElementEnvironment {
  /// Calls [f] for each class that is mixed into [cls] or one of its
  /// superclasses.
  void forEachMixin(ClassEntity cls, void f(ClassEntity mixin));

  /// Returns `true` if [member] a the synthetic getter `loadLibrary` injected
  /// on deferred libraries.
  bool isDeferredLoadLibraryGetter(MemberEntity member);

  /// Returns the imports seen in [library]
  Iterable<ImportEntity> getImports(LibraryEntity library);

  /// Returns the metadata constants declared on [library].
  Iterable<ConstantValue> getLibraryMetadata(LibraryEntity library);

  /// Returns the metadata constants declared on [cls].
  Iterable<ConstantValue> getClassMetadata(ClassEntity cls);

  /// Returns the metadata constants declared on [member].
  Iterable<ConstantValue> getMemberMetadata(MemberEntity member,
      {bool includeParameterMetadata: false});
}

abstract class JElementEnvironment extends ElementEnvironment {
  /// Calls [f] for each class member added to [cls] during compilation.
  void forEachInjectedClassMember(ClassEntity cls, void f(MemberEntity member));

  /// Calls [f] for every constructor body in [cls].
  void forEachConstructorBody(
      ClassEntity cls, void f(ConstructorBodyEntity constructorBody));

  /// Calls [f] for each nested closure in [member].
  void forEachNestedClosure(
      MemberEntity member, void f(FunctionEntity closure));

  /// Returns `true` if [cls] is a mixin application that mixes in methods with
  /// super calls.
  bool isSuperMixinApplication(ClassEntity cls);

  /// The default type of the [typeVariable].
  ///
  /// This is the type used as the default type argument when no explicit type
  /// argument is passed.
  DartType getTypeVariableDefaultType(TypeVariableEntity typeVariable);

  /// Returns the 'element' type of a function with the async, async* or sync*
  /// marker [marker]. [returnType] is the return type marked function.
  DartType getAsyncOrSyncStarElementType(
      AsyncMarker marker, DartType returnType);

  /// Returns the 'element' type of a function with an async, async* or sync*
  /// marker. The return type of the method is inspected to determine the type
  /// parameter of the Future, Stream or Iterable.
  DartType getFunctionAsyncOrSyncStarElementType(FunctionEntity function);

  /// Calls [f] with every instance field, together with its declarer, in an
  /// instance of [cls]. All fields inherited from superclasses and mixins are
  /// included.
  ///
  /// If [isElided] is `true`, the field is not read and should therefore not
  /// be emitted.
  void forEachInstanceField(
      ClassEntity cls, void f(ClassEntity declarer, FieldEntity field));

  /// Calls [f] with every instance field declared directly in class [cls]
  /// (i.e. no inherited fields). Fields are presented in initialization
  /// (i.e. textual) order.
  ///
  /// If [isElided] is `true`, the field is not read and should therefore not
  /// be emitted.
  void forEachDirectInstanceField(ClassEntity cls, void f(FieldEntity field));

  /// Calls [f] for each parameter of [function] providing the type and name of
  /// the parameter and the [defaultValue] if the parameter is optional.
  void forEachParameter(covariant FunctionEntity function,
      void f(DartType type, String name, ConstantValue defaultValue));

  /// Calls [f] for each parameter - given as a [Local] - of [function].
  void forEachParameterAsLocal(GlobalLocalsMap globalLocalsMap,
      FunctionEntity function, void f(Local parameter));
}
