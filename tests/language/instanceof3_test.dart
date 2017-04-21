// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing the instanceof operation.

import "package:expect/expect.dart";

// In the type test 'e is T', if T does not denote a type available in the
// current lexical scope, then T is mapped to dynamic. Direct tests against
// T cause a dynamic type error though.

isCheckedMode() {
  try {
    var i = 1;
    String s = i;
    return false;
  } catch (e) {
    return true;
  }
}

testAll() {
  {
    bool got_type_error = false;
    var x = null;
    try {
      Expect.isTrue(x is UndeclaredType); // x is null.
    } on TypeError catch (error) {
      got_type_error = true;
    }
    // Type error.
    Expect.isTrue(got_type_error);
  }
  {
    bool got_type_error = false;
    var x = 1;
    try {
      Expect.isTrue(x is UndeclaredType); // x is not null.
    } on TypeError catch (error) {
      got_type_error = true;
    }
    // Type error.
    Expect.isTrue(got_type_error);
  }
  {
    bool got_type_error = false;
    var x = null;
    try {
      Expect.isFalse(x is List<UndeclaredType>); // x is null.
    } on TypeError catch (error) {
      got_type_error = true;
    }
    // No type error.
    Expect.isFalse(got_type_error);
  }
  {
    bool got_type_error = false;
    var x = 1;
    try {
      Expect.isFalse(x is List<UndeclaredType>); // x is not a List.
    } on TypeError catch (error) {
      got_type_error = true;
    }
    // No type error.
    Expect.isFalse(got_type_error);
  }
  {
    bool got_type_error = false;
    var x = new List();
    try {
      Expect.isTrue(x is List<UndeclaredType>); // x is a List<dynamic>.
    } on TypeError catch (error) {
      got_type_error = true;
    }
    // No type error.
    Expect.isFalse(got_type_error);
  }
  {
    bool got_type_error = false;
    var x = new List<int>();
    try {
      Expect.isTrue(x is List<UndeclaredType>); // x is a List<int>.
    } on TypeError catch (error) {
      got_type_error = true;
    }
    // No type error.
    Expect.isFalse(got_type_error);
  }
}

main() {
  // Repeat type checks so that inlined tests can be tested as well.
  for (int i = 0; i < 5; i++) {
    testAll();
  }
}
