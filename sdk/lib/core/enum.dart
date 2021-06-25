// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/// An enumerated value.
///
/// This class is implemented by all types and values
/// introduced using an `enum` declaration.
/// Non-platform classes cannot implement, extend or
/// mix in this class.
@Since("2.14")
abstract class Enum {
  /// A numeric identifier for the enumerated value.
  ///
  /// The values of a single enumeration are numbered
  /// consecutively from zero to one less than the
  /// number of values.
  /// This is also the index of the value in the
  /// enumerated type's static `values` list.
  int get index;
}
