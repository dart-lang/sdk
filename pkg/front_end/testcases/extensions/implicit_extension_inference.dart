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

  cVariable = aClass.property;
  cVariable = bClass.property;
  aVariable = cClass.property;

  cVariable = aClass.method(aVariable);
  cVariable = bClass.method(aVariable);
  aVariable = cClass.method(aVariable);

  cVariable = aClass.genericMethod1(aVariable);
  cVariable = aClass.genericMethod1<A>(aVariable);
  cVariable = aClass.genericMethod1<B>(aVariable);
  cVariable = aClass.genericMethod1<C>(aVariable);

  cVariable = bClass.genericMethod1(aVariable);
  cVariable = bClass.genericMethod1<A>(aVariable);
  cVariable = bClass.genericMethod1<B>(aVariable);
  cVariable = bClass.genericMethod1<C>(aVariable);

  cVariable = cClass.genericMethod1(aVariable);
  cVariable = cClass.genericMethod1<A>(aVariable);
  cVariable = cClass.genericMethod1<B>(aVariable);
  cVariable = cClass.genericMethod1<C>(aVariable);
}