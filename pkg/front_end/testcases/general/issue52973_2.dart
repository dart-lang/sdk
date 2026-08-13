// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void f<X>(X? arg) {
  if (arg is int) {
    X x = arg;
    int i = arg;
    var xs = [arg];
    CheckType(xs).expect<Exactly<List<X>>>();
    List<X> ys = xs;
    CheckType(ys).expect<Exactly<List<X>>>();
    List<X?> ys2 = xs;
    CheckType(ys2).expect<Exactly<List<X?>>>();
    var ys3 = xs as List<Object>;
    CheckType(ys3).expect<Exactly<List<Object>>>();
  }
}

typedef Exactly<T> = T Function(T);

extension CheckType<T> on T {
  void expect<S extends Exactly<T>>() {}
}

void main() {
  f<Object>(1);
}
