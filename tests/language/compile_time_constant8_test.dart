// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<T> {
  const A();
  toString() => "a";
}

final a = const A<int>();
final b = const A<double>();

final list1 = const<int> [1, 2];
final list2 = const [1, 2];
main() {
  Expect.isFalse(a === b);
  Expect.isFalse(list1 === list2);
}
