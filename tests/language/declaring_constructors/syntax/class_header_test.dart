// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests declaring constructors with various clauses.

// SharedOptions=--enable-experiment=declaring-constructors

import "package:expect/expect.dart";

// Generics
class GenericsHeader<T>(final T x);
class GenericsBody<T> {
  this(final T x);
}

// Extends
class Base {}

class ExtendsHeader(final int x) extends Base;
class ExtendsBody extends Base {
  this(final int x);
}

// Implements
abstract class Interface {
  int method();
}

class ImplementsHeader(final int x) implements Interface {
  @override
  int method() => x + 1;
}
class ImplementsBody implements Interface {
  this(final int x);

  @override
  int method() => x + 1;
}

// With
mixin Mixin {}

class WithHeader(final int x) with Mixin;
class WithBody with Mixin {
  this(final int x);
}

// Combination
class AllHeader<T>(final T x) extends Base with Mixin implements Interface {
  @override
  int method() => 1;
}

class AllBody<T> extends Base with Mixin implements Interface {
  this(final T x);

  @override
  int method() => 1;
}

void main() {
  Expect.equals(1, GenericsHeader<int>(1).x);
  Expect.equals("str", GenericsBody<String>("str").x);
  Expect.equals(1, ExtendsHeader(1).x);
  Expect.equals(1, ExtendsBody(1).x);
  Expect.equals(2, ImplementsHeader(1).method());
  Expect.equals(1, ImplementsHeader(1).x);
  Expect.equals(2, ImplementsBody(1).method());
  Expect.equals(1, ImplementsBody(1).x);
  Expect.equals(1, WithHeader(1).x);
  Expect.equals(1, WithBody(1).x);
  Expect.equals(1, AllHeader<int>(1).method());
  Expect.equals(1, AllHeader<int>(1).x);
  Expect.equals(1, AllBody<int>(1).method());
  Expect.equals(1, AllBody<int>(1).x);
}
