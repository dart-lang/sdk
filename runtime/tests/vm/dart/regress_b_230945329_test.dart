// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for b/230945329.
//
// Check that AssertAssignables for the same uninstantiated type, where the
// instantiated types at runtime may differ, are not optimized away.
//
// VMOptions=--no-use-field-guards --no-use-osr --deterministic --optimization-counter-threshold=90

void main() {
  final bar = Box<dynamic>('a'); // T=dynamic
  final barInt = Box<int>(1); // T=int

  for (int i = 0; i < 100; ++i) {
    bar.bar(bar);
  }
  try {
    barInt.bar(bar);
    throw 'that should have failed!';
  } on TypeError catch (e, s) {}
}

class Box<T> {
  final T v;
  Box(this.v);

  void bar(Box box) {
    // The uninstantiated compile type of box.v is T, same as the uninstantiated
    // compile type it's being checked against. It's only the instantiated
    // versions at runtime that could differ: the first instance type argument
    // of box (box.v) vs. the first instance type argument of this (T).
    baz(box.v/*=T*/ as T/*=T*/);
  }
}

@pragma('vm:never-inline')
baz(e) {}
