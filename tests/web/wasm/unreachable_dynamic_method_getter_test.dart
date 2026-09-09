// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

void main() {
  final list = <dynamic>[A(), B()];
  for (int i = 0; i < list.length; ++i) {
    final value = list[i];
    if (i == 0) {
      Expect.throws(() => value.getter);
      Expect.throws(() => value.method(one));
    } else {
      Expect.equals(one, value.getter);
      Expect.equals(one + 1, value.method(one));
    }
  }
}

final one = int.parse('1');

class A {
  Never get getter => throw 1;
  Never method(int value) => throw 1;
}

class B {
  int get getter => one;
  int method(int value) => value + 1;
}
