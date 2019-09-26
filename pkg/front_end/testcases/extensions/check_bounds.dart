// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {}
class B extends A {}

class Class<T extends A> {}

extension Extension<T extends B> on Class<T> {
  method() {}
  genericMethod<S extends B>(S s) {}
}

main() {

}

test() {
  A a;

  Class<A> classA = new Class<A>();
  classA.method();
  Extension(classA).method();
  Extension<A>(classA).method();
  Extension<B>(classA).method();

  Class<B> classB = new Class<B>();
  classB.method();
  Extension(classB).method();
  Extension<A>(classB).method();
  Extension<B>(classB).method();

  classB.genericMethod(a);
  classB.genericMethod<A>(a);
  classB.genericMethod<B>(a);
  Extension(classB).genericMethod(a);
  Extension(classB).genericMethod<A>(a);
  Extension(classB).genericMethod<B>(a);
  Extension<A>(classB).genericMethod(a);
  Extension<A>(classB).genericMethod<A>(a);
  Extension<A>(classB).genericMethod<B>(a);
  Extension<B>(classB).genericMethod(a);
  Extension<B>(classB).genericMethod<A>(a);
  Extension<B>(classB).genericMethod<B>(a);
}