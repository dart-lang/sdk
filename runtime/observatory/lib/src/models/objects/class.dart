// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of models;

abstract class ClassRef extends ObjectRef {
  /// The name of this class.
  String get name;
}

abstract class Class extends ObjectRef implements ClassRef {
  /// The error which occurred during class finalization, if it exists.
  /// [optional]
  //ErrorRef get error;

  /// Is this an abstract class?
  bool get isAbstract;

  /// Is this a const class?
  bool get isConst;

  /// The library which contains this class.
  //LibraryRef get library;

  /// The location of this class in the source code.[optional]
  //SourceLocation get location;

  /// The superclass of this class, if any. [optional]
  ClassRef get superclass;

  /// The supertype for this class, if any.
  ///
  /// The value will be of the kind: Type. [optional]
  //InstanceRef get superType;

  /// A list of interface types for this class.
  ///
  /// The values will be of the kind: Type.
  //Iterable<InstanceRef> get interfaces;

  /// The mixin type for this class, if any.
  ///
  /// The value will be of the kind: Type. [optional]
  //Iterable<InstanceRef> get mixin;

  /// A list of fields in this class. Does not include fields from
  /// superclasses.
  //List<FieldRef> get fields;

  /// A list of functions in this class. Does not include functions
  /// from superclasses.
  //List<FunctionRef> get functions;

  // A list of subclasses of this class.
  Iterable<ClassRef> get subclasses;
}
