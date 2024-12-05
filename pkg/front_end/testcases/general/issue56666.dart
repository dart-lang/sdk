// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  T call<T>(T t) => t;
}

X Function(String) f<X>(X Function(String) g) => g;

void main() {
  var g = f((C()));
  Checker(g).expectStaticType<Exactly<String Function(String)>>();
}

typedef Exactly<X> = X Function(X);

class Checker<X> {
  final X x;

  Checker(this.x);

  X expectStaticType<Y extends Exactly<X>>() => x;
}
