// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {}

class B extends A {}

class C extends B {}

class GenericClass<T> {}

extension GenericExtension<T> on GenericClass<T> {
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

  aVariable = aClass.property;
  bVariable = bClass.property;
  cVariable = cClass.property;

  aVariable = aClass.method(aVariable);
  bVariable = bClass.method(bVariable);
  cVariable = cClass.method(cVariable);

  cVariable = aClass.genericMethod1(cVariable);
  aVariable = aClass.genericMethod1<A>(aVariable);
  bVariable = aClass.genericMethod1<B>(bVariable);
  cVariable = aClass.genericMethod1<C>(cVariable);

  cVariable = bClass.genericMethod1(cVariable);
  aVariable = bClass.genericMethod1<A>(cVariable);
  bVariable = bClass.genericMethod1<B>(cVariable);
  cVariable = bClass.genericMethod1<C>(cVariable);

  cVariable = cClass.genericMethod1(cVariable);
  aVariable = cClass.genericMethod1<A>(cVariable);
  bVariable = cClass.genericMethod1<B>(cVariable);
  cVariable = cClass.genericMethod1<C>(cVariable);
}
