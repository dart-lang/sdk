// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*strong.class: I1:*/
/*omit.class: I1:*/
class I1 {}

/*strong.class: I2:checkedInstance,checkedTypeArgument,checks=[],typeArgument*/
/*omit.class: I2:checkedTypeArgument,checks=[],typeArgument*/
class I2 {}

/*strong.class: A:checks=[$isI2],instance*/
/*omit.class: A:checks=[$isI2],instance*/
class A implements I1, I2 {}

/*strong.class: B:checks=[$isI2],instance*/
/*omit.class: B:checks=[$isI2],instance*/
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
