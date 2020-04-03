// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.

// Check function subtyping casts.

import 'package:expect/expect.dart';

typedef void Foo<T>(T t);
typedef void Bar(int i);

class Class<T> {
  void bar(T i) {}
}

void main() {
  Expect.isNotNull(new Class().bar as Foo);
  Expect.isNotNull(new Class().bar as Foo<bool>);
  Expect.isNotNull(new Class().bar as Foo<int>);
  Expect.isNotNull(new Class().bar as Bar);

  Expect.isNotNull(new Class<int>().bar as Foo);
  Expect.isNotNull(new Class<int>().bar as Foo<bool>);
  Expect.isNotNull(new Class<int>().bar as Foo<int>);
  Expect.isNotNull(new Class<int>().bar as Bar);

  Expect.isNotNull(new Class<bool>().bar as Foo);
  Expect.isNotNull(new Class<bool>().bar as Foo<bool>);
  Expect.isNotNull(new Class<bool>().bar as Foo<int>);
  Expect.isNotNull(new Class<bool>().bar as Bar);
}
