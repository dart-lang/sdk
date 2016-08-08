// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of models;

abstract class InstanceRef extends ObjectRef {
  /// Instance references always include their class.
  ClassRef get clazz;

  /// [optional] The value of this instance as a string.
  ///
  /// Provided for the instance kinds:
  ///   Null (null)
  ///   Bool (true or false)
  ///   Double (suitable for passing to Double.parse())
  ///   Int (suitable for passing to int.parse())
  ///   String (value may be truncated)
  ///   Float32x4
  ///   Float64x2
  ///   Int32x4
  ///   StackTrace
  String get valueAsString;

  /// [optional] The valueAsString for String references may be truncated. If so,
  /// this property is added with the value 'true'.
  ///
  /// New code should use 'length' and 'count' instead.
  bool get valueAsStringIsTruncated;

  /// [optional] The length of a List or the number of associations in a Map or
  /// the number of codeunits in a String.
  ///
  /// Provided for instance kinds:
  ///   String
  ///   List
  ///   Map
  ///   Uint8ClampedList
  ///   Uint8List
  ///   Uint16List
  ///   Uint32List
  ///   Uint64List
  ///   Int8List
  ///   Int16List
  ///   Int32List
  ///   Int64List
  ///   Float32List
  ///   Float64List
  ///   Int32x4List
  ///   Float32x4List
  ///   Float64x2List
  int get length;

  /// [optional] The name of a Type instance.
  ///
  /// Provided for instance kinds:
  ///   Type
  String get name;

  /// [optional] The corresponding Class if this Type is canonical.
  ///
  /// Provided for instance kinds:
  ///   Type
  ClassRef get typeClass;

  /// [optional] The parameterized class of a type parameter:
  ///
  /// Provided for instance kinds:
  ///   TypeParameter
  ClassRef get parameterizedClass;

  /// [optional] The pattern of a RegExp instance.
  ///
  /// The pattern is always an instance of kind String.
  ///
  /// Provided for instance kinds:
  ///   RegExp
  InstanceRef get pattern;
}

abstract class Instance extends Object implements InstanceRef {}
