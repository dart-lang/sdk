// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.type_system;

import 'dart_types.dart';
import 'elements/elements.dart' show ClassElement;

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
