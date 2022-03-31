// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A1 {
  A1(int x);
}

class B1 extends A1 {
  B1.one(dynamic super.x); // Error.
  B1.two(dynamic super.x) : super(); // Error.
}

class A2 {
  A2({required String x});
}

class B2 extends A2 {
  B2.one({required dynamic super.x}); // Error.
  B2.two({required dynamic super.x}) : super(); // Error.
}

class A3 {
  A3(num Function(double) f);
}

class B3 extends A3 {
  B3.one(X Function<X>(double) super.f); // Error.
  B3.two(X Function<X>(double) super.f) : super(); // Error.
}

class A4 {
  A4({required num Function(double) f});
}

class B4 extends A4 {
  B4.one({required X Function<X>(double) super.f}); // Error.
  B4.two({required X Function<X>(double) super.f}) : super(); // Error.
}

abstract class C5 {
  String call(int x, num y);
}

class A5 {
  A5(String Function(int, num) f);
}

class B5 extends A5 {
  B5.one(C5 super.f); // Error.
  B5.two(C5 super.f) : super(); // Error.
}

class A6 {
  A6({required String Function(int, num) f});
}

class B6 extends A6 {
  B6.one({required C5 super.f}); // Error.
  B6.two({required C5 super.f}) : super(); // Error.
}

class A7 {
  A7({required int x1,
      required int x2,
      required bool Function(Object) f1,
      required bool Function(Object) f2,
      required void Function(dynamic) g1,
      required void Function(dynamic) g2});
}

class B7 extends A7 {
  B7({required dynamic super.x1, // Error.
      required dynamic x2,
      required X Function<X>(Object) super.f1, // Error.
      required X Function<X>(Object) f2,
      required void Function<X>(X) super.g1, // Error.
      required void Function<X>(X) g2}) :
    super(x2: x2, f2: f2, g2: g2); // Ok.
}

main() {}
