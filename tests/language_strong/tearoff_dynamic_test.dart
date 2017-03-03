// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:expect/expect.dart';

class Foo {
  dynamic method(int x) {}
}

main() {
  Foo foo = new Foo();

  dynamic dynamicMethod1 = foo.method;
  Expect.throws(() => dynamicMethod1(2.5));

  dynamic dynamicMethod2 = (foo as dynamic).method;
  Expect.throws(() => dynamicMethod2(2.5));
}
