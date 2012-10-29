// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
part of some_lib;

abstract class SomeClass {
  factory SomeClass(arg) = SomeClassImpl;
  get message;
}

abstract class SomeInterface2 {
}

// myother7.dart/Baz depends on SomeClass2 which depends on SomeInterface2
class SomeClass2 implements SomeInterface2 {
}
