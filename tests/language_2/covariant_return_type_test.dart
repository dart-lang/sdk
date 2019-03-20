// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

void main() {
  Expect.throwsTypeError(() {
    List<int> l = [1, 2, 3].where((x) => x.isEven).map((x) => x + 1);
  }, 'Iterable<int> should fail implicit cast to List<int>');

  Iterable<int> l = [1, 2, 3].where((x) => x.isEven).map((x) => x + 1);
  Expect.isFalse(l is List<int>, 'Iterable<int> is not a subtype of List<int>');

  C<Object> c = C<Object>(1);
  Iterable<bool Function(Object)> myList = c.f(); // works

  Expect.throwsTypeError(() {
    C<Object> c = C<Object>(1);
    List<bool Function(Object)> myList = c.f();
  }, "f() returns an Iterable, not a List");

  Expect.throwsTypeError(() {
    C<Object> c = C<int>(1);
    List<bool Function(Object)> myList = c.f();
  }, "f() returns an Iterable, not a List");

  Expect.throwsTypeError(() {
    C<Object> c = C<int>(1);
    Iterable<bool Function(Object)> myList = c.f();
  }, "f() returns functions accepting int, not Object");

  {
    C<Iterable<Object>> c = D<Object>([1]);
    Iterable<bool Function(Iterable<Object>)> myList = c.f();
  }

  Expect.throwsTypeError(() {
    C<Iterable<Object>> c = D<Object>([1]);
    List<bool Function(Iterable<Object>)> myList = c.f();
  }, "D.f() returns an Iterable, not a List");

  Expect.throwsTypeError(() {
    C<Iterable<Object>> c = D<int>([1]);
    Iterable<bool Function(Iterable<Object>)> myList = c.f();
  }, "D.f() returns functions accepting Iterable<int>, not Iterable<Object>");
}

class C<T> {
  final T t;
  C(this.t);
  Iterable<bool Function(T)> f() sync* {
    yield (T x) => x == t;
  }
}

class D<S> extends C<Iterable<S>> {
  D(Iterable<S> s) : super(s);
}
