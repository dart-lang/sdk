// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

typedef Convert1<O> = O Function<I>(I input);
typedef Convert2<I> = O Function<O>(I input);
typedef Convert3 = O Function<I, O>(I input);
typedef Other(a, b);

class Mixin<E> {
  E convert1<I>(I input) => null;
}

class Class<F> extends Object with Mixin<F> {
  O convert2<O>(F input) => null;
}

O convert3<I, O>(I input) => null;

test1() {
  var val = new Class<String>();
  Expect.isTrue(val.convert1 is Convert1);
  Expect.isFalse(val.convert1 is Convert2);
  Expect.isTrue(val.convert1 is Convert1<String>);
  Expect.isFalse(val.convert1 is Convert1<int>);
  Expect.isFalse(val.convert1 is Convert2<String>);
  Expect.isFalse(val.convert1 is Other);
}

test2() {
  var val = new Class<String>();
  Expect.isTrue(val.convert2 is Convert2);
  Expect.isFalse(val.convert2 is Convert1);
  Expect.isTrue(val.convert2 is Convert2<String>);
  Expect.isFalse(val.convert2 is Convert2<int>);
  Expect.isFalse(val.convert2 is Convert1<String>);
  Expect.isFalse(val.convert2 is Other);
}

test3() {
  Expect.isTrue(convert3 is Convert3);
  Expect.isFalse(convert3 is Other);
}

main() {
  test1(); //# 01: ok
  test2(); //# 02: ok
  test3(); //# 03: ok
}
