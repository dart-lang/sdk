// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/dart2js.dart';

/*class: I1:checkedInstance*/
class I1 {}

/*class: I2:checkedInstance,checkedTypeArgument,checks=[],typeArgument*/
class I2 {}

// TODO(32954): Exclude $isI1 because foo is only called directly.
/*class: A:checks=[$isI1,$isI2],instance*/
class A implements I1, I2 {}

// TODO(32954): Exclude $isI1 because foo is only called directly.
/*class: B:checks=[$isI1,$isI2],instance*/
class B implements I1, I2 {}

@noInline
void foo(I1 x) {}

@noInline
void bar(I2 x) {}

main() {
  dynamic f = bar;

  foo(new A());
  foo(new B());
  f(new A());
  f(new B());
}
