// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

class I1 {}

/*spec.class: I2:checkedInstance*/
class I2 {}

/*spec.class: A:checks=[$isI2],instance*/
/*prod.class: A:checks=[],instance*/
class A implements I1, I2 {}

/*spec.class: B:checks=[$isI2],instance*/
/*prod.class: B:checks=[],instance*/
class B implements I1, I2 {}

@pragma('dart2js:noInline')
void foo(I1 x) {}

@pragma('dart2js:noInline')
void bar(I2 x) {}

main() {
  dynamic f = bar;

  foo(new A());
  foo(new B());
  f(new A());
  f(new B());
}
