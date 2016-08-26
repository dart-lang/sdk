// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(sigmund): rename and move to common/elements.dart
library dart2js.type_system;

import 'dart_types.dart';
import 'elements/elements.dart'
    show
        ClassElement,
        ConstructorElement,
        FunctionElement,
        LibraryElement,
        Element;

/// The core classes in Dart.
abstract class CoreClasses {
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

  /// The `Future` class defined in 'async';
  ClassElement get futureClass;

  /// The `Stream` class defined in 'async';
  ClassElement get streamClass;
}

/// TODO(sigmund): delete CoreClasses and merge it here.
abstract class CommonElements extends CoreClasses {
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
}

/// The core types in Dart.
abstract class CoreTypes {
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

  /// The `Future` class declaration.
  ClassElement get futureClass;

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
}
