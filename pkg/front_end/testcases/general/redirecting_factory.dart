// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class FooBase<Tf> {
  int get x;
  factory FooBase(int x) = Foo<Tf>;
}

abstract class Foo<T> implements FooBase {
  factory Foo(int x) = Bar<String, T>;
}

class Bar<Sb, Tb> implements Foo<Tb> {
  int x;
  Bar(this.x) {
    print('Bar<$Sb,$Tb>');
  }
}

class Builder<X> {
  method() {
    return new FooBase<X>(4);
  }
}

class SimpleCase<A, B> {
  factory SimpleCase() = SimpleCaseImpl<A, B>;
}

class SimpleCaseImpl<Ai, Bi> implements SimpleCase<Ai, Bi> {
  factory SimpleCaseImpl() = SimpleCaseImpl2<Ai, Bi>;
}

class SimpleCaseImpl2<Ai2, Bi2> implements SimpleCaseImpl<Ai2, Bi2> {}

class Base<M> {}

class Mixin<M> {}

class Mix<M> = Base<M> with Mixin<M>;

main() {
  print(new FooBase<double>(4).x);
  new SimpleCase<int, double>();
  new Mix<double>();
}
