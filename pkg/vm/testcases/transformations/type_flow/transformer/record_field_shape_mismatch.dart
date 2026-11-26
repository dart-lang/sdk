// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test verifying that a record field access does not crash TFA when
// the inferred receiver is a record of a different shape than the static
// receiver type. This can happen as TFA does not distinguish function types
// and instantiations of generic classes or functions.

void main() {
  testGenericField();
  testFunctionType();
  testGenericClosure();
}

// A field of type `T` holds the records of all instantiations of its class.
void testGenericField() {
  print(Box<(String,)>(('a',)).value.$1);

  // No Box<(int, int)> is ever allocated: the loop body is unreachable.
  final list = <Box<(int, int)>>[];
  for (final b in list) {
    // Mismatched record shape missing field '$2': must not crash.
    print(b.value.$2);
  }

  // Type arguments are not tracked for Box, so `is` checks do not filter.
  Object box = Box<(String,)>(('b',));
  if (box is Box<(int, int)>) {
    // Mismatched record shape sharing field name '$1': unreachable.
    print(box.value.$1);
  }
  if (box is Box<({int x})>) {
    // Mismatched record shape missing named field 'x': must not crash.
    print(box.value.x);
  }
}

// Function types are erased, so `is` checks do not filter closures.
void testFunctionType() {
  Object f = () => ('c',);
  if (f is (int, int) Function()) {
    // Mismatched record shape missing field '$2': must not crash.
    print(f().$2);
  }
  Object g = () => (a: 'd');
  if (g is ({int b}) Function()) {
    // Mismatched record shape missing named field 'b': must not crash.
    print(g().b);
  }
}

// A closure of a generic function is shared by all its instantiations.
void testGenericClosure() {
  final c1 = makeClosure<(String,)>(('e',));
  final c2 = makeClosure<(int, int)>(null);
  print(c1()!.$1);
  // Only a (String,) is ever captured: unreachable and must not crash.
  print(c2()!.$2);
}

class Box<T> {
  final T value;
  Box(this.value);
}

T? Function() makeClosure<T>(T? x) =>
    () => x;
