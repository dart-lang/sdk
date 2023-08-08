// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common.dart';
import '../constants/constant_system.dart' as constant_system;
import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/names.dart';
import '../elements/types.dart';
import '../inferrer/abstract_value_domain.dart';
import '../js_backend/native_data.dart' show NativeBasicData;
import '../js_model/locals.dart';
import '../universe/selector.dart' show Selector;

import 'names.dart' show Identifiers, Uris;

/// The common elements and types in Dart.
abstract class CommonElements {
  final DartTypes dartTypes;
  final ElementEnvironment _env;
  ClassEntity? _symbolClass;
  ConstructorEntity? _symbolConstructorTarget;
  bool _computedSymbolConstructorDependencies = false;
  ConstructorEntity? _symbolConstructorImplementationTarget;
  ClassEntity? _mapLiteralClass;
  ClassEntity? _symbolImplementationClass;
  FieldEntity? _symbolImplementationField;

  CommonElements(this.dartTypes, this._env);

  /// The `Object` class defined in 'dart:core'.
  late final ClassEntity objectClass = _findClass(coreLibrary, 'Object');

  /// The `bool` class defined in 'dart:core'.
  late final ClassEntity boolClass = _findClass(coreLibrary, 'bool');

  /// The `num` class defined in 'dart:core'.
  late final ClassEntity numClass = _findClass(coreLibrary, 'num');

  /// The `int` class defined in 'dart:core'.
  late final ClassEntity intClass = _findClass(coreLibrary, 'int');

  /// The `double` class defined in 'dart:core'.
  late final ClassEntity doubleClass = _findClass(coreLibrary, 'double');

  /// The `String` class defined in 'dart:core'.
  late final ClassEntity stringClass = _findClass(coreLibrary, 'String');

  /// The `Function` class defined in 'dart:core'.
  late final ClassEntity functionClass = _findClass(coreLibrary, 'Function');

  /// The `Record` class defined in 'dart:core'.
  late final ClassEntity recordClass = _findClass(coreLibrary, 'Record');

  /// The `Resource` class defined in 'dart:core'.
  late final ClassEntity resourceClass = _findClass(coreLibrary, 'Resource');

  /// The `Symbol` class defined in 'dart:core'.
  late final ClassEntity symbolClass = _findClass(coreLibrary, 'Symbol');

  /// The `Null` class defined in 'dart:core'.
  late final ClassEntity nullClass = _findClass(coreLibrary, 'Null');

  /// The `Type` class defined in 'dart:core'.
  late final ClassEntity typeClass = _findClass(coreLibrary, 'Type');

  /// The `StackTrace` class defined in 'dart:core';
  late final ClassEntity stackTraceClass =
      _findClass(coreLibrary, 'StackTrace');

  /// The `List` class defined in 'dart:core';
  late final ClassEntity listClass = _findClass(coreLibrary, 'List');

  /// The `Set` class defined in 'dart:core';
  late final ClassEntity setClass = _findClass(coreLibrary, 'Set');

  /// The `Map` class defined in 'dart:core';
  late final ClassEntity mapClass = _findClass(coreLibrary, 'Map');

  /// The `Set` class defined in 'dart:core';
  late final ClassEntity unmodifiableSetClass =
      _findClass(collectionLibrary, '_UnmodifiableSet');

  /// The `Iterable` class defined in 'dart:core';
  late final ClassEntity iterableClass = _findClass(coreLibrary, 'Iterable');

  /// The `Future` class defined in 'async';.
  late final ClassEntity futureClass = _findClass(asyncLibrary, 'Future');

  /// The `Future.value` constructor.
  late final ConstructorEntity? futureValueConstructor =
      _env.lookupConstructor(futureClass, 'value');

  /// The `Stream` class defined in 'async';
  late final ClassEntity streamClass = _findClass(asyncLibrary, 'Stream');

  /// The dart:core library.
  late final LibraryEntity coreLibrary =
      _env.lookupLibrary(Uris.dart_core, required: true)!;

  /// The dart:async library.
  late final LibraryEntity? asyncLibrary = _env.lookupLibrary(Uris.dart_async);

  /// The dart:collection library.
  late final LibraryEntity? collectionLibrary =
      _env.lookupLibrary(Uris.dart_collection);

  /// The dart:mirrors library.
  /// Null if the program doesn't access dart:mirrors.
  late final LibraryEntity? mirrorsLibrary =
      _env.lookupLibrary(Uris.dart_mirrors);

  /// The dart:typed_data library.
  late final LibraryEntity typedDataLibrary =
      _env.lookupLibrary(Uris.dart__native_typed_data, required: true)!;

  /// The dart:_js_shared_embedded_names library.
  late final LibraryEntity sharedEmbeddedNamesLibrary =
      _env.lookupLibrary(Uris.dart__js_shared_embedded_names, required: true)!;

  /// The dart:_js_helper library.
  late final LibraryEntity? jsHelperLibrary =
      _env.lookupLibrary(Uris.dart__js_helper);

  /// The dart:_late_helper library
  late final LibraryEntity? lateHelperLibrary =
      _env.lookupLibrary(Uris.dart__late_helper);

  /// The dart:_interceptors library.
  late final LibraryEntity? interceptorsLibrary =
      _env.lookupLibrary(Uris.dart__interceptors);

  /// The dart:_foreign_helper library.
  late final LibraryEntity? foreignLibrary =
      _env.lookupLibrary(Uris.dart__foreign_helper);

  /// The dart:_rti library.
  late final LibraryEntity rtiLibrary =
      _env.lookupLibrary(Uris.dart__rti, required: true)!;

  /// The dart:_internal library.
  late final LibraryEntity internalLibrary =
      _env.lookupLibrary(Uris.dart__internal, required: true)!;

  /// The dart:js_util library.
  late final LibraryEntity? dartJsUtilLibrary =
      _env.lookupLibrary(Uris.dart_js_util);

  /// The package:js library.
  late final LibraryEntity? packageJsLibrary =
      _env.lookupLibrary(Uris.package_js);

  /// The dart:_js_annotations library.
  late final LibraryEntity? dartJsAnnotationsLibrary =
      _env.lookupLibrary(Uris.dart__js_annotations);

  /// The dart:js_interop library.
  late final LibraryEntity? dartJsInteropLibrary =
      _env.lookupLibrary(Uris.dart__js_interop);

  /// The `NativeTypedData` class from dart:typed_data.
  ClassEntity get typedDataClass =>
      _findClass(typedDataLibrary, 'NativeTypedData');

  /// Constructor of the `Symbol` class in dart:internal.
  ///
  /// This getter will ensure that `Symbol` is resolved and lookup the
  /// constructor on demand.
  ConstructorEntity get symbolConstructorTarget {
    // TODO(johnniwinther): Kernel does not include redirecting factories
    // so this cannot be found in kernel. Find a consistent way to handle
    // this and similar cases.
    return _symbolConstructorTarget ??=
        _env.lookupConstructor(symbolImplementationClass, '')!;
  }

  void _ensureSymbolConstructorDependencies() {
    if (_computedSymbolConstructorDependencies) return;
    _computedSymbolConstructorDependencies = true;
    if (_symbolConstructorTarget == null) {
      if (_symbolImplementationClass == null) {
        _symbolImplementationClass =
            _findClassOrNull(internalLibrary, 'Symbol');
      }
      if (_symbolImplementationClass != null) {
        _symbolConstructorTarget = _env.lookupConstructor(
            _symbolImplementationClass!, '',
            required: false);
      }
    }
    if (_symbolClass == null) {
      _symbolClass = _findClassOrNull(coreLibrary, 'Symbol');
    }
    if (_symbolClass == null) {
      return;
    }
    _symbolConstructorImplementationTarget =
        _env.lookupConstructor(symbolClass, '', required: false);
  }

  /// Whether [element] is the same as [symbolConstructor].
  ///
  /// Used to check for the constructor without computing it until it is likely
  /// to be seen.
  bool isSymbolConstructor(ConstructorEntity element) {
    _ensureSymbolConstructorDependencies();
    return element == _symbolConstructorImplementationTarget ||
        element == _symbolConstructorTarget;
  }

  /// The function `identical` in dart:core.
  late final FunctionEntity identicalFunction =
      _findLibraryMember(coreLibrary, 'identical')!;

  /// Whether [element] is the `Function.apply` method.
  ///
  /// This will not resolve the apply method if it hasn't been seen yet during
  /// compilation.
  bool isFunctionApplyMethod(MemberEntity element) =>
      element.name == 'apply' && element.enclosingClass == functionClass;

  /// The `dynamic` type.
  DynamicType get dynamicType => _env.dynamicType as DynamicType;

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

  /// The `String` type defined in 'dart:core'.
  InterfaceType get stringType => _getRawType(stringClass);

  /// The `Symbol` type defined in 'dart:core'.
  InterfaceType get symbolType => _getRawType(symbolClass);

  /// The `Function` type defined in 'dart:core'.
  InterfaceType get functionType => _getRawType(functionClass);

  /// The `Null` type defined in 'dart:core'.
  InterfaceType get nullType => _getRawType(nullClass);

  /// The `Record` type defined in 'dart:core'.
  InterfaceType get recordType => _getRawType(recordClass);

  /// The `Type` type defined in 'dart:core'.
  InterfaceType get typeType => _getRawType(typeClass);

  InterfaceType get typeLiteralType => _getRawType(typeLiteralClass);

  /// The `StackTrace` type defined in 'dart:core';
  InterfaceType get stackTraceType => _getRawType(stackTraceClass);

  /// Returns an instance of the `List` type defined in 'dart:core' with
  /// [elementType] as its type argument.
  ///
  /// If no type argument is provided, the canonical raw type is returned.
  InterfaceType listType([DartType? elementType]) {
    if (elementType == null) {
      return _getRawType(listClass);
    }
    return _createInterfaceType(listClass, [elementType]);
  }

  /// Returns an instance of the `Set` type defined in 'dart:core' with
  /// [elementType] as its type argument.
  ///
  /// If no type argument is provided, the canonical raw type is returned.
  InterfaceType setType([DartType? elementType]) {
    if (elementType == null) {
      return _getRawType(setClass);
    }
    return _createInterfaceType(setClass, [elementType]);
  }

  /// Returns an instance of the `Map` type defined in 'dart:core' with
  /// [keyType] and [valueType] as its type arguments.
  ///
  /// If no type arguments are provided, the canonical raw type is returned.

  InterfaceType mapType([DartType? keyType, DartType? valueType]) {
    if (keyType == null && valueType == null) {
      return _getRawType(mapClass);
    } else if (keyType == null) {
      keyType = dynamicType;
    } else if (valueType == null) {
      valueType = dynamicType;
    }
    return _createInterfaceType(mapClass, [keyType, valueType!]);
  }

  /// Returns an instance of the `Iterable` type defined in 'dart:core' with
  /// [elementType] as its type argument.
  ///
  /// If no type argument is provided, the canonical raw type is returned.
  InterfaceType iterableType([DartType? elementType]) {
    if (elementType == null) {
      return _getRawType(iterableClass);
    }
    return _createInterfaceType(iterableClass, [elementType]);
  }

  /// Returns an instance of the `Future` type defined in 'dart:async' with
  /// [elementType] as its type argument.
  ///
  /// If no type argument is provided, the canonical raw type is returned.
  // CommonElementsForDartTypes
  InterfaceType futureType([DartType? elementType]) {
    if (elementType == null) {
      return _getRawType(futureClass);
    }
    return _createInterfaceType(futureClass, [elementType]);
  }

  /// Returns an instance of the `Stream` type defined in 'dart:async' with
  /// [elementType] as its type argument.
  ///
  /// If no type argument is provided, the canonical raw type is returned.
  InterfaceType streamType([DartType? elementType]) {
    if (elementType == null) {
      return _getRawType(streamClass);
    }
    return _createInterfaceType(streamClass, [elementType]);
  }

  ClassEntity _findClass(LibraryEntity? library, String name) {
    return _env.lookupClass(library!, name, required: true)!;
  }

  ClassEntity? _findClassOrNull(LibraryEntity? library, String name) {
    if (library == null) return null;
    return _env.lookupClass(library, name, required: false);
  }

  T? _findLibraryMember<T extends MemberEntity>(
      LibraryEntity? library, String name,
      {bool setter = false, bool required = true}) {
    if (library == null) return null;
    return _env.lookupLibraryMember(library, name,
        setter: setter, required: required) as T?;
  }

  T? _findClassMemberOrNull<T extends MemberEntity>(
      ClassEntity cls, String name) {
    return _env.lookupLocalClassMember(
        cls, Name(name, cls.library.canonicalUri, isSetter: false),
        required: false) as T?;
  }

  T _findClassMember<T extends MemberEntity>(ClassEntity cls, String name) {
    return _env.lookupLocalClassMember(
        cls, Name(name, cls.library.canonicalUri, isSetter: false),
        required: true) as T;
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

  InterfaceType getConstantListTypeFor(InterfaceType sourceType) {
    // TODO(51534): Use CONST_CANONICAL_TYPE(T_i) for arguments.
    return _env.createInterfaceType(jsArrayClass, sourceType.typeArguments);
  }

  InterfaceType getConstantMapTypeFor(InterfaceType sourceType,
      {bool onlyStringKeys = false}) {
    // TODO(51534): Use CONST_CANONICAL_TYPE(T_i) for arguments.
    ClassEntity classElement =
        onlyStringKeys ? constantStringMapClass : generalConstantMapClass;
    return _env.createInterfaceType(classElement, sourceType.typeArguments);
  }

  InterfaceType getConstantSetTypeFor(InterfaceType sourceType,
      {bool onlyStringKeys = false}) {
    // TODO(51534): Use CONST_CANONICAL_TYPE(T_i) for arguments.
    ClassEntity classElement =
        onlyStringKeys ? constantStringSetClass : generalConstantSetClass;
    return _env.createInterfaceType(classElement, sourceType.typeArguments);
  }

  /// Returns the field that holds the internal name in the implementation class
  /// for `Symbol`.

  FieldEntity get symbolField =>
      _symbolImplementationField ??= _env.lookupLocalClassMember(
          symbolImplementationClass,
          PrivateName('_name', symbolImplementationClass.library.canonicalUri),
          required: true) as FieldEntity;

  InterfaceType get symbolImplementationType =>
      _env.getRawType(symbolImplementationClass);

  // From dart:core
  ClassEntity get mapLiteralClass {
    if (_mapLiteralClass == null) {
      _mapLiteralClass = _env.lookupClass(coreLibrary, 'LinkedHashMap');
      if (_mapLiteralClass == null) {
        _mapLiteralClass = _findClass(collectionLibrary, 'LinkedHashMap');
      }
    }
    return _mapLiteralClass!;
  }

  late final ConstructorEntity mapLiteralConstructor =
      _env.lookupConstructor(mapLiteralClass, '_literal')!;
  late final ConstructorEntity mapLiteralConstructorEmpty =
      _env.lookupConstructor(mapLiteralClass, '_empty')!;
  late final FunctionEntity mapLiteralUntypedMaker =
      _env.lookupLocalClassMember(mapLiteralClass,
              PrivateName('_makeLiteral', mapLiteralClass.library.canonicalUri))
          as FunctionEntity;
  late final FunctionEntity mapLiteralUntypedEmptyMaker =
      _env.lookupLocalClassMember(mapLiteralClass,
              PrivateName('_makeEmpty', mapLiteralClass.library.canonicalUri))
          as FunctionEntity;

  late final ClassEntity setLiteralClass =
      _findClass(collectionLibrary, 'LinkedHashSet');

  late final ConstructorEntity setLiteralConstructor =
      _env.lookupConstructor(setLiteralClass, '_literal')!;
  late final ConstructorEntity setLiteralConstructorEmpty =
      _env.lookupConstructor(setLiteralClass, '_empty')!;
  late final FunctionEntity setLiteralUntypedMaker =
      _env.lookupLocalClassMember(setLiteralClass,
              PrivateName('_makeLiteral', setLiteralClass.library.canonicalUri))
          as FunctionEntity;
  late final FunctionEntity setLiteralUntypedEmptyMaker =
      _env.lookupLocalClassMember(setLiteralClass,
              PrivateName('_makeEmpty', setLiteralClass.library.canonicalUri))
          as FunctionEntity;

  late final FunctionEntity? objectNoSuchMethod = _env.lookupLocalClassMember(
          objectClass, const PublicName(Identifiers.noSuchMethod_))
      as FunctionEntity?;

  bool isDefaultNoSuchMethodImplementation(FunctionEntity element) {
    ClassEntity? classElement = element.enclosingClass;
    return classElement == objectClass ||
        classElement == jsInterceptorClass ||
        classElement == jsNullClass;
  }

  // From dart:async
  ClassEntity _findAsyncHelperClass(String name) =>
      _findClass(asyncLibrary, name);

  FunctionEntity _findAsyncHelperFunction(String name) =>
      _findLibraryMember(asyncLibrary, name)!;

  FunctionEntity get asyncHelperStartSync =>
      _findAsyncHelperFunction("_asyncStartSync");

  FunctionEntity get asyncHelperAwait =>
      _findAsyncHelperFunction("_asyncAwait");

  FunctionEntity get asyncHelperReturn =>
      _findAsyncHelperFunction("_asyncReturn");

  FunctionEntity get asyncHelperRethrow =>
      _findAsyncHelperFunction("_asyncRethrow");

  FunctionEntity get wrapBody =>
      _findAsyncHelperFunction("_wrapJsFunctionForAsync");

  FunctionEntity get yieldStar => _env.lookupLocalClassMember(
      _findAsyncHelperClass("_IterationMarker"),
      const PublicName("yieldStar")) as FunctionEntity;

  FunctionEntity get yieldSingle => _env.lookupLocalClassMember(
      _findAsyncHelperClass("_IterationMarker"),
      const PublicName("yieldSingle")) as FunctionEntity;

  FunctionEntity get syncStarUncaughtError => _env.lookupLocalClassMember(
      _findAsyncHelperClass("_IterationMarker"),
      const PublicName("uncaughtError")) as FunctionEntity;

  FunctionEntity get asyncStarHelper =>
      _findAsyncHelperFunction("_asyncStarHelper");

  FunctionEntity get streamOfController =>
      _findAsyncHelperFunction("_streamOfController");

  FunctionEntity get endOfIteration => _env.lookupLocalClassMember(
      _findAsyncHelperClass("_IterationMarker"),
      const PublicName("endOfIteration")) as FunctionEntity;

  ClassEntity get syncStarIterable =>
      _findAsyncHelperClass("_SyncStarIterable");

  late final ClassEntity _syncStarIteratorClass =
      _findAsyncHelperClass('_SyncStarIterator');

  late final FieldEntity syncStarIteratorCurrentField =
      _findClassMember(_syncStarIteratorClass, '_current');

  late final FieldEntity syncStarIteratorDatumField =
      _findClassMember(_syncStarIteratorClass, '_datum');

  late final FunctionEntity syncStarIteratorYieldStarMethod =
      _findClassMember(_syncStarIteratorClass, '_yieldStar');

  ClassEntity get futureImplementation => _findAsyncHelperClass('_Future');

  ClassEntity get controllerStream =>
      _findAsyncHelperClass("_ControllerStream");

  ClassEntity get streamIterator => _findAsyncHelperClass("StreamIterator");

  ConstructorEntity get streamIteratorConstructor =>
      _env.lookupConstructor(streamIterator, "")!;

  late final FunctionEntity syncStarIterableFactory =
      _findAsyncHelperFunction('_makeSyncStarIterable');

  late final FunctionEntity asyncAwaitCompleterFactory =
      _findAsyncHelperFunction('_makeAsyncAwaitCompleter');

  late final FunctionEntity asyncStarStreamControllerFactory =
      _findAsyncHelperFunction('_makeAsyncStarStreamController');

  // From dart:_interceptors
  ClassEntity _findInterceptorsClass(String name) =>
      _findClass(interceptorsLibrary, name);

  FunctionEntity _findInterceptorsFunction(String name) =>
      _findLibraryMember(interceptorsLibrary, name)!;

  late final ClassEntity jsInterceptorClass =
      _findInterceptorsClass('Interceptor');

  late final ClassEntity jsStringClass = _findInterceptorsClass('JSString');

  late final ClassEntity jsArrayClass = _findInterceptorsClass('JSArray');

  late final ClassEntity jsNumberClass = _findInterceptorsClass('JSNumber');

  late final ClassEntity jsIntClass = _findInterceptorsClass('JSInt');

  late final ClassEntity jsNumNotIntClass =
      _findInterceptorsClass('JSNumNotInt');

  late final ClassEntity jsNullClass = _findInterceptorsClass('JSNull');

  late final ClassEntity jsBoolClass = _findInterceptorsClass('JSBool');

  late final ClassEntity jsPlainJavaScriptObjectClass =
      _findInterceptorsClass('PlainJavaScriptObject');

  late final ClassEntity jsUnknownJavaScriptObjectClass =
      _findInterceptorsClass('UnknownJavaScriptObject');

  late final ClassEntity jsJavaScriptFunctionClass =
      _findInterceptorsClass('JavaScriptFunction');

  InterfaceType get jsJavaScriptFunctionType =>
      _getRawType(jsJavaScriptFunctionClass);

  late final ClassEntity jsLegacyJavaScriptObjectClass =
      _findInterceptorsClass('LegacyJavaScriptObject');

  late final ClassEntity jsJavaScriptObjectClass =
      _findInterceptorsClass('JavaScriptObject');

  InterfaceType get jsJavaScriptObjectType =>
      _getRawType(jsJavaScriptObjectClass);

  late final ClassEntity jsIndexableClass =
      _findInterceptorsClass('JSIndexable');

  late final ClassEntity jsMutableIndexableClass =
      _findInterceptorsClass('JSMutableIndexable');

  late final ClassEntity jsMutableArrayClass =
      _findInterceptorsClass('JSMutableArray');

  late final ClassEntity jsFixedArrayClass =
      _findInterceptorsClass('JSFixedArray');

  late final ClassEntity jsExtendableArrayClass =
      _findInterceptorsClass('JSExtendableArray');

  late final ClassEntity jsUnmodifiableArrayClass =
      _findInterceptorsClass('JSUnmodifiableArray');

  late final ClassEntity jsPositiveIntClass =
      _findInterceptorsClass('JSPositiveInt');

  late final ClassEntity jsUInt32Class = _findInterceptorsClass('JSUInt32');

  late final ClassEntity jsUInt31Class = _findInterceptorsClass('JSUInt31');

  /// Returns `true` member is the 'findIndexForNativeSubclassType' method
  /// declared in `dart:_interceptors`.
  bool isFindIndexForNativeSubclassType(MemberEntity member) {
    return member.name == 'findIndexForNativeSubclassType' &&
        member.isTopLevel &&
        member.library == interceptorsLibrary;
  }

  late final FunctionEntity getNativeInterceptorMethod =
      _findInterceptorsFunction('getNativeInterceptor');

  late final ConstructorEntity jsArrayTypedConstructor =
      _env.lookupConstructor(jsArrayClass, 'typed')!;

  // From dart:_js_helper
  // TODO(johnniwinther): Avoid the need for this (from [CheckedModeHelper]).
  FunctionEntity findHelperFunction(String name) => _findHelperFunction(name);

  FunctionEntity _findHelperFunction(String name) =>
      _findLibraryMember(jsHelperLibrary, name)!;

  ClassEntity _findHelperClass(String name) =>
      _findClass(jsHelperLibrary, name);

  FunctionEntity _findLateHelperFunction(String name) =>
      _findLibraryMember(lateHelperLibrary, name)!;

  late final ClassEntity closureClass = _findHelperClass('Closure');

  late final ClassEntity closureClass0Args = _findHelperClass('Closure0Args');

  late final ClassEntity closureClass2Args = _findHelperClass('Closure2Args');

  late final ClassEntity boundClosureClass = _findHelperClass('BoundClosure');

  late final ClassEntity typeLiteralClass = _findRtiClass('_Type');

  late final ClassEntity constMapLiteralClass = _findHelperClass('ConstantMap');

  late final ClassEntity constSetLiteralClass = _findHelperClass('ConstantSet');

  /// Base class for all records.
  late final ClassEntity recordBaseClass = _findHelperClass('_Record');

  /// A function that is used to model the back-end impacts of record lowering
  /// in the front-end.
  late final FunctionEntity recordImpactModel =
      _findHelperFunction('_recordImpactModel');

  /// Base class for records with N fields. Can be a fixed-arity class or a
  /// general class that works for any arity.
  ClassEntity recordArityClass(int n) {
    return _findClassOrNull(jsHelperLibrary, '_Record$n') ??
        (n == 0 ? emptyRecordClass : recordGeneralBaseClass);
  }

  late final ClassEntity recordGeneralBaseClass = _findHelperClass('_RecordN');

  late final ClassEntity emptyRecordClass = _findHelperClass('_EmptyRecord');

  late final FunctionEntity recordTestByListHelper =
      _findHelperFunction('_testRecordValues');

  late final ClassEntity jsInvocationMirrorClass =
      _findHelperClass('JSInvocationMirror');

  late final ClassEntity requiredSentinelClass = _findHelperClass('_Required');

  InterfaceType get requiredSentinelType => _getRawType(requiredSentinelClass);

  late final MemberEntity invocationTypeArgumentGetter =
      _findClassMember(jsInvocationMirrorClass, 'typeArguments');

  /// Interface used to determine if an object has the JavaScript
  /// indexing behavior. The interface is only visible to specific libraries.
  late final ClassEntity jsIndexingBehaviorInterface =
      _findHelperClass('JavaScriptIndexingBehavior');

  late final ClassEntity stackTraceHelperClass =
      _findHelperClass('_StackTrace');

  late final ClassEntity constantMapClass =
      _findHelperClass(constant_system.JavaScriptMapConstant.DART_CLASS);

  late final ClassEntity constantStringMapClass =
      _findHelperClass(constant_system.JavaScriptMapConstant.DART_STRING_CLASS);

  late final ClassEntity generalConstantMapClass = _findHelperClass(
      constant_system.JavaScriptMapConstant.DART_GENERAL_CLASS);

  late final ClassEntity constantStringSetClass =
      _findHelperClass(constant_system.JavaScriptSetConstant.DART_STRING_CLASS);

  late final ClassEntity generalConstantSetClass = _findHelperClass(
      constant_system.JavaScriptSetConstant.DART_GENERAL_CLASS);

  late final ClassEntity annotationCreatesClass = _findHelperClass('Creates');

  late final ClassEntity annotationReturnsClass = _findHelperClass('Returns');

  late final ClassEntity annotationJSNameClass = _findHelperClass('JSName');

  /// The class for native annotations defined in dart:_js_helper.
  late final ClassEntity nativeAnnotationClass = _findHelperClass('Native');

  late final assertTest = _findHelperFunction('assertTest');

  late final assertThrow = _findHelperFunction('assertThrow');

  late final assertHelper = _findHelperFunction('assertHelper');

  late final assertUnreachableMethod = _findHelperFunction('assertUnreachable');

  /// Holds the method "getIsolateAffinityTag" when dart:_js_helper has been
  /// loaded.
  late final getIsolateAffinityTagMarker =
      _findHelperFunction('getIsolateAffinityTag');

  /// Holds the method "requiresPreamble" in _js_helper.
  late final requiresPreambleMarker = _findHelperFunction('requiresPreamble');

  /// Holds the method "_rawStartupMetrics" in _js_helper.
  late final rawStartupMetrics = _findHelperFunction('rawStartupMetrics');

  FunctionEntity get loadDeferredLibrary =>
      _findHelperFunction("loadDeferredLibrary");

  FunctionEntity get boolConversionCheck =>
      _findHelperFunction('boolConversionCheck');

  FunctionEntity get traceHelper => _findHelperFunction('traceHelper');

  FunctionEntity get closureFromTearOff =>
      _findHelperFunction('closureFromTearOff');

  FunctionEntity get isJsIndexable => _findHelperFunction('isJsIndexable');

  FunctionEntity get throwIllegalArgumentException =>
      _findHelperFunction('iae');

  FunctionEntity get throwIndexOutOfRangeException =>
      _findHelperFunction('ioore');

  FunctionEntity get exceptionUnwrapper =>
      _findHelperFunction('unwrapException');

  FunctionEntity get throwUnsupportedError =>
      _findHelperFunction('throwUnsupportedError');

  FunctionEntity get throwTypeError => _findRtiFunction('throwTypeError');

  /// Recognizes the `checkConcurrentModificationError` helper without needing
  /// it to be resolved.
  bool isCheckConcurrentModificationError(MemberEntity member) {
    return member.name == 'checkConcurrentModificationError' &&
        member.isFunction &&
        member.isTopLevel &&
        member.library == jsHelperLibrary;
  }

  late final FunctionEntity checkConcurrentModificationError =
      _findHelperFunction('checkConcurrentModificationError');

  FunctionEntity get throwConcurrentModificationError =>
      _findHelperFunction('throwConcurrentModificationError');

  FunctionEntity get stringInterpolationHelper => _findHelperFunction('S');

  FunctionEntity get wrapExceptionHelper =>
      _findHelperFunction('wrapException');

  FunctionEntity get throwExpressionHelper =>
      _findHelperFunction('throwExpression');

  FunctionEntity get closureConverter =>
      _findHelperFunction('convertDartClosureToJS');

  FunctionEntity get traceFromException =>
      _findHelperFunction('getTraceFromException');

  FunctionEntity get checkDeferredIsLoaded =>
      _findHelperFunction('checkDeferredIsLoaded');

  FunctionEntity get createRuntimeType => _findRtiFunction('createRuntimeType');

  FunctionEntity get createInvocationMirror =>
      _findHelperFunction('createInvocationMirror');

  FunctionEntity get createUnmangledInvocationMirror =>
      _findHelperFunction('createUnmangledInvocationMirror');

  FunctionEntity get cyclicThrowHelper =>
      _findHelperFunction("throwCyclicInit");

  FunctionEntity get defineProperty => _findHelperFunction('defineProperty');

  FunctionEntity get throwLateFieldNI =>
      _findLateHelperFunction('throwLateFieldNI');

  FunctionEntity get throwLateFieldAI =>
      _findLateHelperFunction('throwLateFieldAI');

  FunctionEntity get throwLateFieldADI =>
      _findLateHelperFunction('throwLateFieldADI');

  FunctionEntity get throwUnnamedLateFieldNI =>
      _findLateHelperFunction('throwUnnamedLateFieldNI');

  FunctionEntity get throwUnnamedLateFieldAI =>
      _findLateHelperFunction('throwUnnamedLateFieldAI');

  FunctionEntity get throwUnnamedLateFieldADI =>
      _findLateHelperFunction('throwUnnamedLateFieldADI');

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

  ClassEntity getInstantiationClass(int typeArgumentCount) {
    _checkTypeArgumentCount(typeArgumentCount);
    return _findHelperClass('Instantiation$typeArgumentCount');
  }

  FunctionEntity getInstantiateFunction(int typeArgumentCount) {
    _checkTypeArgumentCount(typeArgumentCount);
    return _findHelperFunction('instantiate$typeArgumentCount');
  }

  FunctionEntity get convertMainArgumentList =>
      _findHelperFunction('convertMainArgumentList');

  // From dart:_rti

  ClassEntity _findRtiClass(String name) => _findClass(rtiLibrary, name);

  FunctionEntity _findRtiFunction(String name) =>
      _findLibraryMember(rtiLibrary, name)!;

  late final FunctionEntity setArrayType = _findRtiFunction('_setArrayType');

  late final FunctionEntity findType = _findRtiFunction('findType');

  late final FunctionEntity instanceType = _findRtiFunction('instanceType');

  late final FunctionEntity arrayInstanceType =
      _findRtiFunction('_arrayInstanceType');

  late final FunctionEntity simpleInstanceType =
      _findRtiFunction('_instanceType');

  late final FunctionEntity typeLiteralMaker = _findRtiFunction('typeLiteral');

  late final FunctionEntity checkTypeBound = _findRtiFunction('checkTypeBound');

  late final FunctionEntity pairwiseIsTest = _findRtiFunction('pairwiseIsTest');

  ClassEntity get _rtiImplClass => _findRtiClass('Rti');

  ClassEntity get _rtiUniverseClass => _findRtiClass('_Universe');

  FieldEntity _findRtiClassField(String name) =>
      _findClassMember(_rtiImplClass, name);

  late final FieldEntity rtiAsField = _findRtiClassField('_as');

  late final FieldEntity rtiIsField = _findRtiClassField('_is');

  late final FieldEntity rtiRestField = _findRtiClassField('_rest');

  late final FieldEntity rtiPrecomputed1Field =
      _findRtiClassField('_precomputed1');

  late final FunctionEntity rtiEvalMethod =
      _findClassMember(_rtiImplClass, '_eval');

  late final FunctionEntity rtiBindMethod =
      _findClassMember(_rtiImplClass, '_bind');

  late final FunctionEntity rtiAddRulesMethod =
      _findClassMember(_rtiUniverseClass, 'addRules');

  late final FunctionEntity rtiAddErasedTypesMethod =
      _findClassMember(_rtiUniverseClass, 'addErasedTypes');

  late final FunctionEntity rtiAddTypeParameterVariancesMethod =
      _findClassMember(_rtiUniverseClass, 'addTypeParameterVariances');

  FunctionEntity get installSpecializedIsTest =>
      _findRtiFunction('_installSpecializedIsTest');

  FunctionEntity get installSpecializedAsCheck =>
      _findRtiFunction('_installSpecializedAsCheck');

  late final FunctionEntity generalIsTestImplementation =
      _findRtiFunction('_generalIsTestImplementation');

  late final FunctionEntity generalNullableIsTestImplementation =
      _findRtiFunction('_generalNullableIsTestImplementation');

  late final FunctionEntity generalAsCheckImplementation =
      _findRtiFunction('_generalAsCheckImplementation');

  late final FunctionEntity generalNullableAsCheckImplementation =
      _findRtiFunction('_generalNullableAsCheckImplementation');

  late final FunctionEntity specializedIsObject = _findRtiFunction('_isObject');

  late final FunctionEntity specializedAsObject = _findRtiFunction('_asObject');

  FunctionEntity get specializedIsTop => _findRtiFunction('_isTop');

  FunctionEntity get specializedAsTop => _findRtiFunction('_asTop');

  FunctionEntity get specializedIsBool => _findRtiFunction('_isBool');

  FunctionEntity get specializedAsBool => _findRtiFunction('_asBool');

  FunctionEntity get specializedAsBoolLegacy => _findRtiFunction('_asBoolS');

  FunctionEntity get specializedAsBoolNullable => _findRtiFunction('_asBoolQ');

  FunctionEntity get specializedAsDouble => _findRtiFunction('_asDouble');

  FunctionEntity get specializedAsDoubleLegacy =>
      _findRtiFunction('_asDoubleS');

  FunctionEntity get specializedAsDoubleNullable =>
      _findRtiFunction('_asDoubleQ');

  FunctionEntity get specializedIsInt => _findRtiFunction('_isInt');

  FunctionEntity get specializedAsInt => _findRtiFunction('_asInt');

  FunctionEntity get specializedAsIntLegacy => _findRtiFunction('_asIntS');

  FunctionEntity get specializedAsIntNullable => _findRtiFunction('_asIntQ');

  FunctionEntity get specializedIsNum => _findRtiFunction('_isNum');

  FunctionEntity get specializedAsNum => _findRtiFunction('_asNum');

  FunctionEntity get specializedAsNumLegacy => _findRtiFunction('_asNumS');

  FunctionEntity get specializedAsNumNullable => _findRtiFunction('_asNumQ');

  FunctionEntity get specializedIsString => _findRtiFunction('_isString');

  FunctionEntity get specializedAsString => _findRtiFunction('_asString');

  FunctionEntity get specializedAsStringLegacy =>
      _findRtiFunction('_asStringS');

  FunctionEntity get specializedAsStringNullable =>
      _findRtiFunction('_asStringQ');

  FunctionEntity get instantiatedGenericFunctionTypeNewRti =>
      _findRtiFunction('instantiatedGenericFunctionType');

  FunctionEntity get closureFunctionType =>
      _findRtiFunction('closureFunctionType');

  // From dart:_internal

  late final ClassEntity symbolImplementationClass =
      _findClass(internalLibrary, 'Symbol');

  /// Used to annotate items that have the keyword "native".
  late final ClassEntity externalNameClass =
      _findClass(internalLibrary, 'ExternalName');

  InterfaceType get externalNameType => _getRawType(externalNameClass);

  // From dart:_js_embedded_names

  late final ClassEntity jsGetNameEnum =
      _findClass(sharedEmbeddedNamesLibrary, 'JsGetName');

  /// Returns `true` if [member] is a "foreign helper", that is, a member whose
  /// semantics is defined synthetically and not through Dart code.
  ///
  /// Most foreign helpers are located in the `dart:_foreign_helper` library.
  bool isForeignHelper(MemberEntity member) {
    return member.library == foreignLibrary ||
        isLateReadCheck(member) ||
        isLateWriteOnceCheck(member) ||
        isLateInitializeOnceCheck(member) ||
        isCreateInvocationMirrorHelper(member);
  }

  bool _isTopLevelFunctionNamed(String name, MemberEntity member) =>
      member.name == name && member.isFunction && member.isTopLevel;

  /// Returns `true` if [member] is the `createJsSentinel` function defined in
  /// dart:_foreign_helper.
  bool isCreateJsSentinel(MemberEntity member) =>
      member.library == foreignLibrary &&
      _isTopLevelFunctionNamed('createJsSentinel', member);

  /// Returns `true` if [member] is the `isJsSentinel` function defined in
  /// dart:_foreign_helper.
  bool isIsJsSentinel(MemberEntity member) =>
      member.library == foreignLibrary &&
      _isTopLevelFunctionNamed('isJsSentinel', member);

  /// Returns `true` if [member] is the `_lateReadCheck` function defined in
  /// dart:_late_helper.
  bool isLateReadCheck(MemberEntity member) =>
      member.library == lateHelperLibrary &&
      _isTopLevelFunctionNamed('_lateReadCheck', member);

  /// Returns `true` if [member] is the `_lateWriteOnceCheck` function defined
  /// in dart:_late_helper.
  bool isLateWriteOnceCheck(MemberEntity member) =>
      member.library == lateHelperLibrary &&
      _isTopLevelFunctionNamed('_lateWriteOnceCheck', member);

  /// Returns `true` if [member] is the `_lateInitializeOnceCheck` function
  /// defined in dart:_late_helper.
  bool isLateInitializeOnceCheck(MemberEntity member) =>
      member.library == lateHelperLibrary &&
      _isTopLevelFunctionNamed('_lateInitializeOnceCheck', member);

  /// Returns `true` if [member] is the `createSentinel` function defined in
  /// dart:_internal.
  bool isCreateSentinel(MemberEntity member) =>
      member.library == internalLibrary &&
      _isTopLevelFunctionNamed('createSentinel', member);

  /// Returns `true` if [member] is the `isSentinel` function defined in
  /// dart:_internal.
  bool isIsSentinel(MemberEntity member) =>
      member.library == internalLibrary &&
      _isTopLevelFunctionNamed('isSentinel', member);

  ClassEntity getDefaultSuperclass(
      ClassEntity cls, NativeBasicData nativeBasicData) {
    if (nativeBasicData.isJsInteropClass(cls)) {
      return jsLegacyJavaScriptObjectClass;
    }
    // Native classes inherit from Interceptor.
    return nativeBasicData.isNativeClass(cls)
        ? jsInterceptorClass
        : objectClass;
  }

  // From dart:js_util
  late final FunctionEntity? jsAllowInterop =
      _findLibraryMember(dartJsUtilLibrary, 'allowInterop', required: false);

  bool isCreateInvocationMirrorHelper(MemberEntity member) {
    return member.isTopLevel &&
        member.name == '_createInvocationMirror' &&
        member.library == coreLibrary;
  }
}

class KCommonElements extends CommonElements {
  KCommonElements(super.dartTypes, super.env);

  // From package:js

  late final ClassEntity? jsAnnotationClass1 =
      _findClassOrNull(packageJsLibrary, 'JS');

  late final ClassEntity? jsAnonymousClass1 =
      _findClassOrNull(packageJsLibrary, '_Anonymous');

  // From dart:_js_annotations

  late final ClassEntity? jsAnnotationClass2 =
      _findClassOrNull(dartJsAnnotationsLibrary, 'JS');

  late final ClassEntity? jsAnonymousClass2 =
      _findClassOrNull(dartJsAnnotationsLibrary, '_Anonymous');

  // From dart:js_interop

  late final ClassEntity? jsAnnotationClass3 =
      _findClassOrNull(dartJsInteropLibrary, 'JS');

  /// Returns `true` if [cls] is a @JS() annotation.
  ///
  /// The class can come from either `package:js`, `dart:_js_annotations`, or
  /// `dart:js_interop`.
  bool isJsAnnotationClass(ClassEntity cls) {
    return cls == jsAnnotationClass1 ||
        cls == jsAnnotationClass2 ||
        cls == jsAnnotationClass3;
  }

  /// Returns `true` if [cls] is an @anonymous annotation.
  ///
  /// The class can come from either `package:js` or `dart:_js_annotations`.
  bool isJsAnonymousClass(ClassEntity cls) {
    return cls == jsAnonymousClass1 || cls == jsAnonymousClass2;
  }

  late final ClassEntity pragmaClass = _findClass(coreLibrary, 'pragma');

  late final FieldEntity pragmaClassNameField =
      _findClassMember(pragmaClass, 'name');

  late final FieldEntity pragmaClassOptionsField =
      _findClassMember(pragmaClass, 'options');
}

class JCommonElements extends CommonElements {
  JCommonElements(super.dartTypes, super.env);

  /// Returns `true` if [element] is the named constructor of `List`,
  /// e.g. `List.of`.
  ///
  /// This will not resolve the constructor if it hasn't been seen yet during
  /// compilation.
  bool isNamedListConstructor(String name, ConstructorEntity element) =>
      element.name == name && element.enclosingClass == listClass;

  /// Returns `true` if [element] is the named constructor of `JSArray`,
  /// e.g. `JSArray.fixed`.
  ///
  /// This will not resolve the constructor if it hasn't been seen yet during
  /// compilation.
  bool isNamedJSArrayConstructor(String name, ConstructorEntity element) =>
      element.name == name && element.enclosingClass == jsArrayClass;

  bool isDefaultEqualityImplementation(MemberEntity element) {
    assert(element.name == '==');
    ClassEntity? classElement = element.enclosingClass;
    return classElement == objectClass ||
        classElement == jsInterceptorClass ||
        classElement == jsNullClass;
  }

  /// Returns `true` if [selector] applies to `JSIndexable.length`.
  bool appliesToJsIndexableLength(Selector selector) {
    return selector.name == 'length' && (selector.isGetter || selector.isCall);
  }

  late final FunctionEntity jsArrayRemoveLast =
      _findClassMember(jsArrayClass, 'removeLast');

  late final FunctionEntity jsArrayAdd = _findClassMember(jsArrayClass, 'add');

  bool _isJsStringClass(ClassEntity cls) {
    return cls.name == 'JSString' && cls.library == interceptorsLibrary;
  }

  bool isJsStringSplit(MemberEntity member) {
    return member.name == 'split' &&
        member.isInstanceMember &&
        _isJsStringClass(member.enclosingClass!);
  }

  /// Returns `true` if [selector] applies to `JSString.split` on [receiver]
  /// in the given [world].
  ///
  /// Returns `false` if `JSString.split` is not available (e.g. the
  /// method was tree-shaken in an earlier compilation phase).
  bool appliesToJsStringSplit(Selector selector, AbstractValue? receiver,
      AbstractValueDomain abstractValueDomain) {
    final splitMember = jsStringSplit;
    if (splitMember == null) return false;
    return selector.applies(splitMember) &&
        (receiver == null ||
            abstractValueDomain
                .isTargetingMember(receiver, splitMember, selector.memberName)
                .isPotentiallyTrue);
  }

  late final FunctionEntity? jsStringSplit =
      _findClassMemberOrNull(jsStringClass, 'split');

  late final FunctionEntity jsStringToString =
      _findClassMember(jsStringClass, 'toString');

  late final FunctionEntity jsStringOperatorAdd =
      _findClassMember(jsStringClass, '+');

  late final ClassEntity jsConstClass = _findClass(foreignLibrary, 'JS_CONST');

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

  bool isInstantiationClass(ClassEntity cls) {
    return cls.library == jsHelperLibrary &&
        cls.name != 'Instantiation' &&
        cls.name.startsWith('Instantiation');
  }

  // From dart:_native_typed_data

  late final ClassEntity? typedArrayOfIntClass =
      _findClass(typedDataLibrary, 'NativeTypedArrayOfInt');

  late final ClassEntity typedArrayOfDoubleClass =
      _findClass(typedDataLibrary, 'NativeTypedArrayOfDouble');

  late final ClassEntity jsBuiltinEnum =
      _findClass(sharedEmbeddedNamesLibrary, 'JsBuiltin');

  bool isForeign(MemberEntity element) => element.library == foreignLibrary;

  /// Returns `true` if the implementation of the 'operator ==' [function] is
  /// known to handle `null` as argument.
  bool operatorEqHandlesNullArgument(FunctionEntity function) {
    assert(function.name == '==',
        failedAt(function, "Unexpected function $function."));
    ClassEntity? cls = function.enclosingClass;
    return cls == objectClass ||
        cls == jsInterceptorClass ||
        cls == jsNullClass;
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
  LibraryEntity? get mainLibrary;

  /// Returns the main method for the compilation.
  FunctionEntity? get mainFunction;

  /// Returns all known libraries.
  Iterable<LibraryEntity> get libraries;

  /// Returns the library name of [library] or '' if the library is unnamed.
  String getLibraryName(LibraryEntity library);

  /// Lookup the library with the canonical [uri], fail if the library is
  /// missing and [required];
  LibraryEntity? lookupLibrary(Uri uri, {bool required = false});

  /// Calls [f] for every class declared in [library].
  void forEachClass(LibraryEntity library, void f(ClassEntity cls));

  /// Lookup the class [name] in [library], fail if the class is missing and
  /// [required].
  ClassEntity? lookupClass(LibraryEntity library, String name,
      {bool required = false});

  /// Calls [f] for every top level member in [library].
  void forEachLibraryMember(LibraryEntity library, void f(MemberEntity member));

  /// Lookup the member [name] in [library], fail if the class is missing and
  /// [required].
  MemberEntity? lookupLibraryMember(LibraryEntity library, String name,
      {bool setter = false, bool required = false});

  /// Lookup the member [name] in [cls], fail if the class is missing and
  /// [required].
  MemberEntity? lookupLocalClassMember(ClassEntity cls, Name name,
      {bool required = false});

  /// Lookup the member [name] in [cls] and its superclasses.
  ///
  /// Return `null` if the member is not found in the class or any superclass.
  MemberEntity? lookupClassMember(ClassEntity cls, Name name) {
    ClassEntity? clsLocal = cls;
    while (clsLocal != null) {
      final entity = lookupLocalClassMember(clsLocal, name);
      if (entity != null) return entity;

      clsLocal = getSuperClass(clsLocal);
    }
    return null;
  }

  /// Lookup the constructor [name] in [cls], fail if the class is missing and
  /// [required].
  ConstructorEntity? lookupConstructor(ClassEntity cls, String name,
      {bool required = false});

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
  ClassEntity? getSuperClass(ClassEntity cls,
      {bool skipUnnamedMixinApplications = false});

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
  ClassEntity? getEffectiveMixinClass(ClassEntity cls);
}

abstract class KElementEnvironment extends ElementEnvironment {
  /// Calls [f] for each class that is mixed into [cls] or one of its
  /// superclasses.
  void forEachMixin(ClassEntity cls, void f(ClassEntity mixin));

  /// Returns the imports seen in [library]
  Iterable<ImportEntity> getImports(LibraryEntity library);

  /// Returns the metadata constants declared on [member].
  Iterable<ConstantValue> getMemberMetadata(MemberEntity member,
      {bool includeParameterMetadata = false});

  /// `true` if field is the backing field for a `late` or `late final` instance
  /// field.
  bool isLateBackingField(FieldEntity field);

  /// `true` if field is the backing field for a `late final` instance field. If
  /// this is true, so is [isLateBackingField].
  bool isLateFinalBackingField(FieldEntity field);
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

  /// Returns `true` if [cls] is a mixin application with its own members.
  ///
  /// This occurs when a mixin contains methods with super calls or when
  /// the mixin application contains concrete forwarding stubs.
  bool isMixinApplicationWithMembers(ClassEntity cls);

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
      void f(DartType type, String? name, ConstantValue? defaultValue));

  /// Calls [f] for each parameter - given as a [Local] - of [function].
  void forEachParameterAsLocal(GlobalLocalsMap globalLocalsMap,
      FunctionEntity function, void f(Local parameter));
}
