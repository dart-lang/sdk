// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2jsOptions=--strong

@JS()
library foo;

import 'package:expect/expect.dart';
import 'package:js/js.dart';

@JS()
@anonymous
class A<T> {
  external factory A();
}

class B<T> {}

@JS()
@anonymous
class C implements B<int> {
  external factory C();
}

class D<T> {}

@JS()
@anonymous
class E implements B<String> {
  external factory E();
}

main() {
  test(new A<int>());
  test(new A<String>());
  test(new C());
  test(new E());
}

test(o) {
  Expect.isTrue(o is A<int>, "Expected $o to be A<int>");
  Expect.isTrue(o is A<String>, "Expected $o to be A<String>");

  Expect.isTrue(o is B<int>, "Expected $o to be B<int>");
  Expect.isTrue(o is B<String>, "Expected $o to be B<String>");

  Expect.isFalse(o is D<int>, "Expected $o not to be D<int>");
}
