// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.type_system;

import 'dart_types.dart';

/// The core types in Dart.
abstract class CoreTypes {
  /// The `Object` type defined in 'dart:core'.
  InterfaceType get objectType;

  /// The `bool` type defined in 'dart:core'.
  InterfaceType get boolType;

  /// The `bool` type defined in 'dart:core'.
  InterfaceType get numType;

  /// The `int` type defined in 'dart:core'.
  InterfaceType get intType;

  /// The `double` type defined in 'dart:core'.
  InterfaceType get doubleType;

  /// The `String` type defined in 'dart:core'.
  InterfaceType get stringType;

  /// The `Function` type defined in 'dart:core'.
  InterfaceType get functionType;

  /// The `Null` type defined in 'dart:core'.
  InterfaceType get nullType;

  /// Returns an instance of the `List` type defined in 'dart:core' with
  /// [elementType] as its type argument.
  InterfaceType listType([DartType elementType = const DynamicType()]);

  /// Returns an instance of the `Map` type defined in 'dart:core' with
  /// [keyType] and [valueType] as its type arguments.
  InterfaceType mapType([DartType keyType = const DynamicType(),
                         DartType valueType = const DynamicType()]);

  /// Returns an instance of the `Iterable` type defined in 'dart:core' with
  /// [elementType] as its type argument.
  InterfaceType iterableType([DartType elementType = const DynamicType()]);

  /// Returns an instance of the `Future` type defined in 'dart:async' with
  /// [elementType] as its type argument.
  InterfaceType futureType([DartType elementType = const DynamicType()]);

  /// Returns an instance of the `Stream` type defined in 'dart:async' with
  /// [elementType] as its type argument.
  InterfaceType streamType([DartType elementType = const DynamicType()]);
}
