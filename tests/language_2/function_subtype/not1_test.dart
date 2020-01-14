// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.

// Check negative function subtyping tests.

import 'package:expect/expect.dart';

typedef void Foo<T>(T t);
typedef void Bar(int i);

class Class<T> {
  void bar(T i) {}
}

void main() {
  Expect.isFalse(new Class().bar is! Foo);
  Expect.isFalse(new Class().bar is! Foo<bool>);
  Expect.isFalse(new Class().bar is! Foo<int>);
  Expect.isFalse(new Class().bar is! Bar);

  Expect.isFalse(new Class<int>().bar is! Foo);
  Expect.isFalse(new Class<int>().bar is! Foo<bool>);
  Expect.isFalse(new Class<int>().bar is! Foo<int>);
  Expect.isFalse(new Class<int>().bar is! Bar);

  Expect.isFalse(new Class<bool>().bar is! Foo);
  Expect.isFalse(new Class<bool>().bar is! Foo<bool>);
  Expect.isFalse(new Class<bool>().bar is! Foo<int>);
  Expect.isFalse(new Class<bool>().bar is! Bar);
}
