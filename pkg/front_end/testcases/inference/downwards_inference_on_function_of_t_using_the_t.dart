// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

void main() {
  {
    T f<T>(T x) => throw '';
    var v1 = f;
    v1 = <S>(x) => x;
  }
  {
    List<T> f<T>(T x) => throw '';
    var v2 = f;
    v2 = <S>(x) => [x];
    Iterable<int> r = v2(42);
    Iterable<String> s = v2('hello');
    Iterable<List<int>> t = v2(<int>[]);
    Iterable<num> u = v2(42);
    Iterable<num> v = v2<num>(42);
  }
}
