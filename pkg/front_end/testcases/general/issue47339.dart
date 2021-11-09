// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Foo {
  const Foo.named();
  const factory Foo.namedFactory() = Foo.named;
}

typedef Bar = Foo;

const Bar bar = Bar.named();

const Bar bar2 = Bar.namedFactory();

class FooGeneric<X> {
  const FooGeneric.named();
  const factory FooGeneric.namedFactory() = FooGeneric.named;
}

typedef BarGeneric<X> = FooGeneric<X>;

const BarGeneric<int> barGeneric = BarGeneric.named();

const BarGeneric<int> barGeneric2 = BarGeneric.namedFactory();

main() {}
