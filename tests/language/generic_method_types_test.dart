// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--generic-method-syntax --no-reify-generic-functions

import 'package:expect/expect.dart';

typedef O Convert<I, O>(I input);
typedef Other(a, b);

class Mixin<E> {
  E convert1<I>(I input) => null;
}

class Class<F> extends Object with Mixin<F> {
  O convert2<O>(F input) => null;
}

O convert<I, O>(I input) => null;

test1() {
  var val = new Class<String>();
  Expect.isTrue(val.convert1 is Convert);
  Expect.isTrue(val.convert1 is Convert<String, String>);
  Expect.isTrue(val.convert1 is Convert<int, String>);
  Expect.isFalse(val.convert1 is Convert<String, int>);
  Expect.isFalse(val.convert1 is Other);
}

test2() {
  var val = new Class<String>();
  Expect.isTrue(val.convert2 is Convert);
  Expect.isTrue(val.convert2 is Convert<String, String>);
  Expect.isTrue(val.convert2 is Convert<String, int>);
  Expect.isFalse(val.convert2 is Convert<int, String>);
  Expect.isFalse(val.convert2 is Other);
}

test3() {
  Expect.isTrue(convert is Convert);
  Expect.isTrue(convert is Convert<String, String>);
  Expect.isTrue(convert is Convert<String, int>);
  Expect.isTrue(convert is Convert<int, String>);
  Expect.isFalse(convert is Other);
}

main() {
  test1(); //# 01: ok
  test2(); //# 02: ok
  test3(); //# 03: ok
}
