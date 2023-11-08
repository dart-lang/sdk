// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--use_slow_path --runtime_allocate_old

// Test that array allocation in noSuchMethod dispatcher is preserving the
// length register correctly.

import 'dart:async';

import 'package:expect/expect.dart';

final List<dynamic> list = <dynamic>[];

final List<int> invocations = <int>[];

abstract class B {
  void someMethod(int v);
}

class A {
  noSuchMethod(Invocation i) {
    Expect.equals(#someMethod, i.memberName);
    invocations.add(i.positionalArguments[0] as int);
  }
}

class C implements B {
  void someMethod(int v) {
    invocations.add(v);
  }
}

void main() {
  for (var i = 0; i < 10; i++) {
    list.add(A());
    list.add(C());
  }

  for (var i = 0; i < list.length; i++) {
    list[i].someMethod(i);
  }

  Expect.equals(list.length, invocations.length);
  for (var i = 0; i < list.length; i++) {
    Expect.equals(i, invocations[i]);
  }
}
