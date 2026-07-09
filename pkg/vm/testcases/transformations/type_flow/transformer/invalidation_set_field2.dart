// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class T1 {
  T3 go() => new T3();
}

class T2 {}

class T3 {
  run() {
    print('hi');
  }
}

class Q<T> {
  final T result;
  Q(this.result);
}

foo1(List<T1> list) {
  list.map((T1 t1) => new Q<T1>(t1)).first.result.go().run();
}

Q foo2NewValue() => new Q<T2>(new T2());

foo3NewT1() {
  new T1();
}

main(List<String> args) {
  foo1([]);
  foo2NewValue();
  foo3NewT1();
}
