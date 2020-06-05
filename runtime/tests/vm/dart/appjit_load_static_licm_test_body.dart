// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that field load can't be hoisted above field initialization.

import 'package:expect/expect.dart';

// Classes used to trigger deoptimization when running from app-jit snapshot.
class A {
  void foo() {}
}

class B {
  void foo() {}
}

// Static final field with a non-trivial initializer.
// This field will be reset before snapshot is written.
final field = (() => 'value')();

dynamic bar(dynamic o, {bool loadField: false}) {
  o.foo();
  // Create loop to trigger loop invariant code motion. We are testing that
  // field load can't be hoisted above field initialization.
  for (var i = 0; i < 2; i++) {
    final v = loadField ? field : null;
    if (loadField) {
      return v;
    }
  }
  return null;
}

void main(List<String> args) {
  final isTraining = args.contains("--train");
  dynamic o = isTraining ? new A() : new B();
  for (var i = 0; i < 20000; i++) {
    bar(o, loadField: false);
    if (isTraining) {
      // Initialize the field when training.
      bar(o, loadField: true);
    }
  }
  Expect.equals('value', bar(o, loadField: true));
  print(isTraining ? 'OK(Trained)' : 'OK(Run)');
}
