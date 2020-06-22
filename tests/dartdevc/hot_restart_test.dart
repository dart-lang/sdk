// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'dart:_foreign_helper' show JS;
import 'dart:_runtime' as dart;

class Foo<T> {
  Type type() => typeOf<Foo<T>>();
}

class Bar {}

Type typeOf<T>() => T;

Type fooOf<T>() => typeOf<Foo<T>>();

typedef funcType = Function(String);

void func(Object o) {}

void main() {
  var f1 = Foo<Bar>();
  var t1 = typeOf<Foo<Bar>>();
  Expect.equals(f1.type(), t1);
  var s1 = fooOf<Bar>();
  Expect.equals(t1, s1);

  Expect.isTrue(func is funcType);

  dart.hotRestart();

  var f2 = Foo<Bar>();
  Expect.isTrue(f2 is Foo<Bar>);
  var t2 = typeOf<Foo<Bar>>();
  Expect.equals(f2.type(), t2);
  var s2 = fooOf<Bar>();
  Expect.equals(t2, s2);

  Expect.isTrue(func is funcType);
}
