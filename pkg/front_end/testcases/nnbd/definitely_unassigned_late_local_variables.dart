// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The test checks that it's a compile-time error to read a late local
// variables of a potentially non-nullable type if it is definitely
// unassigned.

abstract class A<T> {
  bar(T value) {}
  barInt(int value) {}
  foo() {
    late T value;
    late int intValue;
    bar(value); // Error.
    barInt(intValue); // Error.
  }
}

main() {}
