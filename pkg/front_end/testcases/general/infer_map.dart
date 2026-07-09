// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {}

class B extends A {}

List<int> intList = [1, 2];

List<A> list1 = intList.map((i) => new B()).toList();

test(List<A> list) {
  try {
    list.add(new A());
    list.removeLast();
  } catch (e) {
    return;
  }
  throw 'Expected subtype error';
}

main() {
  test(list1);
  list1 = intList.map((i) => new B()).toList();
  test(list1);

  List<A> list2 = intList.map((i) => new B()).toList();
  test(list2);
  list2 = intList.map((i) => new B()).toList();
  test(list2);

  test(intList.map((i) => new B()).toList());
}
