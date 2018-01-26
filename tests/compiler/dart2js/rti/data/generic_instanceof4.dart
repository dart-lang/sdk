// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/dart2js.dart';

/*class: A:needsArgs,deps=[B],test,explicit=[A.T]*/
class A<T> {
  @noInline
  foo(x) {
    return x is T;
  }
}

/*class: BB:implicit=[BB],required,checks=[BB]*/
class BB {}

/*class: B:needsArgs,indirectTest,implicit=[B.T]*/
class B<T> implements BB {
  @noInline
  foo() {
    return new A<T>().foo(new B());
  }
}

main() {
  new B<BB>().foo();
}
