// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/dart2js.dart';

/*class: A:checks=[],instance*/
class A<T> {
  @noInline
  foo(x) {
    return x is T;
  }
}

/*class: BB:checkedInstance,checks=[],typeArgument*/
class BB {}

/*class: B:checks=[$isBB],instance*/
class B<T> implements BB {
  @noInline
  foo() {
    return new A<T>().foo(new B());
  }
}

main() {
  new B<BB>().foo();
}
