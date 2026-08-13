// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {}

class B extends A {}

class C extends B {}

class GenericClass<T> {}

extension GenericExtension<T> on GenericClass<T>? {
  T? get property => null;

  T? method(T? t) => null;

  S? genericMethod1<S>(S? s) => null;
}

main() {
  A? aVariable;
  B? bVariable;
  C? cVariable;

  GenericClass<A> aClass = new GenericClass<A>();
  GenericClass<B> bClass = new GenericClass<B>();
  GenericClass<C> cClass = new GenericClass<C>();

  aVariable = GenericExtension(aClass).property;
  aVariable = GenericExtension<A>(aClass).property;

  bVariable = GenericExtension(bClass).property;
  aVariable = GenericExtension<A>(bClass).property;
  bVariable = GenericExtension<B>(bClass).property;

  cVariable = GenericExtension(cClass).property;
  aVariable = GenericExtension<A>(cClass).property;
  bVariable = GenericExtension<B>(cClass).property;
  cVariable = GenericExtension<C>(cClass).property;

  aVariable = GenericExtension(aClass).method(aVariable);
  aVariable = GenericExtension<A>(aClass).method(aVariable);

  bVariable = GenericExtension(bClass).method(bVariable);
  aVariable = GenericExtension<A>(bClass).method(aVariable);
  bVariable = GenericExtension<B>(bClass).method(bVariable);

  cVariable = GenericExtension(cClass).method(cVariable);
  aVariable = GenericExtension<A>(cClass).method(aVariable);
  bVariable = GenericExtension<B>(cClass).method(bVariable);
  cVariable = GenericExtension<C>(cClass).method(cVariable);

  cVariable = GenericExtension(aClass).genericMethod1(cVariable);
  aVariable = GenericExtension(aClass).genericMethod1<A>(cVariable);
  bVariable = GenericExtension(aClass).genericMethod1<B>(cVariable);
  cVariable = GenericExtension(aClass).genericMethod1<C>(cVariable);
  cVariable = GenericExtension<A>(aClass).genericMethod1(cVariable);
  aVariable = GenericExtension<A>(aClass).genericMethod1<A>(cVariable);
  bVariable = GenericExtension<A>(aClass).genericMethod1<B>(cVariable);
  cVariable = GenericExtension<A>(aClass).genericMethod1<C>(cVariable);

  cVariable = GenericExtension(bClass).genericMethod1(cVariable);
  aVariable = GenericExtension(bClass).genericMethod1<A>(cVariable);
  bVariable = GenericExtension(bClass).genericMethod1<B>(cVariable);
  cVariable = GenericExtension(bClass).genericMethod1<C>(cVariable);
  cVariable = GenericExtension<A>(bClass).genericMethod1(cVariable);
  aVariable = GenericExtension<A>(bClass).genericMethod1<A>(cVariable);
  bVariable = GenericExtension<A>(bClass).genericMethod1<B>(cVariable);
  cVariable = GenericExtension<A>(bClass).genericMethod1<C>(cVariable);
  cVariable = GenericExtension<B>(bClass).genericMethod1(cVariable);
  aVariable = GenericExtension<B>(bClass).genericMethod1<A>(cVariable);
  bVariable = GenericExtension<B>(bClass).genericMethod1<B>(cVariable);
  cVariable = GenericExtension<B>(bClass).genericMethod1<C>(cVariable);

  cVariable = GenericExtension(cClass).genericMethod1(cVariable);
  aVariable = GenericExtension(cClass).genericMethod1<A>(cVariable);
  bVariable = GenericExtension(cClass).genericMethod1<B>(cVariable);
  cVariable = GenericExtension(cClass).genericMethod1<C>(cVariable);
  cVariable = GenericExtension<A>(cClass).genericMethod1(cVariable);
  aVariable = GenericExtension<A>(cClass).genericMethod1<A>(cVariable);
  bVariable = GenericExtension<A>(cClass).genericMethod1<B>(cVariable);
  cVariable = GenericExtension<A>(cClass).genericMethod1<C>(cVariable);
  cVariable = GenericExtension<B>(cClass).genericMethod1(cVariable);
  aVariable = GenericExtension<B>(cClass).genericMethod1<A>(cVariable);
  bVariable = GenericExtension<B>(cClass).genericMethod1<B>(cVariable);
  cVariable = GenericExtension<B>(cClass).genericMethod1<C>(cVariable);
  cVariable = GenericExtension<C>(cClass).genericMethod1(cVariable);
  aVariable = GenericExtension<C>(cClass).genericMethod1<A>(cVariable);
  bVariable = GenericExtension<C>(cClass).genericMethod1<B>(cVariable);
  cVariable = GenericExtension<C>(cClass).genericMethod1<C>(cVariable);
}
