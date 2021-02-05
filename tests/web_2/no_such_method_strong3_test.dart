// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// dart2jsOptions=--strong

import 'package:expect/expect.dart';

abstract class A {
  m(x, y);
}

class B implements A {
  noSuchMethod(Invocation i) {
    return '${i.positionalArguments[0]},${i.positionalArguments[1]}';
  }
}

void main() {
  A x = new B();
  Expect.equals('3,4', x.m(3, 4));
}
