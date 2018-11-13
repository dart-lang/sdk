// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/dart2js.dart';

/*class: A:deps=[B],direct,explicit=[A.T],needsArgs*/
class A<T> {
  @noInline
  foo(x) {
    return x is T;
  }
}

/*class: BB:implicit=[BB]*/
class BB {}

/*class: B:implicit=[B.T],indirect,needsArgs*/
class B<T> implements BB {
  @noInline
  foo() {
    return new A<T>().foo(new B());
  }
}

main() {
  new B<BB>().foo();
}
