// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

class I1 {}

class I2 {}

class A implements I1, I2 {}

class B implements I1, I2 {}

/*member: foo:params=1*/
@pragma('dart2js:noInline')
void foo(I1 x) {}

/*member: bar:params=1*/
@pragma('dart2js:noInline')
void bar(I2 x) {}

/*member: main:
 calls=[
  bar(1),
  bar(1),
  foo(1),
  foo(1)],
 params=0
*/
main() {
  dynamic f = bar;

  foo(new A());
  foo(new B());
  f(new A());
  f(new B());
}
