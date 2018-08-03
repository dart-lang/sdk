// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2jsOptions=--strong

import 'package:expect/expect.dart';

abstract class A {
  m({a: 1, c: 3, b: 2});
}

class B implements A {
  noSuchMethod(Invocation i) {
    return '${i.namedArguments[#a]},${i.namedArguments[#b]},${i.namedArguments[#c]}';
  }
}

void main() {
  A x = new B();
  Expect.equals('1,2,3', x.m());
  Expect.equals('1,2,3', x.m(a: 1));
  Expect.equals('1,2,3', x.m(c: 3));
  Expect.equals('1,2,3', x.m(b: 2));
  Expect.equals('1,2,3', x.m(a: 1, b: 2));
  Expect.equals('1,2,3', x.m(a: 1, b: 2, c: 3));
}
