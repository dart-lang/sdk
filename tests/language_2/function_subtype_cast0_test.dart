// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.

// Check function subtyping casts.

import 'package:expect/expect.dart';

typedef void Foo<T>(T t);
typedef void Bar(int i);

void bar(int i) {}

void main() {
  Expect.isNotNull(bar as Foo);
  Expect.throws(() => bar as Foo<bool>, (e) => true);
  Expect.isNotNull(bar as Foo<int>);
  Expect.isNotNull(bar as Bar);
}
