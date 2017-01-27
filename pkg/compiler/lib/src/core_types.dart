// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(sigmund): rename and move to common/elements.dart
library dart2js.type_system;

import 'elements/types.dart';
import 'elements/entities.dart';
import 'elements/elements.dart' show Entity;

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

  // TODO(johnniwinther): Move this to the JavaScriptBackend.
  /// The class for patch annotation defined in dart:_js_helper.
  ClassEntity get patchAnnotationClass;

  // TODO(johnniwinther): Move this to the JavaScriptBackend.
  ClassEntity get nativeAnnotationClass;

  /// Constructor of the `Symbol` class. This getter will ensure that `Symbol`
  /// is resolved and lookup the constructor on demand.
  FunctionEntity get symbolConstructor;

  /// Whether [element] is the same as [symbolConstructor]. Used to check
  /// for the constructor without computing it until it is likely to be seen.
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
  bool isMirrorsUsedConstructor(FunctionEntity element);

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

  /// The unnamed constructor of `List`.
  FunctionEntity get unnamedListConstructor;

  /// The 'filled' constructor of `List`.
  FunctionEntity get filledListConstructor;

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
