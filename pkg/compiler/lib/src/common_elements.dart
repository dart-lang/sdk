// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(sigmund): rename and move to common/elements.dart
library dart2js.type_system;

import 'common.dart';
import 'common/names.dart' show Identifiers, Uris;
import 'constants/values.dart';
import 'elements/entities.dart';
import 'elements/names.dart' show PublicName;
import 'elements/types.dart';
import 'js_backend/backend.dart' show JavaScriptBackend;
import 'js_backend/constant_system_javascript.dart';
import 'js_backend/native_data.dart' show NativeBasicData;
import 'constants/expressions.dart' show ConstantExpression;
import 'universe/call_structure.dart' show CallStructure;
import 'universe/selector.dart' show Selector;
import 'universe/call_structure.dart';

/// The common elements and types in Dart.
class CommonElements {
  final ElementEnvironment _env;

  CommonElements(this._env);

  /// The `Object` class defined in 'dart:core'.
  ClassEntity _objectClass;
  ClassEntity get objectClass =>
      _objectClass ??= _findClass(coreLibrary, 'Object');

  /// The `bool` class defined in 'dart:core'.
  ClassEntity _boolClass;
  ClassEntity get boolClass => _boolClass ??= _findClass(coreLibrary, 'bool');

  /// The `num` class defined in 'dart:core'.
  ClassEntity _numClass;
  ClassEntity get numClass => _numClass ??= _findClass(coreLibrary, 'num');

  /// The `int` class defined in 'dart:core'.
  ClassEntity _intClass;
  ClassEntity get intClass => _intClass ??= _findClass(coreLibrary, 'int');

  /// The `double` class defined in 'dart:core'.
  ClassEntity _doubleClass;
  ClassEntity get doubleClass =>
      _doubleClass ??= _findClass(coreLibrary, 'double');

  /// The `String` class defined in 'dart:core'.
  ClassEntity _stringClass;
  ClassEntity get stringClass =>
      _stringClass ??= _findClass(coreLibrary, 'String');

  /// The `Function` class defined in 'dart:core'.
  ClassEntity _functionClass;
  ClassEntity get functionClass =>
      _functionClass ??= _findClass(coreLibrary, 'Function');

  /// The `Resource` class defined in 'dart:core'.
  ClassEntity _resourceClass;
  ClassEntity get resourceClass =>
      _resourceClass ??= _findClass(coreLibrary, 'Resource');

  /// The `Symbol` class defined in 'dart:core'.
  ClassEntity _symbolClass;
  ClassEntity get symbolClass =>
      _symbolClass ??= _findClass(coreLibrary, 'Symbol');

  /// The `Null` class defined in 'dart:core'.
  ClassEntity _nullClass;
  ClassEntity get nullClass => _nullClass ??= _findClass(coreLibrary, 'Null');

  /// The `Type` class defined in 'dart:core'.
  ClassEntity _typeClass;
  ClassEntity get typeClass => _typeClass ??= _findClass(coreLibrary, 'Type');

  /// The `StackTrace` class defined in 'dart:core';
  ClassEntity _stackTraceClass;
  ClassEntity get stackTraceClass =>
      _stackTraceClass ??= _findClass(coreLibrary, 'StackTrace');

  /// The `List` class defined in 'dart:core';
  ClassEntity _listClass;
  ClassEntity get listClass => _listClass ??= _findClass(coreLibrary, 'List');

  /// The `Map` class defined in 'dart:core';
  ClassEntity _mapClass;
  ClassEntity get mapClass => _mapClass ??= _findClass(coreLibrary, 'Map');

  /// The `Iterable` class defined in 'dart:core';
  ClassEntity _iterableClass;
  ClassEntity get iterableClass =>
      _iterableClass ??= _findClass(coreLibrary, 'Iterable');

  /// The `Future` class defined in 'async';.
  ClassEntity _futureClass;
  ClassEntity get futureClass =>
      _futureClass ??= _findClass(asyncLibrary, 'Future');

  /// The `Stream` class defined in 'async';
  ClassEntity _streamClass;
  ClassEntity get streamClass =>
      _streamClass ??= _findClass(asyncLibrary, 'Stream');

  /// The dart:core library.
  LibraryEntity _coreLibrary;
  LibraryEntity get coreLibrary =>
      _coreLibrary ??= _env.lookupLibrary(Uris.dart_core, required: true);

  /// The dart:async library.
  LibraryEntity _asyncLibrary;
  LibraryEntity get asyncLibrary =>
      _asyncLibrary ??= _env.lookupLibrary(Uris.dart_async);

  /// The dart:mirrors library. Null if the program doesn't access dart:mirrors.
  LibraryEntity _mirrorsLibrary;
  LibraryEntity get mirrorsLibrary =>
      _mirrorsLibrary ??= _env.lookupLibrary(Uris.dart_mirrors);

  /// The dart:typed_data library.
  LibraryEntity _typedDataLibrary;
  LibraryEntity get typedDataLibrary =>
      _typedDataLibrary ??= _env.lookupLibrary(Uris.dart__native_typed_data);

  LibraryEntity _jsHelperLibrary;
  LibraryEntity get jsHelperLibrary =>
      _jsHelperLibrary ??= _env.lookupLibrary(Uris.dart__js_helper);

  LibraryEntity _interceptorsLibrary;
  LibraryEntity get interceptorsLibrary =>
      _interceptorsLibrary ??= _env.lookupLibrary(Uris.dart__interceptors);

  LibraryEntity _foreignLibrary;
  LibraryEntity get foreignLibrary =>
      _foreignLibrary ??= _env.lookupLibrary(Uris.dart__foreign_helper);

  LibraryEntity _isolateHelperLibrary;
  LibraryEntity get isolateHelperLibrary =>
      _isolateHelperLibrary ??= _env.lookupLibrary(Uris.dart__isolate_helper);

  /// Reference to the internal library to lookup functions to always inline.
  LibraryEntity _internalLibrary;
  LibraryEntity get internalLibrary => _internalLibrary ??=
      _env.lookupLibrary(Uris.dart__internal, required: true);

  /// The `NativeTypedData` class from dart:typed_data.
  ClassEntity _typedDataClass;
  ClassEntity get typedDataClass =>
      _typedDataClass ??= _findClass(typedDataLibrary, 'NativeTypedData');

  /// Constructor of the `Symbol` class in dart:internal. This getter will
  /// ensure that `Symbol` is resolved and lookup the constructor on demand.
  ConstructorEntity _symbolConstructorTarget;
  ConstructorEntity get symbolConstructorTarget {
    // TODO(johnniwinther): Kernel does not include redirecting factories
    // so this cannot be found in kernel. Find a consistent way to handle
    // this and similar cases.
    return _symbolConstructorTarget ??=
        _findConstructor(symbolImplementationClass, '');
  }

  /// Whether [element] is the same as [symbolConstructor]. Used to check
  /// for the constructor without computing it until it is likely to be seen.
  bool isSymbolConstructor(ConstructorEntity element) {
    return element == symbolConstructorTarget ||
        element == _findConstructor(symbolClass, '', required: false);
  }

  /// The `MirrorSystem` class in dart:mirrors.
  ClassEntity _mirrorSystemClass;
  ClassEntity get mirrorSystemClass => _mirrorSystemClass ??=
      _findClass(mirrorsLibrary, 'MirrorSystem', required: false);

  /// Whether [element] is `MirrorClass.getName`. Used to check for the use of
  /// that static method without forcing the resolution of the `MirrorSystem`
  /// class until it is necessary.
  FunctionEntity _mirrorSystemGetNameFunction;
  bool isMirrorSystemGetNameFunction(MemberEntity element) {
    if (_mirrorSystemGetNameFunction == null) {
      if (!element.isFunction || mirrorsLibrary == null) return false;
      ClassEntity cls = mirrorSystemClass;
      if (element.enclosingClass != cls) return false;
      if (cls != null) {
        _mirrorSystemGetNameFunction =
            _findClassMember(cls, 'getName', required: false);
      }
    }
    return element == _mirrorSystemGetNameFunction;
  }

  /// The `MirrorsUsed` annotation in dart:mirrors.
  ClassEntity _mirrorsUsedClass;
  ClassEntity get mirrorsUsedClass => _mirrorsUsedClass ??=
      _findClass(mirrorsLibrary, 'MirrorsUsed', required: false);

  /// Whether [element] is the constructor of the `MirrorsUsed` class. Used to
  /// check for the constructor without forcing the resolution of the
  /// `MirrorsUsed` class until it is necessary.
  bool isMirrorsUsedConstructor(ConstructorEntity element) =>
      mirrorsLibrary != null && mirrorsUsedClass == element.enclosingClass;

  /// The `DeferredLibrary` annotation in dart:async that was used before the
  /// deferred import syntax was introduced.
  // TODO(sigmund): drop support for this old syntax?
  ClassEntity _deferredLibraryClass;
  ClassEntity get deferredLibraryClass =>
      _deferredLibraryClass ??= _findClass(asyncLibrary, "DeferredLibrary");

  /// The function `identical` in dart:core.
  FunctionEntity _identicalFunction;
  FunctionEntity get identicalFunction =>
      _identicalFunction ??= _findLibraryMember(coreLibrary, 'identical');

  /// The method `Function.apply`.
  FunctionEntity _functionApplyMethod;
  FunctionEntity get functionApplyMethod =>
      _functionApplyMethod ??= _findClassMember(functionClass, 'apply');

  /// Whether [element] is the same as [functionApplyMethod]. This will not
  /// resolve the apply method if it hasn't been seen yet during compilation.
  bool isFunctionApplyMethod(MemberEntity element) =>
      element.name == 'apply' && element.enclosingClass == functionClass;

  /// Returns `true` if [element] is the unnamed constructor of `List`. This
  /// will not resolve the constructor if it hasn't been seen yet during
  /// compilation.
  bool isUnnamedListConstructor(ConstructorEntity element) =>
      (element.name == '' && element.enclosingClass == listClass) ||
      (element.name == 'list' && element.enclosingClass == jsArrayClass);

  /// Returns `true` if [element] is the 'filled' constructor of `List`. This
  /// will not resolve the constructor if it hasn't been seen yet during
  /// compilation.
  bool isFilledListConstructor(ConstructorEntity element) =>
      element.name == 'filled' && element.enclosingClass == listClass;

  /// The `dynamic` type.
  DynamicType get dynamicType => _env.dynamicType;

  /// The `Object` type defined in 'dart:core'.
  InterfaceType get objectType => _getRawType(objectClass);

  /// The `bool` type defined in 'dart:core'.
  InterfaceType get boolType => _getRawType(boolClass);

  /// The `num` type defined in 'dart:core'.
  InterfaceType get numType => _getRawType(numClass);

  /// The `int` type defined in 'dart:core'.
  InterfaceType get intType => _getRawType(intClass);

  /// The `double` type defined in 'dart:core'.
  InterfaceType get doubleType => _getRawType(doubleClass);

  /// The `Resource` type defined in 'dart:core'.
  InterfaceType get resourceType => _getRawType(resourceClass);

  /// The `String` type defined in 'dart:core'.
  InterfaceType get stringType => _getRawType(stringClass);

  /// The `Symbol` type defined in 'dart:core'.
  InterfaceType get symbolType => _getRawType(symbolClass);

  /// The `Function` type defined in 'dart:core'.
  InterfaceType get functionType => _getRawType(functionClass);

  /// The `Null` type defined in 'dart:core'.
  InterfaceType get nullType => _getRawType(nullClass);

  /// The `Type` type defined in 'dart:core'.
  InterfaceType get typeType => _getRawType(typeClass);

  InterfaceType get typeLiteralType => _getRawType(typeLiteralClass);

  /// The `StackTrace` type defined in 'dart:core';
  InterfaceType get stackTraceType => _getRawType(stackTraceClass);

  /// Returns an instance of the `List` type defined in 'dart:core' with
  /// [elementType] as its type argument.
  ///
  /// If no type argument is provided, the canonical raw type is returned.
  InterfaceType listType([DartType elementType]) {
    if (elementType == null) {
      return _getRawType(listClass);
    }
    return _createInterfaceType(listClass, [elementType]);
  }

  /// Returns an instance of the `Map` type defined in 'dart:core' with
  /// [keyType] and [valueType] as its type arguments.
  ///
  /// If no type arguments are provided, the canonical raw type is returned.
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
  InterfaceType streamType([DartType elementType]) {
    if (elementType == null) {
      return _getRawType(streamClass);
    }
    return _createInterfaceType(streamClass, [elementType]);
  }

  /// Returns `true` if [element] is a superclass of `String` or `num`.
  bool isNumberOrStringSupertype(ClassEntity element) {
    return element == _findClass(coreLibrary, 'Comparable', required: false);
  }

  /// Returns `true` if [element] is a superclass of `String`.
  bool isStringOnlySupertype(ClassEntity element) {
    return element == _findClass(coreLibrary, 'Pattern', required: false);
  }

  /// Returns `true` if [element] is a superclass of `List`.
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
    return _env.lookupClassMember(cls, name,
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

  FieldEntity get symbolField => symbolImplementationField;

  InterfaceType get symbolImplementationType =>
      _env.getRawType(symbolImplementationClass);

  bool isDefaultEqualityImplementation(MemberEntity element) {
    assert(element.name == '==');
    ClassEntity classElement = element.enclosingClass;
    return classElement == objectClass ||
        classElement == jsInterceptorClass ||
        classElement == jsNullClass;
  }

  // From dart:core
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
  FunctionEntity _cachedCoreHelper(String name) => _cachedCoreHelpers[name] ??=
      _env.lookupLibraryMember(coreLibrary, name, required: true);

  FunctionEntity _objectEquals;
  FunctionEntity get objectEquals =>
      _objectEquals ??= _findClassMember(objectClass, '==');

  ClassEntity _mapLiteralClass;
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
        _env.lookupClassMember(mapLiteralClass, '_makeLiteral');
    _mapLiteralUntypedEmptyMaker =
        _env.lookupClassMember(mapLiteralClass, '_makeEmpty');
  }

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

  FunctionEntity _objectNoSuchMethod;
  FunctionEntity get objectNoSuchMethod {
    return _objectNoSuchMethod ??=
        _env.lookupClassMember(objectClass, Identifiers.noSuchMethod_);
  }

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

  FunctionEntity get asyncHelperStart =>
      _findAsyncHelperFunction("_asyncStart");
  FunctionEntity get asyncHelperAwait =>
      _findAsyncHelperFunction("_asyncAwait");
  FunctionEntity get asyncHelperReturn =>
      _findAsyncHelperFunction("_asyncReturn");
  FunctionEntity get asyncHelperRethrow =>
      _findAsyncHelperFunction("_asyncRethrow");

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

  // From dart:mirrors
  FunctionEntity _findMirrorsFunction(String name) {
    LibraryEntity library = _env.lookupLibrary(Uris.dart__js_mirrors);
    if (library == null) return null;
    return _env.lookupLibraryMember(library, name, required: true);
  }

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
      LibraryEntity library = _env.lookupLibrary(Uris.dart__js_names);
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

  // From dart:_interceptors
  ClassEntity _findInterceptorsClass(String name) =>
      _findClass(interceptorsLibrary, name);

  FunctionEntity _findInterceptorsFunction(String name) =>
      _findLibraryMember(interceptorsLibrary, name);

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

  FunctionEntity _findIndexForNativeSubclassType;
  FunctionEntity get findIndexForNativeSubclassType =>
      _findIndexForNativeSubclassType ??= _findLibraryMember(
          interceptorsLibrary, 'findIndexForNativeSubclassType');

  FunctionEntity _getInterceptorMethod;
  FunctionEntity get getInterceptorMethod =>
      _getInterceptorMethod ??= _findInterceptorsFunction('getInterceptor');

  FunctionEntity _getNativeInterceptorMethod;
  FunctionEntity get getNativeInterceptorMethod =>
      _getNativeInterceptorMethod ??=
          _findInterceptorsFunction('getNativeInterceptor');

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

  ClassEntity _jsConstClass;
  ClassEntity get jsConstClass =>
      _jsConstClass ??= _findClass(foreignLibrary, 'JS_CONST');

  // From package:js
  ClassEntity _jsAnnotationClass;
  ClassEntity get jsAnnotationClass {
    if (_jsAnnotationClass == null) {
      LibraryEntity library = _env.lookupLibrary(Uris.package_js);
      if (library == null) return null;
      _jsAnnotationClass = _findClass(library, 'JS');
    }
    return _jsAnnotationClass;
  }

  ClassEntity _jsAnonymousClass;
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
  FunctionEntity findHelperFunction(String name) => _findHelperFunction(name);

  FunctionEntity _findHelperFunction(String name) =>
      _findLibraryMember(jsHelperLibrary, name);

  ClassEntity _findHelperClass(String name) =>
      _findClass(jsHelperLibrary, name);

  ClassEntity _closureClass;
  ClassEntity get closureClass => _closureClass ??= _findHelperClass('Closure');

  ClassEntity _boundClosureClass;
  ClassEntity get boundClosureClass =>
      _boundClosureClass ??= _findHelperClass('BoundClosure');

  ClassEntity _typeLiteralClass;
  ClassEntity get typeLiteralClass =>
      _typeLiteralClass ??= _findHelperClass('TypeImpl');

  ClassEntity _constMapLiteralClass;
  ClassEntity get constMapLiteralClass =>
      _constMapLiteralClass ??= _findHelperClass('ConstantMap');

  ClassEntity _typeVariableClass;
  ClassEntity get typeVariableClass =>
      _typeVariableClass ??= _findHelperClass('TypeVariable');

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

  ClassEntity _jsInvocationMirrorClass;
  ClassEntity get jsInvocationMirrorClass =>
      _jsInvocationMirrorClass ??= _findHelperClass('JSInvocationMirror');

  /// Interface used to determine if an object has the JavaScript
  /// indexing behavior. The interface is only visible to specific libraries.
  ClassEntity _jsIndexingBehaviorInterface;
  ClassEntity get jsIndexingBehaviorInterface =>
      _jsIndexingBehaviorInterface ??=
          _findHelperClass('JavaScriptIndexingBehavior');

  ClassEntity get VoidRuntimeType => _findHelperClass('VoidRuntimeType');

  ClassEntity get stackTraceHelperClass => _findHelperClass('_StackTrace');

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

  /// The class for patch annotations defined in dart:_js_helper.
  ClassEntity _patchAnnotationClass;
  ClassEntity get patchAnnotationClass =>
      _patchAnnotationClass ??= _findHelperClass('_Patch');

  /// The class for native annotations defined in dart:_js_helper.
  ClassEntity _nativeAnnotationClass;
  ClassEntity get nativeAnnotationClass =>
      _nativeAnnotationClass ??= _findHelperClass('Native');

  ConstructorEntity _typeVariableConstructor;
  ConstructorEntity get typeVariableConstructor => _typeVariableConstructor ??=
      _env.lookupConstructor(typeVariableClass, '');

  FunctionEntity _invokeOnMethod;
  FunctionEntity get invokeOnMethod => _invokeOnMethod ??=
      _env.lookupClassMember(jsInvocationMirrorClass, '_getCachedInvocation');

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

  /// Holds the method "getIsolateAffinityTag" when dart:_js_helper has been
  /// loaded.
  FunctionEntity _getIsolateAffinityTagMarker;
  FunctionEntity get getIsolateAffinityTagMarker =>
      _getIsolateAffinityTagMarker ??=
          _findHelperFunction('getIsolateAffinityTag');

  /// Holds the method "requiresPreamble" in _js_helper.
  FunctionEntity _requiresPreambleMarker;
  FunctionEntity get requiresPreambleMarker =>
      _requiresPreambleMarker ??= _findHelperFunction('requiresPreamble');

  FunctionEntity get badMain => _findHelperFunction('badMain');

  FunctionEntity get missingMain => _findHelperFunction('missingMain');

  FunctionEntity get mainHasTooManyParameters =>
      _findHelperFunction('mainHasTooManyParameters');

  FunctionEntity get loadLibraryWrapper =>
      _findHelperFunction("_loadLibraryWrapper");

  FunctionEntity get boolConversionCheck =>
      _findHelperFunction('boolConversionCheck');

  FunctionEntity get _consoleTraceHelper =>
      _findHelperFunction('consoleTraceHelper');

  FunctionEntity get _postTraceHelper => _findHelperFunction('postTraceHelper');

  FunctionEntity _traceHelper;
  FunctionEntity get traceHelper {
    return _traceHelper ??= JavaScriptBackend.TRACE_METHOD == 'console'
        ? _consoleTraceHelper
        : _postTraceHelper;
  }

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

  FunctionEntity get throwUnsupportedError =>
      _findHelperFunction('throwUnsupportedError');

  FunctionEntity get throwTypeError => _findHelperFunction('throwTypeError');

  FunctionEntity get throwAbstractClassInstantiationError =>
      _findHelperFunction('throwAbstractClassInstantiationError');

  FunctionEntity _cachedCheckConcurrentModificationError;
  FunctionEntity get checkConcurrentModificationError =>
      _cachedCheckConcurrentModificationError ??=
          _findHelperFunction('checkConcurrentModificationError');

  FunctionEntity get throwConcurrentModificationError =>
      _findHelperFunction('throwConcurrentModificationError');

  /// Return `true` if [member] is the 'checkInt' function defined in
  /// dart:_js_helpers.
  bool isCheckInt(MemberEntity member) {
    return member.isFunction &&
        member.isTopLevel &&
        member.library == jsHelperLibrary &&
        member.name == 'checkInt';
  }

  /// Return `true` if [member] is the 'checkNum' function defined in
  /// dart:_js_helpers.
  bool isCheckNum(MemberEntity member) {
    return member.isFunction &&
        member.isTopLevel &&
        member.library == jsHelperLibrary &&
        member.name == 'checkNum';
  }

  /// Return `true` if [member] is the 'checkString' function defined in
  /// dart:_js_helpers.
  bool isCheckString(MemberEntity member) {
    return member.isFunction &&
        member.isTopLevel &&
        member.library == jsHelperLibrary &&
        member.name == 'checkString';
  }

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

  FunctionEntity get createRuntimeType =>
      _findHelperFunction('createRuntimeType');

  FunctionEntity get fallThroughError =>
      _findHelperFunction("getFallThroughError");

  FunctionEntity get createInvocationMirror =>
      _findHelperFunction('createInvocationMirror');

  FunctionEntity get cyclicThrowHelper =>
      _findHelperFunction("throwCyclicInit");

  FunctionEntity get defineProperty => _findHelperFunction('defineProperty');

  FunctionEntity get convertRtiToRuntimeType =>
      _findHelperFunction('convertRtiToRuntimeType');

  FunctionEntity get toStringForNativeObject =>
      _findHelperFunction('toStringForNativeObject');

  FunctionEntity get hashCodeForNativeObject =>
      _findHelperFunction('hashCodeForNativeObject');

  // From dart:_internal

  ClassEntity _symbolImplementationClass;
  ClassEntity get symbolImplementationClass =>
      _symbolImplementationClass ??= _findClass(internalLibrary, 'Symbol');

  /// Used to annotate items that have the keyword "native".
  ClassEntity _externalNameClass;
  ClassEntity get externalNameClass =>
      _externalNameClass ??= _findClass(internalLibrary, 'ExternalName');
  InterfaceType get externalNameType => _getRawType(externalNameClass);

  final Selector symbolValidatedConstructorSelector =
      new Selector.call(const PublicName('validated'), CallStructure.ONE_ARG);

  ConstructorEntity get symbolValidatedConstructor =>
      _symbolValidatedConstructor ??= _findConstructor(
          symbolImplementationClass, symbolValidatedConstructorSelector.name);

  /// Returns the field that holds the internal name in the implementation class
  /// for `Symbol`.
  FieldEntity _symbolImplementationField;
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

  // From dart:_native_typed_data

  ClassEntity _typedArrayClass;
  ClassEntity get typedArrayClass => _typedArrayClass ??= _findClass(
      _env.lookupLibrary(Uris.dart__native_typed_data, required: true),
      'NativeTypedArray');

  ClassEntity _typedArrayOfIntClass;
  ClassEntity get typedArrayOfIntClass => _typedArrayOfIntClass ??= _findClass(
      _env.lookupLibrary(Uris.dart__native_typed_data, required: true),
      'NativeTypedArrayOfInt');

  // From dart:_js_embedded_names

  /// Holds the class for the [JsGetName] enum.
  ClassEntity _jsGetNameEnum;
  ClassEntity get jsGetNameEnum => _jsGetNameEnum ??= _findClass(
      _env.lookupLibrary(Uris.dart__js_embedded_names, required: true),
      'JsGetName');

  /// Holds the class for the [JsBuiltins] enum.
  ClassEntity _jsBuiltinEnum;
  ClassEntity get jsBuiltinEnum => _jsBuiltinEnum ??= _findClass(
      _env.lookupLibrary(Uris.dart__js_embedded_names, required: true),
      'JsBuiltin');

  // From dart:_isolate_helper

  FunctionEntity get startRootIsolate =>
      _findLibraryMember(isolateHelperLibrary, 'startRootIsolate');

  FunctionEntity get currentIsolate =>
      _findLibraryMember(isolateHelperLibrary, '_currentIsolate');

  FunctionEntity get callInIsolate =>
      _findLibraryMember(isolateHelperLibrary, '_callInIsolate');

  static final Uri PACKAGE_EXPECT =
      new Uri(scheme: 'package', path: 'expect/expect.dart');

  bool _expectAnnotationChecked = false;
  ClassEntity _expectNoInlineClass;
  ClassEntity _expectTrustTypeAnnotationsClass;
  ClassEntity _expectAssumeDynamicClass;

  void _ensureExpectAnnotations() {
    if (!_expectAnnotationChecked) {
      _expectAnnotationChecked = true;
      LibraryEntity library = _env.lookupLibrary(PACKAGE_EXPECT);
      if (library != null) {
        _expectNoInlineClass = _env.lookupClass(library, 'NoInline');
        _expectTrustTypeAnnotationsClass =
            _env.lookupClass(library, 'TrustTypeAnnotations');
        _expectAssumeDynamicClass = _env.lookupClass(library, 'AssumeDynamic');
        if (_expectNoInlineClass == null ||
            _expectTrustTypeAnnotationsClass == null ||
            _expectAssumeDynamicClass == null) {
          // This is not the package you're looking for.
          _expectNoInlineClass = null;
          _expectTrustTypeAnnotationsClass = null;
          _expectAssumeDynamicClass = null;
        }
      }
    }
  }

  ClassEntity get expectNoInlineClass {
    _ensureExpectAnnotations();
    return _expectNoInlineClass;
  }

  ClassEntity get expectTrustTypeAnnotationsClass {
    _ensureExpectAnnotations();
    return _expectTrustTypeAnnotationsClass;
  }

  ClassEntity get expectAssumeDynamicClass {
    _ensureExpectAnnotations();
    return _expectAssumeDynamicClass;
  }

  bool isForeign(MemberEntity element) => element.library == foreignLibrary;

  /// Returns `true` if the implementation of the 'operator ==' [function] is
  /// known to handle `null` as argument.
  bool operatorEqHandlesNullArgument(FunctionEntity function) {
    assert(function.name == '==',
        failedAt(function, "Unexpected function $function."));
    ClassEntity cls = function.enclosingClass;
    return cls == objectClass ||
        cls == jsInterceptorClass ||
        cls == jsNullClass;
  }

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
  MemberEntity lookupClassMember(ClassEntity cls, String name,
      {bool setter: false, bool required: false});

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
  // TODO(redemption): Remove the 'ensureResolved' parameter
  void forEachConstructor(
      ClassEntity cls, void f(ConstructorEntity constructor),
      {bool ensureResolved: true});

  /// Calls [f] for every constructor body in [cls].
  void forEachConstructorBody(
      ClassEntity cls, void f(ConstructorBodyEntity constructorBody));

  /// Calls [f] for each nested closure in [member].
  void forEachNestedClosure(
      MemberEntity member, void f(FunctionEntity closure));

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

  /// Calls [f] for each class that is mixed into [cls] or one of its
  /// superclasses.
  void forEachMixin(ClassEntity cls, void f(ClassEntity mixin));

  /// Create the instantiation of [cls] with the given [typeArguments].
  InterfaceType createInterfaceType(
      ClassEntity cls, List<DartType> typeArguments);

  /// Returns the `dynamic` type.
  // TODO(johnniwinther): Remove this when `ResolutionDynamicType` is no longer
  // needed.
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

  /// The upper bound on the [typeVariable]. If not explicitly declared, this is
  /// `Object`.
  DartType getTypeVariableBound(TypeVariableEntity typeVariable);

  /// Returns the type of [function].
  FunctionType getFunctionType(FunctionEntity function);

  /// Returns the type of [field].
  DartType getFieldType(FieldEntity field);

  /// Returns the type of the [local] function.
  FunctionType getLocalFunctionType(Local local);

  /// Gets the constant value of [field], or `null` if [field] is non-const.
  ConstantExpression getFieldConstant(FieldEntity field);

  /// Returns the 'unaliased' type of [type]. For typedefs this is the function
  /// type it is an alias of, for other types it is the type itself.
  ///
  /// Use this during resolution to ensure that the alias has been computed.
  // TODO(johnniwinther): Remove this when the resolver is removed.
  DartType getUnaliasedType(DartType type);

  /// Returns `true` if [member] a the synthetic getter `loadLibrary` injected
  /// on deferred libraries.
  bool isDeferredLoadLibraryGetter(MemberEntity member);

  /// Returns the metadata constants declared on [library].
  Iterable<ConstantValue> getLibraryMetadata(LibraryEntity library);

  /// Returns the metadata constants declared on [cls].
  Iterable<ConstantValue> getClassMetadata(ClassEntity cls);

  /// Returns the metadata constants declared on [typedef].
  Iterable<ConstantValue> getTypedefMetadata(TypedefEntity typedef);

  /// Returns the metadata constants declared on [member].
  Iterable<ConstantValue> getMemberMetadata(MemberEntity member,
      {bool includeParameterMetadata: false});

  /// Returns the function type that is an alias of a [typedef].
  FunctionType getFunctionTypeOfTypedef(TypedefEntity typedef);

  /// Returns `true` if [cls] is a Dart enum class.
  bool isEnumClass(ClassEntity cls);
}
