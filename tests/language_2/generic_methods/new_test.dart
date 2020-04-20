// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import "package:expect/expect.dart";

class C<E> {
  E e;
  C(this.e);
}

C<T> f1<T>(T t) => new C<T>(t);

List<T> f2<T>(T t) => <T>[t];

Map<T, String> f3<T>(T t) => <T, String>{t: 'hi'};

main() {
  C c = f1<int>(42);
  List i = f2<String>("Hello!");
  Expect.isTrue(c is C<int>);
  Expect.isFalse(c is C<String>);
  Expect.isTrue(i is List<String>);
  Expect.isFalse(i is List<int>);
  Expect.equals(c.e, 42);
  Expect.equals(i[0], "Hello!");

  Map m1 = f3<int>(1);
  Expect.isTrue(m1 is Map<int, String>);
  Expect.isFalse(m1 is Map<String, String>);
  Expect.isFalse(m1 is Map<int, int>);
  Expect.equals('hi', m1[1]);
}
