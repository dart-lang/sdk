// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C<T> {
  T value;
  C(this.value);
  C.id(this.value);

  C<int> toInt(int v) => C<int>(v);
}

extension type ET<T>(T v) {
  ET.id(this.v);

  ET<int> toInt(int v) => ET<int>(v);
}

class CC<T, S extends Iterable<T>> {
  T t;
  CC(this.t);
}

U bar<U>(CC<U, Iterable<U>> cc) => cc.t;

main() {
  var list1 = [bar(.new("String"))];
  List<String> list2 = list1;

  C<int> c1 = .new("String").toInt(1);
  C<int> c2 = .id("String").toInt(2);
  ET<int> et1 = .new("String").toInt(3);
  ET<int> et2 = .id("String").toInt(4);
  List<String> l =
      .generate(10, (int i) => i + 1).map((x) => x.toRadixString(16)).toList();
}
