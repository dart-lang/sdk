// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(sigmund): rename and move to common/elements.dart
library dart2js.type_system;

import 'elements/resolution_types.dart';
import 'elements/elements.dart'
    show
        ClassElement,
        ConstructorElement,
        FunctionElement,
        LibraryElement,
        Element;

/// The common elements and types in Dart.
abstract class CommonElements {
  /// The `Object` class defined in 'dart:core'.
  ClassElement get objectClass;

  /// The `bool` class defined in 'dart:core'.
  ClassElement get boolClass;

  /// The `num` class defined in 'dart:core'.
  ClassElement get numClass;

  /// The `int` class defined in 'dart:core'.
  ClassElement get intClass;

  /// The `double` class defined in 'dart:core'.
  ClassElement get doubleClass;

  /// The `Resource` class defined in 'dart:core'.
  ClassElement get resourceClass;

  /// The `String` class defined in 'dart:core'.
  ClassElement get stringClass;

  /// The `Symbol` class defined in 'dart:core'.
  ClassElement get symbolClass;

  /// The `Function` class defined in 'dart:core'.
  ClassElement get functionClass;

  /// The `Null` class defined in 'dart:core'.
  ClassElement get nullClass;

  /// The `Type` class defined in 'dart:core'.
  ClassElement get typeClass;

  /// The `StackTrace` class defined in 'dart:core';
  ClassElement get stackTraceClass;

  /// The `List` class defined in 'dart:core';
  ClassElement get listClass;

  /// The `Map` class defined in 'dart:core';
  ClassElement get mapClass;

  /// The `Iterable` class defined in 'dart:core';
  ClassElement get iterableClass;

  /// The `Future` class defined in 'async';.
  ClassElement get futureClass;

  /// The `Stream` class defined in 'async';
  ClassElement get streamClass;

  /// The dart:core library.
  LibraryElement get coreLibrary;

  /// The dart:async library.
  LibraryElement get asyncLibrary;

  /// The dart:mirrors library. Null if the program doesn't access dart:mirrors.
  LibraryElement get mirrorsLibrary;

  /// The dart:typed_data library.
  LibraryElement get typedDataLibrary;

  /// The `NativeTypedData` class from dart:typed_data.
  ClassElement get typedDataClass;

  // TODO(johnniwinther): Move this to the JavaScriptBackend.
  /// The class for patch annotation defined in dart:_js_helper.
  ClassElement get patchAnnotationClass;

  // TODO(johnniwinther): Move this to the JavaScriptBackend.
  ClassElement get nativeAnnotationClass;

  /// Constructor of the `Symbol` class. This getter will ensure that `Symbol`
  /// is resolved and lookup the constructor on demand.
  ConstructorElement get symbolConstructor;

  /// Whether [element] is the same as [symbolConstructor]. Used to check
  /// for the constructor without computing it until it is likely to be seen.
  bool isSymbolConstructor(Element e);

  /// The `MirrorSystem` class in dart:mirrors.
  ClassElement get mirrorSystemClass;

  /// Whether [element] is `MirrorClass.getName`. Used to check for the use of
  /// that static method without forcing the resolution of the `MirrorSystem`
  /// class until it is necessary.
  bool isMirrorSystemGetNameFunction(Element element);

  /// The `MirrorsUsed` annotation in dart:mirrors.
  ClassElement get mirrorsUsedClass;

  /// Whether [element] is the constructor of the `MirrorsUsed` class. Used to
  /// check for the constructor without forcing the resolution of the
  /// `MirrorsUsed` class until it is necessary.
  bool isMirrorsUsedConstructor(ConstructorElement element);

  /// The `DeferredLibrary` annotation in dart:async that was used before the
  /// deferred import syntax was introduced.
  // TODO(sigmund): drop support for this old syntax?
  ClassElement get deferredLibraryClass;

  /// The function `identical` in dart:core.
  FunctionElement get identicalFunction;

  /// The method `Function.apply`.
  FunctionElement get functionApplyMethod;

  /// Whether [element] is the same as [functionApplyMethod]. This will not
  /// resolve the apply method if it hasn't been seen yet during compilation.
  bool isFunctionApplyMethod(Element element);

  /// The unnamed constructor of `List`.
  ConstructorElement get unnamedListConstructor;

  /// The 'filled' constructor of `List`.
  ConstructorElement get filledListConstructor;

  /// The `Object` type defined in 'dart:core'.
  ResolutionInterfaceType get objectType;

  /// The `bool` type defined in 'dart:core'.
  ResolutionInterfaceType get boolType;

  /// The `num` type defined in 'dart:core'.
  ResolutionInterfaceType get numType;

  /// The `int` type defined in 'dart:core'.
  ResolutionInterfaceType get intType;

  /// The `double` type defined in 'dart:core'.
  ResolutionInterfaceType get doubleType;

  /// The `Resource` type defined in 'dart:core'.
  ResolutionInterfaceType get resourceType;

  /// The `String` type defined in 'dart:core'.
  ResolutionInterfaceType get stringType;

  /// The `Symbol` type defined in 'dart:core'.
  ResolutionInterfaceType get symbolType;

  /// The `Function` type defined in 'dart:core'.
  ResolutionInterfaceType get functionType;

  /// The `Null` type defined in 'dart:core'.
  ResolutionInterfaceType get nullType;

  /// The `Type` type defined in 'dart:core'.
  ResolutionInterfaceType get typeType;

  /// The `StackTrace` type defined in 'dart:core';
  ResolutionInterfaceType get stackTraceType;

  /// Returns an instance of the `List` type defined in 'dart:core' with
  /// [elementType] as its type argument.
  ///
  /// If no type argument is provided, the canonical raw type is returned.
  ResolutionInterfaceType listType([ResolutionDartType elementType]);

  /// Returns an instance of the `Map` type defined in 'dart:core' with
  /// [keyType] and [valueType] as its type arguments.
  ///
  /// If no type arguments are provided, the canonical raw type is returned.
  ResolutionInterfaceType mapType(
      [ResolutionDartType keyType, ResolutionDartType valueType]);

  /// Returns an instance of the `Iterable` type defined in 'dart:core' with
  /// [elementType] as its type argument.
  ///
  /// If no type argument is provided, the canonical raw type is returned.
  ResolutionInterfaceType iterableType([ResolutionDartType elementType]);

  /// Returns an instance of the `Future` type defined in 'dart:async' with
  /// [elementType] as its type argument.
  ///
  /// If no type argument is provided, the canonical raw type is returned.
  ResolutionInterfaceType futureType([ResolutionDartType elementType]);

  /// Returns an instance of the `Stream` type defined in 'dart:async' with
  /// [elementType] as its type argument.
  ///
  /// If no type argument is provided, the canonical raw type is returned.
  ResolutionInterfaceType streamType([ResolutionDartType elementType]);

  /// Returns `true` if [element] is a superclass of `String` or `num`.
  bool isNumberOrStringSupertype(ClassElement element);

  /// Returns `true` if [element] is a superclass of `String`.
  bool isStringOnlySupertype(ClassElement element);

  /// Returns `true` if [element] is a superclass of `List`.
  bool isListSupertype(ClassElement element);
}
