// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of models;

abstract class Flag {
  /// The name of the flag.
  String get name;

  /// A description of the flag.
  String get comment;

  /// Has this flag been modified from its default setting?
  bool get modified;

  /// The value of this flag as a string. [optional]
  ///
  /// If this property is absent, then the value of the flag was NULL.
  String get valueAsString;
}
