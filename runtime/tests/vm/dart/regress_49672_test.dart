// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that hash code of equal types is the same and not zero.
// Regression test for https://github.com/dart-lang/sdk/issues/49672.

import 'package:expect/expect.dart';

class Foo<T> {
  final brokenType = List<T>;
}

class Bar {}

void test1<T>() {
  Expect.equals(Foo<Bar>, Foo<Bar>);
  Expect.equals((Foo<Bar>).hashCode, (Foo<Bar>).hashCode);
  Expect.equals(Foo<T>, Foo<Bar>);
  Expect.equals((Foo<T>).hashCode, (Foo<Bar>).hashCode);
}

void test2<T>() {
  Expect.equals(Foo<Bar>, Foo<Bar>);
  Expect.equals((Foo<Bar>).hashCode, (Foo<Bar>).hashCode);
  Expect.equals(T, Foo<Bar>);
  Expect.equals((T).hashCode, (Foo<Bar>).hashCode);
}

void main() {
  test1<Bar>();
  test2<Foo<Bar>>();

  final a = Foo<Object>();
  Expect.isTrue(a.brokenType.hashCode != 0);
}
