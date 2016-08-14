// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of models;

abstract class LibraryRef extends ObjectRef {
  /// The name of this library.
  String get name;

  /// The uri of this library.
  String get uri;
}

abstract class Library extends Object implements LibraryRef {
  /// Is this library debuggable? Default true.
  bool get debuggable;

  /// A list of the imports for this library.
  //LibraryDependency[] dependencies;

  // A list of the scripts which constitute this library.
  Iterable<ScriptRef> get scripts;

  // A list of the top-level variables in this library.
  //List<FieldRef> get variables;

  // A list of the top-level functions in this library.
  //List<FunctionRef> get functions;

  // A list of all classes in this library.
  Iterable<ClassRef> get classes;
}
