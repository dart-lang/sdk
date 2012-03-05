// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A dummy library for testing dartdoc name references.
#library('dummy');

topLevelMethod() => null;

class Class {
  Class() => null;
  Class.namedConstructor() => null;
  method(param) => null;
  get getterOnly() => null;
  get getterAndSetter() => null;
  set getterAndSetter(val) => null;
  set setterOnly(val) => null;
}
