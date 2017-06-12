// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that a program in csp mode doesn't access the prototype chain
// on platforms that don't support direct access to __proto__.
// This test is most useful with --csp and on a platform that doesn't support
// __proto__ access (such as Rhino).
// See http://dartbug.com/27290 .

import 'package:expect/expect.dart';

class A {
  var x;
  foo() => 44;
  bar() => 22;
}

class B {
  var y;
  foo() => 42;
}

class C extends A with B {
  var z;
  bar() => 499;
}

@NoInline()
@AssumeDynamic()
confuse(x) => x;

main() {
  var all = [new A(), new B(), new C()];
  Expect.equals(44, confuse(all[0]).foo());
  Expect.equals(22, confuse(all[0]).bar());
  Expect.equals(42, confuse(all[1]).foo());
  Expect.equals(42, confuse(all[2]).foo());
  Expect.equals(499, confuse(all[2]).bar());
}
