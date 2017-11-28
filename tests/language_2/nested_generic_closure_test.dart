// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--reify-generic-functions

import 'package:expect/expect.dart';

void foo(F f<F>(F f)) {}

B bar<B>(B g<F>(F f)) => null;

Function baz<B>() {
  B foo<F>(F f) => null;
  return foo;
}

class C<T> {
  void foo(F f<F>(T t, F f)) => null;
  B bar<B>(B g<F>(T t, F f)) => null;
  Function baz<B>() {
    B foo<F>(T t, F f) => null;
    return foo;
  }
}

main() {
  Expect.equals("(<F>(F) => F) => void", foo.runtimeType.toString());
  Expect.equals("<B>(<F>(F) => B) => B", bar.runtimeType.toString());
  Expect.equals("<F>(F) => int", baz<int>().runtimeType.toString());
  var c = new C<bool>();
  Expect.equals("(<F>(bool, F) => F) => void", c.foo.runtimeType.toString());
  Expect.equals("<B>(<F>(bool, F) => B) => B", c.bar.runtimeType.toString());
  Expect.equals("<F>(bool, F) => int", c.baz<int>().runtimeType.toString());
}
