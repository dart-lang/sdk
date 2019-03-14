// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(sigmund): rename and move to common/elements.dart
library dart2js.type_system;

import 'common.dart';
import 'common/names.dart' show Identifiers, Uris;
import 'constants/constant_system.dart' as constant_system;
import 'constants/expressions.dart' show ConstantExpression;
import 'constants/values.dart';
import 'elements/entities.dart';
import 'elements/types.dart';
import 'inferrer/abstract_value_domain.dart';
import 'js_backend/native_data.dart' show NativeBasicData;
import 'kernel/dart2js_target.dart';
import 'universe/selector.dart' show Selector;

/// The common elements and types in Dart.
abstract class CommonElements {
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
  LibraryEntity get internalLibrary;

  /// The `NativeTypedData` class from dart:typed_data.
  ClassEntity get typedDataClass;

  /// Constructor of the `Symbol` class in dart:internal. This getter will
  /// ensure that `Symbol` is resolved and lookup the constructor on demand.
  ConstructorEntity get symbolConstructorTarget;

  /// Whether [element] is the same as [symbolConstructor]. Used to check
  /// for the constructor without computing it until it is likely to be seen.
  bool isSymbolConstructor(ConstructorEntity element);

  /// The function `identical` in dart:core.
  FunctionEntity get identicalFunction;

  /// Whether [element] is the `Function.apply` method. This will not
  /// resolve the apply method if it hasn't been seen yet during compilation.
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

  /// The `Resource` type defined in 'dart:core'.
  InterfaceType get resourceType;

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

  /// Returns `true` if [element] is a superclass of `String` or `num`.
  bool isNumberOrStringSupertype(ClassEntity element);

  /// Returns `true` if [element] is a superclass of `String`.
  bool isStringOnlySupertype(ClassEntity element);

  /// Returns `true` if [element] is a superclass of `List`.
  bool isListSupertype(ClassEntity element);

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

  ClassEntity get typeVariableClass;

  ClassEntity get jsInvocationMirrorClass;

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

  ConstructorEntity get typeVariableConstructor;

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

  FunctionEntity get throwRuntimeError;

  FunctionEntity get throwUnsupportedError;

  FunctionEntity get throwTypeError;

  FunctionEntity get throwAbstractClassInstantiationError;

  FunctionEntity get checkConcurrentModificationError;

  FunctionEntity get throwConcurrentModificationError;

  FunctionEntity get stringInterpolationHelper;

  FunctionEntity get wrapExceptionHelper;

  FunctionEntity get throwExpressionHelper;

  FunctionEntity get closureConverter;

  FunctionEntity get traceFromException;

  FunctionEntity get setRuntimeTypeInfo;

  FunctionEntity get getRuntimeTypeInfo;

  FunctionEntity get getTypeArgumentByIndex;

  FunctionEntity get computeSignature;

  FunctionEntity get getRuntimeTypeArguments;

  FunctionEntity get getRuntimeTypeArgument;

  FunctionEntity get getRuntimeTypeArgumentIntercepted;

  FunctionEntity get assertIsSubtype;

  FunctionEntity get checkSubtype;

  FunctionEntity get assertSubtype;

  FunctionEntity get subtypeCast;

  FunctionEntity get functionTypeTest;

  FunctionEntity get futureOrTest;

  FunctionEntity get checkSubtypeOfRuntimeType;

  FunctionEntity get assertSubtypeOfRuntimeType;

  FunctionEntity get subtypeOfRuntimeTypeCast;

  FunctionEntity get checkDeferredIsLoaded;

  FunctionEntity get throwNoSuchMethod;

  FunctionEntity get createRuntimeType;

  FunctionEntity get fallThroughError;

  FunctionEntity get createInvocationMirror;

  FunctionEntity get createUnmangledInvocationMirror;

  FunctionEntity get cyclicThrowHelper;

  FunctionEntity get defineProperty;

  bool isExtractTypeArguments(FunctionEntity member);

  ClassEntity getInstantiationClass(int typeArgumentCount);

  FunctionEntity getInstantiateFunction(int typeArgumentCount);

  FunctionEntity get instantiatedGenericFunctionType;

  FunctionEntity get extractFunctionTypeObjectFromInternal;

  // From dart:_internal

  ClassEntity get symbolImplementationClass;

  /// Used to annotate items that have the keyword "native".
  ClassEntity get externalNameClass;

  InterfaceType get externalNameType;

  ConstructorEntity get symbolValidatedConstructor;

  // From dart:_js_embedded_names

  ClassEntity get jsGetNameEnum;

  /// Returns `true` if [member] is a "foreign helper", that is, a member whose
  /// semantics is defined synthetically and not through Dart code.
  ///
  /// Most foreign helpers are located in the `dart:_foreign_helper` library.
  bool isForeignHelper(MemberEntity member);

  ClassEntity getDefaultSuperclass(
      ClassEntity cls, NativeBasicData nativeBasicData);
}

abstract class KCommonElements implements CommonElements {
  // From package:js
  ClassEntity get jsAnnotationClass;

  ClassEntity get jsAnonymousClass;

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
  /// Returns `true` if [element] is the unnamed constructor of `List`. This
  /// will not resolve the constructor if it hasn't been seen yet during
  /// compilation.
  bool isUnnamedListConstructor(ConstructorEntity element);

  /// Returns `true` if [element] is the 'filled' constructor of `List`. This
  /// will not resolve the constructor if it hasn't been seen yet during
  /// compilation.
  bool isFilledListConstructor(ConstructorEntity element);

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

  ClassEntity get jsBuiltinEnum;

  bool isForeign(MemberEntity element);

  /// Returns `true` if the implementation of the 'operator ==' [function] is
  /// known to handle `null` as argument.
  bool operatorEqHandlesNullArgument(FunctionEntity function);
}

class CommonElementsImpl
    implements CommonElements, KCommonElements, JCommonElements {
  final ElementEnvironment _env;

  CommonElementsImpl(this._env);

  /// The `Object` class defined in 'dart:core'.
  ClassEntity _objectClass;
  @override
  ClassEntity get objectClass =>
      _objectClass ??= _findClass(coreLibrary, 'Object');

  /// The `bool` class defined in 'dart:core'.
  ClassEntity _boolClass;
  @override
  ClassEntity get boolClass => _boolClass ??= _findClass(coreLibrary, 'bool');

  /// The `num` class defined in 'dart:core'.
  ClassEntity _numClass;
  @override
  ClassEntity get numClass => _numClass ??= _findClass(coreLibrary, 'num');

  /// The `int` class defined in 'dart:core'.
  ClassEntity _intClass;
  @override
  ClassEntity get intClass => _intClass ??= _findClass(coreLibrary, 'int');

  /// The `double` class defined in 'dart:core'.
  ClassEntity _doubleClass;
  @override
  ClassEntity get doubleClass =>
      _doubleClass ??= _findClass(coreLibrary, 'double');

  /// The `String` class defined in 'dart:core'.
  ClassEntity _stringClass;
  @override
  ClassEntity get stringClass =>
      _stringClass ??= _findClass(coreLibrary, 'String');

  /// The `Function` class defined in 'dart:core'.
  ClassEntity _functionClass;
  @override
  ClassEntity get functionClass =>
      _functionClass ??= _findClass(coreLibrary, 'Function');

  /// The `Resource` class defined in 'dart:core'.
  ClassEntity _resourceClass;
  @override
  ClassEntity get resourceClass =>
      _resourceClass ??= _findClass(coreLibrary, 'Resource');

  /// The `Symbol` class defined in 'dart:core'.
  ClassEntity _symbolClass;
  @override
  ClassEntity get symbolClass =>
      _symbolClass ??= _findClass(coreLibrary, 'Symbol');

  /// The `Null` class defined in 'dart:core'.
  ClassEntity _nullClass;
  @override
  ClassEntity get nullClass => _nullClass ??= _findClass(coreLibrary, 'Null');

  /// The `Type` class defined in 'dart:core'.
  ClassEntity _typeClass;
  @override
  ClassEntity get typeClass => _typeClass ??= _findClass(coreLibrary, 'Type');

  /// The `StackTrace` class defined in 'dart:core';
  ClassEntity _stackTraceClass;
  @override
  ClassEntity get stackTraceClass =>
      _stackTraceClass ??= _findClass(coreLibrary, 'StackTrace');

  /// The `List` class defined in 'dart:core';
  ClassEntity _listClass;
  @override
  ClassEntity get listClass => _listClass ??= _findClass(coreLibrary, 'List');

  /// The `Set` class defined in 'dart:core'.
  ClassEntity _setClass;
  @override
  ClassEntity get setClass => _setClass ??= _findClass(coreLibrary, 'Set');

  /// The `Map` class defined in 'dart:core';
  ClassEntity _mapClass;
  @override
  ClassEntity get mapClass => _mapClass ??= _findClass(coreLibrary, 'Map');

  /// The `_UnmodifiableSet` class defined in 'dart:collection';
  ClassEntity _unmodifiableSetClass;
  @override
  ClassEntity get unmodifiableSetClass => _unmodifiableSetClass ??=
      _findClass(_env.lookupLibrary(Uris.dart_collection), '_UnmodifiableSet');

  /// The `Iterable` class defined in 'dart:core';
  ClassEntity _iterableClass;
  @override
  ClassEntity get iterableClass =>
      _iterableClass ??= _findClass(coreLibrary, 'Iterable');

  /// The `Future` class defined in 'async';.
  ClassEntity _futureClass;
  @override
  ClassEntity get futureClass =>
      _futureClass ??= _findClass(asyncLibrary, 'Future');

  /// The `Stream` class defined in 'async';
  ClassEntity _streamClass;
  @override
  ClassEntity get streamClass =>
      _streamClass ??= _findClass(asyncLibrary, 'Stream');

  /// The dart:core library.
  LibraryEntity _coreLibrary;
  @override
  LibraryEntity get coreLibrary =>
      _coreLibrary ??= _env.lookupLibrary(Uris.dart_core, required: true);

  /// The dart:async library.
  LibraryEntity _asyncLibrary;
  @override
  LibraryEntity get asyncLibrary =>
      _asyncLibrary ??= _env.lookupLibrary(Uris.dart_async);

  /// The dart:mirrors library. Null if the program doesn't access dart:mirrors.
  LibraryEntity _mirrorsLibrary;
  @override
  LibraryEntity get mirrorsLibrary =>
      _mirrorsLibrary ??= _env.lookupLibrary(Uris.dart_mirrors);

  /// The dart:typed_data library.
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

  /// Reference to the internal library to lookup functions to always inline.
  LibraryEntity _internalLibrary;
  @override
  LibraryEntity get internalLibrary => _internalLibrary ??=
      _env.lookupLibrary(Uris.dart__internal, required: true);

  /// The `NativeTypedData` class from dart:typed_data.
  ClassEntity _typedDataClass;
  @override
  ClassEntity get typedDataClass =>
      _typedDataClass ??= _findClass(typedDataLibrary, 'NativeTypedData');

  /// Constructor of the `Symbol` class in dart:internal. This getter will
  /// ensure that `Symbol` is resolved and lookup the constructor on demand.
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

  /// Whether [element] is the same as [symbolConstructor]. Used to check
  /// for the constructor without computing it until it is likely to be seen.
  @override
  bool isSymbolConstructor(ConstructorEntity element) {
    assert(element != null);
    _ensureSymbolConstructorDependencies();
    return element == _symbolConstructorImplementationTarget ||
        element == _symbolConstructorTarget;
  }

  /// The function `identical` in dart:core.
  FunctionEntity _identicalFunction;
  @override
  FunctionEntity get identicalFunction =>
      _identicalFunction ??= _findLibraryMember(coreLibrary, 'identical');

  /// Whether [element] is the `Function.apply` method. This will not
  /// resolve the apply method if it hasn't been seen yet during compilation.
  @override
  bool isFunctionApplyMethod(MemberEntity element) =>
      element.name == 'apply' && element.enclosingClass == functionClass;

  /// Returns `true` if [element] is the unnamed constructor of `List`. This
  /// will not resolve the constructor if it hasn't been seen yet during
  /// compilation.
  @override
  bool isUnnamedListConstructor(ConstructorEntity element) =>
      (element.name == '' && element.enclosingClass == listClass) ||
      (element.name == 'list' && element.enclosingClass == jsArrayClass);

  /// Returns `true` if [element] is the 'filled' constructor of `List`. This
  /// will not resolve the constructor if it hasn't been seen yet during
  /// compilation.
  @override
  bool isFilledListConstructor(ConstructorEntity element) =>
      element.name == 'filled' && element.enclosingClass == listClass;

  /// The `dynamic` type.
  @override
  DynamicType get dynamicType => _env.dynamicType;

  /// The `Object` type defined in 'dart:core'.
  @override
  InterfaceType get objectType => _getRawType(objectClass);

  /// The `bool` type defined in 'dart:core'.
  @override
  InterfaceType get boolType => _getRawType(boolClass);

  /// The `num` type defined in 'dart:core'.
  @override
  InterfaceType get numType => _getRawType(numClass);

  /// The `int` type defined in 'dart:core'.
  @override
  InterfaceType get intType => _getRawType(intClass);

  /// The `double` type defined in 'dart:core'.
  @override
  InterfaceType get doubleType => _getRawType(doubleClass);

  /// The `Resource` type defined in 'dart:core'.
  @override
  InterfaceType get resourceType => _getRawType(resourceClass);

  /// The `String` type defined in 'dart:core'.
  @override
  InterfaceType get stringType => _getRawType(stringClass);

  /// The `Symbol` type defined in 'dart:core'.
  @override
  InterfaceType get symbolType => _getRawType(symbolClass);

  /// The `Function` type defined in 'dart:core'.
  @override
  InterfaceType get functionType => _getRawType(functionClass);

  /// The `Null` type defined in 'dart:core'.
  @override
  InterfaceType get nullType => _getRawType(nullClass);

  /// The `Type` type defined in 'dart:core'.
  @override
  InterfaceType get typeType => _getRawType(typeClass);

  @override
  InterfaceType get typeLiteralType => _getRawType(typeLiteralClass);

  /// The `StackTrace` type defined in 'dart:core';
  @override
  InterfaceType get stackTraceType => _getRawType(stackTraceClass);

  /// Returns an instance of the `List` type defined in 'dart:core' with
  /// [elementType] as its type argument.
  ///
  /// If no type argument is provided, the canonical raw type is returned.
  @override
  InterfaceType listType([DartType elementType]) {
    if (elementType == null) {
      return _getRawType(listClass);
    }
    return _createInterfaceType(listClass, [elementType]);
  }

  /// Returns an instance of the `Set` type defined in 'dart:core' with
  /// [elementType] as its type argument.
  ///
  /// If no type argument is provided, the canonical raw type is returned.
  @override
  InterfaceType setType([DartType elementType]) {
    if (elementType == null) {
      return _getRawType(setClass);
    }
    return _createInterfaceType(setClass, [elementType]);
  }

  /// Returns an instance of the `Map` type defined in 'dart:core' with
  /// [keyType] and [valueType] as its type arguments.
  ///
  /// If no type arguments are provided, the canonical raw type is returned.
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

  /// Returns an instance of the `Iterable` type defined in 'dart:core' with
  /// [elementType] as its type argument.
  ///
  /// If no type argument is provided, the canonical raw type is returned.
  @override
  InterfaceType iterableType([DartType elementType]) {
    if (elementType == null) {
      return _getRawType(iterableClass);
    }
    return _createInterfaceType(iterableClass, [elementType]);
  }

  /// Returns an instance of the `Future` type defined in 'dart:async' with
  /// [elementType] as its type argument.
  ///
  /// If no type argument is provided, the canonical raw type is returned.
  @override
  InterfaceType futureType([DartType elementType]) {
    if (elementType == null) {
      return _getRawType(futureClass);
    }
    return _createInterfaceType(futureClass, [elementType]);
  }

  /// Returns an instance of the `Stream` type defined in 'dart:async' with
  /// [elementType] as its type argument.
  ///
  /// If no type argument is provided, the canonical raw type is returned.
  @override
  InterfaceType streamType([DartType elementType]) {
    if (elementType == null) {
      return _getRawType(streamClass);
    }
    return _createInterfaceType(streamClass, [elementType]);
  }

  /// Returns `true` if [element] is a superclass of `String` or `num`.
  @override
  bool isNumberOrStringSupertype(ClassEntity element) {
    return element == _findClass(coreLibrary, 'Comparable', required: false);
  }

  /// Returns `true` if [element] is a superclass of `String`.
  @override
  bool isStringOnlySupertype(ClassEntity element) {
    return element == _findClass(coreLibrary, 'Pattern', required: false);
  }

  /// Returns `true` if [element] is a superclass of `List`.
  @override
  bool isListSupertype(ClassEntity element) => element == iterableClass;

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

  /// Create the instantiation of [cls] with the given [typeArguments].
  InterfaceType _createInterfaceType(
      ClassEntity cls, List<DartType> typeArguments) {
    return _env.createInterfaceType(cls, typeArguments);
  }

  @override
  InterfaceType getConstantMapTypeFor(InterfaceType sourceType,
      {bool hasProtoKey: false, bool onlyStringKeys: false}) {
    ClassEntity classElement = onlyStringKeys
        ? (hasProtoKey ? constantProtoMapClass : constantStringMapClass)
        : generalConstantMapClass;
    List<DartType> typeArgument = sourceType.typeArguments;
    if (sourceType.treatAsRaw) {
      return _env.getRawType(classElement);
    } else {
      return _env.createInterfaceType(classElement, typeArgument);
    }
  }

  @override
  InterfaceType getConstantSetTypeFor(InterfaceType sourceType) =>
      sourceType.treatAsRaw
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

  /// Returns `true` member is the 'findIndexForNativeSubclassType' method
  /// declared in `dart:_interceptors`.
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

  /// Returns `true` if [selector] applies to `JSIndexable.length`.
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

  /// Returns `true` if [selector] applies to `JSString.split` on [receiver]
  /// in the given [world].
  ///
  /// Returns `false` if `JSString.split` is not available.
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

  // From package:js
  ClassEntity _jsAnnotationClass;
  @override
  ClassEntity get jsAnnotationClass {
    if (_jsAnnotationClass == null) {
      LibraryEntity library = _env.lookupLibrary(Uris.package_js);
      if (library == null) return null;
      _jsAnnotationClass = _findClass(library, 'JS');
    }
    return _jsAnnotationClass;
  }

  ClassEntity _jsAnonymousClass;
  @override
  ClassEntity get jsAnonymousClass {
    if (_jsAnonymousClass == null) {
      LibraryEntity library = _env.lookupLibrary(Uris.package_js);
      if (library == null) return null;
      _jsAnonymousClass = _findClass(library, '_Anonymous');
    }
    return _jsAnonymousClass;
  }

  // From dart:_js_helper
  // TODO(johnniwinther): Avoid the need for this (from [CheckedModeHelper]).
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
      _typeLiteralClass ??= _findHelperClass('TypeImpl');

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

  ClassEntity _typeVariableClass;
  @override
  ClassEntity get typeVariableClass =>
      _typeVariableClass ??= _findHelperClass('TypeVariable');

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

  MemberEntity _invocationTypeArgumentGetter;
  @override
  MemberEntity get invocationTypeArgumentGetter =>
      _invocationTypeArgumentGetter ??=
          _findClassMember(jsInvocationMirrorClass, 'typeArguments');

  /// Interface used to determine if an object has the JavaScript
  /// indexing behavior. The interface is only visible to specific libraries.
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

  /// The class for native annotations defined in dart:_js_helper.
  ClassEntity _nativeAnnotationClass;
  @override
  ClassEntity get nativeAnnotationClass =>
      _nativeAnnotationClass ??= _findHelperClass('Native');

  ConstructorEntity _typeVariableConstructor;
  @override
  ConstructorEntity get typeVariableConstructor => _typeVariableConstructor ??=
      _env.lookupConstructor(typeVariableClass, '');

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

  /// Holds the method "getIsolateAffinityTag" when dart:_js_helper has been
  /// loaded.
  FunctionEntity _getIsolateAffinityTagMarker;
  @override
  FunctionEntity get getIsolateAffinityTagMarker =>
      _getIsolateAffinityTagMarker ??=
          _findHelperFunction('getIsolateAffinityTag');

  /// Holds the method "requiresPreamble" in _js_helper.
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
  FunctionEntity get throwRuntimeError =>
      _findHelperFunction('throwRuntimeError');

  @override
  FunctionEntity get throwUnsupportedError =>
      _findHelperFunction('throwUnsupportedError');

  @override
  FunctionEntity get throwTypeError => _findHelperFunction('throwTypeError');

  @override
  FunctionEntity get throwAbstractClassInstantiationError =>
      _findHelperFunction('throwAbstractClassInstantiationError');

  FunctionEntity _cachedCheckConcurrentModificationError;
  @override
  FunctionEntity get checkConcurrentModificationError =>
      _cachedCheckConcurrentModificationError ??=
          _findHelperFunction('checkConcurrentModificationError');

  @override
  FunctionEntity get throwConcurrentModificationError =>
      _findHelperFunction('throwConcurrentModificationError');

  /// Return `true` if [member] is the 'checkInt' function defined in
  /// dart:_js_helpers.
  @override
  bool isCheckInt(MemberEntity member) {
    return member.isFunction &&
        member.isTopLevel &&
        member.library == jsHelperLibrary &&
        member.name == 'checkInt';
  }

  /// Return `true` if [member] is the 'checkNum' function defined in
  /// dart:_js_helpers.
  @override
  bool isCheckNum(MemberEntity member) {
    return member.isFunction &&
        member.isTopLevel &&
        member.library == jsHelperLibrary &&
        member.name == 'checkNum';
  }

  /// Return `true` if [member] is the 'checkString' function defined in
  /// dart:_js_helpers.
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
  FunctionEntity get setRuntimeTypeInfo =>
      _findHelperFunction('setRuntimeTypeInfo');

  @override
  FunctionEntity get getRuntimeTypeInfo =>
      _findHelperFunction('getRuntimeTypeInfo');

  @override
  FunctionEntity get getTypeArgumentByIndex =>
      _findHelperFunction('getTypeArgumentByIndex');

  @override
  FunctionEntity get computeSignature =>
      _findHelperFunction('computeSignature');

  @override
  FunctionEntity get getRuntimeTypeArguments =>
      _findHelperFunction('getRuntimeTypeArguments');

  @override
  FunctionEntity get getRuntimeTypeArgument =>
      _findHelperFunction('getRuntimeTypeArgument');

  @override
  FunctionEntity get getRuntimeTypeArgumentIntercepted =>
      _findHelperFunction('getRuntimeTypeArgumentIntercepted');

  @override
  FunctionEntity get assertIsSubtype => _findHelperFunction('assertIsSubtype');

  @override
  FunctionEntity get checkSubtype => _findHelperFunction('checkSubtype');

  @override
  FunctionEntity get assertSubtype => _findHelperFunction('assertSubtype');

  @override
  FunctionEntity get subtypeCast => _findHelperFunction('subtypeCast');

  @override
  FunctionEntity get functionTypeTest =>
      _findHelperFunction('functionTypeTest');

  @override
  FunctionEntity get futureOrTest => _findHelperFunction('futureOrTest');

  @override
  FunctionEntity get checkSubtypeOfRuntimeType =>
      _findHelperFunction('checkSubtypeOfRuntimeType');

  @override
  FunctionEntity get assertSubtypeOfRuntimeType =>
      _findHelperFunction('assertSubtypeOfRuntimeType');

  @override
  FunctionEntity get subtypeOfRuntimeTypeCast =>
      _findHelperFunction('subtypeOfRuntimeTypeCast');

  @override
  FunctionEntity get checkDeferredIsLoaded =>
      _findHelperFunction('checkDeferredIsLoaded');

  @override
  FunctionEntity get throwNoSuchMethod =>
      _findHelperFunction('throwNoSuchMethod');

  @override
  FunctionEntity get createRuntimeType =>
      _findHelperFunction('createRuntimeType');

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
  FunctionEntity get instantiatedGenericFunctionType =>
      _findHelperFunction('instantiatedGenericFunctionType');

  @override
  FunctionEntity get extractFunctionTypeObjectFromInternal =>
      _findHelperFunction('extractFunctionTypeObjectFromInternal');

  @override
  bool isInstantiationClass(ClassEntity cls) {
    return cls.library == _jsHelperLibrary &&
        cls.name != 'Instantiation' &&
        cls.name.startsWith('Instantiation');
  }

  // From dart:_internal

  ClassEntity _symbolImplementationClass;
  @override
  ClassEntity get symbolImplementationClass =>
      _symbolImplementationClass ??= _findClass(internalLibrary, 'Symbol');

  /// Used to annotate items that have the keyword "native".
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

  /// Holds the class for the [JsGetName] enum.
  ClassEntity _jsGetNameEnum;
  @override
  ClassEntity get jsGetNameEnum => _jsGetNameEnum ??= _findClass(
      _env.lookupLibrary(Uris.dart__js_embedded_names, required: true),
      'JsGetName');

  /// Holds the class for the [JsBuiltins] enum.
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

  /// Returns `true` if [member] is a "foreign helper", that is, a member whose
  /// semantics is defined synthetically and not through Dart code.
  ///
  /// Most foreign helpers are located in the `dart:_foreign_helper` library.
  @override
  bool isForeignHelper(MemberEntity member) {
    return member.library == foreignLibrary ||
        isCreateInvocationMirrorHelper(member);
  }

  /// Returns `true` if [function] is allowed to be external.
  ///
  /// This returns `true` for foreign helpers, from environment constructors and
  /// members of libraries that support native.
  ///
  /// This returns `false` for JS interop members which therefore must be
  /// allowed to be external through the JS interop annotation handling.
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

  /// Returns `true` if the implementation of the 'operator ==' [function] is
  /// known to handle `null` as argument.
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

  /// Create the instantiation of [cls] with the given [typeArguments].
  InterfaceType createInterfaceType(
      ClassEntity cls, List<DartType> typeArguments);

  /// Returns the `dynamic` type.
  DartType get dynamicType;

  /// Returns the 'raw type' of [cls]. That is, the instantiation of [cls]
  /// where all types arguments are `dynamic`.
  InterfaceType getRawType(ClassEntity cls);

  /// Returns the 'this type' of [cls]. That is, the instantiation of [cls]
  /// where the type arguments are the type variables of [cls].
  InterfaceType getThisType(ClassEntity cls);

  /// Returns `true` if [cls] is generic.
  bool isGenericClass(ClassEntity cls);

  /// Returns `true` if [cls] is a mixin application (named or unnamed).
  bool isMixinApplication(ClassEntity cls);

  /// Returns `true` if [cls] is an unnamed mixin application.
  bool isUnnamedMixinApplication(ClassEntity cls);

  /// The upper bound on the [typeVariable]. If not explicitly declared, this is
  /// `Object`.
  DartType getTypeVariableBound(TypeVariableEntity typeVariable);

  /// Returns the type of [function].
  FunctionType getFunctionType(FunctionEntity function);

  /// Returns the function type variables defined on [function].
  List<TypeVariableType> getFunctionTypeVariables(FunctionEntity function);

  /// Returns the type of the [local] function.
  FunctionType getLocalFunctionType(Local local);

  /// Returns the type of [field].
  DartType getFieldType(FieldEntity field);

  /// Returns the 'unaliased' type of [type]. For typedefs this is the function
  /// type it is an alias of, for other types it is the type itself.
  ///
  /// Use this during resolution to ensure that the alias has been computed.
  // TODO(johnniwinther): Remove this when the resolver is removed.
  DartType getUnaliasedType(DartType type);

  /// Returns `true` if [cls] is a Dart enum class.
  bool isEnumClass(ClassEntity cls);
}

abstract class KElementEnvironment extends ElementEnvironment {
  /// Calls [f] for each class that is mixed into [cls] or one of its
  /// superclasses.
  void forEachMixin(ClassEntity cls, void f(ClassEntity mixin));

  /// Gets the constant value of [field], or `null` if [field] is non-const.
  ConstantExpression getFieldConstantForTesting(FieldEntity field);

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
}
