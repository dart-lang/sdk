// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/dart2js.dart';
import "package:expect/expect.dart";

/*class: A:deps=[method2],direct,explicit=[A.T],needsArgs*/
class A<T> {
  @noInline
  foo(x) {
    return x is T;
  }
}

/*class: BB:arg,checked,implicit=[BB]*/
class BB {}

/*element: method2:deps=[B],implicit=[method2.T],indirect,needsArgs*/
@noInline
method2<T>() => new A<T>();

/*class: B:implicit=[B.T],indirect,needsArgs*/
class B<T> implements BB {
  @noInline
  foo() {
    return method2<T>().foo(new B());
  }
}

main() {
  Expect.isTrue(new B<BB>().foo());
  Expect.isFalse(new B<String>().foo());
}
