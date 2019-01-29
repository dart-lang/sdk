// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {}

class B {}

class C extends B implements A {}

List<A> list;

List<T> g<T extends A>(T t) {
  list = <T>[];
  print(list.runtimeType);
  return list;
}

List<S> f<S>(S s) {
  if (s is A) {
    var list = g(s);
    return list;
  }
  return null;
}

main() {
  f<B>(new C());
  print(list.runtimeType);
  List<A> aList;
  aList = list;
  Object o = aList;
  aList = o;
}
