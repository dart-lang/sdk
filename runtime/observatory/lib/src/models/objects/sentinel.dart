// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of models;

enum SentinelKind {
  /// Indicates that the object referred to has been collected by the GC.
  collected,

  /// Indicates that an object id has expired.
  expired,

  /// Indicates that a variable or field has not been initialized.
  notInitialized,

  /// Indicates that a variable or field is in the process of being initialized.
  initializing,

  /// Indicates that a variable has been eliminated by the optimizing compiler.
  optimizedOut,

  /// Reserved for future use.
  free,
}

abstract class Sentinel {
  /// What kind of sentinel is this?
  SentinelKind get kind;

  /// A reasonable string representation of this sentinel.
  String get valueAsString;
}
