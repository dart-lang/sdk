// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests declaring constructors with various clauses.

// SharedOptions=--enable-experiment=declaring-constructors

import "package:expect/expect.dart";

// Generics
class GenericsHeader<T>(final T x);

// Extends
class Base {}

class ExtendsHeader(final int x) extends Base;

// Implements
abstract class Interface {
  int method();
}

class ImplementsHeader(final int x) implements Interface {
  @override
  int method() => x + 1;
}

// With
mixin Mixin {}

class WithHeader(final int x) with Mixin;

// Combination
class AllHeader<T>(final T x) extends Base with Mixin implements Interface {
  @override
  int method() => 1;
}

void main() {
  Expect.equals(1, GenericsHeader<int>(1).x);
  Expect.equals(1, ExtendsHeader(1).x);
  Expect.equals(2, ImplementsHeader(1).method());
  Expect.equals(1, ImplementsHeader(1).x);
  Expect.equals(1, WithHeader(1).x);
  Expect.equals(1, AllHeader<int>(1).method());
  Expect.equals(1, AllHeader<int>(1).x);
}
