// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  String call(String s) => '$s$s';
}

class B<T> {
  T call(T t) => t;
}

class C {
  T call<T>(T t) => t;
}

test() {
  A a = A();
  List<String> list1 = ['a', 'b', 'c'].map(a.call).toList();
  List<String> list2 = ['a', 'b', 'c'].map(a).toList();

  B<String> b = B();
  List<String> list3 = ['a', 'b', 'c'].map(b.call).toList();
  List<String> list4 = ['a', 'b', 'c'].map(b).toList();

  C c = C();
  List<String> list5 = ['a', 'b', 'c'].map(c.call).toList();
  List<String> list6 = ['a', 'b', 'c'].map(c).toList();
}

main() {}
