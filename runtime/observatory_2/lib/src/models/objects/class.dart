// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of models;

abstract class ClassRef extends ObjectRef {
  /// The name of this class.
  String get name;
}

abstract class Class extends Object implements ClassRef {
  /// The error which occurred during class finalization, if it exists.
  /// [optional]
  ErrorRef get error;

  /// Is this an abstract class?
  bool get isAbstract;

  /// Is this a const class?
  bool get isConst;

  /// [internal]
  bool get isPatch;

  /// [optional] The library which contains this class.
  LibraryRef get library;

  /// [optional] The location of this class in the source code.
  SourceLocation get location;

  /// [optional] The superclass of this class, if any.
  ClassRef get superclass;

  /// [optional]The supertype for this class, if any.
  ///
  /// The value will be of the kind: Type.
  InstanceRef get superType;

  /// A list of interface types for this class.
  ///
  /// The values will be of the kind: Type.
  Iterable<InstanceRef> get interfaces;

  /// The mixin type for this class, if any.
  ///
  /// [optional] The value will be of the kind: Type.
  InstanceRef get mixin;

  /// A list of fields in this class. Does not include fields from
  /// superclasses.
  Iterable<FieldRef> get fields;

  /// A list of functions in this class. Does not include functions
  /// from superclasses.
  Iterable<FunctionRef> get functions;

  // A list of subclasses of this class.
  Iterable<ClassRef> get subclasses;

  bool get hasAllocations;
  bool get hasNoAllocations;

  Allocations get newSpace;
  Allocations get oldSpace;

  bool get traceAllocations;
}

abstract class InstanceSet {
  int get count;
  Iterable<ObjectRef> get instances;
}
