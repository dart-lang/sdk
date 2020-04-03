// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is a regression test to http://dartbug.com/40601.

abstract class A<T> {
  T baz();
  bar(T value) {}
  barInt(int value) {}
  foo() {
    late T value;
    late int intValue;
    // The use of variable "value" below shouldn't be a compile-time
    // error because it's late and not definitely unassigned.
    var result = () {
      bar(value);
      barInt(intValue);
    };
    (() {
      value = baz();
      intValue = 42;
    })();
    return result;
  }
}

main() {}
