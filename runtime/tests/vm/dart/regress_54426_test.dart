// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/54426.

import 'package:expect/expect.dart';

class A<P> {
  final List bar2TypeArguments = [];

  void foo<Q1>() {
    void bar<T1>(List<T1>? arg) {
      void bar2<T2 extends Map<Q1, T1>>(List<T2>? arg) {
        bar2TypeArguments..add(T2);
      }

      dynamic f = bar2;
      f(null);
    }

    // Call with explicit type arguments.
    bar<int>(null);
  }
}

void main() {
  final a = new A<int>();
  a.foo<num>();
  Expect.equals(Map<num, int>, a.bar2TypeArguments.first);
}
