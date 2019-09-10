// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {}
class B extends A {}
class C extends B {}

class GenericClass<T> {}

extension GenericExtension<T> on GenericClass<T> {
  T get property => null;

  T method(T t) => null;

  S genericMethod1<S>(S s) => null;
}

main() {
  A aVariable;
  C cVariable;

  GenericClass<A> aClass;
  GenericClass<B> bClass;
  GenericClass<C> cClass;

  cVariable = GenericExtension(aClass).property;
  cVariable = GenericExtension<A>(aClass).property;
  cVariable = GenericExtension<B>(aClass).property;
  cVariable = GenericExtension<C>(aClass).property;

  cVariable = GenericExtension(bClass).property;
  cVariable = GenericExtension<A>(bClass).property;
  cVariable = GenericExtension<B>(bClass).property;
  cVariable = GenericExtension<C>(bClass).property;

  aVariable = GenericExtension(cClass).property;
  aVariable = GenericExtension<A>(cClass).property;
  aVariable = GenericExtension<B>(cClass).property;
  aVariable = GenericExtension<C>(cClass).property;

  cVariable = GenericExtension(aClass).method(aVariable);
  cVariable = GenericExtension<A>(aClass).method(aVariable);
  cVariable = GenericExtension<B>(aClass).method(aVariable);
  cVariable = GenericExtension<C>(aClass).method(aVariable);

  cVariable = GenericExtension(bClass).method(aVariable);
  cVariable = GenericExtension<A>(bClass).method(aVariable);
  cVariable = GenericExtension<B>(bClass).method(aVariable);
  cVariable = GenericExtension<C>(bClass).method(aVariable);

  aVariable = GenericExtension(cClass).method(aVariable);
  aVariable = GenericExtension<A>(cClass).method(aVariable);
  aVariable = GenericExtension<B>(cClass).method(aVariable);
  aVariable = GenericExtension<C>(cClass).method(aVariable);

  cVariable = GenericExtension(aClass).genericMethod1(aVariable);
  cVariable = GenericExtension(aClass).genericMethod1<A>(aVariable);
  cVariable = GenericExtension(aClass).genericMethod1<B>(aVariable);
  cVariable = GenericExtension(aClass).genericMethod1<C>(aVariable);
  cVariable = GenericExtension<A>(aClass).genericMethod1(aVariable);
  cVariable = GenericExtension<A>(aClass).genericMethod1<A>(aVariable);
  cVariable = GenericExtension<A>(aClass).genericMethod1<B>(aVariable);
  cVariable = GenericExtension<A>(aClass).genericMethod1<C>(aVariable);
  cVariable = GenericExtension<B>(aClass).genericMethod1(aVariable);
  cVariable = GenericExtension<B>(aClass).genericMethod1<A>(aVariable);
  cVariable = GenericExtension<B>(aClass).genericMethod1<B>(aVariable);
  cVariable = GenericExtension<B>(aClass).genericMethod1<C>(aVariable);
  cVariable = GenericExtension<C>(aClass).genericMethod1(aVariable);
  cVariable = GenericExtension<C>(aClass).genericMethod1<A>(aVariable);
  cVariable = GenericExtension<C>(aClass).genericMethod1<B>(aVariable);
  cVariable = GenericExtension<C>(aClass).genericMethod1<C>(aVariable);

  cVariable = GenericExtension(bClass).genericMethod1(aVariable);
  cVariable = GenericExtension(bClass).genericMethod1<A>(aVariable);
  cVariable = GenericExtension(bClass).genericMethod1<B>(aVariable);
  cVariable = GenericExtension(bClass).genericMethod1<C>(aVariable);
  cVariable = GenericExtension<A>(bClass).genericMethod1(aVariable);
  cVariable = GenericExtension<A>(bClass).genericMethod1<A>(aVariable);
  cVariable = GenericExtension<A>(bClass).genericMethod1<B>(aVariable);
  cVariable = GenericExtension<A>(bClass).genericMethod1<C>(aVariable);
  cVariable = GenericExtension<B>(bClass).genericMethod1(aVariable);
  cVariable = GenericExtension<B>(bClass).genericMethod1<A>(aVariable);
  cVariable = GenericExtension<B>(bClass).genericMethod1<B>(aVariable);
  cVariable = GenericExtension<B>(bClass).genericMethod1<C>(aVariable);
  cVariable = GenericExtension<C>(bClass).genericMethod1(aVariable);
  cVariable = GenericExtension<C>(bClass).genericMethod1<A>(aVariable);
  cVariable = GenericExtension<C>(bClass).genericMethod1<B>(aVariable);
  cVariable = GenericExtension<C>(bClass).genericMethod1<C>(aVariable);

  cVariable = GenericExtension(cClass).genericMethod1(aVariable);
  cVariable = GenericExtension(cClass).genericMethod1<A>(aVariable);
  cVariable = GenericExtension(cClass).genericMethod1<B>(aVariable);
  cVariable = GenericExtension(cClass).genericMethod1<C>(aVariable);
  cVariable = GenericExtension<A>(cClass).genericMethod1(aVariable);
  cVariable = GenericExtension<A>(cClass).genericMethod1<A>(aVariable);
  cVariable = GenericExtension<A>(cClass).genericMethod1<B>(aVariable);
  cVariable = GenericExtension<A>(cClass).genericMethod1<C>(aVariable);
  cVariable = GenericExtension<B>(cClass).genericMethod1(aVariable);
  cVariable = GenericExtension<B>(cClass).genericMethod1<A>(aVariable);
  cVariable = GenericExtension<B>(cClass).genericMethod1<B>(aVariable);
  cVariable = GenericExtension<B>(cClass).genericMethod1<C>(aVariable);
  cVariable = GenericExtension<C>(cClass).genericMethod1(aVariable);
  cVariable = GenericExtension<C>(cClass).genericMethod1<A>(aVariable);
  cVariable = GenericExtension<C>(cClass).genericMethod1<B>(aVariable);
  cVariable = GenericExtension<C>(cClass).genericMethod1<C>(aVariable);
}