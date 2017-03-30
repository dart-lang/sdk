// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(sigmund): rename and move to common/elements.dart
library dart2js.type_system;

import 'common.dart';
import 'common/names.dart' show Uris;
import 'elements/types.dart';
import 'elements/entities.dart';

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

  /// The `Resource` class defined in 'dart:core'.
  ClassEntity get resourceClass;

  /// The `String` class defined in 'dart:core'.
  ClassEntity get stringClass;

  /// The `Symbol` class defined in 'dart:core'.
  ClassEntity get symbolClass;

  /// The `Function` class defined in 'dart:core'.
  ClassEntity get functionClass;

  /// The `Null` class defined in 'dart:core'.
  ClassEntity get nullClass;

  /// The `Type` class defined in 'dart:core'.
  ClassEntity get typeClass;

  /// The `StackTrace` class defined in 'dart:core';
  ClassEntity get stackTraceClass;

  /// The `List` class defined in 'dart:core';
  ClassEntity get listClass;

  /// The `Map` class defined in 'dart:core';
  ClassEntity get mapClass;

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

  /// The dart:mirrors library. Null if the program doesn't access dart:mirrors.
  LibraryEntity get mirrorsLibrary;

  /// The dart:typed_data library.
  LibraryEntity get typedDataLibrary;

  /// The `NativeTypedData` class from dart:typed_data.
  ClassEntity get typedDataClass;

  /// Constructor of the `Symbol` class. This getter will ensure that `Symbol`
  /// is resolved and lookup the constructor on demand.
  ConstructorEntity get symbolConstructor;

  /// Whether [element] is the same as [symbolConstructor]. Used to check
  /// for the constructor without computing it until it is likely to be seen.
  // TODO(johnniwinther): Change type of [e] to [MemberEntity].
  bool isSymbolConstructor(Entity e);

  /// The `MirrorSystem` class in dart:mirrors.
  ClassEntity get mirrorSystemClass;

  /// Whether [element] is `MirrorClass.getName`. Used to check for the use of
  /// that static method without forcing the resolution of the `MirrorSystem`
  /// class until it is necessary.
  bool isMirrorSystemGetNameFunction(MemberEntity element);

  /// The `MirrorsUsed` annotation in dart:mirrors.
  ClassEntity get mirrorsUsedClass;

  /// Whether [element] is the constructor of the `MirrorsUsed` class. Used to
  /// check for the constructor without forcing the resolution of the
  /// `MirrorsUsed` class until it is necessary.
  bool isMirrorsUsedConstructor(ConstructorEntity element);

  /// The `DeferredLibrary` annotation in dart:async that was used before the
  /// deferred import syntax was introduced.
  // TODO(sigmund): drop support for this old syntax?
  ClassEntity get deferredLibraryClass;

  /// The function `identical` in dart:core.
  FunctionEntity get identicalFunction;

  /// The method `Function.apply`.
  FunctionEntity get functionApplyMethod;

  /// Whether [element] is the same as [functionApplyMethod]. This will not
  /// resolve the apply method if it hasn't been seen yet during compilation.
  bool isFunctionApplyMethod(MemberEntity element);

  /// Returns `true` if [element] is the unnamed constructor of `List`. This
  /// will not resolve the constructor if it hasn't been seen yet during
  /// compilation.
  bool isUnnamedListConstructor(ConstructorEntity element);

  /// Returns `true` if [element] is the 'filled' constructor of `List`. This
  /// will not resolve the constructor if it hasn't been seen yet during
  /// compilation.
  bool isFilledListConstructor(ConstructorEntity element);

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

  /// The `StackTrace` type defined in 'dart:core';
  InterfaceType get stackTraceType;

  /// Returns an instance of the `List` type defined in 'dart:core' with
  /// [elementType] as its type argument.
  ///
  /// If no type argument is provided, the canonical raw type is returned.
  InterfaceType listType([DartType elementType]);

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
}

/// Interface for accessing libraries, classes and members.
///
/// The _env makes private and injected members directly available and
/// should therefore not be used to determine scopes.
abstract class ElementEnvironment {
  /// Returns the main library for the compilation.
  LibraryEntity get mainLibrary;

  /// Returns the main method for the compilation.
  FunctionEntity get mainFunction;

  /// Lookup the library with the canonical [uri], fail if the library is
  /// missing and [required];
  LibraryEntity lookupLibrary(Uri uri, {bool required: false});

  /// Lookup the class [name] in [library], fail if the class is missing and
  /// [required].
  ClassEntity lookupClass(LibraryEntity library, String name,
      {bool required: false});

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

  /// Calls [f] for each class member declared or inherited in [cls] together
  /// with the class that declared the member.
  ///
  /// TODO(johnniwinther): This should not include static members of
  /// superclasses.
  void forEachClassMember(
      ClassEntity cls, void f(ClassEntity declarer, MemberEntity member));

  /// Returns the declared superclass of [cls].
  ///
  /// Unnamed mixin applications are skipped, for instance for these classes
  ///
  ///     class S {}
  ///     class M {}
  ///     class C extends S with M {}
  ///
  /// the result of `getSuperClass(C)` is `S` and not the unnamed mixin
  /// application typically named `S+M`.
  ClassEntity getSuperClass(ClassEntity cls);

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
}

class CommonElementsImpl implements CommonElements {
  final ElementEnvironment _env;

  CommonElementsImpl(this._env);

  ClassEntity findClass(LibraryEntity library, String name,
      {bool required: true}) {
    if (library == null) return null;
    return _env.lookupClass(library, name, required: required);
  }

  MemberEntity findLibraryMember(LibraryEntity library, String name,
      {bool setter: false, bool required: true}) {
    if (library == null) return null;
    return _env.lookupLibraryMember(library, name,
        setter: setter, required: required);
  }

  MemberEntity findClassMember(ClassEntity cls, String name,
      {bool setter: false, bool required: true}) {
    return _env.lookupClassMember(cls, name,
        setter: setter, required: required);
  }

  ConstructorEntity findConstructor(ClassEntity cls, String name,
      {bool required: true}) {
    return _env.lookupConstructor(cls, name, required: required);
  }

  DartType get dynamicType => _env.dynamicType;

  /// Return the raw type of [cls].
  InterfaceType getRawType(ClassEntity cls) {
    return _env.getRawType(cls);
  }

  /// Create the instantiation of [cls] with the given [typeArguments].
  InterfaceType createInterfaceType(
      ClassEntity cls, List<DartType> typeArguments) {
    return _env.createInterfaceType(cls, typeArguments);
  }

  LibraryEntity _coreLibrary;
  LibraryEntity get coreLibrary =>
      _coreLibrary ??= _env.lookupLibrary(Uris.dart_core, required: true);

  LibraryEntity _typedDataLibrary;
  LibraryEntity get typedDataLibrary =>
      _typedDataLibrary ??= _env.lookupLibrary(Uris.dart__native_typed_data);

  LibraryEntity _mirrorsLibrary;
  LibraryEntity get mirrorsLibrary =>
      _mirrorsLibrary ??= _env.lookupLibrary(Uris.dart_mirrors);

  LibraryEntity _asyncLibrary;
  LibraryEntity get asyncLibrary =>
      _asyncLibrary ??= _env.lookupLibrary(Uris.dart_async);

  // From dart:core

  ClassEntity _objectClass;
  ClassEntity get objectClass =>
      _objectClass ??= findClass(coreLibrary, 'Object');

  ClassEntity _boolClass;
  ClassEntity get boolClass => _boolClass ??= findClass(coreLibrary, 'bool');

  ClassEntity _numClass;
  ClassEntity get numClass => _numClass ??= findClass(coreLibrary, 'num');

  ClassEntity _intClass;
  ClassEntity get intClass => _intClass ??= findClass(coreLibrary, 'int');

  ClassEntity _doubleClass;
  ClassEntity get doubleClass =>
      _doubleClass ??= findClass(coreLibrary, 'double');

  ClassEntity _stringClass;
  ClassEntity get stringClass =>
      _stringClass ??= findClass(coreLibrary, 'String');

  ClassEntity _functionClass;
  ClassEntity get functionClass =>
      _functionClass ??= findClass(coreLibrary, 'Function');

  FunctionEntity _functionApplyMethod;
  FunctionEntity get functionApplyMethod =>
      _functionApplyMethod ??= findClassMember(functionClass, 'apply');

  bool isFunctionApplyMethod(MemberEntity element) =>
      element.name == 'apply' && element.enclosingClass == functionClass;

  ClassEntity _nullClass;
  ClassEntity get nullClass => _nullClass ??= findClass(coreLibrary, 'Null');

  ClassEntity _listClass;
  ClassEntity get listClass => _listClass ??= findClass(coreLibrary, 'List');

  ClassEntity _typeClass;
  ClassEntity get typeClass => _typeClass ??= findClass(coreLibrary, 'Type');

  ClassEntity _mapClass;
  ClassEntity get mapClass => _mapClass ??= findClass(coreLibrary, 'Map');

  ClassEntity _symbolClass;
  ClassEntity get symbolClass =>
      _symbolClass ??= findClass(coreLibrary, 'Symbol');

  ConstructorEntity _symbolConstructor;
  ConstructorEntity get symbolConstructor =>
      _symbolConstructor ??= findConstructor(symbolClass, '');

  bool isSymbolConstructor(Entity e) => e == symbolConstructor;

  ClassEntity _stackTraceClass;
  ClassEntity get stackTraceClass =>
      _stackTraceClass ??= findClass(coreLibrary, 'StackTrace');

  ClassEntity _iterableClass;
  ClassEntity get iterableClass =>
      _iterableClass ??= findClass(coreLibrary, 'Iterable');

  ClassEntity _resourceClass;
  ClassEntity get resourceClass =>
      _resourceClass ??= findClass(coreLibrary, 'Resource');

  FunctionEntity _identicalFunction;
  FunctionEntity get identicalFunction =>
      _identicalFunction ??= findLibraryMember(coreLibrary, 'identical');

  // From dart:async

  ClassEntity _futureClass;
  ClassEntity get futureClass =>
      _futureClass ??= findClass(asyncLibrary, 'Future');

  ClassEntity _streamClass;
  ClassEntity get streamClass =>
      _streamClass ??= findClass(asyncLibrary, 'Stream');

  ClassEntity _deferredLibraryClass;
  ClassEntity get deferredLibraryClass =>
      _deferredLibraryClass ??= findClass(asyncLibrary, "DeferredLibrary");

  // From dart:mirrors

  ClassEntity _mirrorSystemClass;
  ClassEntity get mirrorSystemClass => _mirrorSystemClass ??=
      findClass(mirrorsLibrary, 'MirrorSystem', required: false);

  FunctionEntity _mirrorSystemGetNameFunction;
  bool isMirrorSystemGetNameFunction(MemberEntity element) {
    if (_mirrorSystemGetNameFunction == null) {
      if (!element.isFunction || mirrorsLibrary == null) return false;
      ClassEntity cls = mirrorSystemClass;
      if (element.enclosingClass != cls) return false;
      if (cls != null) {
        _mirrorSystemGetNameFunction =
            findClassMember(cls, 'getName', required: false);
      }
    }
    return element == _mirrorSystemGetNameFunction;
  }

  ClassEntity _mirrorsUsedClass;
  ClassEntity get mirrorsUsedClass => _mirrorsUsedClass ??=
      findClass(mirrorsLibrary, 'MirrorsUsed', required: false);

  bool isMirrorsUsedConstructor(ConstructorEntity element) =>
      mirrorsLibrary != null && mirrorsUsedClass == element.enclosingClass;

  // From dart:typed_data

  ClassEntity _typedDataClass;
  ClassEntity get typedDataClass =>
      _typedDataClass ??= findClass(typedDataLibrary, 'NativeTypedData');

  bool isUnnamedListConstructor(ConstructorEntity element) =>
      element.name == '' && element.enclosingClass == listClass;

  bool isFilledListConstructor(ConstructorEntity element) =>
      element.name == 'filled' && element.enclosingClass == listClass;

  // TODO(johnniwinther): Change types to `ClassEntity` when these are not
  // called with unrelated elements.
  bool isNumberOrStringSupertype(/*Class*/ Entity element) {
    return element == findClass(coreLibrary, 'Comparable', required: false);
  }

  bool isStringOnlySupertype(/*Class*/ Entity element) {
    return element == findClass(coreLibrary, 'Pattern', required: false);
  }

  bool isListSupertype(/*Class*/ Entity element) => element == iterableClass;

  @override
  InterfaceType get objectType => getRawType(objectClass);

  @override
  InterfaceType get boolType => getRawType(boolClass);

  @override
  InterfaceType get doubleType => getRawType(doubleClass);

  @override
  InterfaceType get functionType => getRawType(functionClass);

  @override
  InterfaceType get intType => getRawType(intClass);

  @override
  InterfaceType get resourceType => getRawType(resourceClass);

  @override
  InterfaceType listType([DartType elementType]) {
    if (elementType == null) {
      return getRawType(listClass);
    }
    return createInterfaceType(listClass, [elementType]);
  }

  @override
  InterfaceType mapType([DartType keyType, DartType valueType]) {
    if (keyType == null && valueType == null) {
      return getRawType(mapClass);
    } else if (keyType == null) {
      keyType = dynamicType;
    } else if (valueType == null) {
      valueType = dynamicType;
    }
    return createInterfaceType(mapClass, [keyType, valueType]);
  }

  @override
  InterfaceType get nullType => getRawType(nullClass);

  @override
  InterfaceType get numType => getRawType(numClass);

  @override
  InterfaceType get stringType => getRawType(stringClass);

  @override
  InterfaceType get symbolType => getRawType(symbolClass);

  @override
  InterfaceType get typeType => getRawType(typeClass);

  @override
  InterfaceType get stackTraceType => getRawType(stackTraceClass);

  @override
  InterfaceType iterableType([DartType elementType]) {
    if (elementType == null) {
      return getRawType(iterableClass);
    }
    return createInterfaceType(iterableClass, [elementType]);
  }

  @override
  InterfaceType futureType([DartType elementType]) {
    if (elementType == null) {
      return getRawType(futureClass);
    }
    return createInterfaceType(futureClass, [elementType]);
  }

  @override
  InterfaceType streamType([DartType elementType]) {
    if (elementType == null) {
      return getRawType(streamClass);
    }
    return createInterfaceType(streamClass, [elementType]);
  }
}
