// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// dart2jsOptions=--strong

// Regression test checking that nsm-forwarders do not get installed for private
// members of other libraries. See http://dartbug.com/33665

import 'package:expect/expect.dart';
import 'no_such_method_strong11_lib.dart';

abstract class J {
  int _m3();
  int _m4();
}

class A implements I, J {
  int _m1() => 1;
  int _m3() => 3;
  noSuchMethod(Invocation m) => -1;
}

main() {
  dynamic a = confuse(new A());
  Expect.equals(1, a._m1());
  Expect.equals(3, a._m3());
  Expect.equals(1, (a._m1)());
  Expect.equals(3, (a._m3)());

  Expect.equals(-1, a._m2());
  Expect.equals(-1, a._m4());
  Expect.isFalse(a._m2 is Function);
  Expect.equals(-1, a._m2);
  Expect.isTrue(a._m4 is Function);
  Expect.equals(-1, (a._m4)());
}

@pragma('dart2js:noInline')
@pragma('dart2js:assumeDynamic')
confuse(x) => x;
